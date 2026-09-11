class AddConditionToScenarioEndings < ActiveRecord::Migration[8.1]
  def change
    add_column :scenario_endings, :condition, :text
  end
end
