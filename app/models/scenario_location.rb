class ScenarioLocation < ApplicationRecord
  belongs_to :scenario

  has_many :scenario_scene_locations, dependent: :destroy
  has_many :scenario_scenes, through: :scenario_scene_locations

  has_many :outgoing_connections,
           class_name: "ScenarioLocationConnection",
           foreign_key: :source_location_id,
           inverse_of: :source_location,
           dependent: :destroy

  has_many :incoming_connections,
           class_name: "ScenarioLocationConnection",
           foreign_key: :destination_location_id,
           inverse_of: :destination_location,
           dependent: :destroy

  enum :visibility,
       {
         public: "public",
         secret: "secret"
       },
       prefix: true,
       validate: true

  validates :name, :description, presence: true

  validates :position,
            numericality: {
              only_integer: true,
              greater_than: 0
            },
            uniqueness: {
              scope: :scenario_id
            }

  validates :map_row,
            numericality: {
              only_integer: true,
              greater_than_or_equal_to: 1,
              less_than_or_equal_to: 3
            },
            uniqueness: {
              scope: [ :scenario_id, :map_column ]
            },
            allow_nil: true

  validates :map_column,
            numericality: {
              only_integer: true,
              greater_than_or_equal_to: 1,
              less_than_or_equal_to: 3
            },
            allow_nil: true

  validate :map_coordinates_both_present_or_blank

  private

  def map_coordinates_both_present_or_blank
    return if map_row.blank? && map_column.blank?
    return if map_row.present? && map_column.present?

    errors.add(
      :base,
      "マップの行と列は両方指定してください"
    )
  end
end
