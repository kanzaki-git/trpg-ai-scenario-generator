class ScenarioNpc < ApplicationRecord
  belongs_to :scenario

  has_many :scenario_scene_npcs, dependent: :destroy
  has_many :scenario_scenes, through: :scenario_scene_npcs
end
