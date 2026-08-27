require "test_helper"

class PasswordResetsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
  end

  test "ログインしていなくてもパスワード再設定申請画面を表示できる" do
    get new_password_reset_path

    assert_response :success
    assert_select "h1", text: "パスワード再設定"
    assert_select "form[action=?]", password_resets_path
  end

  test "登録済みメールアドレスを送信すると再設定メールが送信される" do
    assert_emails 1 do
      post password_resets_path, params: { email: @user.email }
    end

    assert_redirected_to login_path
    assert_equal(
      "メールアドレスが登録されている場合、パスワード再設定メールを送信しました",
      flash[:notice]
    )

    @user.reload

    assert_not_nil @user.reset_password_token
    assert_not_nil @user.reset_password_token_expires_at
  end

  test "未登録メールアドレスでも登録状況が分からないメッセージを表示する" do
    assert_no_emails do
      post password_resets_path,
           params: { email: "not-registered@example.com" }
    end

    assert_redirected_to login_path
    assert_equal(
      "メールアドレスが登録されている場合、パスワード再設定メールを送信しました",
      flash[:notice]
    )
  end

  test "有効なトークンで新しいパスワード入力画面を表示できる" do
    @user.generate_reset_password_token!

    get edit_password_reset_path(@user.reset_password_token)

    assert_response :success
    assert_select "h1", text: "新しいパスワードの設定"
    assert_select(
      "form[action=?]",
      password_reset_path(@user.reset_password_token)
    )
  end

  test "無効なトークンではパスワード再設定申請画面へ戻る" do
    get edit_password_reset_path("invalid-token")

    assert_redirected_to new_password_reset_path
    assert_equal(
      "パスワード再設定URLが無効か、有効期限が切れています",
      flash[:alert]
    )
  end

  test "有効期限切れのトークンではパスワード再設定申請画面へ戻る" do
    @user.generate_reset_password_token!
    @user.update!(
      reset_password_token_expires_at: 1.minute.ago
    )

    get edit_password_reset_path(@user.reset_password_token)

    assert_redirected_to new_password_reset_path
    assert_equal(
      "パスワード再設定URLが無効か、有効期限が切れています",
      flash[:alert]
    )
  end

  test "正しい入力でパスワードを再設定できる" do
    @user.generate_reset_password_token!
    token = @user.reset_password_token

    patch password_reset_path(token), params: {
      user: {
        password: "new-password",
        password_confirmation: "new-password"
      }
    }

    assert_redirected_to login_path
    assert_equal "パスワードを再設定しました", flash[:notice]

    @user.reload

    assert @user.valid_password?("new-password")
    assert_nil @user.reset_password_token
  end

  test "パスワードと確認用パスワードが一致しない場合は再設定できない" do
    @user.generate_reset_password_token!
    token = @user.reset_password_token
    original_crypted_password = @user.crypted_password

    patch password_reset_path(token), params: {
      user: {
        password: "new-password",
        password_confirmation: "different-password"
      }
    }

    assert_response :unprocessable_entity
    assert_equal(
      "パスワードを再設定できませんでした",
      flash[:alert]
    )
    assert_select "h1", text: "新しいパスワードの設定"

    @user.reload

    assert_equal original_crypted_password, @user.crypted_password
    assert_equal token, @user.reset_password_token
  end
end
