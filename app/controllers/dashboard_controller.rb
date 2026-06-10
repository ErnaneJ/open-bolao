class DashboardController < ApplicationController
  def index
    skip_authorization
    @participations = current_user.pool_participants
                                  .active
                                  .includes(pool: [:tournament, :match])
                                  .order(rank: :asc)
    @upcoming_matches = upcoming_matches_with_tips
    @recent_notifications = current_user.notifications.recent.limit(5)
  end

  private

  def upcoming_matches_with_tips
    pool_ids = @participations.map(&:pool_id)
    Match.joins(:tips)
         .where(tips: { pool_id: pool_ids, user_id: current_user.id, locked_at: nil })
         .upcoming
         .limit(10)
  end
end
