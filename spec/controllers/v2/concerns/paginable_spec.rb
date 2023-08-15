# frozen_string_literal: true

RSpec.shared_examples 'paginable' do |*parents|
  let(:item_count) { 20 } # We need more items to be created to test pagination properly

  [2, 5, 10, 15, 20].each do |per_page|
    it "returns with the requested #{per_page} records per page" do
      items # force creation
      nested_route(*parents) do |mocked_parents|
        get :index, params: extra_params.merge(
          { 'limit' => per_page },
          parents: mocked_parents
        )
      end

      expect(response_body_data.count).to eq(per_page)
    end

    (1..(20.0 / per_page).ceil).each do |page|
      it "returns #{per_page} records from the #{page.ordinalize} page" do
        idx = ((per_page * (page - 1)))
        nth_page = items[idx..(idx + per_page - 1)].map do |sg|
          hash_including(
            'id' => sg.id,
            'type' => subject.send(:resource).model_name.element,
            'attributes' => a_kind_of(Hash)
          )
        end

        nested_route(*parents) do |mocked_parents|
          get :index, params: extra_params.merge(
            {
              'limit' => per_page,
              'offset' => page
            },
            parents: mocked_parents
          )
        end

        expect(response_body_data).to match_array(nth_page)
        expect(response.parsed_body['meta']['limit']).to eq(per_page)
        expect(response.parsed_body['meta']['offset']).to eq(page)
      end
    end
  end
end
