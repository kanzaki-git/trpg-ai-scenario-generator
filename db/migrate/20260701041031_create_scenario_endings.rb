class CreateScenarioEndings < ActiveRecord::Migration[8.0]
  def change
    create_table :scenario_endings do |t|
      t.references :scenario, null: false, foreign_key: true
      t.text :content
      t.integer :position

      t.timestamps
    end
  end
end
