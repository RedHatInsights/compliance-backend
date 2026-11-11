# frozen_string_literal: true

require 'rails_helper'

RSpec.describe InventoryEventsBatchJob do
  let(:metadata) { { 'topic' => Faker::Internet.domain_word, 'partition' => 2, 'offset' => 41 } }
  let(:first_entry) { { 'type' => 'created', 'payload' => { 'host' => { 'id' => Faker::Internet.uuid } }, 'metadata' => metadata } }
  let(:second_entry) { { 'type' => 'updated', 'payload' => { 'host' => { 'id' => Faker::Internet.uuid } }, 'metadata' => metadata } }
  let(:third_entry) { { 'type' => 'updated', 'payload' => { 'host' => { 'id' => Faker::Internet.uuid } }, 'metadata' => metadata } }

  it 'processes entries in their original order' do
    first_processor = instance_double(InventoryEventsProcessor)
    second_processor = instance_double(InventoryEventsProcessor)
    expect(InventoryEventsProcessor).to receive(:new).with(first_entry).ordered.and_return(first_processor)
    expect(first_processor).to receive(:process).ordered
    expect(InventoryEventsProcessor).to receive(:new).with(second_entry).ordered.and_return(second_processor)
    expect(second_processor).to receive(:process).ordered

    described_class.perform_now([first_entry, second_entry])
  end

  it 'continues processing later entries after an earlier entry fails' do
    failure_message = Faker::Lorem.sentence
    first_processor = instance_double(InventoryEventsProcessor)
    second_processor = instance_double(InventoryEventsProcessor)
    third_processor = instance_double(InventoryEventsProcessor)
    allow(InventoryEventsProcessor).to receive(:new).with(first_entry).and_return(first_processor)
    allow(InventoryEventsProcessor).to receive(:new).with(second_entry).and_return(second_processor)
    allow(InventoryEventsProcessor).to receive(:new).with(third_entry).and_return(third_processor)
    allow(first_processor).to receive(:process).and_raise(StandardError, failure_message)
    expect(second_processor).to receive(:process).ordered
    expect(third_processor).to receive(:process).ordered
    expect(Rails.logger).to receive(:error).with(a_string_including(failure_message))
    allow(described_class).to receive(:perform_later).and_return(true)

    described_class.perform_now([first_entry, second_entry, third_entry])
  end

  describe 'retrying failed entries' do
    let(:events) { [] }
    let(:failing_ids) { [] }

    before do
      allow(InventoryEventsProcessor).to receive(:new) do |entry|
        instance_double(InventoryEventsProcessor).tap do |processor|
          allow(processor).to receive(:process) do
            events << [:process, entry]
            raise StandardError, Faker::Lorem.sentence if failing_ids.include?(entry['payload']['host']['id'])
          end
        end
      end
      allow(described_class).to receive(:perform_later) do |batch|
        events << [:enqueue, batch]
        true
      end
    end

    def fail_entries(*entries)
      failing_ids.concat(entries.map { |e| e['payload']['host']['id'] })
    end

    it 'processes every entry once, including entries after a failure' do
      fail_entries(first_entry)

      described_class.perform_now([first_entry, second_entry, third_entry])

      processed = events.filter_map { |type, entry| entry if type == :process }
      expect(processed).to eq([first_entry, second_entry, third_entry])
    end

    it 'enqueues one retry batch after the final processor call' do
      fail_entries(first_entry, third_entry)

      described_class.perform_now([first_entry, second_entry, third_entry])

      expect(events.map(&:first)).to eq(%i[process process process enqueue])
      expect(described_class).to have_received(:perform_later).once
    end

    it 'preserves entry data and increments retry_count' do
      fail_entries(first_entry, third_entry)

      described_class.perform_now([first_entry, second_entry, third_entry])

      expect(events.last.last).to eq(
        [first_entry.merge('retry_count' => 1), third_entry.merge('retry_count' => 1)]
      )
      expect(first_entry).not_to have_key('retry_count')
    end

    it 'excludes entries that succeed from the retry batch' do
      fail_entries(second_entry)

      described_class.perform_now([first_entry, second_entry])

      expect(events.last.last).to eq([second_entry.merge('retry_count' => 1)])
    end

    it 'retries an entry that has failed once, up to the second retry' do
      fail_entries(first_entry)

      described_class.perform_now([first_entry.merge('retry_count' => 1)])

      expect(events.last.last).to eq([first_entry.merge('retry_count' => 2)])
    end

    it 'does not enqueue an entry whose third attempt fails' do
      fail_entries(first_entry)
      expect(InventoryEventsDeadLetter).to receive(:deliver).with(
        entry: first_entry.merge('retry_count' => 2),
        retry_count: 3,
        error: instance_of(StandardError)
      ).and_return(true)

      described_class.perform_now([first_entry.merge('retry_count' => 2)])

      expect(described_class).not_to have_received(:perform_later)
    end

    it 'publishes sanitized malformed third failures to dead letter' do
      malformed_entry = { 'metadata' => metadata }
      error = StandardError.new(Faker::Lorem.sentence)
      processor = instance_double(InventoryEventsProcessor)
      allow(InventoryEventsProcessor).to receive(:new)
        .with(malformed_entry.merge('retry_count' => 2))
        .and_return(processor)
      allow(processor).to receive(:process).and_raise(error)

      expect(InventoryEventsDeadLetter).to receive(:deliver).with(
        entry: malformed_entry.merge('retry_count' => 2),
        retry_count: 3,
        error: error
      ).and_call_original
      expect(InventoryEventsDeadLetter).to receive(:deliver_message).with(
        type: 'inventory_event_processing_failed',
        payload: {},
        metadata: metadata,
        failure: {
          retry_count: 3,
          error_class: error.class.name,
          error_message: error.message
        }
      ).and_return(true)

      described_class.perform_now([malformed_entry.merge('retry_count' => 2)])

      expect(described_class).not_to have_received(:perform_later)
    end

    it 'does not publish first failures to dead letter' do
      fail_entries(first_entry)
      allow(InventoryEventsDeadLetter).to receive(:deliver)

      described_class.perform_now([first_entry])

      expect(InventoryEventsDeadLetter).not_to have_received(:deliver)
    end

    it 'does not publish second failures to dead letter' do
      fail_entries(first_entry)
      allow(InventoryEventsDeadLetter).to receive(:deliver)

      described_class.perform_now([first_entry.merge('retry_count' => 1)])

      expect(InventoryEventsDeadLetter).not_to have_received(:deliver)
    end

    it 'enqueues retryable entries and publishes exhausted entries in mixed batch' do
      fail_entries(first_entry, third_entry)
      expect(InventoryEventsDeadLetter).to receive(:deliver).with(
        entry: third_entry.merge('retry_count' => 2),
        retry_count: 3,
        error: instance_of(StandardError)
      ).and_return(true)

      described_class.perform_now([first_entry, second_entry, third_entry.merge('retry_count' => 2)])

      expect(events.map(&:first)).to eq(%i[process process process enqueue])
      expect(events.last.last).to eq([first_entry.merge('retry_count' => 1)])
    end

    it 'logs terminal failure with Kafka coordinates' do
      fail_entries(first_entry)
      allow(Rails.logger).to receive(:error)

      described_class.perform_now([first_entry.merge('retry_count' => 2)])

      expect(Rails.logger).to have_received(:error).with(
        a_string_including("#{metadata['topic']}:2:41", 'failure 3', 'retries exhausted')
      )
    end

    it 'propagates a retry enqueue error after all entries finish' do
      fail_entries(first_entry)
      error_message = Faker::Lorem.sentence
      allow(described_class).to receive(:perform_later) do
        events << [:enqueue, nil]
        raise StandardError, error_message
      end

      expect { described_class.perform_now([first_entry, second_entry]) }
        .to raise_error(StandardError, error_message)
      expect(events.map(&:first)).to eq(%i[process process enqueue])
    end

    it 'raises ActiveJob::EnqueueError when the retry enqueue returns false' do
      fail_entries(first_entry)
      allow(described_class).to receive(:perform_later).and_return(false)

      expect { described_class.perform_now([first_entry]) }
        .to raise_error(ActiveJob::EnqueueError, /retry batch/)
    end

    it 'propagates a dead letter delivery error' do
      fail_entries(first_entry)
      error_message = Faker::Lorem.sentence
      allow(InventoryEventsDeadLetter).to receive(:deliver).and_raise(StandardError, error_message)

      expect { described_class.perform_now([first_entry.merge('retry_count' => 2), second_entry]) }
        .to raise_error(StandardError, error_message)
      expect(events.map(&:first)).to eq(%i[process])
      expect(described_class).not_to have_received(:perform_later)
    end

    it 'raises ActiveJob::EnqueueError when dead letter delivery returns false' do
      fail_entries(first_entry)
      allow(InventoryEventsDeadLetter).to receive(:deliver).and_return(false)

      expect { described_class.perform_now([first_entry.merge('retry_count' => 2), second_entry]) }
        .to raise_error(ActiveJob::EnqueueError, /dead letter/)
      expect(events.map(&:first)).to eq(%i[process])
      expect(described_class).not_to have_received(:perform_later)
    end

    describe 'import failure metric' do
      let(:counter) { Yabeda.compliance_system_import_failures_total }

      def run_with(entry, error: ActiveRecord::ActiveRecordError.new(Faker::Lorem.sentence))
        allow(InventoryEventsProcessor).to receive(:new).with(entry).and_return(
          instance_double(InventoryEventsProcessor).tap { |p| allow(p).to receive(:process).and_raise(error) }
        )
        described_class.perform_now([entry])
      end

      %w[created updated].each do |type|
        it "counts one exhausted database failure for #{type} entries" do
          entry = first_entry.merge('type' => type, 'retry_count' => 2)

          expect { run_with(entry) }.to increment_yabeda_counter(counter).by(1)
        end
      end

      it 'does not count first or second failures' do
        [0, 1].each do |count|
          expect { run_with(first_entry.merge('retry_count' => count)) }
            .not_to increment_yabeda_counter(counter)
        end
      end

      it 'does not count exhausted delete entries' do
        entry = first_entry.merge('type' => 'delete', 'retry_count' => 2)

        expect { run_with(entry) }.not_to increment_yabeda_counter(counter)
      end

      it 'does not count exhausted non-database failures' do
        entry = first_entry.merge('retry_count' => 2)

        expect { run_with(entry, error: StandardError.new(Faker::Lorem.sentence)) }
          .not_to increment_yabeda_counter(counter)
      end

      it 'does not count entries that succeed' do
        allow(InventoryEventsProcessor).to receive(:new).and_return(
          instance_double(InventoryEventsProcessor, process: nil)
        )

        expect { described_class.perform_now([first_entry.merge('retry_count' => 2)]) }
          .not_to increment_yabeda_counter(counter)
      end
    end
  end
end
