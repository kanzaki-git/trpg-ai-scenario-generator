class CreateScenarioProgresses < ActiveRecord::Migration[8.1]
  def change
    create_table :scenario_progresses do |t|
      t.references :scenario,
                   null: false,
                   foreign_key: true,
                   index: { unique: true }

      t.timestamps
    end
  end
end
