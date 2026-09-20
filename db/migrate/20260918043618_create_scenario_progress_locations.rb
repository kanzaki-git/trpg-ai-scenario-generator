class CreateScenarioProgressLocations < ActiveRecord::Migration[8.1]
  def change
    create_table :scenario_progress_locations do |t|
      t.references :scenario_progress, null: false, foreign_key: true
      t.references :scenario_location, null: false, foreign_key: true

      t.timestamps
    end

    add_index :scenario_progress_locations,
              %i[scenario_progress_id scenario_location_id],
              unique: true,
              name: "idx_progress_locations_unique"
  end
end
