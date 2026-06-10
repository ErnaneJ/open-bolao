class SpecialBetsController < ApplicationController
  before_action :set_pool
  before_action :require_participant!

  def index
    skip_authorization
    @special_bets_config = @pool.special_bets_config_with_defaults
    @my_bets = current_user.special_bets.where(pool: @pool).index_by { |b| b.bet_type.to_sym }
    @teams = @pool.tournament&.teams&.by_name || []
  end

  def create
    @bet = @pool.special_bets.find_or_initialize_by(user_id: current_user.id, bet_type: bet_params[:bet_type])
    skip_authorization
    @bet.assign_attributes(bet_params)
    if @bet.save
      respond_to do |format|
        format.turbo_stream
        format.html { redirect_to pool_special_bets_path(@pool) }
      end
    else
      render :index, status: :unprocessable_entity
    end
  end

  def update
    @bet = @pool.special_bets.find_by!(user_id: current_user.id, id: params[:id])
    skip_authorization
    if @bet.update(bet_params)
      respond_to do |format|
        format.turbo_stream
        format.html { redirect_to pool_special_bets_path(@pool) }
      end
    else
      render :index, status: :unprocessable_entity
    end
  end

  private

  def set_pool
    @pool = Pool.friendly.find(params[:pool_id])
  end

  def require_participant!
    unless @pool.pool_participants.active.exists?(user_id: current_user.id)
      redirect_to pool_path(@pool), alert: t("errors.not_participant")
    end
  end

  def bet_params
    params.require(:special_bet).permit(:bet_type, :team_id, :player_name, :integer_value)
  end
end
