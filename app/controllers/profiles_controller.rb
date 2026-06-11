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

    success = if params.dig(:user, :password).present?
      # Devise validates current_password before allowing password change
      @user.update_with_password(profile_params)
    else
      # No password change — strip password fields and use plain update
      @user.update_without_password(
        profile_params.except(:current_password, :password, :password_confirmation)
      )
    end

    if success
      # Map enum key ("pt_br") to I18n locale symbol (:"pt-BR")
      I18n.locale = locale_symbol_for(@user.locale)
      bypass_sign_in(@user)
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

  LOCALE_MAP = { "pt_br" => :"pt-BR", "en" => :en }.freeze

  def locale_symbol_for(enum_key)
    LOCALE_MAP[enum_key.to_s] || I18n.default_locale
  end
end
