class CreateScenarioShares < ActiveRecord::Migration[8.1]
  def change
    create_table :scenario_shares do |t|
      t.references :scenario,
                   null: false,
                   foreign_key: true,
                   index: { unique: true }

      t.string :public_title
      t.text :public_description
      t.string :share_token, null: false
      t.datetime :published_at

      t.timestamps
    end

    add_index :scenario_shares,
              :share_token,
              unique: true
  end
end
