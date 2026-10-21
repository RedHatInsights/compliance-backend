# frozen_string_literal: true

require 'rails_helper'
require 'rake'

RSpec.describe 'db:drop_invalid_indexes task' do
  self.use_transactional_tests = false

  before(:all) do
    Rails.application.load_tasks if Rake::Task.tasks.empty?
  end

  around do |example|
    original_confirm = ENV.fetch('CONFIRM', nil)
    example.run
  ensure
    if original_confirm.nil?
      ENV.delete('CONFIRM')
    else
      ENV['CONFIRM'] = original_confirm
    end
  end

  before do
    Rake::Task['db:drop_invalid_indexes'].reenable
  end

  let(:statements) do
    [
      'DROP INDEX CONCURRENTLY IF EXISTS public.fixes_pkey_ccnew',
      'DROP INDEX CONCURRENTLY IF EXISTS public.index_fixes_on_rule_id_and_system_ccnew',
      'DROP INDEX CONCURRENTLY IF EXISTS public.index_fixes_on_rule_id_ccnew',
      'DROP INDEX CONCURRENTLY IF EXISTS public.index_fixes_on_system_ccnew',
      'DROP INDEX CONCURRENTLY IF EXISTS public.index_rule_results_on_rule_id_ccnew',
      'DROP INDEX CONCURRENTLY IF EXISTS public.index_rule_results_on_test_result_id_and_result_ccnew',
      'DROP INDEX CONCURRENTLY IF EXISTS public.index_rule_results_on_test_result_id_and_rule_id_ccnew',
      'DROP INDEX CONCURRENTLY IF EXISTS public.index_rule_results_on_test_result_id_ccnew',
      'DROP INDEX CONCURRENTLY IF EXISTS public.rule_results_pkey_ccnew'
    ]
  end

  let(:temporary_indexes) do
    {
      'index_fixes_on_rule_id_ccnew' => { table: :fixes, column: :rule_id },
      'index_rule_results_on_test_result_id_ccnew' => { table: :rule_results, column: :test_result_id }
    }
  end

  def existing_indexes(connection, names)
    names.select do |name|
      connection.select_value("SELECT indexname FROM pg_indexes WHERE schemaname = 'public' AND indexname = '#{name}'")
    end
  end

  it 'only logs the statements unless CONFIRM is true' do
    ENV['CONFIRM'] = 'false'
    expect(ActiveRecord::Base.connection).not_to receive(:execute)

    Rake::Task['db:drop_invalid_indexes'].execute
  end

  it 'issues every drop statement in order when CONFIRM is true' do
    ENV['CONFIRM'] = 'true'
    connection = ActiveRecord::Base.connection

    statements.each do |statement|
      expect(connection).to receive(:execute).with(statement).ordered
    end

    Rake::Task['db:drop_invalid_indexes'].execute
  end

  it 'drops existing invalid indexes when CONFIRM is true' do
    ENV['CONFIRM'] = 'true'
    connection = ActiveRecord::Base.connection

    begin
      temporary_indexes.each do |name, index|
        connection.execute("DROP INDEX CONCURRENTLY IF EXISTS public.#{name}")
        connection.execute("CREATE INDEX CONCURRENTLY #{name} ON public.#{index[:table]} (#{index[:column]})")
      end

      expect(existing_indexes(connection, temporary_indexes.keys)).to contain_exactly(*temporary_indexes.keys)

      Rake::Task['db:drop_invalid_indexes'].execute

      expect(existing_indexes(connection, temporary_indexes.keys)).to be_empty
    ensure
      temporary_indexes.each_key do |name|
        connection.execute("DROP INDEX CONCURRENTLY IF EXISTS public.#{name}")
      end
    end
  end
end
