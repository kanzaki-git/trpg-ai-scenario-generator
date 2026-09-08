class AddParticipationModeToScenarioSceneNpcs < ActiveRecord::Migration[8.0]
  def change
    add_column :scenario_scene_npcs,
               :participation_mode,
               :string,
               default: "in_person",
               null: false
  end
end
