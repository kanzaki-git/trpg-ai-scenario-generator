require "test_helper"
require "minitest/mock"
require "ostruct"

class ScenarioGenerationStatusUpdaterTest < ActiveSupport::TestCase
  setup do
    @user = User.create!(
      name: "テストユーザー",
      email: "status-updater-test@example.com",
      password: "password",
      password_confirmation: "password"
    )

    @scenario = @user.scenarios.create!(
      genre: "ホラー",
      world_setting: "現代日本",
      tone: "ダーク",
      player_count: 2,
      play_time: 30,
      generation_status: :generating,
      openai_response_id: "resp_background_failed"
    )

    @user.update!(
      scenario_generation_count: 1
    )

    @generation_log = @user.scenario_generation_logs.create!(
      scenario: @scenario,
      status: :processing,
      openai_response_id: "resp_background_failed",
      openai_model: "gpt-5.2",
      started_at: Time.current
    )
  end

  test "OpenAI側で生成に失敗した場合は失敗状態に更新する" do
    openai_response = OpenStruct.new(
      id: "resp_background_failed",
      model: "gpt-5.2",
      status: :failed,
      error: OpenStruct.new(
        code: "server_error",
        message: "OpenAI側で生成に失敗しました"
      ),
      usage: nil
    )

    fake_generator = Minitest::Mock.new
    fake_generator.expect(
      :retrieve_background,
      openai_response,
      [ "resp_background_failed" ]
    )

    ScenarioGenerator.stub(
      :new,
      ->(scenario:) {
        assert_equal @scenario, scenario
        fake_generator
      }
    ) do
      ScenarioGenerationStatusUpdater.new(
        scenario: @scenario
      ).call
    end

    fake_generator.verify

    assert @scenario.reload.failed?
    assert_equal 0, @user.reload.scenario_generation_count

    @generation_log.reload

    assert @generation_log.failed?
    assert_equal "failed", @generation_log.openai_status
    assert_equal "server_error", @generation_log.error_class
    assert_equal "OpenAI側で生成に失敗しました",
                 @generation_log.error_message
    assert @generation_log.finished_at.present?
  end

  test "OpenAI側で生成が完了した場合は結果を保存する" do
    @scenario.update!(
      openai_response_id: "resp_background_completed"
    )

    @generation_log.update!(
      openai_response_id: "resp_background_completed"
    )

    openai_response = OpenStruct.new(
      id: "resp_background_completed",
      model: "gpt-5.2",
      status: :completed,
      usage: OpenStruct.new(
        input_tokens: 10_000,
        input_tokens_details: OpenStruct.new(
          cached_tokens: 2_000
        ),
        output_tokens: 5_000,
        output_tokens_details: OpenStruct.new(
          reasoning_tokens: 500
        ),
        total_tokens: 15_000
      )
    )

    generation_result_from_generator = Object.new

    fake_generator = Minitest::Mock.new
    fake_generator.expect(
      :retrieve_background,
      openai_response,
      [ "resp_background_completed" ]
    )
    fake_generator.expect(
      :extract_background_result,
      generation_result_from_generator,
      [ openai_response ]
    )

    fake_saver = Minitest::Mock.new
    fake_saver.expect(
      :call,
      true
    )

    ScenarioGenerator.stub(
      :new,
      ->(scenario:) {
        assert_equal @scenario, scenario
        fake_generator
      }
    ) do
      ScenarioGenerationSaver.stub(
        :new,
        lambda do |scenario:, generation_result:|
          assert_equal @scenario, scenario
          assert_same generation_result,
                      generation_result_from_generator
          fake_saver
        end
      ) do
        ScenarioGenerationStatusUpdater.new(
          scenario: @scenario
        ).call
      end
    end

    fake_generator.verify
    fake_saver.verify

    assert @scenario.reload.completed?

    @generation_log.reload

    assert @generation_log.completed?
    assert_equal "completed", @generation_log.openai_status
    assert_equal 10_000, @generation_log.input_tokens
    assert_equal 2_000, @generation_log.cached_input_tokens
    assert_equal 5_000, @generation_log.output_tokens
    assert_equal 15_000, @generation_log.total_tokens
    assert_equal BigDecimal("0.08435"),
                 @generation_log.estimated_cost_usd
    assert @generation_log.finished_at.present?
    assert_equal 1, @user.reload.scenario_generation_count
  end

  test "OpenAIへの状況確認中にエラーが発生した場合は失敗状態に更新する" do
    failing_generator = Object.new

    failing_generator.define_singleton_method(
      :retrieve_background
    ) do |_response_id|
      raise ScenarioGenerator::GenerationError,
            "テスト用の状況確認エラー"
    end

    ScenarioGenerator.stub(
      :new,
      ->(scenario:) {
        assert_equal @scenario, scenario
        failing_generator
      }
    ) do
      ScenarioGenerationStatusUpdater.new(
        scenario: @scenario
      ).call
    end

    assert @scenario.reload.failed?
    assert_equal 0, @user.reload.scenario_generation_count

    @generation_log.reload

    assert @generation_log.failed?
    assert_equal "request_error",
                 @generation_log.openai_status
    assert_equal "ScenarioGenerator::GenerationError",
                 @generation_log.error_class
    assert_equal "テスト用の状況確認エラー",
                 @generation_log.error_message
    assert @generation_log.finished_at.present?
  end
end
