require "test_helper"

class PublicScenariosControllerTest <
  ActionDispatch::IntegrationTest
  setup do
    @user = User.create!(
      name: "公開ページテストユーザー",
      email: "public-scenario-test@example.com",
      password: "password",
      password_confirmation: "password"
    )

    @scenario = @user.scenarios.create!(
      title: "GMだけが見る元タイトル",
      summary: "公開してはいけないシナリオ概要",
      truth: "公開してはいけない事件の真相",
      genre: "ミステリー",
      world_setting: "現代日本",
      tone: "シリアス",
      player_count: 3,
      play_time: 90,
      generation_status: :completed
    )

    @share = @scenario.create_scenario_share!(
      public_title: "霧に包まれた港町",
      public_description: "港町で起きた事件を調査するシナリオです。",
      published_at: Time.current
    )
  end

  test "ログインせずに公開中の紹介ページを表示できる" do
    get shared_scenario_url(
      share_token: @share.share_token
    )

    assert_response :success
    assert_select "h1", text: @share.public_title
    assert_select "p", text: /#{@share.public_description}/
    assert_select "dd", text: @scenario.genre
    assert_select "dd", text: @scenario.tone
    assert_select "dd", text: "#{@scenario.player_count}人"
    assert_select "dd", text: "約#{@scenario.play_time}分"
  end

  test "非公開情報をHTMLに含めない" do
    get shared_scenario_url(
      share_token: @share.share_token
    )

    assert_response :success

    assert_not_includes response.body,
                        @scenario.title

    assert_not_includes response.body,
                        @scenario.summary

    assert_not_includes response.body,
                        @scenario.truth

    assert_not_includes response.body,
                        @user.email
  end

  test "検索エンジンへ掲載しない設定がある" do
    get shared_scenario_url(
      share_token: @share.share_token
    )

    assert_response :success

    assert_select(
      'meta[name="robots"]' \
      '[content="noindex, nofollow, noarchive"]'
    )
  end

  test "共有停止後は紹介ページを表示できない" do
    @share.unpublish!

    get shared_scenario_url(
      share_token: @share.share_token
    )

    assert_response :not_found
  end

  test "無効な共有トークンでは紹介ページを表示できない" do
    get shared_scenario_url(
      share_token: "invalid-share-token"
    )

    assert_response :not_found
  end

  test "シナリオ削除後は紹介ページを表示できない" do
    share_token = @share.share_token

    @scenario.destroy!

    get shared_scenario_url(
      share_token: share_token
    )

    assert_response :not_found
  end

  test "公開ページにOGP情報が設定される" do
    get shared_scenario_url(
      share_token: @share.share_token
    )

    assert_response :success

    assert_select(
      'meta[property="og:title"]' \
      "[content=?]",
      @share.public_title
    )

    assert_select(
      'meta[property="og:description"]' \
      "[content=?]",
      @share.public_description
    )

    assert_select(
      'meta[property="og:type"]' \
      '[content="website"]'
    )

    assert_select(
      'meta[property="og:url"]' \
      "[content=?]",
      shared_scenario_url(
        share_token: @share.share_token
      )
    )

    assert_select(
      'meta[property="og:image"]'
    ) do |elements|
      assert_includes elements.first["content"],
                      "scenario_share_ogp"
    end

    assert_select(
      'meta[property="og:image:width"]' \
      '[content="1200"]'
    )

    assert_select(
      'meta[property="og:image:height"]' \
      '[content="630"]'
    )

    assert_select(
      'meta[name="twitter:card"]' \
      '[content="summary_large_image"]'
    )
  end
end
