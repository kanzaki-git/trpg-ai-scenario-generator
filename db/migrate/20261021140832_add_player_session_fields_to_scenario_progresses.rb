class AddPlayerSessionFieldsToScenarioProgresses < ActiveRecord::Migration[8.1]
  def up
    # ① プレイヤー用トークンを追加
    add_column :scenario_progresses, :player_token, :string

    # ② 既存データにトークンを割り当てる
    progress_model = Class.new(ActiveRecord::Base) do
      self.table_name = "scenario_progresses"
    end

    progress_model.reset_column_information

    progress_model.where(player_token: nil).find_each do |progress|
      progress.update_columns(
        player_token: SecureRandom.urlsafe_base64(32)
      )
    end

    # ③ NULL禁止と一意制約を設定
    change_column_null :scenario_progresses, :player_token, false
    add_index :scenario_progresses, :player_token, unique: true

    # ④ 現在地を追加
    add_reference :scenario_progresses,
                  :current_location,
                  null: true,
                  index: true

    # ⑤ 場所の削除時に現在地をNULLにする
    add_foreign_key :scenario_progresses,
                    :scenario_locations,
                    column: :current_location_id,
                    on_delete: :nullify
  end

  def down
    remove_foreign_key :scenario_progresses, column: :current_location_id
    remove_reference :scenario_progresses, :current_location
    remove_index :scenario_progresses, :player_token
    remove_column :scenario_progresses, :player_token
  end
end
