class ScenarioGenerator
  MODEL = "gpt-5.2".freeze

  def initialize(scenario:)
    @scenario = scenario
  end

  def call
    response = client.responses.create(
      model: MODEL,
      input: prompt
    )

    extract_text(response)
  end

  private

  attr_reader :scenario

  def client
    @client ||= OpenAI::Client.new(
      api_key: ENV.fetch("OPENAI_API_KEY")
    )
  end

  def prompt
    <<~PROMPT
      あなたはTRPGシナリオを作成するゲームデザイナーです。

      以下の条件をもとに、短いシナリオ案を作成してください。

      ジャンル：#{scenario.genre}
      世界観：#{scenario.world_setting}
      雰囲気：#{scenario.tone}
      プレイ人数：#{scenario.player_count}人
      プレイ時間：#{scenario.play_time}分

      今回は接続確認のため、次の2項目だけを日本語で返してください。

      ・タイトル
      ・シナリオ概要
    PROMPT
  end

  def extract_text(response)
    response.output
      .flat_map { |item| item.type == :message ? item.content : [] }
      .filter_map { |content| content.type == :output_text ? content.text : nil }
      .join
  end
end
