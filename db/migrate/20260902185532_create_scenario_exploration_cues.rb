class CreateScenarioExplorationCues < ActiveRecord::Migration[8.0]
  def change
    create_table :scenario_exploration_cues do |t|
      t.references :scenario_scene, null: false, foreign_key: true

      t.references :source_location,
                   null: false,
                   foreign_key: { to_table: :scenario_locations }

      t.references :target_location,
                   null: false,
                   foreign_key: { to_table: :scenario_locations }

      t.references :scenario_npc, null: true, foreign_key: true

      t.text :trigger_condition, null: false
      t.text :read_aloud_text, null: false
      t.integer :position, null: false

      t.timestamps
    end

    add_index :scenario_exploration_cues,
              [ :scenario_scene_id, :position ],
              unique: true,
              name: "index_exploration_cues_on_scene_and_position"
  end
end
