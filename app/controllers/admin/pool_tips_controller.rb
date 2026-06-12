class Admin::PoolTipsController < Admin::BaseController
  before_action :set_pool

  def new
    skip_authorization
    @tip = Tip.new
    @participants = @pool.pool_participants.active.includes(:user).order("users.display_name")
    @matches = @pool.active_matches.includes(:home_team, :away_team, :stage).order(:scheduled_at)
  end

  def create
    skip_authorization
    user = User.find(tip_params[:user_id])
    match = Match.find(tip_params[:match_id])
    tip = Tip.find_or_initialize_by(pool: @pool, user: user, match: match)
    tip.home_score_tip = tip_params[:home_score_tip]
    tip.away_score_tip = tip_params[:away_score_tip]
    tip.skip_lock_validation = true

    if tip.save
      redirect_to new_admin_pool_tip_path(@pool),
        notice: "Palpite de #{user.display_name} salvo: #{tip.home_score_tip}×#{tip.away_score_tip}"
    else
      @participants = @pool.pool_participants.active.includes(:user).order("users.display_name")
      @matches = @pool.active_matches.includes(:home_team, :away_team, :stage).order(:scheduled_at)
      render :new, status: :unprocessable_entity
    end
  end

  private

  def set_pool
    @pool = current_user.administered_pools.friendly.find(params[:pool_id])
  rescue ActiveRecord::RecordNotFound
    @pool = Pool.friendly.find(params[:pool_id]) if current_user.role_super_admin?
  end

  def tip_params
    params.require(:tip).permit(:user_id, :match_id, :home_score_tip, :away_score_tip)
  end
end
