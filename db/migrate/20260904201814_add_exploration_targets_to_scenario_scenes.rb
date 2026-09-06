class AddExplorationTargetsToScenarioScenes < ActiveRecord::Migration[8.0]
  def change
    add_column :scenario_scenes,
               :exploration_targets,
               :jsonb,
               default: [],
               null: false
  end
end
