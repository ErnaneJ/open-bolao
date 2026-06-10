class ApplicationController < ActionController::Base
  allow_browser versions: :modern
  stale_when_importmap_changes

  include Pundit::Authorization
  include Pagy::Backend

  before_action :authenticate_user!
  before_action :set_locale
  before_action :configure_permitted_parameters, if: :devise_controller?

  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized

  private

  def set_locale
    I18n.locale = current_user&.i18n_locale || I18n.default_locale
  end

  def user_not_authorized
    flash[:alert] = t("errors.not_authorized")
    redirect_back_or_to root_path
  end

  def after_sign_in_path_for(_resource)
    dashboard_path
  end

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: [:name])
    devise_parameter_sanitizer.permit(:account_update, keys: [:name, :locale, :time_zone])
  end
end
