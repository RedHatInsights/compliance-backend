# frozen_string_literal: true

require 'test_helper'
require 'rake'

class ImportRemediationsTest < ActiveSupport::TestCase
  test 'import_remediations fails on error' do
    ENV['JOBS_ACCOUNT_NUMBER'] = accounts(:test).account_number

    RemediationsAPI.any_instance.expects(:import_remediations)
                   .raises(StandardError)

    assert_raises StandardError do
      Rake::Task['import_remediations'].execute
    end
  end
end
