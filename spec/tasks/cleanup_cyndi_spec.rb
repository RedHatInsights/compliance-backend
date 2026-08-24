# frozen_string_literal: true

require 'rails_helper'
require 'rake'

RSpec.describe 'cyndi:cleanup task' do
  before(:all) do
    Rails.application.load_tasks if Rake::Task.tasks.empty?
  end

  def capture_stdout
    original = $stdout
    $stdout = StringIO.new
    yield
    $stdout.string
  ensure
    $stdout = original
  end

  cyndi_env_keys = %w[CONFIRM DROP_ROLES].freeze

  around do |example|
    original_envs = cyndi_env_keys.to_h { |k| [k, ENV.fetch(k, nil)] }
    begin
      example.run
    ensure
      cyndi_env_keys.each do |key|
        original_envs[key].nil? ? ENV.delete(key) : (ENV[key] = original_envs[key])
      end
    end
  end

  before do
    Rake::Task['cyndi:cleanup'].reenable
  end

  let(:logger) { instance_double(Logger, info: nil, warn: nil) }

  describe CyndiCleaner do
    subject(:cleaner) { described_class.new(logger: logger) }

    let(:connection) { ActiveRecord::Base.connection }

    # Route each discover_* query to a canned row set based on which catalog it
    # targets, WITHOUT asserting on SQL string shape. We classify by intent
    # (schema vs view vs table vs role) using stable, semantic markers.
    def stub_discovery(schema:, views:, tables:, roles:)
      allow(connection).to receive(:select_values) do |sql|
        case sql
        when /FROM pg_roles/ then roles
        when /relkind = 'v'/ then views
        when /relkind = 'r'/ then tables
        when /FROM pg_namespace WHERE nspname/ then [schema].compact
        else []
        end
      end
    end

    describe '#discover' do
      it 'returns the schema, versioned tables, view, and roles as a structured hash' do
        stub_discovery(
          schema: 'inventory',
          views: ['hosts'],
          tables: ['hosts_v1_1783001514628273919'],
          roles: %w[cyndi cyndi_admin cyndi_reader]
        )

        expect(cleaner.discover).to eq(
          schema: 'inventory',
          tables: ['hosts_v1_1783001514628273919'],
          views: ['hosts'],
          roles: %w[cyndi cyndi_admin cyndi_reader]
        )
      end

      it 'returns nil schema and empty collections when nothing exists' do
        stub_discovery(schema: nil, views: [], tables: [], roles: [])

        expect(cleaner.discover).to eq(schema: nil, tables: [], views: [], roles: [])
      end

      it 'returns every matching versioned table when more than one exists' do
        stub_discovery(
          schema: 'inventory', views: ['hosts'],
          tables: %w[hosts_v1_1783001514628273919 hosts_v1_1784955527079753691],
          roles: []
        )

        expect(cleaner.discover[:tables])
          .to eq(%w[hosts_v1_1783001514628273919 hosts_v1_1784955527079753691])
      end

      it 'scopes view discovery to the documented hosts view only' do
        allow(connection).to receive(:select_values).and_return([])

        cleaner.discover

        # The view query must be constrained to relname = 'hosts', so unrelated
        # views in the schema are never even discovered (let alone dropped).
        expect(connection).to have_received(:select_values)
          .with(a_string_matching(/relkind = 'v'.*relname = 'hosts'/m))
      end
    end

    describe '#run in dry-run mode (default)' do
      before do
        allow(cleaner).to receive(:discover).and_return(
          schema: 'inventory',
          tables: ['hosts_v1_1783001514628273919'],
          views: ['hosts'],
          roles: %w[cyndi cyndi_admin cyndi_reader]
        )
      end

      it 'does not execute any destructive SQL' do
        expect(connection).not_to receive(:execute)
        cleaner.run(confirm: false, drop_roles: true)
      end

      it 'logs what it would drop' do
        cleaner.run(confirm: false, drop_roles: true)

        expect(logger).to have_received(:info).with(/DRY RUN/i)
        expect(logger).to have_received(:info).with(/inventory.*hosts_v1_1783001514628273919/)
        expect(logger).to have_received(:info).with(/cyndi_reader/)
      end
    end

    describe '#run with confirm: true (objects only)' do
      before do
        allow(cleaner).to receive(:discover).and_return(
          schema: 'inventory',
          tables: ['hosts_v1_1783001514628273919'],
          views: ['hosts'],
          roles: %w[cyndi cyndi_admin cyndi_reader]
        )
        allow(connection).to receive(:execute)
        allow(connection).to receive(:transaction).and_yield
      end

      it 'wraps the object drops in a transaction' do
        cleaner.run(confirm: true, drop_roles: false)
        expect(connection).to have_received(:transaction).at_least(:once)
      end

      it 'drops the view before the tables before the schema' do
        cleaner.run(confirm: true, drop_roles: false)

        expect(connection).to have_received(:execute)
          .with(/DROP VIEW IF EXISTS "inventory"\."hosts"/).ordered
        expect(connection).to have_received(:execute)
          .with(/DROP TABLE IF EXISTS "inventory"\."hosts_v1_1783001514628273919" RESTRICT/).ordered
        expect(connection).to have_received(:execute)
          .with(/DROP SCHEMA IF EXISTS "inventory" RESTRICT/).ordered
      end

      it 'drops the table with RESTRICT, never CASCADE' do
        cleaner.run(confirm: true, drop_roles: false)

        expect(connection).not_to have_received(:execute).with(/DROP TABLE.*CASCADE/)
      end

      it 'does not drop roles when drop_roles is false' do
        cleaner.run(confirm: true, drop_roles: false)

        expect(connection).not_to have_received(:execute).with(/DROP ROLE/)
      end
    end

    describe '#run with confirm: true and drop_roles: true' do
      before do
        allow(cleaner).to receive(:discover).and_return(
          schema: 'inventory',
          tables: ['hosts_v1_1783001514628273919'],
          views: ['hosts'],
          roles: %w[cyndi cyndi_admin cyndi_reader]
        )
        allow(connection).to receive(:execute)
        allow(connection).to receive(:transaction).and_yield
      end

      context 'when no cyndi role owns anything' do
        before do
          allow(connection).to receive(:select_values).and_return([])
        end

        it 'drops roles in dependency order (reader, admin, base) with DROP OWNED first' do
          cleaner.run(confirm: true, drop_roles: true)

          expect(connection).to have_received(:execute).with(/DROP OWNED BY "cyndi_reader" RESTRICT/).ordered
          expect(connection).to have_received(:execute).with(/DROP OWNED BY "cyndi_admin" RESTRICT/).ordered
          expect(connection).to have_received(:execute).with(/DROP OWNED BY "cyndi" RESTRICT/).ordered
          expect(connection).to have_received(:execute).with(/DROP ROLE IF EXISTS "cyndi_reader"/).ordered
          expect(connection).to have_received(:execute).with(/DROP ROLE IF EXISTS "cyndi_admin"/).ordered
          expect(connection).to have_received(:execute).with(/DROP ROLE IF EXISTS "cyndi"/).ordered
        end

        it 'never uses CASCADE on DROP OWNED' do
          cleaner.run(confirm: true, drop_roles: true)

          expect(connection).not_to have_received(:execute).with(/DROP OWNED.*CASCADE/)
        end
      end

      context 'when a cyndi role still owns objects locally' do
        before do
          allow(connection).to receive(:select_values) do |sql|
            sql.match?(/pg_class/) ? ['inventory.some_leftover'] : []
          end
        end

        it 'aborts role removal and raises without issuing any DROP ROLE' do
          expect { cleaner.run(confirm: true, drop_roles: true) }
            .to raise_error(CyndiCleaner::RolePreconditionError, /still own objects/)

          expect(connection).not_to have_received(:execute).with(/DROP ROLE/)
          expect(connection).not_to have_received(:execute).with(/DROP OWNED/)
        end
      end

      context 'when a cyndi role owns objects in another database' do
        before do
          allow(connection).to receive(:select_values) do |sql|
            sql.match?(/pg_shdepend/) ? ['other_db'] : []
          end
        end

        it 'aborts role removal citing the other database' do
          expect { cleaner.run(confirm: true, drop_roles: true) }
            .to raise_error(CyndiCleaner::RolePreconditionError, /other_db/)
        end
      end

      context 'when an unexpected cyndi role is present' do
        before do
          allow(cleaner).to receive(:discover).and_return(
            schema: nil, tables: [], views: [],
            roles: %w[cyndi cyndi_admin cyndi_reader cyndi_weird]
          )
          allow(connection).to receive(:select_values).and_return([])
        end

        it 'skips the unknown role with a warning and does not drop it' do
          cleaner.run(confirm: true, drop_roles: true)

          expect(logger).to have_received(:warn).with(/cyndi_weird.*skipping|skipping.*cyndi_weird/i)
          expect(connection).not_to have_received(:execute).with(/"cyndi_weird"/)
        end

        it 'still drops the known roles' do
          cleaner.run(confirm: true, drop_roles: true)

          expect(connection).to have_received(:execute).with(/DROP ROLE IF EXISTS "cyndi_reader"/)
        end
      end
    end

    describe '#run when nothing is present' do
      before do
        allow(cleaner).to receive(:discover).and_return(
          schema: nil, tables: [], views: [], roles: []
        )
      end

      it 'is a no-op and logs that nothing was found' do
        expect(connection).not_to receive(:execute)
        cleaner.run(confirm: true, drop_roles: true)
        expect(logger).to have_received(:info).with(/nothing to remove/i)
      end
    end

    # These run against the real database (no discover/execute stubbing) to prove
    # scoping and fail-loud behaviour end to end. Each wraps its work in a
    # transaction that is rolled back so the shared dev schema is left intact.
    describe 'integration against the real schema', :integration do
      let(:real_cleaner) { described_class.new(logger: Logger.new(IO::NULL)) }

      # The dev DB is seeded with the real Cyndi objects (inventory schema,
      # hosts view, hosts_v1_* table). We add only our test-specific objects on
      # top and roll everything back, so we never mutate the shared seed.
      def seeded_table
        connection.select_values(<<~SQL.squish).first
          SELECT c.relname FROM pg_class c
          JOIN pg_namespace n ON n.oid = c.relnamespace
          WHERE n.nspname = 'inventory' AND c.relkind = 'r' AND c.relname ~ '^hosts_v1_[0-9]+$'
          LIMIT 1
        SQL
      end

      def view_exists?(name)
        connection.select_values(<<~SQL.squish).include?(name)
          SELECT c.relname FROM pg_class c
          JOIN pg_namespace n ON n.oid = c.relnamespace
          WHERE n.nspname = 'inventory' AND c.relkind = 'v'
        SQL
      end

      before do
        skip 'requires the seeded Cyndi inventory schema' unless seeded_table
      end

      it 'leaves an unrelated view in the schema untouched' do
        connection.transaction do
          connection.execute(
            "CREATE OR REPLACE VIEW inventory.not_cyndi AS SELECT id FROM inventory.#{seeded_table}"
          )

          # not_cyndi keeps the schema non-empty, so DROP SCHEMA RESTRICT aborts.
          expect { real_cleaner.run(confirm: true, drop_roles: false) }
            .to raise_error(ActiveRecord::StatementInvalid)

          # Everything rolled back: the unrelated view is still present, and so is
          # the cyndi view (nothing partially dropped).
          expect(view_exists?('not_cyndi')).to be(true)
          expect(view_exists?('hosts')).to be(true)

          raise ActiveRecord::Rollback
        end
      end

      it 'fails loudly (RESTRICT) and rolls back when an object depends on the table' do
        connection.transaction do
          # A view depending on the table blocks DROP TABLE ... RESTRICT (the
          # cyndi hosts view is dropped first, so this extra one triggers it).
          connection.execute(
            "CREATE OR REPLACE VIEW inventory.dependent AS SELECT id FROM inventory.#{seeded_table}"
          )

          expect { real_cleaner.run(confirm: true, drop_roles: false) }
            .to raise_error(ActiveRecord::StatementInvalid, /depend|cannot drop/i)

          # Table survived the rollback (nothing partially dropped).
          survivors = connection.select_values(<<~SQL.squish)
            SELECT c.relname FROM pg_class c
            JOIN pg_namespace n ON n.oid = c.relnamespace
            WHERE n.nspname = 'inventory' AND c.relkind = 'r' AND c.relname ~ '^hosts_v1_[0-9]+$'
          SQL
          expect(survivors).to include(seeded_table)

          raise ActiveRecord::Rollback
        end
      end
    end
  end

  describe 'the rake task wrapper' do
    it 'runs in dry-run mode by default and does not drop anything' do
      cleaner = instance_double(CyndiCleaner)
      allow(CyndiCleaner).to receive(:new).and_return(cleaner)

      expect(cleaner).to receive(:run).with(confirm: false, drop_roles: false)

      capture_stdout { Rake::Task['cyndi:cleanup'].invoke }
    end

    it 'passes confirm and drop_roles flags from the environment' do
      cleaner = instance_double(CyndiCleaner)
      allow(CyndiCleaner).to receive(:new).and_return(cleaner)

      expect(cleaner).to receive(:run).with(confirm: true, drop_roles: true)

      capture_stdout do
        ENV['CONFIRM'] = 'true'
        ENV['DROP_ROLES'] = 'true'
        Rake::Task['cyndi:cleanup'].invoke
      end
    end
  end
end
