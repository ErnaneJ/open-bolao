class ProfilesController < ApplicationController
  def show
    skip_authorization
    @user = current_user
  end

  def edit
    skip_authorization
    @user = current_user
  end

  def update
    skip_authorization
    @user = current_user
    if @user.update(profile_params)
      I18n.locale = @user.locale
      redirect_to profile_path, notice: t("profile.updated")
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def profile_params
    params.require(:user).permit(:name, :locale, :time_zone, :avatar,
                                 :password, :password_confirmation, :current_password)
  end
end
