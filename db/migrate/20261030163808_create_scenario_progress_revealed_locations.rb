
class CreateScenarioProgressRevealedLocations < ActiveRecord::Migration[8.1]
  def change
    create_table :scenario_progress_revealed_locations do |t|
      t.references :scenario_progress,
                   null: false,
                   foreign_key: true,
                   index: false

      t.references :scenario_location,
                   null: false,
                   foreign_key: true

      t.timestamps
    end

    add_index :scenario_progress_revealed_locations,
              [ :scenario_progress_id, :scenario_location_id ],
              unique: true,
              name: "index_progress_revealed_locations_on_progress_and_location"
  end
end
