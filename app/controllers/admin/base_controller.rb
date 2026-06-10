class Admin::BaseController < ApplicationController
  layout "admin"
  before_action :require_admin!

  private

  def require_admin!
    unless current_user&.role_admin? || current_user&.role_super_admin?
      redirect_to root_path, alert: t("errors.not_authorized")
    end
  end
end
