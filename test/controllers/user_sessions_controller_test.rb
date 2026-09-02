require "test_helper"

class UserSessionsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = User.create!(
      name: "ログインテストユーザー",
      email: "login-test@example.com",
      password: "password",
      password_confirmation: "password"
    )
  end

  test "ログイン画面を表示できる" do
    get login_url

    assert_response :success
  end

  test "ログインに成功するとトップページへ移動する" do
    post login_url, params: {
      email: @user.email,
      password: "password"
    }

    assert_redirected_to root_url
    assert_equal "ログインしました", flash[:notice]

    follow_redirect!

    assert_response :success
    assert_select "a[href=?]", scenarios_path,
                  text: "シナリオ一覧を見る"
    assert_select "a[href=?]", new_scenario_path,
                  text: "シナリオを作成する"
  end

  test "誤ったパスワードの場合はエラーメッセージを表示する" do
    post login_url, params: {
      email: @user.email,
      password: "wrong-password"
    }

    assert_response :unprocessable_entity
    assert_select ".alert-danger", text: "ログインに失敗しました"
  end
end
