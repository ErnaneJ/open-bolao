module Rankings
  class UpdatePoolRankingJob < ApplicationJob
    queue_as :default

    def perform(pool_id)
      pool = Pool.find_by(id: pool_id)
      return unless pool

      Rankings::UpdatePoolRankingService.call(pool: pool)

      ActionCable.server.broadcast("ranking_pool_#{pool.id}", {
        event: "ranking_updated",
        pool_id: pool.id
      })

      participants = pool.pool_participants.active.includes(:user).order(rank: :asc)

      leader = participants.first&.user&.display_name
      Webhooks::DispatchJob.perform_later(
        event_type: "pool.ranking_updated",
        payload: {
          "pool" => {
            "id" => pool.id,
            "name" => pool.name
          },
          "leader" => leader,
          "ranking" => participants.map { |p|
            {
              "user" => p.user.display_name,
              "rank" => p.rank,
              "total_points" => p.total_points,
              "trend" => p.rank_trend
            }
          }
        },
        owner_ids: pool.id
      )
    end
  end
end
