module Pools
  class LockTipsJob < ApplicationJob
    queue_as :scheduler

    def perform
      Pool.open_pools.find_each do |pool|
        lock_minutes = pool.lock_before_minutes || 5
        cutoff = Time.current + lock_minutes.minutes

        matches_starting_soon = pool_matches(pool).where(
          scheduled_at: Time.current..cutoff,
          status: :scheduled
        )

        matches_starting_soon.find_each do |match|
          pool.tips.where(match: match, locked_at: nil).update_all(locked_at: Time.current)
        end
      end
    end

    private

    def pool_matches(pool)
      if pool.tournament_pool?
        pool.tournament.matches
      else
        Match.where(id: pool.match_id)
      end
    end
  end
end
