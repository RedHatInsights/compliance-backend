# frozen_string_literal: true

require 'test_helper'
require './db/migrate/20210316092758_deduplicate_canonical_profiles.rb'

class DuplicateCanonicalProfileResolverTest < ActiveSupport::TestCase
  setup do
    ActiveRecord::Migration.suppress_messages do
      DeduplicateCanonicalProfiles.new.down
    end

    @benchmark = FactoryBot.create(:benchmark)

    assert_difference('Profile.count' => 5) do
      5.times do |n|
        Profile.new(
          name: "foo #{n}",
          ref_id: 'bar',
          benchmark: @benchmark
        ).save(validate: false)
      end
    end
  end

  test 'removes duplicate entities' do
    STDOUT.stubs(:puts)
    assert_difference('Profile.count' => -4) do
      ActiveRecord::Migration.suppress_messages do
        DeduplicateCanonicalProfiles.new.up
      end
    end
  end

  test 'fails if there are child profiles' do
    Warning.stubs(:warn)
    account = FactoryBot.create(:account)
    Profile.find_by(name: 'foo 2').clone_to(
      account: account,
      policy: FactoryBot.create(:policy, account: account)
    )

    assert_raises ActiveRecord::StatementInvalid do
      ActiveRecord::Migration.suppress_messages do
        DeduplicateCanonicalProfiles.new.up
      end
    end
  end
end
