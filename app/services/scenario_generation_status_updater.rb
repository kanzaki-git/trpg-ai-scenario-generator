class ScenarioGenerationStatusUpdater
  def initialize(scenario:)
    @scenario = scenario
  end

   def call
    return unless scenario.generating?

    generator = ScenarioGenerator.new(
      scenario: scenario
    )

    openai_response = generator.retrieve_background(
      scenario.openai_response_id
    )

    Rails.logger.info(
      "OpenAI Background response: " \
      "id=#{openai_response.id} " \
      "status=#{openai_response.status}"
    )

    case openai_response.status
    when :completed
      complete_generation(
        generator: generator,
        openai_response: openai_response
      )
    when :failed, :incomplete, :cancelled
      fail_generation(
        openai_status: openai_response.status,
        openai_response: openai_response
      )
    end
  rescue OpenAI::Errors::APIError,
         ScenarioGenerator::GenerationError => e
    Rails.logger.error(
      "シナリオ生成状況の確認に失敗しました: " \
      "scenario_id=#{scenario.id} " \
      "#{e.class} #{e.message}"
    )

    fail_generation(
      openai_status: :request_error,
      error: e
    )
  end

  private

  attr_reader :scenario

  def complete_generation(generator:, openai_response:)
    scenario.with_lock do
      next unless scenario.generating?

      generation_result = generator.extract_background_result(
        openai_response
      )

      ScenarioGenerationSaver.new(
        scenario: scenario,
        generation_result: generation_result
      ).call

      scenario.update!(
        generation_status: :completed
      )

      generation_log = scenario.scenario_generation_logs.find_by(
        openai_response_id: openai_response.id
      )

      generation_log&.record_completion!(
        openai_response
      )
    end
  end

  def fail_generation(
    openai_status:,
    openai_response: nil,
    error: nil
  )
    scenario.with_lock do
      next unless scenario.generating?

      Rails.logger.error(
        "OpenAI Background generation failed: " \
        "scenario_id=#{scenario.id} " \
        "status=#{openai_status}"
      )

      generation_log = scenario.scenario_generation_logs.find_by(
        openai_response_id: scenario.openai_response_id
      )

      generation_log&.record_failure!(
        openai_status: openai_status,
        openai_response: openai_response,
        error: error
      )

      scenario.update!(
        generation_status: :failed
      )

      scenario.user.refund_scenario_generation!
    end
  end
end
