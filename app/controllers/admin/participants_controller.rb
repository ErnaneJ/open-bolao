class Admin::ParticipantsController < Admin::BaseController
  include Pagy::Backend
  before_action :set_pool
  before_action :set_participant, only: [ :update, :destroy ]

  def index
    skip_authorization
    @pagy, @participants = pagy(
      @pool.pool_participants.includes(:user).order(rank: :asc, joined_at: :asc)
    )
  end

  def update
    skip_authorization
    @participant.update!(status: params[:participant][:status])
    redirect_to admin_pool_participants_path(@pool), notice: t("admin.participants.updated")
  end

  def destroy
    skip_authorization
    @participant.destroy!
    redirect_to admin_pool_participants_path(@pool), notice: t("admin.participants.removed")
  end

  private

  def set_pool
    @pool = current_user.role_super_admin? ? Pool.friendly.find(params[:pool_id]) : current_user.administered_pools.friendly.find(params[:pool_id])
  end

  def set_participant
    @participant = @pool.pool_participants.find(params[:id])
  end
end
