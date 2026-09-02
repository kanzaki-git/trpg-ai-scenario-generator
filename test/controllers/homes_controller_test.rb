require "test_helper"

class HomesControllerTest < ActionDispatch::IntegrationTest
  test "未ログイン時は利用上限が表示され残り回数は表示されない" do
    get root_url

    assert_response :success

    assert_select ".app-header a[href=?]", root_path,
                  text: "TRPG AI Scenario Generator"
    assert_select ".alert-info",
                  text: /累計\s*#{User::SCENARIO_GENERATION_LIMIT}回/

    assert_select ".alert-info p",
                  text: /残り生成回数/,
                  count: 0
  end

  test "ログイン中は利用上限と自分の残り回数が表示される" do
    user = User.create!(
      name: "トップページテストユーザー",
      email: "home-test@example.com",
      password: "password",
      password_confirmation: "password",
      scenario_generation_count: 1
    )

    post login_url, params: {
      email: user.email,
      password: "password"
    }

    get root_url

    assert_response :success

    assert_select ".app-header a[href=?]", root_path,
                  text: "TRPG AI Scenario Generator"
    assert_select ".alert-info",
                  text: /累計\s*#{User::SCENARIO_GENERATION_LIMIT}回/

    assert_select ".alert-info p",
                  text: "残り生成回数：#{User::SCENARIO_GENERATION_LIMIT - 1}回"
  end
end
