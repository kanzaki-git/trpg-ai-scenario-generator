class AddInitialPlacementToScenarioNpcs < ActiveRecord::Migration[8.0]
  def change
    add_reference :scenario_npcs,
                  :initial_location,
                  null: true,
                  foreign_key: { to_table: :scenario_locations }

    add_column :scenario_npcs, :initial_activity, :text
  end
end
