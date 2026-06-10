class SuperAdmin::BaseController < ApplicationController
  layout "super_admin"
  before_action :require_super_admin!

  private

  def require_super_admin!
    unless current_user&.role_super_admin?
      redirect_to root_path, alert: t("errors.not_authorized")
    end
  end
end
