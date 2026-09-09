class CreateScenarioSceneTransitions < ActiveRecord::Migration[8.1]
  def change
    create_table :scenario_scene_transitions do |t|
      t.references :source_scene,
                   null: false,
                   foreign_key: { to_table: :scenario_scenes }
      t.references :destination_scene,
                   null: false,
                   foreign_key: { to_table: :scenario_scenes }
      t.text :condition, null: false
      t.integer :position, null: false

      t.timestamps
    end

    add_index :scenario_scene_transitions,
              %i[source_scene_id position],
              unique: true,
              name: "index_scene_transitions_on_source_and_position"
  end
end
