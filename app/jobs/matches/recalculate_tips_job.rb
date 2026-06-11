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

        pool.tips.where(match: match).includes(:user).find_each do |tip|
          points = Tips::ScoringService.call(tip: tip, match: match, pool: pool)

          Webhooks::DispatchJob.perform_later(
            event_type: "tip.scored",
            payload: {
              "tip" => {
                "user" => tip.user.display_name,
                "home_score_tip" => tip.home_score_tip,
                "away_score_tip" => tip.away_score_tip,
                "points_earned" => points
              }
            },
            owner_ids: pool_id
          )
        end

        Rankings::UpdatePoolRankingJob.perform_later(pool_id)
      end
    end
  end
end
