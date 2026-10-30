class ScenarioProgressesController < ApplicationController
  before_action :set_scenario
  before_action :set_scenario_progress

  def update
    clue_ids = selected_ids(
      @scenario.scenario_clues,
      :clue_ids
    )
    location_ids = selected_ids(
      @scenario.scenario_locations,
      :location_ids
    )
    npc_ids = selected_ids(
      @scenario.scenario_npcs,
      :npc_ids
    )
    revealed_location_ids = selected_ids(
      @scenario.scenario_locations.visibility_secret,
      :revealed_location_ids
    )

    current_location_id = progress_params[:current_location_id]

    ScenarioProgress.transaction do
      @scenario_progress.current_location_id =
        current_location_id.presence

      @scenario_progress.save!

      @scenario_progress.presented_clue_ids = clue_ids
      @scenario_progress.visited_location_ids = location_ids
      @scenario_progress.appeared_npc_ids = npc_ids

      @scenario_progress.revealed_location_ids = revealed_location_ids
    end


    redirect_to scenes_scenario_path(
                @scenario,
                session_progress_open: "1"
              ),
              notice: "進行状況を保存しました。",
              status: :see_other
  rescue ActiveRecord::RecordInvalid
    redirect_to scenes_scenario_path(
                  @scenario,
                  session_progress_open: "1"
                ),
                alert: "進行状況を保存できませんでした。",
                status: :see_other
  end

  private

  def set_scenario
    @scenario = current_user.scenarios.find(
      params[:scenario_id]
    )
  end

  def set_scenario_progress
    @scenario_progress =
      @scenario.scenario_progress ||
      @scenario.build_scenario_progress
  end

  def progress_params
    params.fetch(
      :scenario_progress,
      ActionController::Parameters.new
    ).permit(
      :current_location_id,
      clue_ids: [],
      location_ids: [],
      npc_ids: [],
      revealed_location_ids: []
    )
  end

  def selected_ids(scope, key)
    ids = Array(progress_params[key]).compact_blank

    scope.where(id: ids).pluck(:id)
  end
end
