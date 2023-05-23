# frozen_string_literal: true

RSpec.shared_examples 'paginable' do
  let(:item_count) { 20 }

  [2, 5, 10, 15].each do |per_page|
    it "returns with the requested #{per_page} records per page" do
      items # force creation

      get :index, params: { 'limit' => per_page }

      expect(response_body_data.count).to eq(per_page)
    end

    (1..(20.0 / per_page).ceil).each do |page|
      it "returns #{per_page} records from the #{page.ordinalize} page" do
        idx = ((per_page * (page - 1)))
        nth_page = items[idx..(idx + per_page - 1)].map do |sg|
          hash_including(
            'id' => sg.id,
            'type' => 'security_guide',
            'attributes' => hash_including
          )
        end

        get :index, params: { 'limit' => per_page, 'offset' => page }

        expect(response_body_data).to match_array(nth_page)
      end
    end
  end
end
