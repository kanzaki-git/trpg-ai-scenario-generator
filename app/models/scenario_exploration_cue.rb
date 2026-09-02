class ScenarioExplorationCue < ApplicationRecord
  belongs_to :scenario_scene
  belongs_to :source_location, class_name: "ScenarioLocation"
  belongs_to :target_location, class_name: "ScenarioLocation"
  belongs_to :scenario_npc, optional: true

  validates :trigger_condition, :read_aloud_text, presence: true
  validates :position,
            numericality: { only_integer: true, greater_than: 0 },
            uniqueness: { scope: :scenario_scene_id }

  validate :locations_belong_to_same_scenario
  validate :source_location_belongs_to_scene
  validate :speaker_matches_scene_and_location

  private

  def locations_belong_to_same_scenario
    return if scenario_scene.blank?

    if source_location.present? &&
       source_location.scenario_id != scenario_scene.scenario_id
      errors.add(
        :source_location,
        "はシーンと同じシナリオに属する場所を指定してください"
      )
    end

    if target_location.present? &&
       target_location.scenario_id != scenario_scene.scenario_id
      errors.add(
        :target_location,
        "はシーンと同じシナリオに属する場所を指定してください"
      )
    end
  end

  def source_location_belongs_to_scene
    return if scenario_scene.blank? || source_location.blank?

    return if scenario_scene.scenario_scene_locations.exists?(
      scenario_location_id: source_location.id
    )

    errors.add(
      :source_location,
      "はこのシーンに関連付けられた場所を指定してください"
    )
  end

  def speaker_matches_scene_and_location
    return if scenario_scene.blank? || scenario_npc.blank?

    if scenario_npc.scenario_id != scenario_scene.scenario_id
      errors.add(
        :scenario_npc,
        "はシーンと同じシナリオに属するNPCを指定してください"
      )
      return
    end

    appearance = scenario_scene.scenario_scene_npcs.find_by(
      scenario_npc_id: scenario_npc.id
    )

    if appearance.blank?
      errors.add(:scenario_npc, "はこのシーンに登場するNPCを指定してください")
      return
    end

    return if source_location.blank?

    speaker_location_id =
      appearance.scenario_location_id || scenario_npc.initial_location_id

    return if speaker_location_id == source_location.id

    errors.add(
      :scenario_npc,
      "の居場所と情報を得る場所を一致させてください"
    )
  end
end
