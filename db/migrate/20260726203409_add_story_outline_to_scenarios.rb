class AddStoryOutlineToScenarios < ActiveRecord::Migration[8.0]
  def change
    add_column :scenarios, :story_outline, :text
  end
end
