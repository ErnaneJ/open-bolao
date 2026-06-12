class MatchesController < ApplicationController
  skip_before_action :authenticate_user!, only: [ :show ]

  def show
    skip_authorization
    @match = Match.includes(:home_team, :away_team, :stage, :tournament).find(params[:id])
    @pools = Pool.joins(:pool_matches).where(pool_matches: { match_id: @match.id })
                 .or(Pool.where(match_id: @match.id))
                 .includes(:admin)
                 .order(:name)
    @my_pools = user_signed_in? ? @pools.select { |p| p.pool_participants.active.exists?(user_id: current_user.id) || p.admin_id == current_user.id } : []
  end

  # GET /matches/:id/dashboard_panel
  def dashboard_panel
    skip_authorization
    @match = Match.includes(:home_team, :away_team, :stage, :tournament).find(params[:id])
    @user_pools = user_pools_for_match
    @tips_by_pool = current_user.tips.where(match: @match, pool_id: @user_pools.map(&:id)).index_by(&:pool_id)
    @is_locked = @user_pools.all? { |p| p.tips_locked_for?(@match) }
    existing = @tips_by_pool.values.first
    @consensus_home = existing&.home_score_tip
    @consensus_away = existing&.away_score_tip
    render partial: "matches/dashboard_panel"
  end

  # POST /matches/:id/bulk_tip
  def bulk_tip
    skip_authorization
    @match = Match.find(params[:id])
    home_score = params.dig(:tip, :home_score_tip)
    away_score = params.dig(:tip, :away_score_tip)

    saved = 0
    user_pools_for_match.each do |pool|
      next if pool.tips_locked_for?(@match)
      tip = current_user.tips.find_or_initialize_by(pool: pool, match: @match)
      tip.home_score_tip = home_score
      tip.away_score_tip = away_score
      tip.save
      saved += 1
    end

    @user_pools = user_pools_for_match
    @tips_by_pool = current_user.tips.where(match: @match, pool_id: @user_pools.map(&:id)).index_by(&:pool_id)
    @is_locked = @user_pools.all? { |p| p.tips_locked_for?(@match) }
    @consensus_home = home_score
    @consensus_away = away_score
    @saved_count = saved

    render partial: "matches/dashboard_panel"
  end

  private

  def user_pools_for_match
    match_pool_ids = PoolMatch.where(match_id: @match.id).select(:pool_id)
    tournament_pool_ids = @match.tournament_id.present? ?
      Pool.where(tournament_id: @match.tournament_id).select(:id) : Pool.none

    all_pool_ids = Pool.where(id: match_pool_ids).or(Pool.where(id: tournament_pool_ids)).select(:id)
    Pool.where(id: current_user.pool_participants.active.where(pool_id: all_pool_ids).select(:pool_id))
        .includes(:admin)
  end
end
