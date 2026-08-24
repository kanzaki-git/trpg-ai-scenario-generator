class ScenariosController < ApplicationController
  before_action :set_scenario,
                only: %i[show materials scenes conclusion generating generation_status destroy]

  def index
    @scenarios = current_user.scenarios
      .completed
      .order(created_at: :desc)
  end

  def new
    @scenario = Scenario.new
  end

  def create
    @scenario = current_user.scenarios.build(scenario_params)

    if @scenario.valid?
      reservation_result = current_user.reserve_scenario_generation!(
        @scenario
      )

      case reservation_result
      when :already_generating
        generating_scenario = current_user.scenarios
          .generating
          .order(created_at: :desc)
          .first

        redirect_path = if generating_scenario
                          generating_scenario_path(generating_scenario)
        else
                          new_scenario_path
        end

        redirect_to redirect_path,
                    alert: "現在、別のシナリオを生成中です。生成完了までお待ちください。"
        return
      when :limit_reached
        redirect_to new_scenario_path,
                    alert: "シナリオを生成できる回数は3回までです。"
        return
      end

      ScenarioGenerationStarter.new(
        user: current_user,
        scenario: @scenario
      ).call

      redirect_to generating_scenario_path(@scenario)
    else
      render :new, status: :unprocessable_entity
    end

  rescue OpenAI::Errors::APIError,
        ScenarioGenerator::GenerationError => e
    Rails.logger.error(
      "シナリオ生成に失敗しました: #{e.class} #{e.message}"
    )

    @scenario = current_user.scenarios.build(scenario_params)

    @scenario.errors.add(
      :base,
      "シナリオの生成に失敗しました。時間をおいて、もう一度お試しください。"
    )

    render :new, status: :service_unavailable
  end

  def show; end

  def destroy
    @scenario.destroy!

    redirect_to scenarios_path,
                notice: "シナリオを削除しました。",
                status: :see_other
  end

  def materials; end

  def scenes
    @scenario_scenes = @scenario.scenario_scenes
      .includes(
        :scenario_clues,
        :scenario_events,
        scenario_scene_npcs: :scenario_npc
      )
      .order(:position)
  end

  def conclusion; end

  def generating; end

    def generation_status
    ScenarioGenerationStatusUpdater.new(
      scenario: @scenario
    ).call

    @scenario.reload

    response_data = {
      status: @scenario.generation_status
    }

    if @scenario.completed?
      response_data[:redirect_url] = scenario_path(@scenario)
    end

    render json: response_data
  end

  private

  def set_scenario
    @scenario = current_user.scenarios.find(params[:id])
  end

  def scenario_params
    params.require(:scenario).permit(
      :genre,
      :world_setting,
      :tone,
      :player_count,
      :play_time
    )
  end
end
