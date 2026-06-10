class HomeController < ApplicationController
  skip_before_action :authenticate_user!

  def index
    skip_authorization
    redirect_to dashboard_path if user_signed_in?
  end
end
