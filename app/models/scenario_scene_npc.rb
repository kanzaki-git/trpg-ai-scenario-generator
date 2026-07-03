class ScenarioSceneNpc < ApplicationRecord
  belongs_to :scenario_scene
  belongs_to :scenario_npc

  validates :scenario_npc_id,
            uniqueness: { scope: :scenario_scene_id }
end
