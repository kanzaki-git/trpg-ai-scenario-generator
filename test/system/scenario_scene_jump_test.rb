require "application_system_test_case"
require "uri"

class ScenarioSceneJumpTest < ApplicationSystemTestCase
  setup do
    @user = User.create!(
      name: "ジャンプテストユーザー",
      email: "scene-jump@example.com",
      password: "password",
      password_confirmation: "password"
    )

    @scenario = Scenario.create!(
      user: @user,
      title: "宇宙船の異常",
      genre: "SF",
      world_setting: "宇宙船",
      tone: "シリアス",
      player_count: 4,
      play_time: 60
    )

    first_scene = @scenario.scenario_scenes.create!(
      title: "操舵室の調査",
      position: 1
    )

    second_scene = @scenario.scenario_scenes.create!(
      title: "機関室の調査",
      position: 2
    )

    first_scene.outgoing_transitions.create!(
      destination_scene: second_scene,
      condition: "停電の原因を調べに機関室へ向かう",
      position: 1
    )
  end

  test "ボタンから移動先のシーンを開いてジャンプできる" do
    visit login_url

    fill_in "メールアドレス", with: @user.email
    fill_in "パスワード", with: "password"
    click_button "ログイン"

    assert_text "ログインしました"

    visit scenes_scenario_url(@scenario)

    assert_selector "#scene-1[open]"
    assert_selector "#scene-2:not([open])"

    within "#scene-1" do
      click_link "このシーンを開く"
    end

    assert_selector "#scene-1[open]"
    assert_selector "#scene-2[open]"

    assert_equal(
      "scene-2",
      URI.parse(page.current_url).fragment
    )
  end
end
