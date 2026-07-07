class Scenario < ApplicationRecord
  belongs_to :user

  has_many :scenario_scenes, dependent: :destroy
  has_many :scenario_npcs, dependent: :destroy
  has_many :scenario_clues, dependent: :destroy
  has_many :scenario_events, dependent: :destroy
  has_many :scenario_endings, dependent: :destroy

  validates :genre, presence: true
  validates :world_setting, presence: true
  validates :tone, presence: true
  validates :player_count, presence: true
  validates :play_time, presence: true
end
