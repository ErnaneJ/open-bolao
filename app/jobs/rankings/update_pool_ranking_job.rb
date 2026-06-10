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
    end
  end
end
