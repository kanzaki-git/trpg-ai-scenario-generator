class ScenarioClue < ApplicationRecord
  belongs_to :scenario

  has_many :scenario_scene_clues, dependent: :destroy
  has_many :scenario_scenes, through: :scenario_scene_clues
  has_many :scenario_progress_clues, dependent: :destroy
end
