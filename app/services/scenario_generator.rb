class ScenarioGenerator
  MODEL = "gpt-5.2".freeze

  def initialize(scenario:)
    @scenario = scenario
  end

  def call
    response = client.responses.create(
      model: MODEL,
      input: prompt,
      text: ScenarioGenerationSchema
    )

    extract_result(response)
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

      プレイ時間は、現実のセッションにかかる時間です。
      物語内の制限時間として扱わないでください。

      今回は接続確認のため、次の2項目を日本語で生成してください。

      ・タイトル
      ・シナリオ概要
    PROMPT
  end

  def extract_result(response)
    result = response.output
      .flat_map { |item| item.respond_to?(:content) ? item.content : [] }
      .filter_map { |content| content.respond_to?(:parsed) ? content.parsed : nil }
      .first

    return result if result

    raise "OpenAI APIから構造化された結果を取得できませんでした"
  end
end
