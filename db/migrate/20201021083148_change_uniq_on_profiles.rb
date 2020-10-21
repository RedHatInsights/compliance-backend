class ChangeUniqOnProfiles < ActiveRecord::Migration[5.2]
  def up
    remove_index :profiles, name: 'uniqueness'
    add_index :profiles,
              %i[ref_id account_id benchmark_id external policy_id],
              unique: true, name: 'uniqueness'
  end

  def down
    remove_index :profiles, name: 'uniqueness'
    add_index :profiles,
              %i[ref_id account_id benchmark_id external],
              unique: true, name: 'uniqueness'
  end
end
