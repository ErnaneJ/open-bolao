class NotificationsController < ApplicationController
  include Pagy::Backend

  def index
    skip_authorization
    @pagy, @notifications = pagy(current_user.notifications.recent)
  end

  def update
    @notification = current_user.notifications.find(params[:id])
    skip_authorization
    @notification.mark_as_read!
    respond_to do |format|
      format.turbo_stream
      format.html { redirect_back_or_to notifications_path }
    end
  end
end
