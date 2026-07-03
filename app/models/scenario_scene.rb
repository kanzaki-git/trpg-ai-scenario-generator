class ScenarioScene < ApplicationRecord
  belongs_to :scenario

  has_many :scenario_scene_npcs, dependent: :destroy
  has_many :scenario_scene_clues, dependent: :destroy
  has_many :scenario_scene_events, dependent: :destroy

  has_many :scenario_npcs, through: :scenario_scene_npcs
  has_many :scenario_clues, through: :scenario_scene_clues
  has_many :scenario_events, through: :scenario_scene_events
end
