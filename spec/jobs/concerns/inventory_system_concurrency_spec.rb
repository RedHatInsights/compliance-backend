# frozen_string_literal: true

require 'rails_helper'

RSpec.describe InventorySystemConcurrency do
  let(:system_id) { SecureRandom.uuid }
  let(:metadata) { { 'topic' => 'inventory', 'partition' => 2, 'offset' => 41 } }
  let(:import_message) { { 'host' => { 'id' => system_id } } }
  let(:delete_message) { { 'id' => system_id } }

  it 'derives the same key for import and delete messages' do
    import_job = SystemImportJob.new(import_message, metadata)
    delete_job = SystemDeleteJob.new(delete_message, metadata)

    expect(import_job.good_job_concurrency_key).to eq("inventory-system:#{system_id}")
    expect(delete_job.good_job_concurrency_key).to eq(import_job.good_job_concurrency_key)
  end

  it 'limits execution rather than enqueueing later jobs away' do
    [SystemImportJob, SystemDeleteJob].each do |job_class|
      expect(job_class.good_job_concurrency_config[:perform_limit]).to eq(1)
      expect(job_class.good_job_concurrency_config[:total_limit]).to be_nil
    end
  end
end
