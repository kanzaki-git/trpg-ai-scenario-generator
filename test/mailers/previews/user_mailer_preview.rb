class UserMailerPreview < ActionMailer::Preview
  def reset_password_email
    user = User.first || User.new(
      name: "プレビューユーザー",
      email: "preview@example.com"
    )
    user.reset_password_token = "preview-token"

    UserMailer.reset_password_email(user)
  end
end
