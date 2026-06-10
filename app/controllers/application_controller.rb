class ApplicationController < ActionController::Base
  allow_browser versions: :modern
  stale_when_importmap_changes

  include Pundit::Authorization
  include Pagy::Backend

  before_action :authenticate_user!
  before_action :set_locale

  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized

  private

  def set_locale
    I18n.locale = current_user&.locale || I18n.default_locale
  end

  def user_not_authorized
    flash[:alert] = t("errors.not_authorized")
    redirect_back_or_to root_path
  end

  def after_sign_in_path_for(_resource)
    dashboard_path
  end
end
