class ScenarioSceneEvent < ApplicationRecord
  belongs_to :scenario_scene
  belongs_to :scenario_event

  validates :scenario_event_id,
            uniqueness: { scope: :scenario_scene_id }
end
