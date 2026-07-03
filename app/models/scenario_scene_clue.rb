class ScenarioSceneClue < ApplicationRecord
  belongs_to :scenario_scene
  belongs_to :scenario_clue

  validates :scenario_clue_id,
            uniqueness: { scope: :scenario_scene_id }
end
