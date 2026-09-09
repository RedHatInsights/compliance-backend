# frozen_string_literal: true

require 'rails_helper'
require 'rake'

Rails.application.load_tasks unless Rake::Task.task_defined?('systems:backfill_profile_fields')

# rubocop:disable Metrics/MethodLength, Metrics/ParameterLists
module SystemsProfileFieldsBackfillHelpers
  def uuid(sequence)
    format('00000000-0000-0000-0000-%012d', sequence)
  end

  def create_backfill_system(sequence:, profile:, owner_id: nil, major: nil, minor: nil, deleted_at: nil, **attrs)
    account = Account.find_or_create_by!(org_id: "backfill-#{sequence}")
    system = FactoryBot.create(:system, id: uuid(sequence), account: account, **attrs)
    system.update_columns( # rubocop:disable Rails/SkipsModelValidations
      owner_id: owner_id,
      os_major_version: major,
      os_minor_version: minor,
      deleted_at: deleted_at
    )
    system.class.connection.exec_update(
      "UPDATE systems SET system_profile = #{system.class.connection.quote(profile.to_json)}::jsonb " \
      "WHERE id = #{system.class.connection.quote(system.id)}"
    )
    system.reload
  end
end
# rubocop:enable Metrics/MethodLength, Metrics/ParameterLists

RSpec.describe 'systems:backfill_profile_fields task' do
  include SystemsProfileFieldsBackfillHelpers

  ENV_KEYS = %w[BATCH_SIZE MAX_ROWS_PER_RUN].freeze

  def capture_stdout
    original = $stdout
    $stdout = StringIO.new
    yield
    $stdout.string
  ensure
    $stdout = original
  end

  def invoke_task
    Rake::Task['systems:backfill_profile_fields'].invoke
  end

  around do |example|
    original = ENV_KEYS.to_h { |key| [key, ENV.fetch(key, nil)] }
    example.run
  ensure
    original.each do |key, value|
      value.nil? ? ENV.delete(key) : ENV[key] = value
    end
  end

  before do
    Rake::Task['systems:backfill_profile_fields'].reenable
  end

  it 'writes one, two, or three null targets and counts each row once' do
    owner_1 = uuid(101)
    owner_2 = uuid(102)
    systems = [
      create_backfill_system(
        sequence: 1,
        profile: { 'owner_id' => owner_1, 'operating_system' => { 'major' => 9, 'minor' => 4 } },
        major: 8,
        minor: 1
      ),
      create_backfill_system(
        sequence: 2,
        profile: { 'owner_id' => owner_2, 'operating_system' => { 'major' => 9, 'minor' => 4 } },
        major: 8
      ),
      create_backfill_system(
        sequence: 3,
        profile: { 'owner_id' => uuid(103), 'operating_system' => { 'major' => 9, 'minor' => 4 } }
      )
    ]

    output = capture_stdout { invoke_task }

    native_values = systems.map do |system|
      system.reload.attributes.values_at('owner_id', 'os_major_version', 'os_minor_version')
    end
    expect(native_values).to eq([[owner_1, 8, 1], [owner_2, 8, 4], [uuid(103), 9, 4]])
    expect(output).to include('selected_rows=3', 'scanned_rows=3', 'successful_rows=3')
  end

  it 'changes only null native target columns' do
    system = create_backfill_system(
      sequence: 1,
      profile: {
        'owner_id' => uuid(101),
        'operating_system' => { 'major' => 9, 'minor' => 4 },
        'preserved' => { 'value' => Faker::Lorem.word }
      },
      major: 8,
      display_name: Faker::Internet.domain_name,
      tags: [{ namespace: Faker::Lorem.word, key: Faker::Lorem.word, value: Faker::Lorem.word }],
      groups: [{ id: uuid(500), name: Faker::Company.name }]
    )
    before = System.unscoped.find(system.id).attributes.deep_dup

    capture_stdout { invoke_task }

    after = System.unscoped.find(system.id).attributes
    targets = %w[owner_id os_major_version os_minor_version]
    expect(after.except(*targets)).to eq(before.except(*targets))
    expect(after.slice(*targets)).to eq(
      'owner_id' => uuid(101),
      'os_major_version' => 8,
      'os_minor_version' => 4
    )
  end

  it 'counts malformed fields only when corresponding targets remain null' do
    create_backfill_system(
      sequence: 1,
      profile: {
        'owner_id' => Faker::Lorem.word,
        'operating_system' => Faker::Lorem.word
      },
      major: 8
    )

    output = capture_stdout { invoke_task }

    expect(output).to include('selected_rows=1', 'scanned_rows=1')
    expect(output).to include('malformed_owner_ids=1')
    expect(output).to include('malformed_os_major=0')
    expect(output).to include('malformed_os_minor=1')
    expect(output).to include('successful_rows=0')
  end

  it 'does not classify missing or null sources as malformed' do
    create_backfill_system(sequence: 1, profile: {})
    create_backfill_system(
      sequence: 2,
      profile: {
        'owner_id' => nil,
        'operating_system' => { 'major' => nil, 'minor' => nil }
      }
    )

    output = capture_stdout { invoke_task }

    expect(output).to include('selected_rows=2', 'scanned_rows=2')
    expect(output).to include('malformed_owner_ids=0')
    expect(output).to include('malformed_os_major=0')
    expect(output).to include('malformed_os_minor=0')
    expect(output).to include('successful_rows=0')
  end

  it 'never selects a soft-deleted row' do
    system = create_backfill_system(
      sequence: 1,
      profile: { 'owner_id' => uuid(101) },
      deleted_at: 1.day.ago
    )
    before = System.unscoped.find(system.id).attributes.deep_dup

    expect(SystemProfileNativeFields).not_to receive(:normalize)
    output = capture_stdout { invoke_task }

    expect(System.unscoped.find(system.id).attributes).to eq(before)
    expect(output).to include('selected_rows=0', 'scanned_rows=0')
  end

  it 'issues a batch-level FOR UPDATE lock of systems' do
    create_backfill_system(sequence: 1, profile: { 'owner_id' => uuid(101) })
    sql = []
    callback = lambda do |_name, _started, _finished, _id, payload|
      sql << payload[:sql] unless payload[:name] == 'SCHEMA'
    end

    ActiveSupport::Notifications.subscribed(callback, 'sql.active_record') do
      capture_stdout { invoke_task }
    end

    expect(sql).to include(match(/FROM "systems".*FOR UPDATE OF systems/i))
  end

  it 'continues after a malformed-only batch' do
    ENV['BATCH_SIZE'] = '2'
    ENV['MAX_ROWS_PER_RUN'] = '10'
    create_backfill_system(sequence: 1, profile: { 'owner_id' => Faker::Lorem.word })
    create_backfill_system(sequence: 2, profile: { 'owner_id' => Faker::Lorem.word })
    valid = create_backfill_system(sequence: 3, profile: { 'owner_id' => uuid(103) })

    output = capture_stdout { invoke_task }

    expect(valid.reload[:owner_id]).to eq(uuid(103))
    expect(output).to include('selected_rows=3', 'scanned_rows=3')
    expect(output).to include('malformed_owner_ids=2')
    expect(output).to include('successful_rows=1')
  end

  it 'counts successful rows and stops immediately at the mid-batch cap' do
    ENV['BATCH_SIZE'] = '4'
    ENV['MAX_ROWS_PER_RUN'] = '2'
    malformed = create_backfill_system(sequence: 1, profile: { 'owner_id' => Faker::Lorem.word })
    first = create_backfill_system(
      sequence: 2,
      profile: { 'owner_id' => uuid(102), 'operating_system' => { 'major' => 9, 'minor' => 4 } }
    )
    second = create_backfill_system(sequence: 3, profile: { 'owner_id' => uuid(103) })
    unprocessed = create_backfill_system(sequence: 4, profile: { 'owner_id' => uuid(104) })

    output = capture_stdout { invoke_task }

    expect(malformed.reload[:owner_id]).to be_nil
    expect(first.reload.attributes.values_at('owner_id', 'os_major_version', 'os_minor_version'))
      .to eq([uuid(102), 9, 4])
    expect(second.reload[:owner_id]).to eq(uuid(103))
    expect(unprocessed.reload[:owner_id]).to be_nil
    expect(output).to include('selected_rows=4', 'scanned_rows=3', 'successful_rows=2')
    expect(output).to include('Stopped after reaching MAX_ROWS_PER_RUN=2')
  end

  it 'processes rows left by a capped invocation on the next invocation' do
    ENV['BATCH_SIZE'] = '3'
    ENV['MAX_ROWS_PER_RUN'] = '1'
    first = create_backfill_system(sequence: 1, profile: { 'owner_id' => uuid(101) })
    second = create_backfill_system(sequence: 2, profile: { 'owner_id' => uuid(102) })

    capture_stdout { invoke_task }
    expect(first.reload[:owner_id]).to eq(uuid(101))
    expect(second.reload[:owner_id]).to be_nil

    Rake::Task['systems:backfill_profile_fields'].reenable
    capture_stdout { invoke_task }
    expect(second.reload[:owner_id]).to eq(uuid(102))
  end

  it 'reports permanently malformed rows on every invocation' do
    system = create_backfill_system(sequence: 1, profile: { 'owner_id' => Faker::Lorem.word })

    first = capture_stdout { invoke_task }
    Rake::Task['systems:backfill_profile_fields'].reenable
    second = capture_stdout { invoke_task }

    expect(system.reload[:owner_id]).to be_nil
    expect(first).to include('malformed_owner_ids=1')
    expect(second).to include('malformed_owner_ids=1')
  end

  it 'rejects an overflowing field, persists valid siblings, and continues later rows' do
    profile = { 'owner_id' => uuid(101), 'operating_system' => { 'minor' => 4 } }
    partial = create_backfill_system(sequence: 1, profile: profile)
    later = create_backfill_system(sequence: 2, profile: { 'owner_id' => uuid(102) })
    normalized = SystemProfileNativeFields.normalize(profile)
    allow(SystemProfileNativeFields).to receive(:normalize).and_call_original
    allow(SystemProfileNativeFields).to receive(:normalize).with(profile).and_return(
      normalized.with(os_major_version: 2_147_483_648)
    )

    output = capture_stdout { invoke_task }

    expect(partial.reload.attributes.values_at('owner_id', 'os_major_version', 'os_minor_version'))
      .to eq([uuid(101), nil, 4])
    expect(later.reload[:owner_id]).to eq(uuid(102))
    expect(output).to include('selected_rows=2', 'scanned_rows=2', 'successful_rows=2')
    expect(output).to include('failed_rows=1')
    expect(output).to include('rejected_fields=1', 'WARN')
    expect(output).not_to include('2147483648')
  end

  it 'rolls back a real persistence failure savepoint and keeps the batch transaction usable' do
    first = create_backfill_system(sequence: 1, profile: { 'owner_id' => uuid(101) })
    failed = create_backfill_system(sequence: 2, profile: { 'owner_id' => uuid(102) })
    last = create_backfill_system(sequence: 3, profile: { 'owner_id' => uuid(103) })
    connection = ActiveRecord::Base.connection
    constraint = 'systems_backfill_profile_fields_persistence_failure'
    connection.execute(<<~SQL.squish)
      ALTER TABLE systems
      ADD CONSTRAINT #{constraint}
      CHECK (id <> #{connection.quote(failed.id)} OR owner_id IS NULL)
      NOT VALID
    SQL

    output = capture_stdout { invoke_task }

    expect(first.reload[:owner_id]).to eq(uuid(101))
    expect(failed.reload[:owner_id]).to be_nil
    expect(last.reload[:owner_id]).to eq(uuid(103))
    expect(output).to include('selected_rows=3', 'scanned_rows=3', 'successful_rows=2', 'failed_rows=1')
  ensure
    connection&.execute("ALTER TABLE systems DROP CONSTRAINT IF EXISTS #{constraint}")
  end

  %w[0 -1 invalid].each do |value|
    it "rejects BATCH_SIZE=#{value}" do
      ENV['BATCH_SIZE'] = value
      expect { capture_stdout { invoke_task } }
        .to raise_error(ArgumentError, 'BATCH_SIZE must be a positive integer')
    end

    it "rejects MAX_ROWS_PER_RUN=#{value}" do
      ENV['MAX_ROWS_PER_RUN'] = value
      expect { capture_stdout { invoke_task } }
        .to raise_error(ArgumentError, 'MAX_ROWS_PER_RUN must be a positive integer')
    end
  end
end

RSpec.describe SystemsProfileFieldsBackfiller do
  include SystemsProfileFieldsBackfillHelpers

  describe '#run' do
    it 'queries a full configured batch even when one success remains' do
      4.times do |index|
        system = FactoryBot.create(
          :system,
          id: uuid(index + 1),
          system_profile: { 'owner_id' => uuid(index + 101) }
        )
        system.update_columns( # rubocop:disable Rails/SkipsModelValidations
          owner_id: nil, os_major_version: 1, os_minor_version: 1
        )
      end
      limits = []
      callback = lambda do |_name, _start, _finish, _id, payload|
        next unless payload[:sql].match?(/SELECT "systems"\."id"/i)

        limits << payload[:binds].last.value
      end

      ActiveSupport::Notifications.subscribed(callback, 'sql.active_record') do
        described_class.new(batch_size: 4, max_updates: 1, logger: Logger.new(StringIO.new)).run
      end

      expect(limits).to include(4)
    end

    it 'passes independently serialized values to update_columns' do
      profile = { 'operating_system' => { 'major' => 9 } }
      system = create_backfill_system(sequence: 1, profile: profile)
      normalized = SystemProfileNativeFields.normalize(profile)
      allow(SystemProfileNativeFields).to receive(:normalize).with(profile).and_return(
        normalized.with(os_major_version: '9')
      )
      allow_any_instance_of(System).to receive(:update_columns) do |_record, updates| # rubocop:disable RSpec/AnyInstance
        expect(updates).to eq(os_major_version: 9)
      end

      described_class.new(batch_size: 10, max_updates: 10, logger: Logger.new(StringIO.new)).run

      expect(system.reload[:os_major_version]).to be_nil
    end

    it 'returns the number of successfully updated rows and logs scanned rows' do
      system = FactoryBot.create(
        :system,
        id: uuid(1),
        system_profile: { 'owner_id' => uuid(101) }
      )
      system.update_columns( # rubocop:disable Rails/SkipsModelValidations
        owner_id: nil, os_major_version: 1, os_minor_version: 1
      )
      io = StringIO.new

      result = described_class.new(batch_size: 10, max_updates: 10, logger: Logger.new(io)).run

      expect(result).to eq(1)
      expect(io.string).to include('selected_rows=1', 'scanned_rows=1')
    end

    it 'warns without source values when failures occurred' do
      source_owner = uuid(101)
      profile = { 'owner_id' => source_owner }
      create_backfill_system(sequence: 1, profile: profile)
      normalized = SystemProfileNativeFields.normalize(profile)
      allow(SystemProfileNativeFields).to receive(:normalize).with(profile).and_return(
        normalized.with(os_major_version: 2_147_483_648)
      )
      io = StringIO.new

      described_class.new(batch_size: 10, max_updates: 10, logger: Logger.new(io)).run

      expect(io.string).to include('WARN', 'failed_rows=1')
      expect(io.string).not_to include(source_owner, '2147483648')
    end
  end
end

RSpec.describe SystemsProfileFieldsBackfiller, :postgresql_concurrency do
  include SystemsProfileFieldsBackfillHelpers

  self.use_transactional_tests = false

  # rubocop:disable Metrics/MethodLength
  def wait_until_backend_is_lock_waiting(pid, timeout: 5)
    deadline = Process.clock_gettime(Process::CLOCK_MONOTONIC) + timeout
    loop do
      waiting = ActiveRecord::Base.connection_pool.with_connection do |observer|
        observer.select_value(<<~SQL.squish)
          SELECT wait_event_type = 'Lock'
          FROM pg_stat_activity
          WHERE pid = #{observer.quote(pid)}
        SQL
      end
      return if waiting
      raise "backend #{pid} did not enter a lock wait" if Process.clock_gettime(Process::CLOCK_MONOTONIC) >= deadline

      sleep 0.01
    end
  end

  # rubocop:enable Metrics/MethodLength

  # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/MethodLength
  def run_lock_wait_race(system_id)
    mutation_started = Queue.new
    release_mutation = Queue.new
    backfill_pid = Queue.new
    mutation = Thread.new do
      ActiveRecord::Base.connection_pool.with_connection do |connection|
        connection.transaction do
          yield connection
          mutation_started << true
          release_mutation.pop
        end
      end
    end
    mutation_started.pop

    log = StringIO.new
    backfill = Thread.new do
      ActiveRecord::Base.connection_pool.with_connection do |connection|
        backfill_pid << connection.select_value('SELECT pg_backend_pid()')
        SystemsProfileFieldsBackfiller.new(
          batch_size: 1000,
          max_updates: 50_000,
          logger: Logger.new(log)
        ).run
      end
    end

    pid = backfill_pid.pop
    wait_until_backend_is_lock_waiting(pid)
    release_mutation << true
    mutation.join(5) || raise('mutation thread did not finish')
    backfill.join(5) || raise('backfill thread did not finish')
    [System.unscoped.find(system_id), log.string]
  ensure
    release_mutation << true if mutation&.alive?
    mutation&.join(5)
    backfill&.join(5)
    mutation&.kill if mutation&.alive?
    backfill&.kill if backfill&.alive?
  end
  # rubocop:enable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/MethodLength

  after { System.unscoped.where(id: [uuid(1), uuid(2)]).delete_all }

  it 'preserves a native value committed while the backfill waits for its lock' do
    concurrent_owner = uuid(900)
    system = create_backfill_system(
      sequence: 1,
      profile: { 'owner_id' => uuid(101) },
      major: 9,
      minor: 4
    )

    reloaded, output = run_lock_wait_race(system.id) do |connection|
      connection.exec_update(
        "UPDATE systems SET owner_id = #{connection.quote(concurrent_owner)} " \
        "WHERE id = #{connection.quote(system.id)}"
      )
    end

    expect(reloaded[:owner_id]).to eq(concurrent_owner)
    expect(output).to include('selected_rows=1', 'scanned_rows=0')
  end

  it 'preserves soft deletion committed while the backfill waits for its lock' do
    system = create_backfill_system(sequence: 2, profile: { 'owner_id' => uuid(102) })

    reloaded, output = run_lock_wait_race(system.id) do |connection|
      connection.exec_update(
        "UPDATE systems SET deleted_at = #{connection.quote(Time.current)} " \
        "WHERE id = #{connection.quote(system.id)}"
      )
    end

    expect(reloaded.deleted_at).not_to be_nil
    expect(reloaded[:owner_id]).to be_nil
    expect(output).to include('selected_rows=1', 'scanned_rows=0')
  end
end
