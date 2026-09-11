require "test_helper"
require "minitest/mock"
require "ostruct"

class ScenariosControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = User.create!(
      name: "テストユーザー",
      email: "scenario-test@example.com",
      password: "password",
      password_confirmation: "password"
    )

    post login_url, params: {
      email: @user.email,
      password: "password"
    }
  end

  test "ログイン中のユーザーは自分のシナリオ一覧を表示できる" do
    own_scenario = create_scenario

    other_user = User.create!(
      name: "別のユーザー",
      email: "other-scenario-test@example.com",
      password: "password",
      password_confirmation: "password"
    )

    other_scenario = create_scenario(
      user: other_user,
      title: "他のユーザーのシナリオ"
    )

    get scenarios_url

    assert_response :success
    assert_select "h1", text: "シナリオ一覧"
    assert_select "h3", text: own_scenario.title
    assert_select "h3", text: other_scenario.title, count: 0
    assert_select "a[href=?]", scenario_path(own_scenario),
                  text: "詳細を見る"
  end

  test "ログイン中のユーザーはシナリオ生成画面を表示できる" do
    get new_scenario_url

    assert_response :success
    assert_select(
      'input[type="submit"]' \
      '[data-turbo-submits-with="シナリオを生成しています…"]'
    )
  end

  test "生成画面に利用上限と残り回数が表示され生成ボタンが有効になる" do
    @user.update!(scenario_generation_count: 1)

    get new_scenario_url

    assert_response :success

    assert_select ".alert-info",
                  text: /累計\s*#{User::SCENARIO_GENERATION_LIMIT}回/

    assert_select ".alert-info p",
                  text: "残り生成回数：#{User::SCENARIO_GENERATION_LIMIT - 1}回"

    assert_select 'input[type="submit"]:not([disabled])', count: 1
    assert_select ".alert-warning", count: 0
  end

  test "上限に達すると残り0回と案内が表示され生成ボタンが無効になる" do
    @user.update!(
      scenario_generation_count: User::SCENARIO_GENERATION_LIMIT
    )

    get new_scenario_url

    assert_response :success

    assert_select ".alert-info p",
                  text: "残り生成回数：0回"

    assert_select ".alert-warning",
                  text: /利用上限に達したため、新しいシナリオは生成できません/

    assert_select 'input[type="submit"][disabled]', count: 1
  end

  test "生成状況の確認に失敗した場合の案内が生成中画面に用意されている" do
    scenario = create_scenario
    scenario.update!(generation_status: :generating)

    get generating_scenario_url(scenario)

    assert_response :success

    assert_select(
      '[data-scenario-generation-polling-target="communicationFailure"]'
    ) do
      assert_select "h1", text: "生成状況を確認できませんでした"

      assert_select(
        'button[data-action="scenario-generation-polling#reload"]',
        text: "画面を再読み込み"
      )

      assert_select "a[href=?]", scenarios_path,
                    text: "シナリオ一覧へ戻る"
    end
  end

  test "ログイン中のユーザーはシナリオ生成を開始できる" do
    background_response = OpenStruct.new(
      id: "resp_test_background",
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
      ->(scenario:) { fake_generator }
    ) do
      assert_difference("Scenario.count", 1) do
        post scenarios_url, params: {
          scenario: {
            genre: "ホラー",
            world_setting: "現代日本",
            tone: "ダーク",
            player_count: 2,
            play_time: 30
          }
        }
      end
    end

    fake_generator.verify

    created_scenario = Scenario.find_by!(
      openai_response_id: "resp_test_background"
    )

    assert created_scenario.generating?
    assert_redirected_to generating_scenario_path(created_scenario)
    assert_equal 1, @user.reload.scenario_generation_count
  end

  test "生成中のシナリオがある場合は新しい生成を開始できない" do
    generating_scenario = create_scenario
    generating_scenario.update!(
      generation_status: :generating
    )
    @user.update!(scenario_generation_count: 1)

    ScenarioGenerator.stub(
      :new,
      ->(scenario:) { flunk "生成中にOpenAI APIを呼び出しています" }
    ) do
      assert_no_difference("Scenario.count") do
        post scenarios_url, params: {
          scenario: {
            genre: "ホラー",
            world_setting: "現代日本",
            tone: "ダーク",
            player_count: 2,
            play_time: 30
          }
        }
      end
    end

    assert_redirected_to generating_scenario_path(generating_scenario)
    assert_equal(
      "現在、別のシナリオを生成中です。生成完了までお待ちください。",
      flash[:alert]
    )
    assert_equal 1, @user.reload.scenario_generation_count
  end

  test "シナリオ生成に失敗した場合は入力内容を保持して生成画面を再表示する" do
    failing_generator = Object.new

    failing_generator.define_singleton_method(:start_background) do
      raise ScenarioGenerator::GenerationError,
            "テスト用の生成エラー"
    end

    ScenarioGenerator.stub(
      :new,
      ->(scenario:) { failing_generator }
    ) do
      assert_no_difference("Scenario.count") do
        post scenarios_url, params: {
          scenario: {
            genre: "ホラー",
            world_setting: "現代日本の廃校",
            tone: "不気味",
            player_count: 2,
            play_time: 60
          }
        }
      end
    end

    assert_response :service_unavailable
    assert_equal 0, @user.reload.scenario_generation_count

    assert_select ".alert-danger",
                  text: /シナリオの生成に失敗しました/

    assert_select(
      'select[name="scenario[genre]"] option[selected][value="ホラー"]'
    )

    assert_select 'textarea[name="scenario[world_setting]"]',
                  text: "現代日本の廃校"
  end

  test "生成回数が上限に達している場合はシナリオ生成を開始できない" do
    @user.update!(
      scenario_generation_count: User::SCENARIO_GENERATION_LIMIT
    )

    ScenarioGenerator.stub(
      :new,
      ->(scenario:) { flunk "上限到達時にOpenAI APIを呼び出しています" }
    ) do
      assert_no_difference("Scenario.count") do
        post scenarios_url, params: {
          scenario: {
            genre: "ホラー",
            world_setting: "現代日本",
            tone: "ダーク",
            player_count: 2,
            play_time: 30
          }
        }
      end
    end

    assert_redirected_to new_scenario_url
    assert_equal "シナリオを生成できる回数は3回までです。",
                 flash[:alert]
    assert_equal User::SCENARIO_GENERATION_LIMIT,
                 @user.reload.scenario_generation_count
  end

  test "未入力の場合はシナリオを作成できない" do
    assert_no_difference("Scenario.count") do
      post scenarios_url, params: {
        scenario: {
          genre: "",
          world_setting: "",
          tone: "",
          player_count: "",
          play_time: ""
        }
      }
    end

    assert_response :unprocessable_entity
  end

    test "バックグラウンド生成に失敗した場合は失敗状態を返す" do
    scenario = create_scenario
    scenario.update!(
      generation_status: :generating,
      openai_response_id: "resp_background_failed"
    )
    @user.update!(scenario_generation_count: 1)

    @user.scenario_generation_logs.create!(
      scenario: scenario,
      status: :processing,
      openai_response_id: "resp_background_failed",
      openai_model: "gpt-5.2",
      started_at: Time.current
    )

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
      ->(scenario:) { fake_generator }
    ) do
      get generation_status_scenario_url(scenario)
    end

    fake_generator.verify

    assert_response :success
    assert_equal "failed", response.parsed_body["status"]
  end

  test "バックグラウンド生成完了時に詳細画面のURLを返す" do
    scenario = create_scenario
    scenario.update!(
      generation_status: :generating,
      openai_response_id: "resp_background_completed"
    )
    @user.update!(scenario_generation_count: 1)

    @user.scenario_generation_logs.create!(
      scenario: scenario,
      status: :processing,
      openai_response_id: "resp_background_completed",
      openai_model: "gpt-5.2",
      started_at: Time.current
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

    generation_result = Object.new

    fake_generator = Minitest::Mock.new
    fake_generator.expect(
      :retrieve_background,
      openai_response,
      [ "resp_background_completed" ]
    )
    fake_generator.expect(
      :extract_background_result,
      generation_result,
      [ openai_response ]
    )

    fake_saver = Minitest::Mock.new
    fake_saver.expect(
      :call,
      true
    )

    ScenarioGenerator.stub(
      :new,
      ->(scenario:) { fake_generator }
    ) do
      ScenarioGenerationSaver.stub(
        :new,
        lambda do |scenario:, generation_result:|
          fake_saver
        end
      ) do
        get generation_status_scenario_url(scenario)
      end
    end

    fake_generator.verify
    fake_saver.verify

    assert_response :success
    assert_equal "completed", response.parsed_body["status"]
    assert_equal scenario_path(scenario),
                 response.parsed_body["redirect_url"]
  end

  test "ログイン中のユーザーはシナリオ概要を表示できる" do
    scenario = create_scenario

    get scenario_url(scenario)

    assert_response :success
    assert_select "h1", text: scenario.title
  end

  test "ログイン中のユーザーはセッション準備資料を表示できる" do
    scenario = create_scenario

    get materials_scenario_url(scenario)

    assert_response :success
    assert_select "h1", text: "セッション準備資料"
  end

  test "ログイン中のユーザーはシーン進行を表示できる" do
    scenario = create_scenario

    get scenes_scenario_url(scenario)

    assert_response :success
    assert_select "h1", text: "シーン進行"
  end

  test "シーンの移動条件と複数の移動先を表示できる" do
    scenario = create_scenario

    first_scene = scenario.scenario_scenes.create!(
      title: "操舵室の調査",
      transition_condition: "調査先を決めたとき",
      position: 1
    )

    second_scene = scenario.scenario_scenes.create!(
      title: "機関室の調査",
      position: 2
    )

    third_scene = scenario.scenario_scenes.create!(
      title: "AIコア区画の調査",
      position: 3
    )

    first_scene.outgoing_transitions.create!(
      destination_scene: second_scene,
      condition: "停電の原因を調べに機関室へ向かう",
      position: 1
    )

    first_scene.outgoing_transitions.create!(
      destination_scene: third_scene,
      condition: "異常信号を追ってAIコア区画へ向かう",
      position: 2
    )

    get scenes_scenario_url(scenario)

    assert_response :success

    assert_select "main[data-controller='scene-jump']"
    assert_select "details#scene-1"
    assert_select "details#scene-2"
    assert_select "details#scene-3"

    assert_select ".scene-transitions", count: 1 do
      assert_select "h3", text: "次に進む"
      assert_select "th", text: "プレイヤーの行動・状況"
      assert_select "th", text: "移動先"

      assert_select(
        "p",
        text: "停電の原因を調べに機関室へ向かう"
      )
      assert_select(
        "p",
        text: "異常信号を追ってAIコア区画へ向かう"
      )

      assert_select "span", text: /シーン2：\s*機関室の調査/
      assert_select "span", text: /シーン3：\s*AIコア区画の調査/

      assert_select "a[href='#scene-2']",
                    text: "このシーンを開く" do |links|
        assert_equal(
          "click->scene-jump#open",
          links.first["data-action"]
        )
        assert_equal(
          "scene-2",
          links.first["data-scene-jump-target-id-param"]
        )
      end

      assert_select "a[href='#scene-3']",
                    text: "このシーンを開く"
    end

    assert_select(
      "h3",
      text: "次のシーンへ進む条件",
      count: 0
    )
  end

  test "移動情報のない既存シーンも従来の条件を表示できる" do
    scenario = create_scenario

    scenario.scenario_scenes.create!(
      title: "既存の調査シーン",
      transition_condition: "鍵を発見したとき",
      position: 1
    )

    scenario.scenario_scenes.create!(
      title: "移動条件がないシーン",
      transition_condition: nil,
      position: 2
    )

    get scenes_scenario_url(scenario)

    assert_response :success

    assert_select "h3",
                  text: "次のシーンへ進む条件",
                  count: 1
    assert_select "p", text: "鍵を発見したとき"
    assert_select(
      "a",
      text: "このシーンを開く",
      count: 0
    )
  end

  test "シーン内に複数イベントの発生条件と詳細を区別して表示できる" do
    scenario = create_scenario

    scene = scenario.scenario_scenes.create!(
      title: "操舵室の調査",
      position: 1
    )

    power_failure = scenario.scenario_events.create!(
      title: "非常電源の停止",
      trigger_condition: "保管庫端末の記録を確認した後",
      read_aloud_text: "突然、頭上の照明が消えます。",
      gm_actions: "機関室で電源を復旧できることを伝える。",
      post_event_changes: "復旧するまで端末を使用できない。",
      position: 1
    )

    warning_signal = scenario.scenario_events.create!(
      title: "正体不明の信号",
      trigger_condition: "警告音が3回鳴ったとき",
      read_aloud_text: "通信機から短い信号音が聞こえます。",
      gm_actions: "通信記録を調査できることを伝える。",
      post_event_changes: "AIコア区画への経路が判明する。",
      position: 2
    )

    scene.scenario_scene_events.create!(
      scenario_event: power_failure
    )
    scene.scenario_scene_events.create!(
      scenario_event: warning_signal
    )

    get scenes_scenario_url(scenario)

    assert_response :success

    assert_select ".scene-events", count: 1 do
      assert_select "h3",
                    text: "GM向け：このシーンのイベント"
      assert_select "article.scene-event", count: 2

      assert_select "h4", text: "非常電源の停止"
      assert_select "p",
                    text: "保管庫端末の記録を確認した後"
      assert_select "p",
                    text: "突然、頭上の照明が消えます。"
      assert_select "p",
                    text: "機関室で電源を復旧できることを伝える。"
      assert_select "p",
                    text: "復旧するまで端末を使用できない。"

      assert_select "h4", text: "正体不明の信号"
      assert_select "p",
                    text: "警告音が3回鳴ったとき"
      assert_select "p",
                    text: "通信機から短い信号音が聞こえます。"
      assert_select "p",
                    text: "通信記録を調査できることを伝える。"
      assert_select "p",
                    text: "AIコア区画への経路が判明する。"

      assert_select "h5",
                    text: "PL向けの読み上げ文",
                    count: 2
      assert_select "h5",
                    text: "GM向けの対応",
                    count: 2
      assert_select "h5",
                    text: "発生後の変化",
                    count: 2
    end
  end

  test "既存形式のイベント内容もシーン内に表示できる" do
    scenario = create_scenario

    scene = scenario.scenario_scenes.create!(
      title: "既存の調査シーン",
      position: 1
    )

    event = scenario.scenario_events.create!(
      content: "停電が発生し、周囲が暗くなる。",
      trigger_condition: "机を調べた後",
      position: 1
    )

    scene.scenario_scene_events.create!(
      scenario_event: event
    )

    get scenes_scenario_url(scenario)

    assert_response :success

    assert_select ".scene-events", count: 1 do
      assert_select "h4", text: "イベント 1"
      assert_select "p", text: "机を調べた後"
      assert_select "h5", text: "イベント内容"
      assert_select "p",
                    text: "停電が発生し、周囲が暗くなる。"
    end
  end

  test "イベントがないシーンに別シナリオのイベントを表示しない" do
    scenario = create_scenario

    scenario.scenario_scenes.create!(
      title: "イベントがないシーン",
      position: 1
    )

    other_scenario = create_scenario(
      title: "別のシナリオ"
    )

    other_scenario.scenario_events.create!(
      title: "別シナリオのイベント",
      trigger_condition: "別の条件",
      read_aloud_text: "別の読み上げ文",
      gm_actions: "別のGM向け対応",
      post_event_changes: "別の変化",
      position: 1
    )

    get scenes_scenario_url(scenario)

    assert_response :success
    assert_select ".scene-events", count: 0
    assert_select "h4",
                  text: "別シナリオのイベント",
                  count: 0
  end

  test "ログイン中のユーザーは真相とシナリオ解説を表示できる" do
    scenario = create_scenario

    get conclusion_scenario_url(scenario)

    assert_response :success
    assert_select "h1", text: "真相・シナリオ解説"
    assert_select ".scenario-endings", count: 0
  end

  test "エンディングの条件と読み上げ文と終了案内を表示できる" do
    scenario = create_scenario
    scenario.scenario_endings.create!(
      condition: "犯人を特定し、盗まれた宝石を取り戻した場合",
      content: "事件は解決し、屋敷には穏やかな日常が戻りました。",
      position: 1
    )

    get scenes_scenario_url(scenario)

    assert_response :success

    assert_select ".scenario-endings", count: 1 do
      assert_select "h2", text: "エンディング候補"
    end

    assert_select ".ending-condition", count: 1 do
      assert_select(
        "h4",
        text: "このエンディングになる条件（GM向け）"
      )
      assert_select(
        "p",
        text: "犯人を特定し、盗まれた宝石を取り戻した場合"
      )
    end

    assert_select ".ending-read-aloud", count: 1 do
      assert_select "h4", text: "結末の読み上げ文"
      assert_select(
        "p",
        text: "事件は解決し、屋敷には穏やかな日常が戻りました。"
      )
    end

    assert_select ".ending-session-close", count: 1 do
      assert_select "h4", text: "セッション終了の案内"
      assert_select(
        "p",
        text: "以上で、このシナリオは終了です。お疲れさまでした。"
      )
    end
  end

  test "シナリオ解説をネタバレ注意付きの折りたたみで表示できる" do
    scenario = create_scenario
    scenario.update!(
      story_outline: <<~TEXT
        【事件の真相】
        執事が宝石を持ち出していた。

        【出来事の順序】
        執事が宝石を隠し、プレイヤーが調査を始めた。
      TEXT
    )

    get conclusion_scenario_url(scenario)

    assert_response :success

    assert_select ".scenario-explanation", count: 1 do
      assert_select "h2", text: "シナリオ解説"
      assert_select(
        "p.text-danger",
        text: /ネタバレが含まれています/
      )
      assert_select "details", count: 1
      assert_select "details[open]", count: 0
      assert_select "summary", text: "シナリオ解説を表示する"
      assert_select "p", text: /執事が宝石を持ち出していた/
    end
  end

  test "条件とシナリオ解説がない既存シナリオも表示できる" do
    scenario = create_scenario
    scenario.scenario_endings.create!(
      content: "事件は解決し、屋敷には日常が戻りました。",
      position: 1
    )

    get scenes_scenario_url(scenario)

    assert_response :success

    assert_select ".ending-condition", count: 0

    assert_select ".ending-read-aloud", count: 1 do
      assert_select(
        "p",
        text: "事件は解決し、屋敷には日常が戻りました。"
      )
    end

    assert_select ".ending-session-close", count: 1

    get conclusion_scenario_url(scenario)

    assert_response :success

    assert_select ".scenario-explanation", count: 1 do
      assert_select(
        ".alert-secondary",
        text: "シナリオ解説は登録されていません。"
      )
    end
  end

  test "ログイン中のユーザーは自分のシナリオを削除できる" do
    scenario = create_scenario

    assert_difference("Scenario.count", -1) do
      delete scenario_url(scenario)
    end

    assert_redirected_to scenarios_url
    assert_equal "シナリオを削除しました。", flash[:notice]
  end

  test "ログイン中のユーザーは他のユーザーのシナリオを削除できない" do
    other_user = User.create!(
      name: "別のユーザー",
      email: "delete-other-scenario@example.com",
      password: "password",
      password_confirmation: "password"
    )

    other_scenario = create_scenario(
      user: other_user,
      title: "削除できないシナリオ"
    )

    assert_no_difference("Scenario.count") do
      delete scenario_url(other_scenario)
    end

    assert_response :not_found
  end

  test "準備資料にNPCの初登場時の居場所と様子を表示できる" do
    scenario = create_scenario

    location = scenario.scenario_locations.create!(
      name: "玄関ホール",
      description: "大きな窓のある広いホール。",
      position: 1
    )

    scenario.scenario_npcs.create!(
      name: "管理人",
      description: "屋敷を管理している人物。",
      initial_location: location,
      initial_activity: "窓枠を拭いている",
      position: 1
    )

    get materials_scenario_url(scenario)

    assert_response :success
    assert_select "h3", text: "管理人"
    assert_select "dt", text: "初登場時の居場所"
    assert_select "dd", text: "玄関ホール"
    assert_select "dt", text: "初登場時の様子"
    assert_select "dd p", text: "窓枠を拭いている"
  end

  test "初期配置が未設定のNPCも準備資料に表示できる" do
    scenario = create_scenario

    scenario.scenario_npcs.create!(
      name: "旅の商人",
      description: "各地を旅している商人。",
      position: 1
    )

    get materials_scenario_url(scenario)

    assert_response :success
    assert_select "h3", text: "旅の商人"
    assert_select "p", text: "各地を旅している商人。"
    assert_select "dt", text: "初登場時の居場所", count: 0
    assert_select "dt", text: "初登場時の様子", count: 0
  end

  test "シーン進行にNPCの場面ごとの配置と様子を表示できる" do
    scenario = create_scenario

    hall = scenario.scenario_locations.create!(
      name: "玄関ホール",
      description: "大きな窓のあるホール。",
      position: 1
    )

    study = scenario.scenario_locations.create!(
      name: "書斎",
      description: "本棚のある部屋。",
      position: 2
    )

    npc = scenario.scenario_npcs.create!(
      name: "管理人",
      description: "屋敷を管理している人物。",
      initial_location: hall,
      initial_activity: "窓枠を拭いている",
      position: 1
    )

    scene = scenario.scenario_scenes.create!(
      title: "書斎の調査",
      position: 1
    )

    scene.scenario_scene_locations.create!(
      scenario_location: study
    )

    scene.scenario_scene_npcs.create!(
      scenario_npc: npc,
      scenario_location: study,
      activity: "本棚を調べている",
      appearance_condition: "書斎の物音を聞いて移動した後",
      reaction: "質問に慎重に答える"
    )

    get scenes_scenario_url(scenario)

    assert_response :success

    assert_select "article", text: /管理人/ do
      assert_select "dd", text: "書斎"
      assert_select "dd", text: "玄関ホール", count: 0
      assert_select "dd p", text: "本棚を調べている"
      assert_select "dd p", text: "書斎の物音を聞いて移動した後"
      assert_select "h5", text: "人物の反応・ゲームマスター向けメモ"
      assert_select "p", text: "質問に慎重に答える"
    end
  end

  test "遠隔参加のNPCを物理的な居場所と区別して表示できる" do
    scenario = create_scenario

    bridge = scenario.scenario_locations.create!(
      name: "操舵室",
      description: "船を操作する区画。",
      position: 1
    )

    cargo_hold = scenario.scenario_locations.create!(
      name: "貨物保管庫",
      description: "船の荷物を保管する区画。",
      position: 2
    )

    npc = scenario.scenario_npcs.create!(
      name: "船長",
      description: "調査船の船長。",
      initial_location: cargo_hold,
      initial_activity: "鉱石標本を確認している",
      position: 1
    )

    scene = scenario.scenario_scenes.create!(
      title: "操舵室からの通信",
      position: 1
    )

    scene.scenario_scene_locations.create!(
      scenario_location: bridge
    )

    scene.scenario_scene_npcs.create!(
      scenario_npc: npc,
      scenario_location: cargo_hold,
      participation_mode: "remote",
      activity: "貨物保管庫で鉱石標本を確認している",
      appearance_condition: "船内通信が接続されたとき",
      reaction: "通信越しに落ち着いて状況を説明する"
    )

    get scenes_scenario_url(scenario)

    assert_response :success

    assert_select "summary", text: /このシーンに関わる人物/
    assert_select "article", text: /船長/ do
      assert_select ".badge", text: "遠隔"
      assert_select "dt", text: "実際の居場所"
      assert_select "dd", text: "貨物保管庫"
      assert_select "dt", text: "別の場所での様子"
      assert_select "dd p",
                    text: "貨物保管庫で鉱石標本を確認している"
      assert_select "dt", text: "参加・登場のタイミング"
      assert_select "dd p", text: "船内通信が接続されたとき"
    end
  end

  test "探索の台詞と描写をGM向け情報と分けて表示できる" do
    scenario = create_scenario

    hall = scenario.scenario_locations.create!(
      name: "玄関ホール",
      description: "大きな窓のある広いホール。",
      position: 1
    )

    study = scenario.scenario_locations.create!(
      name: "書斎",
      description: "本棚と大きな机がある部屋。",
      position: 2
    )

    npc = scenario.scenario_npcs.create!(
      name: "管理人",
      description: "屋敷を管理している人物。",
      initial_location: hall,
      initial_activity: "窓枠を拭いている",
      position: 1
    )

    scene = scenario.scenario_scenes.create!(
      title: "屋敷の調査",
      position: 1
    )

    [ hall, study ].each do |location|
      scene.scenario_scene_locations.create!(
        scenario_location: location
      )
    end

    gm_note = "管理人は宝石の隠し場所を知っている。"

    scene.scenario_scene_npcs.create!(
      scenario_npc: npc,
      scenario_location: hall,
      activity: "窓枠を拭いている",
      reaction: gm_note
    )

    dialogue_timing = "昨夜のことを尋ねられたとき"
    dialogue_text = "昨夜、書斎から物音がしたんです。"
    sound_timing = "ホールに入ったとき"
    sound_text = "書斎の方向から物音が聞こえます。"

    scene.scenario_exploration_cues.create!(
      source_location: hall,
      target_location: study,
      scenario_npc: npc,
      trigger_condition: dialogue_timing,
      read_aloud_text: dialogue_text,
      position: 1
    )

    scene.scenario_exploration_cues.create!(
      source_location: hall,
      target_location: study,
      trigger_condition: sound_timing,
      read_aloud_text: sound_text,
      position: 2
    )

    get scenes_scenario_url(scenario)

    assert_response :success

    assert_select ".scene-locations" do
      assert_select "h4", text: "玄関ホール"
      assert_select "h4", text: "書斎"
      assert_select "p", text: hall.description
      assert_select "p", text: study.description
    end

    assert_select ".scene-exploration-cues" do
      assert_select "h4", text: "管理人の台詞"
      assert_select "h4", text: "周囲の描写"
      assert_select "dd", text: "玄関ホール", count: 2
      assert_select "dd", text: "書斎", count: 2
      assert_select "p", text: dialogue_timing
      assert_select "p", text: sound_timing
    end

    assert_select "p", text: gm_note

    assert_select ".exploration-read-aloud", count: 2 do |blocks|
      read_aloud_text = blocks.map(&:text).join("\n")

      assert_includes read_aloud_text, dialogue_text
      assert_includes read_aloud_text, sound_text

      [ gm_note, dialogue_timing, sound_timing, scenario.truth ].each do |text|
        assert_not_includes read_aloud_text, text
      end
    end
  end

  test "場所と探索のきっかけが未設定の既存シーンも表示できる" do
    scenario = create_scenario

    npc = scenario.scenario_npcs.create!(
      name: "旅の商人",
      description: "各地を旅している商人。",
      position: 1
    )

    scene = scenario.scenario_scenes.create!(
      title: "商人との出会い",
      read_aloud_text: "街道で一人の商人に出会いました。",
      position: 1
    )

    scene.scenario_scene_npcs.create!(
      scenario_npc: npc,
      reaction: "穏やかに質問へ答える"
    )

    get scenes_scenario_url(scenario)

    assert_response :success
    assert_select "h4", text: "旅の商人"
    assert_select "p", text: "街道で一人の商人に出会いました。"
    assert_select "p", text: "穏やかに質問へ答える"
    assert_select ".scene-locations", count: 0
    assert_select ".scene-exploration-cues", count: 0
  end

  test "場所の描写を探索結果やGM向け情報と分けて表示できる" do
    scenario = create_scenario

    description = "薄暗い聖堂には蝋燭の匂いが漂い、奥には石の祭壇が置かれている。"
    action_label = "祭壇を調べる"
    exploration_result = "祭壇の石の角が一部欠けている。"
    gm_guide = "欠けた石について尋ねられたら、司祭との会話へ進める。"

    scenario.scenario_scenes.create!(
      title: "聖堂の調査",
      position: 1,
      read_aloud_text: description,
      investigation_options: [
        {
          label: action_label,
          result: exploration_result,
          gm_guide: gm_guide
        }
      ].to_json
    )

    get scenes_scenario_url(scenario)

    assert_response :success

    assert_select ".scene-location-description", count: 1 do |elements|
      assert_select "h3", text: "場所の描写"

      displayed_text = elements.first.text

      assert_includes displayed_text, description
      assert_not_includes displayed_text, exploration_result
      assert_not_includes displayed_text, gm_guide
      assert_not_includes displayed_text, scenario.truth
    end

    assert_includes response.body, action_label
    assert_includes response.body, exploration_result
    assert_includes response.body, gm_guide
  end

  test "到着時から見える探索対象だけを場所の描写に表示できる" do
    scenario = create_scenario

    visible_description = "書斎の中央に古い机があります。"
    hidden_description = "机の裏側に小さな鍵があります。"

    scenario.scenario_scenes.create!(
      title: "書斎の調査",
      position: 1,
      read_aloud_text: "皆さんが書斎に入ると、薄暗い室内が広がっています。",
      exploration_targets: [
        {
          key: "writing_desk",
          name: "書斎の机",
          visible_on_arrival: true,
          description: visible_description,
          reveal_condition: ""
        },
        {
          key: "hidden_key",
          name: "隠された鍵",
          visible_on_arrival: false,
          description: hidden_description,
          reveal_condition: "机を詳しく調べた後"
        }
      ]
    )

    get scenes_scenario_url(scenario)

    assert_response :success

    assert_select ".scene-location-description", count: 1 do |elements|
      displayed_text = elements.first.text

      assert_includes displayed_text, visible_description
      assert_not_includes displayed_text, hidden_description
    end
  end

  test "場所の描写がなくても見える探索対象があれば表示できる" do
    scenario = create_scenario

    scenario.scenario_scenes.create!(
      title: "書斎の調査",
      position: 1,
      read_aloud_text: nil,
      exploration_targets: [
        {
          key: "writing_desk",
          name: "書斎の机",
          visible_on_arrival: true,
          description: "書斎の中央に古い机があります。",
          reveal_condition: ""
        }
      ]
    )

    get scenes_scenario_url(scenario)

    assert_response :success

    assert_select ".scene-location-description", count: 1 do
      assert_select "p", text: "書斎の中央に古い机があります。"
    end
  end

  test "場所の描写が未設定や空文字の既存シーンも表示できる" do
    scenario = create_scenario

    scenario.scenario_scenes.create!(
      title: "描写が未設定のシーン",
      position: 1,
      read_aloud_text: nil
    )

    scenario.scenario_scenes.create!(
      title: "描写が空文字のシーン",
      position: 2,
      read_aloud_text: ""
    )

    get scenes_scenario_url(scenario)

    assert_response :success
    assert_includes response.body, "描写が未設定のシーン"
    assert_includes response.body, "描写が空文字のシーン"
    assert_select ".scene-location-description", count: 0
  end

  [ 2, 4 ].each do |option_count|
    test "行動選択肢が#{option_count}個でもすべて順番に表示できる" do
      scenario = create_scenario

      options = Array.new(option_count) do |index|
        number = index + 1

        {
          label: "対象#{number}を調べる",
          result: "対象#{number}の調査結果です。",
          gm_guide: "対象#{number}の調査後の案内です。"
        }
      end

      scenario.scenario_scenes.create!(
        title: "調査するシーン",
        position: 1,
        read_aloud_text: "皆さんは今、調査室にいます。",
        investigation_options: options.to_json
      )

      get scenes_scenario_url(scenario)

      assert_response :success

      assert_select ".scene-investigation-options", count: 1 do
        assert_select "h3", text: "プレイヤーの行動選択肢"

        assert_select "details", count: option_count do |blocks|
          options.each_with_index do |option, index|
            assert_select(
              blocks[index],
              "summary",
              text: /選択肢#{index + 1}：\s*#{Regexp.escape(option[:label])}/
            )

            assert_select(
              blocks[index],
              ".alert-info p",
              text: option[:result]
            )

            assert_select(
              blocks[index],
              ".border.rounded-3 p",
              text: option[:gm_guide]
            )
          end
        end
      end
    end
  end

  private

  def create_scenario(user: @user, title: "テストシナリオ")
    user.scenarios.create!(
      genre: "ミステリー",
      world_setting: "テスト用の世界観です。",
      tone: "シリアス",
      player_count: 2,
      play_time: 30,
      title: title,
      summary: "テスト用の概要です。",
      introduction: "テスト用の導入です。",
      truth: "テスト用の真相です。"
    )
  end
end
