class ScenarioGenerationLog < ApplicationRecord
  INPUT_PRICE_PER_MILLION_USD = BigDecimal("1.75")
  CACHED_INPUT_PRICE_PER_MILLION_USD = BigDecimal("0.175")
  OUTPUT_PRICE_PER_MILLION_USD = BigDecimal("14.00")
  ONE_MILLION_TOKENS = BigDecimal("1000000")

  TOKEN_FIELDS = %i[
    input_tokens
    cached_input_tokens
    output_tokens
    reasoning_tokens
    total_tokens
  ].freeze

  PRICE_FIELDS = %i[
    input_price_per_million_usd
    cached_input_price_per_million_usd
    output_price_per_million_usd
    estimated_cost_usd
  ].freeze

  belongs_to :user
  belongs_to :scenario, optional: true

  enum :status,
       {
         processing: "processing",
         completed: "completed",
         failed: "failed"
       },
       validate: true

  before_validation :set_default_pricing,
                    on: :create

  before_validation :calculate_estimated_cost_usd

  validates :openai_model,
            presence: true

  validates :started_at,
            presence: true

  validates :openai_response_id,
            uniqueness: true,
            allow_nil: true

  validates(*TOKEN_FIELDS,
            numericality: {
              only_integer: true,
              greater_than_or_equal_to: 0
            })

  validates(*PRICE_FIELDS,
            numericality: {
              greater_than_or_equal_to: 0
            })

  validate :cached_input_tokens_cannot_exceed_input_tokens
  validate :finished_at_required_after_processing

  def record_completion!(openai_response)
    update!(
      usage_attributes(openai_response).merge(
        status: :completed,
        openai_response_id: openai_response.id,
        openai_model: openai_response.model,
        openai_status: openai_response.status.to_s,
        finished_at: Time.current
      )
    )
  end

  def record_failure!(
    openai_status:,
    openai_response: nil,
    error: nil
  )
    response_error = openai_response&.error

    update!(
      usage_attributes(openai_response).merge(
        status: :failed,
        openai_response_id:
          openai_response&.id || openai_response_id,
        openai_model:
          openai_response&.model.presence || openai_model,
        openai_status: openai_status.to_s,
        error_class:
          error&.class&.name ||
          response_error&.code ||
          "OpenAIBackgroundGenerationError",
        error_message:
          error&.message ||
          response_error&.message ||
          "OpenAIの生成に失敗しました（status: #{openai_status}）",
        finished_at: Time.current
      )
    )
  end

  private

  def usage_attributes(openai_response)
    usage = openai_response&.usage

    return {} unless usage

    {
      input_tokens: usage.input_tokens.to_i,
      cached_input_tokens:
        usage.input_tokens_details&.cached_tokens.to_i,
      output_tokens: usage.output_tokens.to_i,
      reasoning_tokens:
        usage.output_tokens_details&.reasoning_tokens.to_i,
      total_tokens: usage.total_tokens.to_i
    }
  end

  def set_default_pricing
    if input_price_per_million_usd.zero?
      self.input_price_per_million_usd =
        INPUT_PRICE_PER_MILLION_USD
    end

    if cached_input_price_per_million_usd.zero?
      self.cached_input_price_per_million_usd =
        CACHED_INPUT_PRICE_PER_MILLION_USD
    end

    if output_price_per_million_usd.zero?
      self.output_price_per_million_usd =
        OUTPUT_PRICE_PER_MILLION_USD
    end
  end

  def calculate_estimated_cost_usd
    uncached_input_tokens = [
      input_tokens.to_i - cached_input_tokens.to_i,
      0
    ].max

    input_cost =
      BigDecimal(uncached_input_tokens.to_s) *
      input_price_per_million_usd.to_d

    cached_input_cost =
      BigDecimal(cached_input_tokens.to_i.to_s) *
      cached_input_price_per_million_usd.to_d

    output_cost =
      BigDecimal(output_tokens.to_i.to_s) *
      output_price_per_million_usd.to_d

    self.estimated_cost_usd =
      (input_cost + cached_input_cost + output_cost) /
      ONE_MILLION_TOKENS
  end

  def cached_input_tokens_cannot_exceed_input_tokens
    return if cached_input_tokens.to_i <= input_tokens.to_i

    errors.add(
      :cached_input_tokens,
      "は入力トークン数以下にしてください"
    )
  end

  def finished_at_required_after_processing
    return unless completed? || failed?
    return if finished_at.present?

    errors.add(
      :finished_at,
      "を処理完了時に設定してください"
    )
  end
end
