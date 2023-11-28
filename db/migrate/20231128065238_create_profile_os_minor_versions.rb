# frozen_string_literal: true

class CreateProfileOsMinorVersions < ActiveRecord::Migration[7.0]
  def change
    create_table :profile_os_minor_versions, id: :uuid do |t|
      t.references :profile, type: :uuid, index: true
      t.integer :os_minor_version

      t.timestamps
    end
  end
end
