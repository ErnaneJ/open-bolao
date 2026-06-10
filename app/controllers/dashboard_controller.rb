class DashboardController < ApplicationController
  def index
    skip_authorization
    @participations = current_user.pool_participants
                                  .active
                                  .includes(pool: [:tournament, :match])
                                  .order(rank: :asc)
    @administered_pools = current_user.administered_pools
                                      .where.not(id: @participations.map(&:pool_id))
                                      .includes(:tournament, :match)
                                      .order(created_at: :desc)
                                      .limit(5)
    @live_matches   = Match.where(status: :live).includes(:home_team, :away_team, :tournament).limit(5)
    @next_matches   = Match.where(status: :scheduled)
                           .where("scheduled_at > ?", Time.current)
                           .order(:scheduled_at)
                           .includes(:home_team, :away_team, :tournament)
                           .limit(8)
    @upcoming_tips  = upcoming_matches_with_tips
  end

  private

  def upcoming_matches_with_tips
    pool_ids = @participations.map(&:pool_id)
    return Match.none if pool_ids.empty?
    Match.joins(:pool_matches)
         .where(pool_matches: { pool_id: pool_ids })
         .where(status: :scheduled)
         .where("scheduled_at > ?", Time.current)
         .order(:scheduled_at)
         .includes(:home_team, :away_team)
         .limit(5)
  rescue
    Match.none
  end
end
