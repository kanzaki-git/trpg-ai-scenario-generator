class PasswordResetsController < ApplicationController
  skip_before_action :require_login
  before_action :set_user, only: %i[edit update]

  def new; end

  def create
    user = User.find_by(email: params[:email])
    user&.deliver_reset_password_instructions!

    redirect_to login_path,
                notice: "メールアドレスが登録されている場合、パスワード再設定メールを送信しました"
  end

  def edit; end

  def update
    @user.password_confirmation = password_reset_params[:password_confirmation]

    if @user.change_password(password_reset_params[:password])
      redirect_to login_path, notice: "パスワードを再設定しました"
    else
      flash.now[:alert] = "パスワードを再設定できませんでした"
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def set_user
    @user = User.load_from_reset_password_token(params[:id])

    return if @user

    redirect_to new_password_reset_path,
                alert: "パスワード再設定URLが無効か、有効期限が切れています"
  end

  def password_reset_params
    params.require(:user).permit(:password, :password_confirmation)
  end
end
