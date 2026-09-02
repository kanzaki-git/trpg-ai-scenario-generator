class ScenarioSceneLocation < ApplicationRecord
  belongs_to :scenario_scene
  belongs_to :scenario_location

  validates :scenario_location_id,
            uniqueness: { scope: :scenario_scene_id }

  validate :location_belongs_to_same_scenario

  private

  def location_belongs_to_same_scenario
    return if scenario_scene.blank? || scenario_location.blank?
    return if scenario_scene.scenario_id == scenario_location.scenario_id

    errors.add(
      :scenario_location,
      "はシーンと同じシナリオに属する場所を指定してください"
    )
  end
end
