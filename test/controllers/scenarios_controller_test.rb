require "test_helper"

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
end
