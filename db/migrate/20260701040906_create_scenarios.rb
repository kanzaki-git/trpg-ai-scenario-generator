class CreateScenarios < ActiveRecord::Migration[8.0]
  def change
    create_table :scenarios do |t|
      t.references :user, null: false, foreign_key: true
      t.string :title
      t.text :summary
      t.string :genre
      t.text :world_setting
      t.integer :player_count
      t.integer :play_time
      t.string :tone
      t.text :introduction
      t.text :truth

      t.timestamps
    end
  end
end
