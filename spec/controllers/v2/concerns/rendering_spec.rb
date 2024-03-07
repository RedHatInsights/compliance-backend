# frozen_string_literal: true

# The `parents` parameter is required when testing nested controllers, and it should contain
# an ordered list of reflection symbols similarly to how they are defined in the routes. It is
# also required to set the `extra_params` variable in a let block and pass all the parent IDs
# there as a hash. For example:
# ```
# let(:extra_params) { { security_guide_id: 123, profile_id: 456 } }
#
# it_behaves_like 'collection', :security_guide, :profile
# ```
#
# In a non-nested case the let block should contain an empty hash and the `parents` parameter
# should be empty, like so:
# ```
# let(:extra_params) { {} }
#
# it_behaves_like 'collection'
# ```
#
# In some cases, however, additional ActiveRecord objects and scalar values are required for
# invoking a factory. Therefore, if you don't want these objects to be passed to the `params`
# of the request, you can safely specify ActiveRecord objects in the `extra_params`. For scalar
# values you can use the `pw()` wrapper method that makes sure that the value is only passed to
# the factory and not to the URL params.
# ```
# let(:extra_params) { { account: FactoryBot.create(:v2_account), system_count: pw(10) } }
#
# it_behaves_like 'collection'
# ```
#
RSpec.shared_examples 'collection' do |*parents|
  let(:passable_params) { reject_nonscalar(extra_params) }

  it 'returns base fields for each result' do
    collection = items.map do |item|
      hash_including(
        'id' => item.id,
        'type' => described_class.controller_name.singularize,
        **attributes.each_with_object({}) do |(key, value), obj|
          # If it is a lambda, execute it on the instance, otherwise call the method by name
          obj[key.to_s] = value.is_a?(Proc) ? item.instance_exec(&value) : item.send(value)
        end
      )
    end

    get :index, params: passable_params.merge(parents: parents)

    expect(response).to have_http_status :ok
    expect(response_body_data).to match_array(collection)

    response_body_data.each do |item|
      expect(item.keys.count).to eq((attributes.keys + %i[id type]).count)
    end
  end

  context 'under a single incorrect parent', if: parents.present? do
    parents.each do |parent|
      context "#{parent} is incorrect" do
        it 'returns not_found' do
          reflection = subject.send(:resource).reflect_on_association(parent)

          get :index, params: passable_params.merge(reflection.foreign_key => Faker::Internet.uuid, parents: parents)

          expect(response).to have_http_status :not_found
        end
      end
    end
  end

  context 'under invalid parent hierarchy', if: parents.count > 1 do
    (1..parents.length - 1).each do |count|
      parents.combination(count).each do |invalid_parents|
        context "#{invalid_parents.join(',')} are invalid" do
          it 'returns not_found' do
            params = invalid_parents.each_with_object(parents: parents) do |parent, obj|
              reflection = subject.send(:resource).reflect_on_association(parent)
              reflection_key = reflection.foreign_key.to_sym
              obj[reflection_key] = invalid_params[reflection_key]
            end

            get :index, params: passable_params.merge(params)

            expect(response).to have_http_status :not_found
          end
        end
      end
    end
  end

  context 'Unathorized' do
    let(:rbac_allowed?) { false }

    it 'responds with unauthorized status' do
      get :index, params: passable_params.merge(parents: parents)

      expect(response).to have_http_status :forbidden
    end
  end
end

# The `parents` parameter is required when testing nested controllers, and it should contain
# an ordered list of reflection symbols similarly to how they are defined in the routes. It is
# also required to set the `extra_params` variable in a let block and pass there all the parent IDs and
# IDs to search for as a hash. For example:
# ```
# let(:extra_params) { { security_guide_id: 123, profile_id: 456, id: 789 } }
#
# it_behaves_like 'individual', :security_guide, :profile
# ```
#
# In a non-nested case the let block should the ID to search for and the `parents` parameter
# should be empty, like so:
# ```
# let(:extra_params) { { id: 789 } }
#
# it_behaves_like 'individual'
# ```
#
# In some cases, however, additional ActiveRecord objects and scalar values are required for
# invoking a factory. Therefore, if you don't want these objects to be passed to the `params`
# of the request, you can safely specify ActiveRecord objects in the `extra_params`. For scalar
# values you can use the `pw()` wrapper method that makes sure that the value is only passed to
# the factory and not to the URL params.
# ```
# let(:extra_params) { { account: FactoryBot.create(:v2_account), system_count: pw(10) } }
#
# it_behaves_like 'individual'
# ```
#
RSpec.shared_examples 'individual' do |*parents|
  let(:passable_params) { reject_nonscalar(extra_params) }

  it 'returns item by id' do
    expected = hash_including('data' => {
                                'id' => item.id,
                                'type' => described_class.controller_name.singularize,
                                **attributes.each_with_object({}) do |(key, value), obj|
                                  # If it is a lambda, execute it on the instance, otherwise call the method by name
                                  obj[key.to_s] = value.is_a?(Proc) ? item.instance_exec(&value) : item.send(value)
                                end
                              })

    get :show, params: passable_params.merge(parents: parents)

    expect(response.parsed_body).to match(expected)
  end

  context 'with nonexistent id' do
    it 'returns not_found' do
      get :show, params: passable_params.merge(parents: parents, id: 'incorrect')

      expect(response).to have_http_status :not_found
    end
  end

  context 'under incorrect parent', if: parents.present? do
    it 'returns not_found' do
      get :show, params: notfound_params.merge(parents: parents)

      expect(response).to have_http_status :not_found
    end
  end
end
