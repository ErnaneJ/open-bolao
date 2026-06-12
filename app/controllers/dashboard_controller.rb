class DashboardController < ApplicationController
  def index
    skip_authorization
    @participations = current_user.pool_participants
                                  .active
                                  .includes(pool: [ :tournament, :match ])
                                  .order(rank: :asc)
    @administered_pools = current_user.administered_pools
                                      .where.not(id: @participations.map(&:pool_id))
                                      .includes(:tournament, :match)
                                      .order(created_at: :desc)
                                      .limit(5)
    @live_matches = Match.where(status: :live).includes(:home_team, :away_team, :tournament).limit(5)

    pool_ids = (@participations.map(&:pool_id) + @administered_pools.map(&:id)).uniq
    @next_matches = if pool_ids.any?
      match_ids = PoolMatch.where(pool_id: pool_ids).select(:match_id)
      Match.where(id: match_ids)
           .where(status: :scheduled)
           .where("scheduled_at > ?", Time.current)
           .order(:scheduled_at)
           .includes(:home_team, :away_team, :tournament)
    else
      Match.none
    end
  end
end
