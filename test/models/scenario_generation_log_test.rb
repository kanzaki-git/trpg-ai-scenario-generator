require "test_helper"
require "ostruct"

class ScenarioGenerationLogTest < ActiveSupport::TestCase
  test "正しい情報があれば生成履歴は有効になる" do
    generation_log = build_generation_log

    assert generation_log.valid?
  end

  test "新規作成時にGPT-5.2の料金単価が設定される" do
    generation_log = build_generation_log

    generation_log.valid?

    assert_equal BigDecimal("1.75"),
                 generation_log.input_price_per_million_usd

    assert_equal BigDecimal("0.175"),
                 generation_log.cached_input_price_per_million_usd

    assert_equal BigDecimal("14.00"),
                 generation_log.output_price_per_million_usd
  end

  test "トークン数から推定料金が計算される" do
    generation_log = build_generation_log(
      input_tokens: 10_000,
      cached_input_tokens: 2_000,
      output_tokens: 5_000,
      reasoning_tokens: 500,
      total_tokens: 15_000
    )

    generation_log.valid?

    assert_equal BigDecimal("0.08435"),
                 generation_log.estimated_cost_usd
  end

  test "トークン数がマイナスの場合は無効になる" do
    generation_log = build_generation_log(
      input_tokens: -1
    )

    assert_not generation_log.valid?

    assert generation_log.errors.of_kind?(
      :input_tokens,
      :greater_than_or_equal_to
    )
  end

  test "キャッシュ済み入力が入力全体より多い場合は無効になる" do
    generation_log = build_generation_log(
      input_tokens: 1_000,
      cached_input_tokens: 1_001
    )

    assert_not generation_log.valid?

    assert_includes generation_log.errors[:cached_input_tokens],
                    "は入力トークン数以下にしてください"
  end

  test "完了した履歴には終了日時が必要になる" do
    generation_log = build_generation_log(
      status: :completed,
      finished_at: nil
    )

    assert_not generation_log.valid?

    assert_includes generation_log.errors[:finished_at],
                    "を処理完了時に設定してください"
  end

  test "シナリオがなくても生成履歴は有効になる" do
    generation_log = build_generation_log(
      scenario: nil
    )

    assert generation_log.valid?
  end

  test "OpenAIレスポンスIDは重複できない" do
    generation_log = build_generation_log(
      openai_response_id:
        scenario_generation_logs(:one).openai_response_id
    )

    assert_not generation_log.valid?

    assert generation_log.errors.of_kind?(
      :openai_response_id,
      :taken
    )
  end

  test "シナリオを削除しても生成履歴は残る" do
    generation_log = scenario_generation_logs(:one)

    generation_log.scenario.destroy!

    assert_nil generation_log.reload.scenario_id
  end

  test "OpenAIの完了レスポンスから利用状況を記録できる" do
    generation_log = build_generation_log
    generation_log.save!

    openai_response = OpenStruct.new(
      id: "resp_completed_test",
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

    generation_log.record_completion!(openai_response)

    generation_log.reload

    assert generation_log.completed?
    assert_equal "resp_completed_test",
                generation_log.openai_response_id
    assert_equal "gpt-5.2",
                generation_log.openai_model
    assert_equal "completed",
                generation_log.openai_status
    assert_equal 10_000,
                generation_log.input_tokens
    assert_equal 2_000,
                generation_log.cached_input_tokens
    assert_equal 5_000,
                generation_log.output_tokens
    assert_equal 500,
                generation_log.reasoning_tokens
    assert_equal 15_000,
                generation_log.total_tokens
    assert_equal BigDecimal("0.08435"),
                generation_log.estimated_cost_usd
    assert generation_log.finished_at.present?
  end

  test "OpenAIの失敗レスポンスからエラーと利用状況を記録できる" do
    generation_log = build_generation_log(
      openai_response_id: "resp_failed_test"
    )
    generation_log.save!

    openai_response = OpenStruct.new(
      id: "resp_failed_test",
      model: "gpt-5.2",
      status: :failed,
      error: OpenStruct.new(
        code: "server_error",
        message: "OpenAI側で生成に失敗しました"
      ),
      usage: OpenStruct.new(
        input_tokens: 2_000,
        input_tokens_details: OpenStruct.new(
          cached_tokens: 0
        ),
        output_tokens: 100,
        output_tokens_details: OpenStruct.new(
          reasoning_tokens: 100
        ),
        total_tokens: 2_100
      )
    )

    generation_log.record_failure!(
      openai_status: openai_response.status,
      openai_response: openai_response
    )

    generation_log.reload

    assert generation_log.failed?
    assert_equal "failed",
                generation_log.openai_status
    assert_equal "server_error",
                generation_log.error_class
    assert_equal "OpenAI側で生成に失敗しました",
                generation_log.error_message
    assert_equal 2_000,
                generation_log.input_tokens
    assert_equal 100,
                generation_log.output_tokens
    assert_equal 2_100,
                generation_log.total_tokens
    assert_equal BigDecimal("0.0049"),
                generation_log.estimated_cost_usd
    assert generation_log.finished_at.present?
  end

  private

  def build_generation_log(attributes = {})
    default_attributes = {
      user: users(:one),
      scenario: scenarios(:one),
      status: :processing,
      openai_model: "gpt-5.2",
      started_at: Time.current
    }

    ScenarioGenerationLog.new(
      default_attributes.merge(attributes)
    )
  end
end
