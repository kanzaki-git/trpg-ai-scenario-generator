require "test_helper"

class UsersControllerTest < ActionDispatch::IntegrationTest
  test "should get new" do
    get new_user_url
    assert_response :success
  end

  test "登録に成功すると自動ログインしてシナリオ一覧へ移動する" do
    assert_difference("User.count", 1) do
      post users_url, params: {
        user: {
          name: "登録テスト",
          email: "signup-test@example.com",
          password: "Password12345",
          password_confirmation: "Password12345"
        }
      }
    end

    user = User.find_by!(email: "signup-test@example.com")

    assert_equal user.id.to_s, session[:user_id].to_s
    assert_redirected_to scenarios_url
    assert_equal "ユーザー登録が完了しました", flash[:notice]

    follow_redirect!
    assert_response :success
  end

  test "登録に失敗するとユーザーは作成されずログインもしない" do
    assert_no_difference("User.count") do
      post users_url, params: {
        user: {
          name: "登録テスト",
          email: "",
          password: "Password12345",
          password_confirmation: "Password12345"
        }
      }
    end

    assert_response :unprocessable_entity
    assert_nil session[:user_id]

    get scenarios_url
    assert_redirected_to login_url
  end
end
