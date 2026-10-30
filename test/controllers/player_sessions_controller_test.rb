
require "test_helper"

class PlayerSessionsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = User.create!(
      name: "プレイヤー画面テストユーザー",
      email: "player-session-test@example.com",
      password: "password",
      password_confirmation: "password"
    )

    @scenario = @user.scenarios.create!(
      title: "消えた宝石の謎",
      summary: "宝石の盗難事件を調査するシナリオ",
      truth: "執事が宝石を隠していた",
      genre: "ミステリー",
      world_setting: "現代日本",
      tone: "シリアス",
      player_count: 3,
      play_time: 90,
      generation_status: :completed
    )

    @progress = @scenario.create_scenario_progress!
  end

  test "正しいトークンでプレイヤー画面を表示できる" do
    get player_session_url(
      player_token: @progress.player_token
    )

    assert_response :success
    assert_select "h1", text: @scenario.title
    assert_select "h2", text: "現在地"
    assert_select "h2", text: "共通マップ"
    assert_select "h2", text: "登場人物"
  end

  test "ログインしていなくても表示できる" do
    get player_session_url(
      player_token: @progress.player_token
    )

    assert_response :success
    assert_select "p", text: "プレイヤー向けセッション情報"
  end

  test "不正なトークンでは404になる" do
    get player_session_url(
      player_token: "invalid-player-token"
    )

    assert_response :not_found
  end

  test "GM専用の真相を表示しない" do
    get player_session_url(
      player_token: @progress.player_token
    )

    assert_response :success

    assert_not_includes response.body, @scenario.truth
    assert_not_includes response.body, @scenario.summary
  end

  test "登場済みNPCだけを表示する" do
    appeared_npc = @scenario.scenario_npcs.create!(
      name: "村の司祭",
      description: "事件の秘密を知っている",
      position: 1
    )

    hidden_npc = @scenario.scenario_npcs.create!(
      name: "謎の黒幕",
      description: "事件の犯人",
      position: 2
    )

    @progress.appeared_npcs << appeared_npc

    get player_session_url(
      player_token: @progress.player_token
    )

    assert_response :success

    assert_select "li", text: appeared_npc.name
    assert_select "li", text: hidden_npc.name, count: 0

    assert_not_includes response.body, appeared_npc.description
    assert_not_includes response.body, hidden_npc.description
  end

  test "検索エンジンに登録させない設定がある" do
    get player_session_url(
      player_token: @progress.player_token
    )

    assert_response :success

    assert_select(
      'meta[name="robots"][content="noindex, nofollow"]'
    )
  end

  test "現在地が未設定でも表示できる" do
    get player_session_url(
      player_token: @progress.player_token
    )

    assert_response :success
    assert_select "div", text: /現在地は未設定です/
  end

  test "公開されている現在地を表示する" do
    location = @scenario.scenario_locations.create!(
      name: "村の広場",
      description: "村の中心にある広場",
      position: 1,
      visibility: :public,
      map_row: 1,
      map_column: 1
    )

    @progress.update!(current_location: location)

    get player_session_url(
      player_token: @progress.player_token
    )

    assert_response :success
    assert_select "h3", text: location.name
    assert_select ".scenario-map-location.is-active", count: 1
  end

  test "秘密の現在地の名前を表示しない" do
    location = @scenario.scenario_locations.create!(
      name: "秘密の地下室",
      description: "事件の真相が隠された部屋",
      position: 1,
      visibility: :secret,
      map_row: 1,
      map_column: 1
    )

    @progress.update!(current_location: location)

    get player_session_url(
      player_token: @progress.player_token
    )

    assert_response :success

    assert_includes(
      response.body,
      "現在地の情報はまだ公開されていません。"
    )

    assert_not_includes response.body, location.name
    assert_not_includes response.body, location.description
  end

  test "公開可能な場所と経路だけをマップに表示する" do
    public_location1 = @scenario.scenario_locations.create!(
      name: "村の広場",
      description: "村の中心にある広場",
      position: 1,
      visibility: :public,
      map_row: 1,
      map_column: 1
    )

    public_location2 = @scenario.scenario_locations.create!(
      name: "村の宿屋",
      description: "旅人が集まる宿屋",
      position: 2,
      visibility: :public,
      map_row: 1,
      map_column: 2
    )

    secret_location = @scenario.scenario_locations.create!(
      name: "秘密の地下通路",
      description: "事件の真相につながる隠し通路",
      position: 3,
      visibility: :secret,
      map_row: 2,
      map_column: 2
    )

    @scenario.scenario_location_connections.create!(
      source_location: public_location1,
      destination_location: public_location2,
      visibility: :public,
      position: 1
    )

    @scenario.scenario_location_connections.create!(
      source_location: public_location2,
      destination_location: secret_location,
      visibility: :secret,
      position: 2
    )

    get player_session_url(
      player_token: @progress.player_token
    )

    assert_response :success

    assert_select ".scenario-map-location", count: 2
    assert_select ".scenario-map-connection", count: 1

    assert_includes response.body, public_location1.name
    assert_includes response.body, public_location2.name

    assert_not_includes response.body, secret_location.name
    assert_not_includes response.body, secret_location.description
  end

  test "map_viewをgmに変更してもGM向けマップにならない" do
    secret_location = @scenario.scenario_locations.create!(
      name: "隠された研究室",
      description: "GMだけが知る秘密の部屋",
      position: 1,
      visibility: :secret,
      map_row: 1,
      map_column: 1
    )

    get player_session_url(
      player_token: @progress.player_token,
      map_view: "gm"
    )

    assert_response :success

    assert_not_includes response.body, secret_location.name
    assert_not_includes response.body, secret_location.description

    assert_select ".scenario-map-location.is-secret", count: 0
    assert_select ".btn-group[aria-label='マップの表示対象']", count: 0
  end

  test "提示済みの手がかりを表示しない" do
    clue = @scenario.scenario_clues.create!(
      content: "犯人の名前が書かれた秘密の手紙",
      position: 1
    )

    @progress.presented_clues << clue

    get player_session_url(
      player_token: @progress.player_token
    )

    assert_response :success
    assert_not_includes response.body, clue.content
  end

  test "プレイヤー画面へのアクセスで進行状況が変更されない" do
    original_updated_at = @progress.updated_at

    assert_no_difference [
      "ScenarioProgress.count",
      "ScenarioProgressNpc.count",
      "ScenarioProgressClue.count",
      "ScenarioProgressLocation.count"
    ] do
      get player_session_url(
        player_token: @progress.player_token
      )
    end

    assert_response :success
    assert_equal original_updated_at, @progress.reload.updated_at
  end
end
