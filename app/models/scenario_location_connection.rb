class ScenarioLocationConnection < ApplicationRecord
  belongs_to :scenario

  belongs_to :source_location,
             class_name: "ScenarioLocation",
             inverse_of: :outgoing_connections

  belongs_to :destination_location,
             class_name: "ScenarioLocation",
             inverse_of: :incoming_connections

  enum :visibility,
       {
         public: "public",
         secret: "secret"
       },
       prefix: true,
       validate: true

  before_validation :normalize_location_order

  validates :position,
            numericality: {
              only_integer: true,
              greater_than: 0
            },
            uniqueness: {
              scope: :scenario_id
            }

  validates :destination_location_id,
            uniqueness: {
              scope: [ :scenario_id, :source_location_id ]
            }

  validate :locations_are_different
  validate :locations_belong_to_scenario

  private

  def normalize_location_order
    return if source_location.blank? || destination_location.blank?
    return if source_location.id.blank? || destination_location.id.blank?
    return if source_location.id < destination_location.id

    self.source_location, self.destination_location =
      destination_location, source_location
  end

  def locations_are_different
    return if source_location.blank? || destination_location.blank?
    return unless source_location == destination_location

    errors.add(
      :destination_location,
      "は接続元と異なる場所を指定してください"
    )
  end

  def locations_belong_to_scenario
    return if scenario.blank?
    return if source_location.blank? || destination_location.blank?

    source_matches = source_location.scenario_id == scenario_id
    destination_matches =
      destination_location.scenario_id == scenario_id

    return if source_matches && destination_matches

    errors.add(
      :base,
      "接続する場所は同じシナリオに属している必要があります"
    )
  end
end
