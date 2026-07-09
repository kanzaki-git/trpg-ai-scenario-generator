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
      あなたは、TRPG初心者向けのシナリオを設計するゲームデザイナーです。

      以下の条件をもとに、ゲームマスター未経験者でも進行できる、
      完結したオリジナルのTRPGシナリオを日本語で作成してください。

      【入力条件】

      ジャンル：#{scenario.genre}
      世界観：#{scenario.world_setting}
      雰囲気：#{scenario.tone}
      プレイ人数：#{scenario.player_count}人
      プレイ時間：#{scenario.play_time}分

      【生成時のルール】

      ・プレイ時間は、現実のセッションにかかる時間です
      ・プレイ時間を物語内の制限時間として扱わないでください
      ・指定されたプレイ時間内で完結する規模にしてください
      ・ゲームマスター未経験者にも分かる表現にしてください
      ・特定の既存作品やキャラクターを再現しないでください
      ・登場人物、手がかり、イベント、真相に矛盾がないようにしてください
      ・手がかりを確認すれば、真相を論理的に推理できるようにしてください
      ・概要には、真相やエンディングの内容を含めないでください
      ・概要は300文字以内を目安にしてください
      ・導入は、ゲームマスターがセッション開始時に利用できる内容にしてください
      ・真相には、事件の原因、犯人または原因となる存在、動機を含めてください
      ・エンディングは、プレイヤーの行動や推理結果によって分岐させてください

      【positionのルール】

      ・登場人物、手がかり、イベント、シーン、エンディングには、
        それぞれ1から始まる重複のないpositionを設定してください
      ・positionは途中の番号を飛ばさず、表示順に設定してください

      【シーンのルール】

      ・各シーンには、目的、想定時間、読み上げ文章、
        ゲームマスターが行うこと、プレイヤーへの質問例、
        調査できる場所や行動、開始条件、次へ進む条件、
        進行が止まった場合のヒントを含めてください
      ・すべてのシーンのestimated_timeの合計が、
        指定されたプレイ時間を大きく超えないようにしてください
      ・シーンは物語の進行順に並べてください

      【シーンと各要素の関連付け】

      ・npc_positionsには、そのシーンに登場する登場人物のpositionを入れてください
      ・clue_positionsには、そのシーンで入手できる手がかりのpositionを入れてください
      ・event_positionsには、そのシーンで発生するイベントのpositionを入れてください
      ・参照するpositionは、実際に生成した要素のpositionだけを使用してください
      ・該当する要素がない場合は、空の配列にしてください

      定義された構造化出力の形式に従って、すべての項目を生成してください。
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
