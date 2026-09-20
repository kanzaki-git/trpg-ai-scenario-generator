class ScenarioProgressClue < ApplicationRecord
  belongs_to :scenario_progress
  belongs_to :scenario_clue

  validates :scenario_clue_id,
            uniqueness: {
              scope: :scenario_progress_id
            }

  validate :clue_belongs_to_same_scenario

  private

  def clue_belongs_to_same_scenario
    return if scenario_progress.blank? || scenario_clue.blank?
    return if scenario_progress.scenario_id == scenario_clue.scenario_id

    errors.add(
      :scenario_clue,
      "は進行状況と同じシナリオに属する必要があります"
    )
  end
end
