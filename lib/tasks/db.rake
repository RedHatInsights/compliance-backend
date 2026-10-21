# frozen_string_literal: true

INVALID_INDEX_DROP_STATEMENTS = [
  'DROP INDEX CONCURRENTLY IF EXISTS public.fixes_pkey_ccnew',
  'DROP INDEX CONCURRENTLY IF EXISTS public.index_fixes_on_rule_id_and_system_ccnew',
  'DROP INDEX CONCURRENTLY IF EXISTS public.index_fixes_on_rule_id_ccnew',
  'DROP INDEX CONCURRENTLY IF EXISTS public.index_fixes_on_system_ccnew',
  'DROP INDEX CONCURRENTLY IF EXISTS public.index_rule_results_on_rule_id_ccnew',
  'DROP INDEX CONCURRENTLY IF EXISTS public.index_rule_results_on_test_result_id_and_result_ccnew',
  'DROP INDEX CONCURRENTLY IF EXISTS public.index_rule_results_on_test_result_id_and_rule_id_ccnew',
  'DROP INDEX CONCURRENTLY IF EXISTS public.index_rule_results_on_test_result_id_ccnew',
  'DROP INDEX CONCURRENTLY IF EXISTS public.rule_results_pkey_ccnew'
].freeze

namespace :db do
  desc 'Reindex the database, including the inventory table'
  task reindex: [:environment] do
    [
      'REINDEX (VERBOSE, CONCURRENTLY) SCHEMA public',
      'VACUUM (VERBOSE, ANALYZE)'
    ].each do |query|
      Rails.logger.info(query)
      ActiveRecord::Base.connection.execute(query)
    end
  end

  desc 'Drop invalid concurrent index builds'
  task drop_invalid_indexes: [:environment] do
    confirm = ENV['CONFIRM'] == 'true'
    INVALID_INDEX_DROP_STATEMENTS.each do |statement|
      Rails.logger.info("#{confirm ? 'Executing' : 'Would execute'}: #{statement}")
      ActiveRecord::Base.connection.execute(statement) if confirm
    end
  end
end
