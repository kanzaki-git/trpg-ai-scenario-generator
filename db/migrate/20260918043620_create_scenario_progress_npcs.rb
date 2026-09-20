class CreateScenarioProgressNpcs < ActiveRecord::Migration[8.1]
  def change
    create_table :scenario_progress_npcs do |t|
      t.references :scenario_progress, null: false, foreign_key: true
      t.references :scenario_npc, null: false, foreign_key: true

      t.timestamps
    end

    add_index :scenario_progress_npcs,
              %i[scenario_progress_id scenario_npc_id],
              unique: true,
              name: "idx_progress_npcs_unique"
  end
end
