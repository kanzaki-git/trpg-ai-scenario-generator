class CreateScenarioSceneNpcs < ActiveRecord::Migration[8.0]
  def change
    create_table :scenario_scene_npcs do |t|
      t.references :scenario_scene, null: false, foreign_key: true
      t.references :scenario_npc, null: false, foreign_key: true
      t.text :reaction

      t.timestamps
    end

    add_index :scenario_scene_npcs,
              %i[scenario_scene_id scenario_npc_id],
              unique: true,
              name: "index_scene_npcs_on_scene_and_npc"
  end
end
