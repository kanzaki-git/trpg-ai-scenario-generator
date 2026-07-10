class ScenariosController < ApplicationController
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

      redirect_to root_path, notice: "シナリオを生成しました"
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

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
