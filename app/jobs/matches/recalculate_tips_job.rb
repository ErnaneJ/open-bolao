module Matches
  class RecalculateTipsJob < ApplicationJob
    queue_as :default

    def perform(match_id)
      match = Match.find_by(id: match_id)
      return unless match&.status_finished?

      pool_ids = Tip.where(match: match).distinct.pluck(:pool_id)
      pool_ids.each do |pool_id|
        pool = Pool.find_by(id: pool_id)
        next unless pool

        pool.tips.where(match: match).find_each do |tip|
          Tips::ScoringService.call(tip: tip, match: match, pool: pool)
        end

        Rankings::UpdatePoolRankingJob.perform_later(pool_id)
      end
    end
  end
end
