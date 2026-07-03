class CreateScenarioEvents < ActiveRecord::Migration[8.0]
  def change
    create_table :scenario_events do |t|
      t.references :scenario, null: false, foreign_key: true
      t.text :content
      t.text :trigger_condition
      t.integer :position

      t.timestamps
    end
  end
end
