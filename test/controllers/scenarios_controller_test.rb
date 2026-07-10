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

  test "ログイン中のユーザーはシナリオ生成画面を表示できる" do
    get new_scenario_url

    assert_response :success
  end

  test "ログイン中のユーザーはシナリオを作成できる" do
    fake_generator = Minitest::Mock.new
    fake_generator.expect(:call, fake_generation_result)

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

    assert_redirected_to root_path
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

  private

  def fake_generation_result
    OpenStruct.new(
      title: "テストシナリオ",
      summary: "テスト用の概要です。",
      introduction: "テスト用の導入です。",
      truth: "テスト用の真相です。",
      npcs: [],
      clues: [],
      events: [],
      scenes: [],
      endings: []
    )
  end
end
