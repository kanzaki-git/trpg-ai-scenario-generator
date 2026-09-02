class ScenarioLocation < ApplicationRecord
  belongs_to :scenario

  has_many :scenario_scene_locations, dependent: :destroy
  has_many :scenario_scenes, through: :scenario_scene_locations

  validates :name, :description, presence: true
  validates :position,
            numericality: { only_integer: true, greater_than: 0 },
            uniqueness: { scope: :scenario_id }
end
