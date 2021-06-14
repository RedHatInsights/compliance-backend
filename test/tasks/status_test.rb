# frozen_string_literal: true

require 'test_helper'
require 'rake'

class DbStatusTest < ActiveSupport::TestCase
  test 'db:status fails without a database connection' do
    ActiveRecord::Base.stubs(:connected?)
    assert_raises SystemExit do
      capture_io do
        Rake::Task['db:status'].execute
      end
    end
  end

  test 'db:status succeeds with a database connection' do
    ActiveRecord::Base.stubs(:connected?).returns(true)
    assert_nothing_raised do
      capture_io do
        Rake::Task['db:status'].execute
      end
    end
  end
end

class RedisStatusTest < ActiveSupport::TestCase
  test 'redis:status fails without a redis connection' do
    Redis.any_instance.stubs(:ping).raises(Redis::BaseError)
    assert_raises SystemExit do
      capture_io do
        Rake::Task['redis:status'].execute
      end
    end
  end

  test 'redis:status succeeds with a redis connection' do
    Redis.any_instance.stubs(:ping).returns(true)
    assert_nothing_raised do
      capture_io do
        Rake::Task['redis:status'].execute
      end
    end
  end
end
