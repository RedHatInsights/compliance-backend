# frozen_string_literal: true

# A service class to resolve duplicated accounts
class DuplicateAccountResolver
  MAIN_ID_COLUMN = Arel.sql('((array_agg("id"))[1]) as main')
  DUPL_ID_COLUMN = Arel.sql('unnest((array_agg("id"))[2:]) as dupl')

  class << self
    def run!
      duplicates = Account.select(MAIN_ID_COLUMN, DUPL_ID_COLUMN)
                          .group(:account_number)

      [Profile, Policy, User].each do |model|
        ActiveRecord::Base.connection.execute("
          UPDATE #{model.table_name} SET account_id = sq.main
          FROM (#{duplicates.to_sql}) AS sq WHERE account_id = sq.dupl
        ")
      end

      # This is safe as we resolved the relations with the UPDATE above
      Account.where(id: duplicates.pluck(DUPL_ID_COLUMN)).delete_all
    end
  end
end
