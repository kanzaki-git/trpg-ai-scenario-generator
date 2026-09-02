class AddPlacementToScenarioSceneNpcs < ActiveRecord::Migration[8.0]
  def change
    add_reference :scenario_scene_npcs,
                  :scenario_location,
                  null: true,
                  foreign_key: true

    add_column :scenario_scene_npcs, :activity, :text
    add_column :scenario_scene_npcs, :appearance_condition, :text
  end
end
