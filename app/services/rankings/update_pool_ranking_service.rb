module Rankings
  class UpdatePoolRankingService
    def self.call(pool:)
      new(pool: pool).call
    end

    def initialize(pool:)
      @pool = pool
    end

    def call
      previous_ranks = snapshot_current_ranks
      recalculate_totals
      assign_ranks(previous_ranks)
    end

    private

    attr_reader :pool

    def snapshot_current_ranks
      pool.pool_participants.active.pluck(:user_id, :rank).to_h
    end

    def recalculate_totals
      totals = pool.tips
                   .scored
                   .group(:user_id)
                   .sum(:points_earned)

      pool.pool_participants.active.each do |participant|
        special_points = pool.special_bets
                             .where(user_id: participant.user_id)
                             .sum(:points_earned)
        total = (totals[participant.user_id] || 0) + special_points
        participant.update_column(:total_points, total)
      end
    end

    def assign_ranks(previous_ranks)
      sorted = pool.pool_participants
                   .active
                   .order(total_points: :desc, joined_at: :asc)

      sorted.each_with_index do |participant, idx|
        new_rank = idx + 1
        prev_rank = previous_ranks[participant.user_id]

        trend = if prev_rank.nil? then :same
                elsif new_rank < prev_rank then :up
                elsif new_rank > prev_rank then :down
                else :same
                end

        participant.update_columns(
          rank: new_rank,
          rank_previous: prev_rank,
          rank_trend: PoolParticipant.rank_trends[trend]
        )
      end
    end
  end
end
