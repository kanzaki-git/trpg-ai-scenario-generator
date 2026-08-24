class ScenarioGenerationStarter
  def initialize(user:, scenario:)
    @user = user
    @scenario = scenario
  end

  def call
    generation_log = user.scenario_generation_logs.create!(
      scenario: scenario,
      status: :processing,
      openai_model: ScenarioGenerator::MODEL,
      started_at: Time.current
    )

    background_response = ScenarioGenerator.new(
      scenario: scenario
    ).start_background

    scenario.update!(
      openai_response_id: background_response.id
    )

    generation_log.update!(
      openai_response_id: background_response.id,
      openai_model: background_response.model,
      openai_status: background_response.status
    )

    background_response

  rescue OpenAI::Errors::APIError,
         ScenarioGenerator::GenerationError => e
    generation_log&.record_failure!(
      openai_status: :request_error,
      error: e
    )

    scenario.destroy! if scenario.persisted?
    user.refund_scenario_generation!

    raise
  end

  private

  attr_reader :user, :scenario
end
