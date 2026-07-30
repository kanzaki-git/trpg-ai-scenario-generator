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
  end

  test "ログイン中のユーザーはシナリオ生成を開始できる" do
    background_response = OpenStruct.new(
      id: "resp_test_background"
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

    assert_select ".alert-danger",
                  text: /シナリオの生成に失敗しました/

    assert_select(
      'select[name="scenario[genre]"] option[selected][value="ホラー"]'
    )

    assert_select 'textarea[name="scenario[world_setting]"]',
                  text: "現代日本の廃校"
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

  test "ログイン中のユーザーは真相とエンディングを表示できる" do
    scenario = create_scenario

    get conclusion_scenario_url(scenario)

    assert_response :success
    assert_select "h1", text: "真相・エンディング"
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
