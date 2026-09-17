class CreateScenarioLocationConnections < ActiveRecord::Migration[8.1]
  def change
    create_table :scenario_location_connections do |t|
      t.references :scenario,
                   null: false,
                   foreign_key: true

      t.references :source_location,
                   null: false,
                   foreign_key: {
                     to_table: :scenario_locations
                   }

      t.references :destination_location,
                   null: false,
                   foreign_key: {
                     to_table: :scenario_locations
                   }

      t.string :visibility,
               default: "public",
               null: false

      t.integer :position,
                null: false

      t.timestamps
    end

    add_index :scenario_location_connections,
              [ :scenario_id, :source_location_id, :destination_location_id ],
              unique: true,
              name: "idx_location_connections_unique_pair"

    add_index :scenario_location_connections,
              [ :scenario_id, :position ],
              unique: true,
              name: "idx_location_connections_scenario_position"

    add_check_constraint :scenario_location_connections,
                         "source_location_id < destination_location_id",
                         name: "chk_location_connections_order"
  end
end
