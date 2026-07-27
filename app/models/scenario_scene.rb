class ScenarioScene < ApplicationRecord
  belongs_to :scenario

  has_many :scenario_scene_npcs, dependent: :destroy
  has_many :scenario_scene_clues, dependent: :destroy
  has_many :scenario_scene_events, dependent: :destroy

  has_many :scenario_npcs, through: :scenario_scene_npcs
  has_many :scenario_clues, through: :scenario_scene_clues
  has_many :scenario_events, through: :scenario_scene_events

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
