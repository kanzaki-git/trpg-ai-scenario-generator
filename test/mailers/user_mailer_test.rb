require "test_helper"

class UserMailerTest < ActionMailer::TestCase
  setup do
    @user = users(:one)
    @user.generate_reset_password_token!
  end

  test "パスワード再設定メールの内容が正しい" do
    mail = UserMailer.reset_password_email(@user)
    text_body = mail.text_part.decoded
    html_body = mail.html_part.decoded

    assert_equal "パスワード再設定のご案内", mail.subject
    assert_equal [ @user.email ], mail.to

    assert_match @user.name, text_body
    assert_match @user.reset_password_token, text_body
    assert_match "メール送信から1時間", text_body

    assert_match @user.name, html_body
    assert_match @user.reset_password_token, html_body
  end
end
