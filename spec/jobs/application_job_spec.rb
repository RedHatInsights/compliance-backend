# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ApplicationJob do
  it 'registers retries for selected transient Active Record failures' do
    handled_exceptions = described_class.rescue_handlers.map(&:first)

    expect(handled_exceptions).to include(
      'ActiveRecord::Deadlocked',
      'ActiveRecord::ConnectionFailed',
      'ActiveRecord::ConnectionNotEstablished',
      'ActiveRecord::SerializationFailure'
    )
  end

  it 'does not install a catch-all StandardError retry handler' do
    handled_exceptions = described_class.rescue_handlers.map(&:first)

    expect(handled_exceptions).not_to include('StandardError')
  end
end

RSpec.describe ApplicationJob, 'retry execution policy' do
  it 'retries a selected transient failure twice and raises on the third execution' do
    retry_probe = Class.new(ApplicationJob) do
      attr_reader :retry_calls

      def perform
        raise ActiveRecord::Deadlocked
      end

      def retry_job(options = {})
        @retry_calls ||= []
        @retry_calls << options
      end
    end
    retry_probe.retry_jitter = 0
    job = retry_probe.new

    expect { 2.times { job.perform_now } }.not_to raise_error
    expect { job.perform_now }.to raise_error(ActiveRecord::Deadlocked)
    expect(job.retry_calls.size).to eq(2)
    expect(job.retry_calls.map { |call| call[:wait] }).to eq([3, 18])
  end
end
