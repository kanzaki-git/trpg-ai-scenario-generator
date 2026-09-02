class ScenarioNpc < ApplicationRecord
  belongs_to :scenario
  belongs_to :initial_location,
             class_name: "ScenarioLocation",
             optional: true

  has_many :scenario_scene_npcs, dependent: :destroy
  has_many :scenario_scenes, through: :scenario_scene_npcs

  validate :initial_location_belongs_to_same_scenario

  private

  def initial_location_belongs_to_same_scenario
    return if initial_location.blank?
    return if initial_location.scenario_id == scenario_id

    errors.add(
      :initial_location,
      "はNPCと同じシナリオに属する場所を指定してください"
    )
  end
end
