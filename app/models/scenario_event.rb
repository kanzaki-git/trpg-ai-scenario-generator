class ScenarioEvent < ApplicationRecord
  belongs_to :scenario

  has_many :scenario_scene_events, dependent: :destroy
  has_many :scenario_scenes, through: :scenario_scene_events
end
