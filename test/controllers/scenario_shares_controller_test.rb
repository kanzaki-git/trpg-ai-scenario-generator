require "test_helper"

class ScenarioSharesControllerTest <
  ActionDispatch::IntegrationTest
  setup do
    @user = User.create!(
      name: "共有設定テストユーザー",
      email: "scenario-share-test@example.com",
      password: "password",
      password_confirmation: "password"
    )

    post login_url, params: {
      email: @user.email,
      password: "password"
    }

    @scenario = create_scenario
  end

  test "共有設定画面を表示できる" do
    get edit_scenario_share_url(@scenario)

    assert_response :success
    assert_select "h1", text: "シナリオ共有設定"

    assert_select(
      'input[name="scenario_share[public_title]"]' \
      "[value=?]",
      @scenario.title
    )

    assert_select(
      'textarea[name="scenario_share[public_description]"]'
    )
  end

  test "共有設定を作成できる" do
    assert_difference("ScenarioShare.count", 1) do
      post scenario_share_url(@scenario), params: {
        scenario_share: {
          public_title: "プレイヤー向けタイトル",
          public_description: "ネタバレを含まない紹介文です。"
        }
      }
    end

    assert_redirected_to edit_scenario_share_path(@scenario)
    assert_equal "共有設定を保存しました。", flash[:notice]

    share = @scenario.reload.scenario_share

    assert_equal "プレイヤー向けタイトル",
                 share.public_title

    assert_equal "ネタバレを含まない紹介文です。",
                 share.public_description

    assert_predicate share.share_token, :present?
    assert_not share.published?
  end

  test "入力に不備がある場合は共有設定を作成できない" do
    assert_no_difference("ScenarioShare.count") do
      post scenario_share_url(@scenario), params: {
        scenario_share: {
          public_title: "",
          public_description: ""
        }
      }
    end

    assert_response :unprocessable_entity
    assert_select ".alert-danger"
  end

  test "共有設定を更新できる" do
    share = create_share

    patch scenario_share_url(@scenario), params: {
      scenario_share: {
        public_title: "更新後のタイトル",
        public_description: "更新後の紹介文です。"
      }
    }

    assert_redirected_to edit_scenario_share_path(@scenario)
    assert_equal "共有設定を更新しました。", flash[:notice]

    share.reload

    assert_equal "更新後のタイトル",
                 share.public_title

    assert_equal "更新後の紹介文です。",
                 share.public_description
  end

  test "共有を開始できる" do
    share = create_share

    assert_not share.published?

    patch publish_scenario_share_url(@scenario)

    assert_redirected_to edit_scenario_share_path(@scenario)
    assert_equal "シナリオの共有を開始しました。",
                 flash[:notice]
    assert share.reload.published?
  end

  test "共有を停止できる" do
    share = create_share(
      published_at: Time.current
    )

    assert share.published?

    patch unpublish_scenario_share_url(@scenario)

    assert_redirected_to edit_scenario_share_path(@scenario)
    assert_equal "シナリオの共有を停止しました。",
                 flash[:notice]
    assert_not share.reload.published?
  end

  test "別ユーザーのシナリオの共有設定画面は表示できない" do
    other_user = User.create!(
      name: "別のユーザー",
      email: "other-share-test@example.com",
      password: "password",
      password_confirmation: "password"
    )

    other_scenario = create_scenario(
      user: other_user,
      title: "別ユーザーのシナリオ"
    )

    get edit_scenario_share_url(other_scenario)

    assert_response :not_found
  end

  test "ログインしていない場合はログイン画面へ移動する" do
    delete logout_url

    get edit_scenario_share_url(@scenario)

    assert_redirected_to login_path
    assert_equal "ログインしてください", flash[:alert]
  end

  private

  def create_scenario(
    user: @user,
    title: "共有設定テストシナリオ"
  )
    user.scenarios.create!(
      title: title,
      genre: "ミステリー",
      world_setting: "現代日本",
      tone: "シリアス",
      player_count: 3,
      play_time: 90,
      generation_status: :completed
    )
  end

  def create_share(published_at: nil)
    @scenario.create_scenario_share!(
      public_title: "公開用タイトル",
      public_description: "ネタバレを含まない公開用紹介文です。",
      published_at: published_at
    )
  end
end
