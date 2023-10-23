class AddProfileIdToPolicies < ActiveRecord::Migration[7.0]
  def up
    add_reference :policies, :profile, default: nil, foreign_key: { to_table: :profiles }, type: :uuid

    query = %{
      UPDATE "policies" SET "profile_id" = "sq"."parent_profile_id" FROM (
        SELECT DISTINCT ON ("profiles"."created_at") "policies"."id", "profiles"."parent_profile_id"
        FROM "policies" INNER JOIN "profiles" ON "profiles"."policy_id" = "policies"."id"
        ORDER BY "profiles"."created_at" ASC
      ) "sq" WHERE "sq"."id" = "policies"."id"
    }

    ActiveRecord::Base.connection.execute(query)
  end

  def down
    remove_reference :policies, :profile
  end
end
