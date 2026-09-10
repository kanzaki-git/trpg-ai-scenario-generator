class AddDisplayFieldsToScenarioEvents < ActiveRecord::Migration[8.1]
  def change
    add_column :scenario_events, :title, :string
    add_column :scenario_events, :read_aloud_text, :text
    add_column :scenario_events, :gm_actions, :text
    add_column :scenario_events, :post_event_changes, :text
  end
end
