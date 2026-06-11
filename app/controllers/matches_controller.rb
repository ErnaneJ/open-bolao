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
end
