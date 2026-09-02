class ScenarioGenerator
  class GenerationError < StandardError; end

  MODEL = "gpt-5.2".freeze

  def initialize(scenario:)
    @scenario = scenario
  end

  def start_background
    response = client.responses.create(
      model: MODEL,
      input: prompt,
      text: ScenarioGenerationSchema,
      background: true
    )

    return response if response.id.present?

    raise GenerationError,
          "OpenAI APIから生成受付番号を取得できませんでした"
  end

  def retrieve_background(response_id)
    client.responses.retrieve(response_id)
  end

  def extract_background_result(response)
    json_text = response.output
      .flat_map { |item| item.respond_to?(:content) ? item.content : [] }
      .filter_map { |content| content.respond_to?(:text) ? content.text : nil }
      .first

    if json_text.blank?
      raise GenerationError,
            "OpenAI APIの生成結果を取得できませんでした"
    end

    generation_data = JSON.parse(
      json_text,
      symbolize_names: true
    )

    build_generation_result(generation_data)
  rescue JSON::ParserError, KeyError, ArgumentError => e
    raise GenerationError,
          "OpenAI APIの生成結果を変換できませんでした: #{e.message}"
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

      以下の条件をもとに、ゲームマスター未経験者でも
      画面を見ながら進行できる、完結したオリジナルの
      TRPGシナリオを日本語で作成してください。

      【入力条件】

      ジャンル：#{scenario.genre}
      世界観：#{scenario.world_setting}
      雰囲気：#{scenario.tone}
      プレイ人数：#{scenario.player_count}人
      プレイ時間：#{scenario.play_time}分

      【生成時の基本ルール】

      ・プレイ時間は、現実のセッションにかかる時間です
      ・プレイ時間を物語内の制限時間として扱わないでください
      ・指定されたプレイ時間内で完結する規模にしてください
      ・初心者ゲームマスターにも分かる言葉を使ってください
      ・一文を短くし、一つの項目に情報を詰め込みすぎないでください
      ・同じ情報を複数の項目で繰り返さないでください
      ・専門用語や抽象的な表現を避けてください
      ・誰が、何を、なぜ行うのかを具体的にしてください
      ・特定の既存作品やキャラクターを再現しないでください
      ・登場人物、手がかり、イベント、真相に矛盾がないようにしてください
      ・手がかりを確認すれば、真相を論理的に推理できるようにしてください

      【概要】

      ・summaryは、ゲームマスターが1分以内で
        シナリオ全体を理解できるクイックガイドにしてください

      ・必ず次の見出しを、この順番で含めてください

        【一言でいうと】
        【プレイヤーの目的】
        【事件の発端】
        【物語の流れ】
        【ゲームマスターが知っておく真相】
        【クライマックス】

      ・「物語の流れ」は、シーンの進行順に
        番号付きで簡潔に記載してください

      ・細かな演出や会話例は含めず、
        物語の理解に必要な情報だけを記載してください

      ・500文字以内を目安にしてください

      【ゲームマスター向けストーリー全体】

      ・story_outlineには、ゲームマスターが
        シナリオ全体を理解するための詳しいあらすじを
        記載してください

      ・次の内容を、物語の時系列に沿って説明してください

        事件が起きた背景
        登場人物の目的と行動
        プレイヤーが事件に関わる理由
        調査の流れ
        手がかり同士のつながり
        真相へ至る流れ
        クライマックス
        エンディングにつながる条件

      ・ゲームマスターだけが知る真相や
        ネタバレを含めて構いません

      ・シーンごとの細かな進行手順ではなく、
        出来事の原因と結果が分かる内容にしてください

      ・専門用語や曖昧な表現を避けてください

      ・800〜1,200文字を目安にしてください

      【導入・真相・エンディング】

      ・introductionは、セッション開始時にゲームマスターが
        プレイヤーへそのまま読み上げられる文章にしてください

      ・最初に、舞台となる時代、場所、世界の特徴、
        全体の雰囲気を簡潔に説明してください

      ・続けて、プレイヤーたちが現在いる場所、
        その場所へ来た理由、目の前で起きている出来事を
        具体的に説明してください

      ・最後に、プレイヤーが最初に判断または
        行動できる状態で終えてください

      ・プレイヤーがまだ知らない真相、
        犯人、登場人物の秘密は含めないでください

      ・ゲームマスターへの指示や説明は含めず、
        読み上げる文章だけを記載してください

      ・5〜8文、300文字以内を目安にしてください

      ・truthには、事件の原因、原因となる人物または存在、
        その動機を含めてください

      ・endingsは、プレイヤーの行動や
        推理結果によって分岐する内容にしてください

      【positionのルール】

      ・場所、登場人物、手がかり、イベント、シーン、エンディングには、
        種類ごとに1から始まるpositionを設定してください

      ・それぞれの一覧内でpositionを重複させず、
        途中の番号を飛ばさずに設定してください

      ・探索のきっかけのpositionは、シーンごとに1から始め、
        同じシーン内で重複させないでください

      ・関連付けには、実際に生成した対象のpositionを使用してください
        データベースのIDを作成する必要はありません

      【シーン全体のルール】

      ・シーンは物語の進行順に並べてください

      ・前のシーンで得た情報や決定を受けて始まり、
        その結果が次のシーンへつながるようにしてください

      ・各シーンには、次のいずれかの役割を持たせてください

        導入
        目的の提示
        調査
        情報の整理
        状況の変化
        クライマックス
        エンディング

      ・各シーンの終了時には、プレイヤーが
        次に行うことを理解できるようにしてください

      ・同じ説明を複数のシーンで繰り返さないでください

      【シーンの目的】

      ・purposeには、そのシーンでプレイヤーが
        理解、発見、決定することを記載してください

      ・1〜2文にまとめてください

      ・そのシーンを終了してよい状態が
        分かる内容にしてください

      ・背景説明やゲームマスターの手順は含めないでください

      【想定時間】

      ・estimated_timeは分単位の整数にしてください

      ・estimated_timeには、ゲームマスターの説明や、
        プレイヤーが行動を決めるための
        1〜2分程度の余裕を含めてください

      ・estimated_timeは、そのシーンを終えるための
        目安となる上限時間として設定してください

      ・すべてのシーンのestimated_timeの合計は、
        指定されたプレイ時間の90％以内を目安にしてください

      ・残りの時間は、プレイヤーが迷った場合や、
        会話や確認が長引いた場合の予備時間として確保してください

      ・プレイ時間が短い場合でも、
        最低5分程度の予備時間を残してください

      ・時間内に収まらない場合は、
        各シーンの内容を短くするか、シーン数を減らしてください

      ・導入や移動だけのシーンは短くしてください

      ・調査やクライマックスには十分な時間を割り当ててください

      ・最後のシーンとエンディングまで、
        指定されたプレイ時間内に完了できる構成にしてください

      【シーンの開始条件】

      ・trigger_conditionには、そのシーンが
        どのような状態で開始するのかを記載してください

      ・どの情報を得たとき、どこへ移動したとき、
        またはどの行動をしたときに始まるのかを
        1〜2文で具体的に記載してください

      ・最初のシーンは、セッション開始時に
        そのまま始められる条件にしてください

      【読み上げ文章】

      ・read_aloud_textには、ゲームマスターが
        プレイヤーへそのまま読み上げられる文章を記載してください

      ・現在の場所、起きた出来事、
        プレイヤーが判断するために必要な情報だけを含めてください

      ・プレイヤーがまだ知らない真相や、
        ゲームマスターだけが知る情報は含めないでください

      ・2〜4文、120文字以内を目安にしてください

      【ゲームマスターが行うこと】

      ・gm_actionsには、ゲームマスターが行うことを
        実行する順番に番号を付けて記載してください

      ・必ず3項目以内にしてください

      ・各項目には、一つの行動だけを記載してください

      ・各項目は一文で簡潔にしてください

      ・次のような形式で記載してください

        1. 現在の状況を説明する
        2. 行動に応じた情報を伝える
        3. 次に行うことを確認する

      【プレイヤーからの想定質問と回答】

      ・player_questionsには、プレイヤーから
        ゲームマスターへ出ると考えられる質問と、
        その回答を記載してください

      ・ゲームマスターからプレイヤーへ
        投げかける質問ではありません

      ・各シーン2〜3組にしてください

      ・質問と回答は、それぞれ1〜2文にしてください

      ・回答には、その時点でプレイヤーが
        知ってよい情報だけを含めてください

      ・次の形式で記載してください

        【質問1】
        プレイヤーからの質問

        【ゲームマスターの回答】
        質問に対する短い回答

      【プレイヤーの行動選択肢】

      ・investigation_optionsには、プレイヤーが選べる
        具体的な行動を3つ設定してください

      ・各選択肢には、label、result、gm_guideを
        必ず設定してください

      ・labelには、プレイヤーが行う行動を
        20文字程度で記載してください

      ・resultには、その行動を選んだ直後に、
        ゲームマスターがプレイヤーへそのまま
        読み上げられる文章を記載してください

      ・プレイヤーが見たもの、聞いたもの、
        気付いたこと、入手した情報を具体的に描写してください

      ・「プレイヤーは〜を知る」
        「ゲームマスターは〜を伝える」などの
        説明文や進行指示は含めないでください

      ・プレイヤーがまだ知ることのできない真相や、
        ゲームマスターだけが知る情報は含めないでください

      ・読み上げた後に、プレイヤーが次の判断を
        できる情報を含めてください

      ・2〜4文、150文字以内を目安にしてください

      ・gm_guideには、結果を受けてゲームマスターが
        次に伝えることや行うことを1〜2文で記載してください

      ・各選択肢は、手がかりの発見、登場人物との会話、
        次の目的の決定など、物語の進行につなげてください

      ・選択肢はプレイヤーの行動を制限するものではなく、
        初心者ゲームマスターが判断するための例にしてください

      ・選択肢にない行動をされた場合でも、
        シーンの目的に沿って対応できる内容にしてください

      【手がかり】

      ・そのシーンに関連付ける手がかりは、
        どの行動によって発見できるのかが
        分かるようにしてください

      ・手がかりをプレイヤーへ伝える言葉を、
        resultまたはgm_guideに含めてください

      ・重要な手がかりを一つ見落としただけで
        進行不能にならないようにしてください

      ・複数の手がかりから、
        真相を論理的に推理できるようにしてください

      【登場人物】

      ・npc_appearancesには、そのシーンに
        実際に登場する人物だけを設定してください

      ・npc_positionには、登場人物に設定した
        positionを使用してください

      ・reactionには、そのシーンでの人物の目的、
        態度、知っている情報、質問された場合の反応を
        簡潔に記載してください

      ・人物の生い立ちや基本プロフィールを
        繰り返さないでください

      ・必要に応じて、短い台詞例を含めてください

      【イベント】

      ・そのシーンに関連付けるイベントには、
        発生条件と、発生後に起こる変化を含めてください

      ・イベントが発生する理由と、
        物語に与える影響を明確にしてください

      ・イベント発生後にプレイヤーが
        次に行えることを分かりやすくしてください

      【進行が止まった場合のヒント】

      ・hintには、プレイヤーが次に調べる対象や
        行うべきことに気付けるヒントを一つ記載してください

      ・答えを直接教えすぎないでください

      ・ゲームマスターがそのまま伝えられる
        短い文章にしてください

      ・80文字以内を目安にしてください

      【次のシーンへ進む条件】

      ・transition_conditionには、プレイヤーが
        何を発見、理解、決定、実行したら
        次へ進むのかを記載してください

      ・1〜2文にまとめてください

      ・ゲームマスターが条件を達成したか
        判断できる内容にしてください

      ・特定の手がかりを得られなかった場合でも、
        別の行動やヒントで進めるようにしてください

      【シーンと各要素の関連付け】

      ・npc_appearancesには、そのシーンに登場する
        登場人物の情報を設定してください

      ・npc_positionには、実際に生成した
        登場人物のpositionを使用してください

      ・clue_positionsには、そのシーンで入手できる
        手がかりのpositionを設定してください

      ・event_positionsには、そのシーンで発生する
        イベントのpositionを設定してください

      ・実際に生成していないpositionは使用しないでください

      ・同じ登場人物、手がかり、イベントを
        意味なく複数のシーンへ関連付けないでください

      ・該当する要素がない場合は、空の配列にしてください

            【共通の場所データ】

      ・locationsには、シナリオで使用する場所をまとめてください
        部屋、村、森、遺跡など、ジャンルに合う場所を設定してください

      ・同じ場所を別々のデータとして重複して作成しないでください
        NPCの配置、探索先、シーン内の文章では同じ場所名を使ってください

      ・nameには場所の名前、descriptionには基本的な外観や特徴を
        簡潔に記載してください
        descriptionには、未発見の手がかりや真相を含めないでください

      ・各シーンのlocation_positionsには、
        その場面でプレイヤーが活動する場所のpositionを設定してください
        一つのシーンで複数の場所を扱っても構いません

      ・場所同士の位置関係や移動経路が、会話や描写と矛盾しないようにしてください

      【NPCの初期配置】

      ・各NPCのinitial_location_positionには、
        初登場時の基本の居場所となる場所のpositionを設定してください

      ・initial_activityには、そこで何をしているか、
        外から見て分かる様子を1〜2文で記載してください

      ・全NPCを最初のシーンから登場させる必要はありません
        npc_appearancesには、そのシーンに実際に登場するNPCだけを含めてください

      【シーンごとのNPC配置】

      ・npc_appearancesのlocation_positionには、
        そのシーンでのNPCの居場所を必ず設定してください
        初期位置から変わらない場合も、その場所のpositionを設定してください

      ・配置場所は、そのシーンのlocation_positionsに含めてください

      ・activityには、その場面での行動や様子を簡潔に記載してください

      ・appearance_conditionには、必要な場合だけ登場や移動の条件を記載し、
        特別な条件がなければ空文字にしてください

      ・細かな行動予定表は作らず、GMが登場させるための目安にしてください
        前の場面での移動や出来事と、後の場面の配置を整合させてください

      ・reactionにはGMが演じるための目的、態度、反応を記載してください
        探索先を知らせる具体的な台詞は、exploration_cuesにまとめてください

      【探索のきっかけ】

      ・各シーンのexploration_cuesには、プレイヤーが探索先を知り、
        調べたい理由を持てるNPCの台詞や周囲の描写を設定してください

      ・source_location_positionには情報を得る場所、
        target_location_positionには気になる探索先のpositionを設定してください

      ・情報を得る場所は、そのシーンのlocation_positionsに含めてください
        探索先は、後のシーンで訪れる場所でも構いません

      ・NPCの台詞の場合、npc_positionに話すNPCのpositionを設定してください
        そのNPCは、そのシーンのnpc_appearancesに含まれ、
        情報を得る場所と同じ場所にいる必要があります

      ・音、痕跡、書類、出来事などによるきっかけは、
        npc_positionをnullにしてください

      ・trigger_conditionには、GMが情報を提示するタイミングを
        「その場所に入ったとき」「昨夜について尋ねられたとき」など、
        短く具体的に記載してください

      ・read_aloud_textには、プレイヤーへそのまま伝えられる
        台詞または描写を1〜2文で記載してください
        探索先の名前と、そこが気になる理由を含めてください

      ・read_aloud_textにはGMへの指示や、その場面でまだ公開しない
        真相、犯人、NPCの秘密を混ぜないでください

      ・重要な探索先には、特定のNPCとの会話をしなくても
        気づける別のきっかけを必ず用意してください
        代替のきっかけは、そのNPCとの会話や、その会話でしか得られない
        情報を前提にしないでください

      ・未訪問の探索先を知らせるきっかけは、
        その探索先へ行く前に得られるようにしてください
        行き先を知るために、先にその行き先へ到着する必要がある構成は避けてください

      ・プレイヤーが誰に話すか、どこを調べるかを選べる余地を残してください
        行き先を命令する文章ではなく、興味を持てる情報を提示してください

      ・重要な探索先を中心に必要なきっかけを簡潔に用意し、
        同じ情報を場面ごとに繰り返さないでください
        きっかけが不要なシーンでは、exploration_cuesを空の配列にしてください

      定義された構造化出力の形式に従って、
      すべての項目を生成してください。
    PROMPT
  end

  def build_generation_result(generation_data)
    ScenarioGenerationSchema.new(
      **generation_data.merge(
        locations: build_collection(
          generation_data.fetch(:locations),
          ScenarioGenerationSchema::Location
        ),
        npcs: build_collection(
          generation_data.fetch(:npcs),
          ScenarioGenerationSchema::Npc
        ),
        clues: build_collection(
          generation_data.fetch(:clues),
          ScenarioGenerationSchema::Clue
        ),
        events: build_collection(
          generation_data.fetch(:events),
          ScenarioGenerationSchema::Event
        ),
        scenes: generation_data.fetch(:scenes).map do |scene_data|
          build_scene(scene_data)
        end,
        endings: build_collection(
          generation_data.fetch(:endings),
          ScenarioGenerationSchema::Ending
        )
      )
    )
  end

  def build_scene(scene_data)
    ScenarioGenerationSchema::Scene.new(
      **scene_data.merge(
        investigation_options: build_collection(
          scene_data.fetch(:investigation_options),
          ScenarioGenerationSchema::InvestigationOption
        ),
        npc_appearances: build_collection(
          scene_data.fetch(:npc_appearances),
          ScenarioGenerationSchema::SceneNpc
        ),
        exploration_cues: scene_data.fetch(:exploration_cues).map do |cue_data|
          build_exploration_cue(cue_data)
        end
      )
    )
  end

  def build_collection(collection, model_class)
    collection.map do |attributes|
      model_class.new(**attributes)
    end
  end

  def build_exploration_cue(cue_data)
    # openai 0.68.0では、newへ明示的にnilを渡すと読み取り時に
    # 変換エラーになるため、NPCなしの場合はこの項目を渡さない。
    attributes =
      if cue_data.fetch(:npc_position).nil?
        cue_data.except(:npc_position)
      else
        cue_data
      end

    ScenarioGenerationSchema::ExplorationCue.new(**attributes)
  end

  def extract_result(response)
    result = response.output
      .flat_map { |item| item.respond_to?(:content) ? item.content : [] }
      .filter_map { |content| content.respond_to?(:parsed) ? content.parsed : nil }
      .first

    return result if result

    raise GenerationError,
      "OpenAI APIから構造化された結果を取得できませんでした"
  end
end
