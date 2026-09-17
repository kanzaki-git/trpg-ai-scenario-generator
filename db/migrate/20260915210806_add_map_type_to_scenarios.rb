class AddMapTypeToScenarios < ActiveRecord::Migration[8.1]
  def change
    add_column :scenarios, :map_type, :string
  end
end
