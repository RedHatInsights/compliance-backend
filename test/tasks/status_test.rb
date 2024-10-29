# frozen_string_literal: true

require 'test_helper'
require 'rake'

class DbStatusTest < ActiveSupport::TestCase
  setup do
    Rails.application.load_tasks if Rake::Task.tasks.empty?
  end

  test 'db:status fails without a database connection' do
    ActiveRecord::Base.stubs(:connection).raises(StandardError)
    assert_raises SystemExit do
      capture_io do
        Rake::Task['db:status'].execute
      end
    end
  end

  test 'db:status succeeds with a database connection' do
    assert_nothing_raised do
      capture_io do
        Rake::Task['db:status'].execute
      end
    end
  end
end

class RedisStatusTest < ActiveSupport::TestCase
  setup do
    Rails.application.load_tasks if Rake::Task.tasks.empty?
  end

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

class KafkaStatusTest < ActiveSupport::TestCase
  setup do
    Rails.application.load_tasks if Rake::Task.tasks.empty?
  end

  test 'kafka:status fails without a kafka connection' do
    ApplicationProducer.stubs(:kafka).raises(Rdkafka::RdkafkaError.new(1))
    assert_raises SystemExit do
      capture_io do
        Rake::Task['kafka:status'].execute
      end
    end
  end

  test 'kafka:status succeeds with a kafka connection' do
    ApplicationProducer.stubs(:ping).returns(1)
    assert_nothing_raised do
      capture_io do
        Rake::Task['kafka:status'].execute
      end
    end
  end
end
