class CreateScenarioLocations < ActiveRecord::Migration[8.0]
  def change
    create_table :scenario_locations do |t|
      t.references :scenario, null: false, foreign_key: true
      t.string :name, null: false
      t.text :description, null: false
      t.integer :position, null: false

      t.timestamps
    end

    add_index :scenario_locations,
              [ :scenario_id, :position ],
              unique: true
  end
end
