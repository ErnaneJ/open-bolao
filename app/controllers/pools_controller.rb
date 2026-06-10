class PoolsController < ApplicationController
  before_action :set_pool, only: [:show, :join, :leave]

  def index
    skip_policy_scope
    @pagy, @pools = pagy(
      policy_scope(Pool).includes(:admin, :tournament).order(created_at: :desc)
    )
  end

  def show
    authorize @pool
    @participant = @pool.pool_participants.find_by(user_id: current_user.id)
    @pagy_ranking, @ranking = pagy(
      @pool.pool_participants.active.ranked.includes(:user), items: 50
    )
    @matches = pool_matches
    @tips_map = current_user.tips.where(pool: @pool).index_by(&:match_id)
  end

  def join
    authorize @pool
    participant = @pool.pool_participants.find_or_initialize_by(user_id: current_user.id)
    if participant.new_record?
      participant.status = :active
      participant.save!
      redirect_to pool_path(@pool), notice: t("pools.joined")
    else
      redirect_to pool_path(@pool), alert: t("pools.already_joined")
    end
  end

  def leave
    authorize @pool
    if @pool.competition_started?
      redirect_to pool_path(@pool), alert: t("pools.cannot_leave_started")
      return
    end
    participant = @pool.pool_participants.find_by!(user_id: current_user.id)
    participant.destroy!
    redirect_to pools_path, notice: t("pools.left")
  end

  # GET /join/:invite_code — preview page before accepting
  def join_by_code
    @pool = Pool.find_by(invite_code: params[:invite_code].upcase)
    if @pool.nil?
      redirect_to pools_path, alert: t("pools.invalid_invite_code")
    elsif @pool.pool_participants.active.exists?(user_id: current_user.id)
      redirect_to pool_path(@pool), notice: t("pools.already_joined")
    end
  end

  # POST /join/:invite_code — accept and join
  def accept_invite
    @pool = Pool.find_by!(invite_code: params[:invite_code].upcase)
    participant = @pool.pool_participants.find_or_initialize_by(user_id: current_user.id)
    if participant.new_record?
      participant.status = :active
      participant.save!
      redirect_to pool_path(@pool), notice: t("pools.joined")
    else
      redirect_to pool_path(@pool), alert: t("pools.already_joined")
    end
  end

  private

  def set_pool
    @pool = Pool.friendly.find(params[:id])
  end

  def pool_matches
    @pool.active_matches
  end
end
