class CreateScenarioSceneLocations < ActiveRecord::Migration[8.0]
  def change
    create_table :scenario_scene_locations do |t|
      t.references :scenario_scene, null: false, foreign_key: true
      t.references :scenario_location, null: false, foreign_key: true

      t.timestamps
    end

    add_index :scenario_scene_locations,
              [ :scenario_scene_id, :scenario_location_id ],
              unique: true,
              name: "index_scene_locations_on_scene_and_location"
  end
end
