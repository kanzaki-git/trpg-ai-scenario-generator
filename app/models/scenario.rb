class Scenario < ApplicationRecord
  belongs_to :user

  has_many :scenario_npcs, dependent: :destroy
  has_many :scenario_clues, dependent: :destroy
  has_many :scenario_events, dependent: :destroy
  has_many :scenario_endings, dependent: :destroy
end
