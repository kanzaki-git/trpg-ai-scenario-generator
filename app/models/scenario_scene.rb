class ScenarioScene < ApplicationRecord
  belongs_to :scenario

  has_many :scenario_exploration_cues, dependent: :destroy
  has_many :scenario_scene_npcs, dependent: :destroy
  has_many :scenario_scene_clues, dependent: :destroy
  has_many :scenario_scene_events, dependent: :destroy
  has_many :scenario_scene_locations, dependent: :destroy

  has_many :scenario_npcs, through: :scenario_scene_npcs
  has_many :scenario_clues, through: :scenario_scene_clues
  has_many :scenario_events, through: :scenario_scene_events
  has_many :scenario_locations, through: :scenario_scene_locations

  has_many :outgoing_transitions,
           -> { order(:position) },
           class_name: "ScenarioSceneTransition",
           foreign_key: :source_scene_id,
           inverse_of: :source_scene,
           dependent: :destroy
  has_many :incoming_transitions,
           class_name: "ScenarioSceneTransition",
           foreign_key: :destination_scene_id,
           inverse_of: :destination_scene,
           dependent: :destroy

  def exploration_target_items
    required_keys = %w[
      key
      name
      visible_on_arrival
      description
      reveal_condition
    ]

    Array(exploration_targets).select do |target|
      target.is_a?(Hash) &&
        required_keys.all? { |key| target.key?(key) }
    end
  end

  def visible_exploration_target_items
    exploration_target_items.select do |target|
      target["visible_on_arrival"] == true
    end
  end

  def investigation_option_items
    parsed_options = JSON.parse(investigation_options)

    return [] unless parsed_options.is_a?(Array)

    parsed_options.select do |option|
      option.is_a?(Hash) &&
        option.key?("label") &&
        option.key?("result") &&
        option.key?("gm_guide")
    end
  rescue JSON::ParserError, TypeError
    []
  end
end
