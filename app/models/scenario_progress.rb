class ScenarioProgress < ApplicationRecord
  belongs_to :scenario

  belongs_to :current_location,
             class_name: "ScenarioLocation",
             optional: true

  has_secure_token :player_token

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
  validates :player_token, presence: true, uniqueness: true

  validate :current_location_belongs_to_scenario

  private

  def current_location_belongs_to_scenario
    return if current_location.nil?
    return if current_location.scenario_id == scenario_id

    errors.add(
      :current_location,
      "は同じシナリオに所属する場所を指定してください"
    )
  end
end
