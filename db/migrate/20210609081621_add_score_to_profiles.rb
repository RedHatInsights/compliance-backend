class AddScoreToProfiles < ActiveRecord::Migration[5.2]
  def up
    add_column :profiles, :score, :decimal

    Profile.transaction do
      scores = TestResult.latest.joins(:profile).group(:profile_id).average(:score)

      # Profile.canonical(false).where(score: nil).joins(:test_results).distinct.find_each(&:calculate_score!)
      # TODO: replace this with upsert after upgrading to Rails 6
      values = scores.map do |k, v|
        "(#{ActiveRecord::Base.connection.quote(k)}, #{ActiveRecord::Base.connection.quote(v)})"
      end.join(', ')

      query = %{
        UPDATE profiles P
        SET score = uv.new_score
        FROM (VALUES #{values}) AS uv (id, new_score)
        WHERE P.id = uv.id::uuid
      }.gsub(/\s+/, " ").strip

      ActiveRecord::Base.connection.execute(query)
    end
  end

  def down
    remove_column :profiles, :score
  end
end
