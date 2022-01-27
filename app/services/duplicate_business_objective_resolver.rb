# frozen_string_literal: true

# A service class to resolve duplicated business objectives
class DuplicateBusinessObjectiveResolver
  MAIN_ID_COLUMN = Arel.sql('((array_agg("id" ORDER BY "id"))[1]) as main')
  DUPL_ID_COLUMN = Arel.sql('unnest((array_agg("id" ORDER BY "id"))[2:]) as dupl')

  class << self
    def run!
      duplicates = BusinessObjective.select(MAIN_ID_COLUMN, DUPL_ID_COLUMN)
                                    .group(:title)

      ActiveRecord::Base.connection.execute("
        UPDATE policies SET business_objective_id = sq.main
        FROM (#{duplicates.to_sql}) AS sq WHERE business_objective_id = sq.dupl
      ")

      # This is safe as we resolved the relations with the UPDATE above
      BusinessObjective.where(id: duplicates.pluck(DUPL_ID_COLUMN)).delete_all
    end
  end
end
