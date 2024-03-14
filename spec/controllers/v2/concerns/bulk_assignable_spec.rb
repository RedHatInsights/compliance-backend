# frozen_string_literal: true

# The parameters of this shared example should be present when calling it in the order it is given here:
# assoc_model - model link between left and right entities
# left_sym - symbol of left entity factory
# right_sym - symbol of right entity factory
# linked - symbol specifying the option for left entity to be created with linked right entities
# link_amount

RSpec.shared_examples 'bulk assignable' do |assoc_model, left_sym, right_sym|
  let(:right_name) { assoc_model.reflect_on_all_associations.last.klass.model_name.element }
  let(:right_fk) { assoc_model.reflections.dig(right_name).foreign_key }

  let(:unlinked_left) { FactoryBot.create(left_sym, account: current_user.account) }
  let(:right_ids) { FactoryBot.create_list(right_sym, new_link_count).map(&:id) }
  let(:left) { FactoryBot.create(left_sym, account: current_user.account, right_fk => FactoryBot.create(right_sym).id) }

  let(:links) { left.reload.send(right_name.pluralize) }
  # TODO: systems controller spec type usage of factories (factory hell cose os_major_ver)

  # The endpoint has the same name as the key in the input hash, so we use the same variable for both
  let(:right_key) { right_name.pluralize.to_sym }

  it 'replaces all links' do
    patch :update, params: { id: left.id, right_key => right_ids }

    expect(links.count).to eq(new_link_count)
    expect(links.map(&:id)).to match_array(right_ids)
    expect(response).to have_http_status :ok
  end

  context 'with no previous links' do
    let(:links) { unlinked_left.reload.send(right_name.pluralize) }

    it 'creates all new links' do
      patch right_key, params: { id: unlinked_left.id, data: data }

      expect(links.count).to eq(new_link_count)
      expect(links.map(&:id)).to match_array(right_ids)
      expect(response).to have_http_status :ok
    end
  end

  context 'with empty right-side record IDs' do
    let!(:original_ids) { links.map(&:id) }
    let(:right_ids) { [] }

    it 'rejects the assignment and raises an error' do
      patch right_key, params: { id: left.id, data: data }

      expect(links.count).to eq(old_link_count)
      expect(links.map(&:id)).to match_array(original_ids)
      expect(response).to have_http_status :not_found
    end
  end

  context 'with invalid left-side record ID' do
    it 'raises an error' do
      patch right_key, params: { id: Faker::Internet.uuid, data: data }

      expect(response).to have_http_status :not_found
    end
  end

  context 'with invalid right-side record IDs' do
    let!(:original_ids) { links.map(&:id) }
    let(:right_ids) { [Faker::Internet.uuid, Faker::Internet.uuid] }

    it 'rejects the assignment and raises an error' do
      patch right_key, params: { id: left.id, data: data }

      expect(links.count).to eq(old_link_count)
      expect(links.map(&:id)).to match_array(original_ids)
      expect(response).to have_http_status :not_found
    end
  end

  context 'with partially invalid right-side record IDs' do
    let!(:original_ids) { links.map(&:id) }
    let(:data) { { right_key => right_ids + [Faker::Internet.uuid] } }

    it 'rejects the assignment and raises an error' do
      patch right_key, params: { id: left.id, data: data }

      expect(links.count).to eq(old_link_count)
      expect(links.map(&:id)).to match_array(original_ids)
      expect(response).to have_http_status :not_found
    end
  end

  context 'with undefined right-side IDs' do
    let!(:original_ids) { links.map(&:id) }
    let(:data) { { right_key => [nil, nil] } }

    it 'rejects the assignment and raises an error' do
      patch right_key, params: { id: left.id, data: data }

      expect(links.count).to eq(old_link_count)
      expect(links.map(&:id)).to match_array(original_ids)
      expect(response).to have_http_status :not_found
    end
  end

  context 'with undefined right-side' do
    let!(:original_ids) { links.map(&:id) }
    let(:data) { { right_key => nil } }

    it 'rejects the assignment and raises an error' do
      patch right_key, params: { id: left.id, data: data }

      expect(links.count).to eq(old_link_count)
      expect(links.map(&:id)).to match_array(original_ids)
      expect(response).to have_http_status :unprocessable_entity
    end
  end

  context 'with invalid right key' do
    let!(:original_ids) { links.map(&:id) }
    let(:data) { { definitely_not_systems: right_ids } }

    it 'rejects the assignment and raises an error' do
      patch right_key, params: { id: left.id, data: data }

      expect(links.count).to eq(old_link_count)
      expect(links.map(&:id)).to match_array(original_ids)
      expect(response).to have_http_status :unprocessable_entity
    end
  end

  context 'with undefined data' do
    let!(:original_ids) { links.map(&:id) }
    let(:data) {}

    it 'rejects the assignment and raises an error' do
      patch right_key, params: { id: left.id, data: data }

      expect(links.count).to eq(old_link_count)
      expect(links.map(&:id)).to match_array(original_ids)
      expect(response).to have_http_status :unprocessable_entity
    end
  end
end
