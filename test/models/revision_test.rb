# frozen_string_literal: true

require 'test_helper'

class RevisionTest < ActiveSupport::TestCase
  context 'ActiveRecord validations' do
    subject { Revision.new(name: 'foo', revision: '12345') }
    should validate_uniqueness_of(:name)
    should validate_presence_of(:name)
    should validate_presence_of(:revision)
  end

  context 'DB validations' do
    should 'require a name' do
      assert_raises ActiveRecord::NotNullViolation do
        Revision.new(revision: 'foo').save(validate: false)
      end
    end

    should 'require a revision' do
      assert_raises ActiveRecord::NotNullViolation do
        Revision.new(name: 'foo').save(validate: false)
      end
    end

    should 'disallow duplicate revision names' do
      Revision.create!(name: 'foo', revision: '2021-01-01')

      assert_raises ActiveRecord::RecordNotUnique do
        Revision.new(name: 'foo', revision: '2021-01-01')
                .save(validate: false)
      end
    end
  end
end
