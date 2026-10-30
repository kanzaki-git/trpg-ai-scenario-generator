class PlayerSessionsController < ApplicationController
  skip_before_action :require_login

  def show
    @progress = ScenarioProgress
      .includes(:scenario, :current_location)
      .find_by!(player_token: params[:player_token])

    @scenario = @progress.scenario
    @current_location = @progress.current_location

    @appeared_npcs = @progress.appeared_npcs
      .where(scenario_id: @scenario.id)
      .order(:position)
      .select(:id, :name)

    load_player_map
  end

  private

  def load_player_map
    @map_view = "player"

    locations = @scenario.scenario_locations
      .where.not(map_row: nil, map_column: nil)
      .order(:position)

    @map_locations = locations.visibility_public.load

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
end
