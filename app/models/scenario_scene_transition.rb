class ScenarioSceneTransition < ApplicationRecord
  belongs_to :source_scene,
             class_name: "ScenarioScene",
             inverse_of: :outgoing_transitions
  belongs_to :destination_scene,
             class_name: "ScenarioScene",
             inverse_of: :incoming_transitions

  validates :condition, presence: true
  validates :position,
            numericality: { only_integer: true, greater_than: 0 },
            uniqueness: { scope: :source_scene_id }

  validate :scenes_belong_to_same_scenario
  validate :destination_differs_from_source

  private

  def scenes_belong_to_same_scenario
    return if source_scene.blank? || destination_scene.blank?
    return if source_scene.scenario_id == destination_scene.scenario_id

    errors.add(
      :destination_scene,
      "は移動元と同じシナリオに属するシーンを指定してください"
    )
  end

  def destination_differs_from_source
    return if source_scene.blank? || destination_scene.blank?
    return unless source_scene == destination_scene

    errors.add(
      :destination_scene,
      "は移動元とは異なるシーンを指定してください"
    )
  end
end
