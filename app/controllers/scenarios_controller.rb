class ScenariosController < ApplicationController
  before_action :set_scenario,
                only: %i[show materials scenes conclusion]

  def index
    @scenarios = current_user.scenarios.order(created_at: :desc)
  end

  def new
    @scenario = Scenario.new
  end

  def create
    @scenario = current_user.scenarios.build(scenario_params)

    if @scenario.valid?
      generation_result = ScenarioGenerator.new(
        scenario: @scenario
      ).call

      ScenarioGenerationSaver.new(
        scenario: @scenario,
        generation_result: generation_result
      ).call

      redirect_to @scenario, notice: "シナリオを生成しました"
    else
      render :new, status: :unprocessable_entity
    end
  rescue OpenAI::Errors::APIError,
        ScenarioGenerator::GenerationError => e
    Rails.logger.error(
      "シナリオ生成に失敗しました: #{e.class} #{e.message}"
    )

    @scenario.errors.add(
      :base,
      "シナリオの生成に失敗しました。時間をおいて、もう一度お試しください。"
    )

    render :new, status: :service_unavailable
  end

  def show; end

  def materials; end

  def scenes; end

  def conclusion; end

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
