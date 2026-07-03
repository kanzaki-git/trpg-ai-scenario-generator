class CreateScenarioSceneClues < ActiveRecord::Migration[8.0]
  def change
    create_table :scenario_scene_clues do |t|
      t.references :scenario_scene, null: false, foreign_key: true
      t.references :scenario_clue, null: false, foreign_key: true

      t.timestamps
    end

    add_index :scenario_scene_clues,
              %i[scenario_scene_id scenario_clue_id],
              unique: true,
              name: "index_scene_clues_on_scene_and_clue"
  end
end
