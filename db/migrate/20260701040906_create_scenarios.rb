class CreateScenarios < ActiveRecord::Migration[8.0]
  def change
    create_table :scenarios do |t|
      t.string :title
      t.text :introduction
      t.text :truth
      t.references :user, null: false, foreign_key: true

      t.timestamps
    end
  end
end
