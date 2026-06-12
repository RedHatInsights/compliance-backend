# frozen_string_literal: true

require 'rails_helper'
require 'rake'

RSpec.describe 'systems:backfill', type: :task do
  before(:all) do
    Rails.application.load_tasks if Rake::Task.tasks.empty?
  end

  let(:org_id) { '12345' }
  let(:account) { Account.find_or_create_by(org_id: org_id) }

  describe 'missing systems from new table' do
    let!(:missing_system) { FactoryBot.create(:system, account: account) }

    it 'inserts missing systems' do
      count_before = ActiveRecord::Base.connection.select_value('SELECT COUNT(*) FROM systems').to_i
      expect(count_before).to eq(0)

      Rake::Task['systems:backfill'].execute

      count_after = ActiveRecord::Base.connection.select_value('SELECT COUNT(*) FROM systems').to_i
      expect(count_after).to eq(1)
    end
  end

  describe 'conflict resolution' do
    let(:host_id) { SecureRandom.uuid }

    context 'updates systems if inventory.hosts is newer' do
      let(:new_name) { Faker::Lorem.word }
      let!(:newer_system) { FactoryBot.create(:system, id: host_id, display_name: new_name, account: account) }

      it 'updates systems if inventory.hosts is newer' do
        # Create stale record in `systems`
        ActiveRecord::Base.connection.execute(<<-SQL)
          INSERT INTO systems (id, org_id, display_name, tags, updated, created, stale_timestamp, system_profile)
          VALUES ('#{host_id}', '#{org_id}', '#{Faker::Lorem.word}', '{}', '#{2.days.ago.iso8601}', '#{2.days.ago.iso8601}', '#{2.days.ago.iso8601}', '{}')
        SQL

        Rake::Task['systems:backfill'].execute

        name = ActiveRecord::Base.connection.select_value("SELECT display_name FROM systems WHERE id = '#{host_id}'")
        expect(name).to eq(new_name)
      end
    end

    context 'skips update if systems is equal or newer' do
      let(:live_name) { Faker::Lorem.word }
      let!(:stale_system) { FactoryBot.create(:system, id: host_id, account: account, updated: 2.days.ago) }

      it 'skips update if systems is equal or newer' do
        # Create fresh record in `systems`
        ActiveRecord::Base.connection.execute(<<-SQL)
          INSERT INTO systems (id, org_id, display_name, tags, updated, created, stale_timestamp, system_profile)
          VALUES ('#{host_id}', '#{org_id}', '#{live_name}', '{}', '#{1.day.ago.iso8601}', '#{2.days.ago.iso8601}', '#{2.days.ago.iso8601}', '{}')
        SQL

        Rake::Task['systems:backfill'].execute

        name = ActiveRecord::Base.connection.select_value("SELECT display_name FROM systems WHERE id = '#{host_id}'")
        expect(name).to eq(live_name) # Ignored the backfill
      end
    end
  end

  describe 'batching and limits' do
    context 'respects MAX_ROWS_PER_RUN' do
      let!(:systems) { FactoryBot.create_list(:system, 2, account: account) }

      it 'respects MAX_ROWS_PER_RUN' do
        begin
          ENV['MAX_ROWS_PER_RUN'] = '1'
          ENV['BATCH_SIZE'] = '1'

          Rake::Task['systems:backfill'].execute

          count = ActiveRecord::Base.connection.select_value('SELECT COUNT(*) FROM systems').to_i
          expect(count).to eq(1)
        ensure
          ENV.delete('MAX_ROWS_PER_RUN')
          ENV.delete('BATCH_SIZE')
        end
      end
    end

    context 'processes multiple batches correctly' do
      let!(:systems) { FactoryBot.create_list(:system, 5, account: account) }

      it 'processes multiple batches correctly' do
        begin
          ENV['MAX_ROWS_PER_RUN'] = '100'
          ENV['BATCH_SIZE'] = '2'

          count_before = ActiveRecord::Base.connection.select_value('SELECT COUNT(*) FROM systems').to_i
          expect(count_before).to eq(0)

          Rake::Task['systems:backfill'].execute

          count_after = ActiveRecord::Base.connection.select_value('SELECT COUNT(*) FROM systems').to_i
          expect(count_after).to eq(5)
        ensure
          ENV.delete('MAX_ROWS_PER_RUN')
          ENV.delete('BATCH_SIZE')
        end
      end
    end

    context 'processes multiple accounts (organizations)' do
      let(:org_2) { '67890' }
      let(:account_2) { Account.find_or_create_by(org_id: org_2) }
      let!(:org_1_systems) { FactoryBot.create_list(:system, 3, account: account) }
      let!(:org_2_systems) { FactoryBot.create_list(:system, 2, account: account_2) }

      it 'processes multiple accounts' do
        begin
          ENV['MAX_ROWS_PER_RUN'] = '100'
          ENV['BATCH_SIZE'] = '10'

          count_before = ActiveRecord::Base.connection.select_value('SELECT COUNT(*) FROM systems').to_i
          expect(count_before).to eq(0)

          Rake::Task['systems:backfill'].execute

          count_after = ActiveRecord::Base.connection.select_value('SELECT COUNT(*) FROM systems').to_i
          expect(count_after).to eq(5)
          
          # Verify counts per org
          org1_count = ActiveRecord::Base.connection.select_value("SELECT COUNT(*) FROM systems WHERE org_id = '#{org_id}'").to_i
          org2_count = ActiveRecord::Base.connection.select_value("SELECT COUNT(*) FROM systems WHERE org_id = '#{org_2}'").to_i
          
          expect(org1_count).to eq(3)
          expect(org2_count).to eq(2)
        ensure
          ENV.delete('MAX_ROWS_PER_RUN')
          ENV.delete('BATCH_SIZE')
        end
      end
    end
  end
end
