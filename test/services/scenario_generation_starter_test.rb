require "test_helper"
require "minitest/mock"
require "ostruct"

class ScenarioGenerationStarterTest < ActiveSupport::TestCase
  setup do
    @user = User.create!(
      name: "テストユーザー",
      email: "starter-test@example.com",
      password: "password",
      password_confirmation: "password"
    )

    @scenario = @user.scenarios.build(
      genre: "ホラー",
      world_setting: "現代日本",
      tone: "ダーク",
      player_count: 2,
      play_time: 30
    )

    @user.reserve_scenario_generation!(@scenario)
  end

  test "生成ログを作成してバックグラウンド生成を開始する" do
    background_response = OpenStruct.new(
      id: "resp_starter_test",
      status: :in_progress,
      model: "gpt-5.2"
    )

    fake_generator = Minitest::Mock.new
    fake_generator.expect(
      :start_background,
      background_response
    )

    ScenarioGenerator.stub(
      :new,
      ->(scenario:) {
        assert_equal @scenario, scenario
        fake_generator
      }
    ) do
      assert_difference("ScenarioGenerationLog.count", 1) do
        result = ScenarioGenerationStarter.new(
          user: @user,
          scenario: @scenario
        ).call

        assert_equal background_response, result
      end
    end

    fake_generator.verify

    generation_log = @user.scenario_generation_logs.find_by!(
      openai_response_id: "resp_starter_test"
    )

    assert_equal "resp_starter_test",
                 @scenario.reload.openai_response_id
    assert generation_log.processing?
    assert_equal @scenario, generation_log.scenario
    assert_equal "gpt-5.2", generation_log.openai_model
    assert_equal "in_progress", generation_log.openai_status
    assert generation_log.started_at.present?
  end

  test "バックグラウンド生成の開始に失敗した場合は後片付けをする" do
    failing_generator = Object.new

    failing_generator.define_singleton_method(:start_background) do
      raise ScenarioGenerator::GenerationError,
            "テスト用の生成エラー"
    end

    ScenarioGenerator.stub(
      :new,
      ->(scenario:) {
        assert_equal @scenario, scenario
        failing_generator
      }
    ) do
      assert_difference("Scenario.count", -1) do
        assert_difference("ScenarioGenerationLog.count", 1) do
          assert_raises(ScenarioGenerator::GenerationError) do
            ScenarioGenerationStarter.new(
              user: @user,
              scenario: @scenario
            ).call
          end
        end
      end
    end

    generation_log = @user.scenario_generation_logs
      .order(created_at: :desc)
      .first

    assert generation_log.failed?
    assert_nil generation_log.scenario_id
    assert_equal "request_error", generation_log.openai_status
    assert_equal "ScenarioGenerator::GenerationError",
                 generation_log.error_class
    assert_equal "テスト用の生成エラー",
                 generation_log.error_message
    assert generation_log.finished_at.present?
    assert_equal 0, @user.reload.scenario_generation_count
  end
end
