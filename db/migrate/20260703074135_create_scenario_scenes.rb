class CreateScenarioScenes < ActiveRecord::Migration[8.0]
  def change
    create_table :scenario_scenes do |t|
      t.references :scenario, null: false, foreign_key: true
      t.string :title
      t.text :purpose
      t.integer :estimated_time
      t.text :read_aloud_text
      t.text :gm_actions
      t.text :player_questions
      t.text :investigation_options
      t.text :trigger_condition
      t.text :transition_condition
      t.text :hint
      t.integer :position

      t.timestamps
    end
  end
end
