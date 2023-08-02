# frozen_string_literal: true

require 'test_helper'

class GraphQLCollectionTest < ActiveSupport::TestCase
  setup do
    @user = FactoryBot.create(:user)
    User.current = @user

    stub_rbac_permissions(Rbac::COMPLIANCE_ADMIN, Rbac::INVENTORY_HOSTS_READ)
  end

  test 'deterministic pagination' do
    @num_created = 44
    @per_page = 10

    created_profiles = FactoryBot.create_list(
      :profile, @num_created,
      name: 'The same name',
      parent_profile_id: nil
    )

    collected_ids = Set.new
    pages = (@num_created / @per_page.to_f).ceil

    pages.times do |page|
      query = <<-GRAPHQL
        query Profiles($offset: Int, $limit: Int){
          profiles(search: "", sortBy: ["name"], offset: $offset, limit: $limit) {
            edges {
              node {
                id
              }
            }
          }
        }
      GRAPHQL

      result = Schema.execute(
        query,
        variables: { limit: @per_page, offset: page + 1 },
        context: { current_user: @user }
      )
      batch = result.dig('data', 'profiles', 'edges').map do |edge|
        edge['node']
      end

      batch_ids = batch.map { |p| p['id'] }.to_set
      intersection = collected_ids.intersection(batch_ids)

      assert_equal 0, intersection.count,
                   'Intersected items from previous page(s):' \
                   " #{intersection}"

      collected_ids.merge(batch_ids)
    end

    assert_equal created_profiles.count, collected_ids.count
    created_ids = created_profiles.map(&:id).to_set
    assert_equal created_profiles.count, created_ids.count
    assert_equal 0, (created_ids - collected_ids).count
  end
end
