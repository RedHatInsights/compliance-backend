# frozen_string_literal: true

require 'test_helper'
require 'rake'

class ImportRemediationsTest < ActiveSupport::TestCase
  setup do
    Rails.application.load_tasks if Rake::Task.tasks.empty?
    @rules = FactoryBot.create_list(:rule, 10)
  end

  test 'import_remediations fails on error' do
    PlaybookDownloader.expects(:playbooks_exist?).raises(StandardError)

    assert_raises StandardError do
      capture_io do
        Rake::Task['import_remediations'].execute
      end
    end
  end

  test 'import_remediations updates all relevant rules' do
    # rubocop:disable Rails/SkipsModelValidations
    Rule.where(id: @rules).update_all(remediation_available: false)
    # rubocop:enable Rails/SkipsModelValidations

    remediation_available = {}
    @rules.each do |rule|
      remediation_available[rule.id] = rand(2).zero?
    end

    PlaybookDownloader.expects(:playbooks_exist?).returns(remediation_available)

    capture_io do
      Rake::Task['import_remediations'].execute
    end

    @rules.each do |rule|
      assert_equal(remediation_available[rule.id],
                   rule.reload.remediation_available)
    end
  end
end
