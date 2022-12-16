# frozen_string_literal: true

# Service for copying value overrides from parent profiles to non-canonical profiles
class CopyValueOverridesToNonCanonical
  class << self
    def run!
      query = 'UPDATE "profiles"
               SET "value_overrides" = "parent_profiles"."value_overrides"
               FROM "profiles" AS "parent_profiles"
               WHERE "profiles"."parent_profile_id" IS NOT NULL
               AND "profiles"."parent_profile_id" = "parent_profiles"."id"'
      ActiveRecord::Base.connection.execute(query)
    end
  end
end
