class CreateScenarioProgressClues < ActiveRecord::Migration[8.1]
  def change
    create_table :scenario_progress_clues do |t|
      t.references :scenario_progress, null: false, foreign_key: true
      t.references :scenario_clue, null: false, foreign_key: true

      t.timestamps
    end

    add_index :scenario_progress_clues,
              %i[scenario_progress_id scenario_clue_id],
              unique: true,
              name: "idx_progress_clues_unique"
  end
end
