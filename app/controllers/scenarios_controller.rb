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
      unless current_user.reserve_scenario_generation!
        redirect_to new_scenario_path,
                    alert: "シナリオを生成できる回数は3回までです。"
        return
      end

      @generation_reserved = true

      background_response = ScenarioGenerator.new(
        scenario: @scenario
      ).start_background

      @scenario.assign_attributes(
        generation_status: :generating,
        openai_response_id: background_response.id
      )

      @scenario.save!

      redirect_to generating_scenario_path(@scenario)
    else
      render :new, status: :unprocessable_entity
    end
  rescue OpenAI::Errors::APIError,
        ScenarioGenerator::GenerationError => e
    current_user.refund_scenario_generation! if @generation_reserved

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

  def destroy
    @scenario.destroy!

    redirect_to scenarios_path,
                notice: "シナリオを削除しました。",
                status: :see_other
  end

  def materials; end

  def scenes; end

  def conclusion; end

  def generating; end

  def generation_status
    if @scenario.generating?
      generator = ScenarioGenerator.new(
        scenario: @scenario
      )

      openai_response = generator.retrieve_background(
        @scenario.openai_response_id
      )

      Rails.logger.info(
        "OpenAI Background response: " \
        "id=#{openai_response.id} " \
        "status=#{openai_response.status}"
      )

      case openai_response.status
      when :completed
        complete_background_generation(
          generator: generator,
          openai_response: openai_response
        )
      when :failed, :incomplete, :cancelled
        fail_background_generation(
          openai_status: openai_response.status
        )
      end
    end

    @scenario.reload

    response_data = {
      status: @scenario.generation_status
    }

    if @scenario.completed?
      response_data[:redirect_url] = scenario_path(@scenario)
    end

    render json: response_data
  rescue OpenAI::Errors::APIError,
        ScenarioGenerator::GenerationError => e
    Rails.logger.error(
      "シナリオ生成状況の確認に失敗しました: " \
      "scenario_id=#{@scenario.id} " \
      "#{e.class} #{e.message}"
    )

    fail_background_generation(
      openai_status: :request_error
    )

    render json: {
      status: @scenario.reload.generation_status
    }
  end

  private

  def complete_background_generation(generator:, openai_response:)
    @scenario.with_lock do
      next unless @scenario.generating?

      generation_result = generator.extract_background_result(
        openai_response
      )

      ScenarioGenerationSaver.new(
        scenario: @scenario,
        generation_result: generation_result
      ).call

      @scenario.update!(
        generation_status: :completed
      )
    end
  end

  def fail_background_generation(openai_status:)
    @scenario.with_lock do
      next unless @scenario.generating?

      Rails.logger.error(
        "OpenAI Background generation failed: " \
        "scenario_id=#{@scenario.id} " \
        "status=#{openai_status}"
      )

      @scenario.update!(
        generation_status: :failed
      )

      @scenario.user.refund_scenario_generation!
    end
  end

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
