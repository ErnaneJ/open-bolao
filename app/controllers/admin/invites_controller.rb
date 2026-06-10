class Admin::InvitesController < Admin::BaseController
  before_action :set_pool

  def show
    skip_authorization
    @invite_url = join_pool_url(@pool, invite: @pool.invite_code)
    @qr = RQRCode::QRCode.new(@invite_url)
  end

  def update
    skip_authorization
    @pool.update!(invite_code: SecureRandom.alphanumeric(8).upcase)
    redirect_to admin_pool_invite_path(@pool), notice: t("admin.invites.regenerated")
  end

  private

  def set_pool
    @pool = current_user.role_super_admin? ? Pool.friendly.find(params[:pool_id]) : current_user.administered_pools.friendly.find(params[:pool_id])
  end
end
