class PoolsController < ApplicationController
  before_action :set_pool, only: [:show, :join, :leave]

  def index
    skip_policy_scope
    @pools = policy_scope(Pool).includes(:admin, :tournament).open_pools.order(created_at: :desc)
    @pools = Pagy::Backend.instance_method(:pagy).bind(self).call(@pools)
  end

  def show
    authorize @pool
    @participant = @pool.pool_participants.find_by(user_id: current_user.id)
    @ranking = @pool.pool_participants.active.ranked.includes(:user).limit(20)
    @matches = pool_matches
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
    participant = @pool.pool_participants.find_by!(user_id: current_user.id)
    participant.destroy!
    redirect_to pools_path, notice: t("pools.left")
  end

  private

  def set_pool
    @pool = Pool.friendly.find(params[:id])
  end

  def pool_matches
    if @pool.tournament_pool?
      @pool.tournament.matches.includes(:home_team, :away_team, :stage).order(:scheduled_at)
    else
      [@pool.match]
    end
  end
end
