class ScenarioSceneNpc < ApplicationRecord
  belongs_to :scenario_scene
  belongs_to :scenario_npc
  belongs_to :scenario_location, optional: true

  validates :scenario_npc_id,
            uniqueness: { scope: :scenario_scene_id }

  validate :npc_belongs_to_same_scenario
  validate :location_belongs_to_scene

  private

  def npc_belongs_to_same_scenario
    return if scenario_scene.blank? || scenario_npc.blank?
    return if scenario_scene.scenario_id == scenario_npc.scenario_id

    errors.add(
      :scenario_npc,
      "はシーンと同じシナリオに属するNPCを指定してください"
    )
  end

  def location_belongs_to_scene
    return if scenario_scene.blank? || scenario_location.blank?

    if scenario_scene.scenario_id != scenario_location.scenario_id
      errors.add(
        :scenario_location,
        "はシーンと同じシナリオに属する場所を指定してください"
      )
      return
    end

    return if scenario_scene.scenario_scene_locations.exists?(
      scenario_location_id: scenario_location.id
    )

    errors.add(
      :scenario_location,
      "はこのシーンに関連付けられた場所を指定してください"
    )
  end
end
