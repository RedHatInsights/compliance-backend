# frozen_string_literal: true

# The v2_test_results view contains a subquery:
#   SELECT profile_id, host_id, MAX(end_time) FROM test_results GROUP BY profile_id, host_id
# which then joins back to test_results ON (profile_id, host_id, end_time).
#
# This covering index allows PostgreSQL to satisfy both the GROUP BY + MAX
# aggregation and the self-join using an index-only scan.
class AddCoveringIndexForV2TestResultsView < ActiveRecord::Migration[7.2]
  def change
    add_index :test_results, %i[profile_id host_id end_time],
              order: { end_time: :desc },
              name: 'index_test_results_for_latest_lookup',
              include: %i[id]
  end
end
