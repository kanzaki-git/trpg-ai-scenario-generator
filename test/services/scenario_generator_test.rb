require "test_helper"
require "ostruct"

class ScenarioGeneratorTest < ActiveSupport::TestCase
  class FakeResponses
    attr_reader :create_options, :retrieved_response_id

    def initialize(create_response: nil, retrieve_response: nil)
      @create_response = create_response
      @retrieve_response = retrieve_response
    end

    def create(**options)
      @create_options = options
      @create_response
    end

    def retrieve(response_id)
      @retrieved_response_id = response_id
      @retrieve_response
    end
  end

  setup do
    scenario = Scenario.new(
      genre: "ミステリー",
      world_setting: "現代",
      tone: "シリアス",
      player_count: 4,
      play_time: 60
    )

    @generator = ScenarioGenerator.new(scenario: scenario)
  end

  test "バックグラウンド生成を開始してレスポンスを返す" do
    response = OpenStruct.new(id: "resp_test")
    responses = FakeResponses.new(create_response: response)
    client = OpenStruct.new(responses: responses)

    result = @generator.stub(:client, client) do
      @generator.start_background
    end

    assert_same response, result
    assert_equal ScenarioGenerator::MODEL,
                 responses.create_options[:model]
    assert_equal ScenarioGenerationSchema,
                 responses.create_options[:text]
    assert_equal true,
                 responses.create_options[:background]

    prompt = responses.create_options[:input]

    assert_includes prompt, "ジャンル：ミステリー"
    assert_includes prompt, "世界観：現代"
    assert_includes prompt, "雰囲気：シリアス"
    assert_includes prompt, "プレイ人数：4人"
    assert_includes prompt, "プレイ時間：60分"
  end

  test "生成受付番号がなければエラーになる" do
    response = OpenStruct.new(id: nil)
    responses = FakeResponses.new(create_response: response)
    client = OpenStruct.new(responses: responses)

    error = assert_raises(
      ScenarioGenerator::GenerationError
    ) do
      @generator.stub(:client, client) do
        @generator.start_background
      end
    end

    assert_equal(
      "OpenAI APIから生成受付番号を取得できませんでした",
      error.message
    )
  end

  test "生成受付番号を使ってバックグラウンド結果を取得する" do
    response = OpenStruct.new(
      id: "resp_test",
      status: "completed"
    )
    responses = FakeResponses.new(retrieve_response: response)
    client = OpenStruct.new(responses: responses)

    result = @generator.stub(:client, client) do
      @generator.retrieve_background("resp_test")
    end

    assert_same response, result
    assert_equal "resp_test",
                 responses.retrieved_response_id
  end

  test "JSONから構造化された生成結果を作成する" do
    response = response_with_text(
      JSON.generate(valid_generation_data)
    )

    result = @generator.extract_background_result(response)

    assert_instance_of ScenarioGenerationSchema, result
    assert_equal "消えた宝石の謎", result.title

    assert_instance_of(
      ScenarioGenerationSchema::Npc,
      result.npcs.first
    )

    assert_instance_of(
      ScenarioGenerationSchema::Clue,
      result.clues.first
    )

    assert_instance_of(
      ScenarioGenerationSchema::Event,
      result.events.first
    )

    assert_instance_of(
      ScenarioGenerationSchema::Scene,
      result.scenes.first
    )

    assert_instance_of(
      ScenarioGenerationSchema::InvestigationOption,
      result.scenes.first.investigation_options.first
    )

    assert_instance_of(
      ScenarioGenerationSchema::SceneNpc,
      result.scenes.first.npc_appearances.first
    )

    assert_instance_of(
      ScenarioGenerationSchema::Ending,
      result.endings.first
    )
  end

  test "生成結果のテキストが空の場合はエラーになる" do
    response = response_with_text("")

    error = assert_raises(
      ScenarioGenerator::GenerationError
    ) do
      @generator.extract_background_result(response)
    end

    assert_equal(
      "OpenAI APIの生成結果を取得できませんでした",
      error.message
    )
  end

  test "生成結果が不正なJSONの場合はエラーになる" do
    response = response_with_text("{invalid json")

    error = assert_raises(
      ScenarioGenerator::GenerationError
    ) do
      @generator.extract_background_result(response)
    end

    assert_includes(
      error.message,
      "OpenAI APIの生成結果を変換できませんでした"
    )
  end

  test "同期生成から構造化された結果を取得する" do
    generation_result = @generator.extract_background_result(
      response_with_text(
        JSON.generate(valid_generation_data)
      )
    )

    response = OpenStruct.new(
      output: [
        OpenStruct.new(
          content: [
            OpenStruct.new(parsed: generation_result)
          ]
        )
      ]
    )

    responses = FakeResponses.new(create_response: response)
    client = OpenStruct.new(responses: responses)

    result = @generator.stub(:client, client) do
      @generator.call
    end

    assert_same generation_result, result
    assert_equal ScenarioGenerator::MODEL,
                 responses.create_options[:model]
    assert_equal ScenarioGenerationSchema,
                 responses.create_options[:text]
    assert_not responses.create_options.key?(:background)
  end

  test "同期生成に構造化された結果がなければエラーになる" do
    response = OpenStruct.new(
      output: [
        OpenStruct.new(
          content: [ Object.new ]
        )
      ]
    )

    responses = FakeResponses.new(create_response: response)
    client = OpenStruct.new(responses: responses)

    error = assert_raises(
      ScenarioGenerator::GenerationError
    ) do
      @generator.stub(:client, client) do
        @generator.call
      end
    end

    assert_equal(
      "OpenAI APIから構造化された結果を取得できませんでした",
      error.message
    )
  end

  private

  def response_with_text(text)
    OpenStruct.new(
      output: [
        OpenStruct.new(
          content: [
            OpenStruct.new(text: text)
          ]
        )
      ]
    )
  end

  def valid_generation_data
    {
      title: "消えた宝石の謎",
      summary: "宝石の行方を調査する物語",
      story_outline: "屋敷で事件が発生し調査が始まる",
      introduction: "あなたたちは屋敷へ招待された。",
      truth: "執事が宝石を隠していた。",
      npcs: [
        {
          name: "執事",
          description: "屋敷に仕える執事",
          position: 1
        }
      ],
      clues: [
        {
          content: "机の下に落ちていた鍵",
          position: 1
        }
      ],
      events: [
        {
          content: "停電が発生する",
          trigger_condition: "机を調べた後",
          position: 1
        }
      ],
      scenes: [
        {
          title: "屋敷の調査",
          purpose: "手がかりを見つける",
          estimated_time: 10,
          read_aloud_text: "薄暗い部屋に机がある。",
          gm_actions: "調べる場所を確認する。",
          player_questions: "どこを調べますか？",
          investigation_options: [
            {
              label: "机を調べる",
              result: "鍵を発見する",
              gm_guide: "机の下へ誘導する"
            }
          ],
          trigger_condition: "屋敷へ到着したとき",
          transition_condition: "鍵を発見したとき",
          hint: "机の周辺に注目させる",
          npc_appearances: [
            {
              npc_position: 1,
              reaction: "慎重に答える"
            }
          ],
          clue_positions: [ 1 ],
          event_positions: [ 1 ],
          position: 1
        }
      ],
      endings: [
        {
          content: "宝石を取り戻し事件は解決した。",
          position: 1
        }
      ]
    }
  end
end
