# frozen_string_literal: true

require 'rails_helper'

RSpec.describe InventoryPartitionConcurrency do
  let(:metadata) { { 'topic' => 'inventory', 'partition' => 2, 'offset' => 41 } }
  let(:import_message) { { 'host' => { 'id' => SecureRandom.uuid } } }
  let(:delete_message) { { 'id' => SecureRandom.uuid } }
  let(:expected_key) { "inventory-partition:#{metadata.fetch('topic')}:#{metadata.fetch('partition')}" }

  it 'derives the same topic-partition key for import and delete jobs' do
    import_job = SystemImportJob.new(import_message, metadata)
    delete_job = SystemDeleteJob.new(delete_message, metadata)

    expect(import_job.good_job_concurrency_key).to eq(expected_key)
    expect(delete_job.good_job_concurrency_key).to eq(expected_key)
  end

  it 'limits execution without a total limit' do
    [SystemImportJob, SystemDeleteJob].each do |job_class|
      expect(job_class.good_job_concurrency_config[:perform_limit]).to eq(1)
      expect(job_class.good_job_concurrency_config[:total_limit]).to be_nil
    end
  end
end
