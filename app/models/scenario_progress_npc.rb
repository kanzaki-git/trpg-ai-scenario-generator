class ScenarioProgressNpc < ApplicationRecord
  belongs_to :scenario_progress
  belongs_to :scenario_npc

  validates :scenario_npc_id,
            uniqueness: {
              scope: :scenario_progress_id
            }

  validate :npc_belongs_to_same_scenario

  private

  def npc_belongs_to_same_scenario
    return if scenario_progress.blank? || scenario_npc.blank?
    return if scenario_progress.scenario_id == scenario_npc.scenario_id

    errors.add(
      :scenario_npc,
      "は進行状況と同じシナリオに属する必要があります"
    )
  end
end
