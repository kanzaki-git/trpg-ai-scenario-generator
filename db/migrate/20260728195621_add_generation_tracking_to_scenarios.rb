class AddGenerationTrackingToScenarios < ActiveRecord::Migration[8.0]
  def change
    add_column :scenarios, :generation_status, :string, null: false, default: "completed"
    add_column :scenarios, :openai_response_id, :string
  end
end
