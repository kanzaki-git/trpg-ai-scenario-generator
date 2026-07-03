class CreateScenarioSceneEvents < ActiveRecord::Migration[8.0]
  def change
    create_table :scenario_scene_events do |t|
      t.references :scenario_scene, null: false, foreign_key: true
      t.references :scenario_event, null: false, foreign_key: true

      t.timestamps
    end

    add_index :scenario_scene_events,
              %i[scenario_scene_id scenario_event_id],
              unique: true,
              name: "index_scene_events_on_scene_and_event"
  end
end
