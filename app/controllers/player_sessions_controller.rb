
class PlayerSessionsController < ApplicationController
  skip_before_action :require_login
  before_action :set_progress, only: %i[show status]

  def show
    @current_location = @progress.current_location
    @current_location_visible =
      location_visible_to_player?(@current_location)

    @appeared_npcs = appeared_npcs

    load_player_map
  end

  def status
    response.headers["Cache-Control"] = "no-store"

    load_player_map

    location = @progress.current_location

    current_location =
      if location_visible_to_player?(location)
        { id: location.id, name: location.name }
      end

    location_status =
      if location.nil?
        "unset"
      elsif current_location
        "public"
      else
        "hidden"
      end

    render json: {
      current_location: current_location,
      location_status: location_status,
      appeared_npcs: appeared_npcs.map do |npc|
        { id: npc.id, name: npc.name }
      end,
      map_locations: @map_locations.map do |map_location|
        {
          id: map_location.id,
          name: map_location.name,
          description: map_location.description,
          position: map_location.position,
          x: helpers.scenario_map_coordinate(map_location.map_column),
          y: helpers.scenario_map_coordinate(map_location.map_row)
        }
      end,
      map_connections: @map_connections.map do |connection|
        {
          source_location_id: connection.source_location_id,
          destination_location_id: connection.destination_location_id
        }
      end
    }
  end

  private

  def set_progress
    @progress = ScenarioProgress
      .includes(:scenario, :current_location)
      .find_by!(player_token: params[:player_token])

    @scenario = @progress.scenario
  end

  def appeared_npcs
    @progress.appeared_npcs
      .where(scenario_id: @scenario.id)
      .order(:position)
      .select(:id, :name)
  end

  def load_player_map
    @map_view = "player"

    locations = @scenario.scenario_locations
      .where.not(map_row: nil, map_column: nil)
      .order(:position)

    revealed_location_ids = @progress.revealed_locations
      .where(scenario_id: @scenario.id)
      .visibility_secret
      .pluck(:id)

    @map_locations = locations
      .where(visibility: :public)
      .or(locations.where(id: revealed_location_ids))
      .order(:position)
      .load

    visible_location_ids = @map_locations.map(&:id)

    @map_connections = @scenario.scenario_location_connections
      .visibility_public
      .where(
        source_location_id: visible_location_ids,
        destination_location_id: visible_location_ids
      )
      .includes(:source_location, :destination_location)
      .order(:position)
      .load

    @map_has_secret_content = false
    @map_has_secret_connections = false
  end

  def location_visible_to_player?(location)
    return false if location.nil?
    return true if location.visibility_public?

    @progress.revealed_locations.exists?(id: location.id)
  end
end
