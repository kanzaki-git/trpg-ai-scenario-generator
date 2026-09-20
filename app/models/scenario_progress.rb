class ScenarioProgress < ApplicationRecord
  belongs_to :scenario

  has_many :scenario_progress_clues,
           dependent: :destroy
  has_many :presented_clues,
           through: :scenario_progress_clues,
           source: :scenario_clue

  has_many :scenario_progress_locations,
           dependent: :destroy
  has_many :visited_locations,
           through: :scenario_progress_locations,
           source: :scenario_location

  has_many :scenario_progress_npcs,
           dependent: :destroy
  has_many :appeared_npcs,
           through: :scenario_progress_npcs,
           source: :scenario_npc

  validates :scenario_id, uniqueness: true
end
