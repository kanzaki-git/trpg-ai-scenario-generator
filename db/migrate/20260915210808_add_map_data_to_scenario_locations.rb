class AddMapDataToScenarioLocations < ActiveRecord::Migration[8.1]
  def change
    add_column :scenario_locations, :map_row, :integer
    add_column :scenario_locations, :map_column, :integer
    add_column :scenario_locations,
               :visibility,
               :string,
               default: "public",
               null: false

    add_index :scenario_locations,
              [ :scenario_id, :map_row, :map_column ],
              unique: true,
              where: "map_row IS NOT NULL AND map_column IS NOT NULL",
              name: "idx_scenario_locations_unique_map_coordinates"
  end
end
