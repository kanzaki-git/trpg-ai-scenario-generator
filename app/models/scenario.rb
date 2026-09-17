class Scenario < ApplicationRecord
  MAP_THEMES = {
    "ホラー" => "horror",
    "ミステリー" => "mystery",
    "ファンタジー" => "fantasy",
    "SF" => "sci_fi",
    "コメディ" => "comedy"
  }.freeze

  belongs_to :user

  has_many :scenario_generation_logs, dependent: :nullify

  enum :generation_status,
       {
         generating: "generating",
         completed: "completed",
         failed: "failed"
       },
       validate: true

  enum :map_type,
       {
         floor_plan: "floor_plan",
         area_map: "area_map",
         network: "network"
       },
       prefix: true,
       validate: { allow_nil: true }

  has_many :scenario_scenes, dependent: :destroy
  has_many :scenario_npcs, dependent: :destroy
  has_many :scenario_clues, dependent: :destroy
  has_many :scenario_events, dependent: :destroy
  has_many :scenario_endings, dependent: :destroy
  has_many :scenario_location_connections, dependent: :destroy
  has_many :scenario_locations, dependent: :destroy

  validates :genre, presence: true
  validates :world_setting, presence: true
  validates :tone, presence: true
  validates :player_count, presence: true
  validates :play_time, presence: true

  def map_theme
    MAP_THEMES.fetch(genre, "neutral")
  end
end
