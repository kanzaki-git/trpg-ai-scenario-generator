class UserMailer < ApplicationMailer
  def reset_password_email(user)
    @user = user

    mail(
      to: @user.email,
      subject: "パスワード再設定のご案内"
    )
  end
end
