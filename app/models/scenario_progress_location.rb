class ScenarioProgressLocation < ApplicationRecord
  belongs_to :scenario_progress
  belongs_to :scenario_location

  validates :scenario_location_id,
            uniqueness: {
              scope: :scenario_progress_id
            }

  validate :location_belongs_to_same_scenario

  private

  def location_belongs_to_same_scenario
    return if scenario_progress.blank? || scenario_location.blank?
    return if scenario_progress.scenario_id == scenario_location.scenario_id

    errors.add(
      :scenario_location,
      "は進行状況と同じシナリオに属する必要があります"
    )
  end
end
