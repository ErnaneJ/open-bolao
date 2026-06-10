module Sync
  class FetchResultsJob < ApplicationJob
    queue_as :sync

    def perform(schedulable_id, schedulable_type)
      schedulable = schedulable_type.constantize.find_by(id: schedulable_id)
      return unless schedulable

      schedule = SyncSchedule.find_by(schedulable: schedulable)
      return unless schedule&.api_provider

      log = SyncLog.create!(sync_schedule: schedule, started_at: Time.current, status: :failed)

      begin
        adapter = build_adapter(schedule.api_provider)
        results = adapter.fetch_results(schedulable)
        stats   = process_results(results, schedulable)

        log.update!(
          finished_at: Time.current,
          status: :success,
          matches_checked: stats[:checked],
          matches_updated: stats[:updated],
          goals_detected: stats[:goals],
          raw_response_size_bytes: results.to_json.bytesize
        )
        schedule.record_success!
      rescue => e
        log.update!(finished_at: Time.current, status: :failed, error_message: e.message)
        schedule.record_failure!(e.message)
        raise
      end
    end

    private

    def build_adapter(api_provider)
      case api_provider.provider_type
      when "worldcup2026" then ApiProviders::Worldcup2026Adapter.new(api_provider)
      else raise "Unknown provider: #{api_provider.provider_type}"
      end
    end

    def process_results(results, schedulable)
      stats = { checked: 0, updated: 0, goals: 0 }

      results.each do |match_data|
        stats[:checked] += 1
        match = find_match(match_data, schedulable)
        next unless match

        prev_home   = match.home_score
        prev_away   = match.away_score
        prev_status = match.status

        changes = detect_changes(match, match_data)
        next if changes.empty?

        match.update!(changes)
        stats[:updated] += 1

        handle_status_change(match, prev_status, changes[:status], schedulable)

        if goal_scored?(prev_home, prev_away, match_data)
          new_goals = total_new_goals(prev_home, prev_away, match_data)
          stats[:goals] += new_goals
          on_goal(match, new_goals)
        end
      end

      stats
    end

    def find_match(match_data, schedulable)
      case schedulable
      when Tournament then schedulable.matches.find_by(external_id: match_data.external_id)
      when Match      then schedulable
      end
    end

    def detect_changes(match, data)
      changes = {}
      changes[:home_score] = data.home_score if data.home_score != match.home_score
      changes[:away_score] = data.away_score if data.away_score != match.away_score
      if data.status && Match.statuses[data.status.to_s] && data.status.to_s != match.status
        changes[:status] = data.status
      end
      changes
    end

    # ── Event handlers ──────────────────────────────────────────────────

    def handle_status_change(match, prev_status, new_status_value, schedulable)
      return unless new_status_value

      new_status = new_status_value.to_s

      if new_status == "live" && prev_status != "live"
        on_match_started(match)
      end

      if new_status == "finished" && prev_status != "finished"
        on_match_finished(match, schedulable)
      end
    end

    def on_goal(match, count)
      # Broadcast to MatchChannel
      ActionCable.server.broadcast("match_#{match.id}", {
        event: "goal",
        home_score: match.home_score,
        away_score: match.away_score,
        home_team: match.home_team.name,
        away_team: match.away_team.name
      })

      # Notify all pool participants watching this match
      pools_for_match(match).each do |pool|
        pool.pool_participants.active.includes(:user).each do |pp|
          Notifications::BroadcastJob.perform_later(
            user_id: pp.user_id,
            kind: "goal",
            title: "⚽ Gol em #{match.home_team.name} × #{match.away_team.name}",
            body: "Placar: #{match.home_score} × #{match.away_score}",
            notifiable_type: "Match",
            notifiable_id: match.id
          )
        end
      end
    end

    def on_match_started(match)
      ActionCable.server.broadcast("match_#{match.id}", {
        event: "match_started",
        home_team: match.home_team.name,
        away_team: match.away_team.name
      })

      pools_for_match(match).each do |pool|
        # Auto-lock tips for this match in this pool
        pool.tips.where(match: match, locked_at: nil).update_all(locked_at: Time.current)

        pool.pool_participants.active.each do |pp|
          Notifications::BroadcastJob.perform_later(
            user_id: pp.user_id,
            kind: "match_starting",
            title: "🏁 Jogo começou!",
            body: "#{match.home_team.name} × #{match.away_team.name} acabou de começar.",
            notifiable_type: "Match",
            notifiable_id: match.id
          )
        end
      end
    end

    def on_match_finished(match, schedulable)
      # Recalculate tips for all pools containing this match
      pools_for_match(match).each do |pool|
        Matches::RecalculateTipsJob.perform_later(match.id)
      end

      ActionCable.server.broadcast("match_#{match.id}", {
        event: "match_finished",
        home_score: match.home_score,
        away_score: match.away_score
      })

      pools_for_match(match).each do |pool|
        pool.pool_participants.active.each do |pp|
          Notifications::BroadcastJob.perform_later(
            user_id: pp.user_id,
            kind: "match_finished",
            title: "🔔 Jogo encerrado",
            body: "#{match.home_team.name} #{match.home_score} × #{match.away_score} #{match.away_team.name}",
            notifiable_type: "Match",
            notifiable_id: match.id
          )
        end

        check_pool_finished(pool)
      end
    end

    def check_pool_finished(pool)
      return unless pool.pool_scope_tournament?
      return unless pool.tournament.present?

      all_matches = pool.tournament.matches
      return unless all_matches.any?
      return unless all_matches.all? { |m| m.status_finished? || m.status_cancelled? }

      # All matches done — finalize pool if still open/locked
      return unless pool.status_open? || pool.status_locked?

      pool.update!(status: :finished)

      # Broadcast final ranking
      ActionCable.server.broadcast("ranking_pool_#{pool.id}", { event: "pool_finished" })

      # Notify all participants with their final rank
      pool.pool_participants.active.ranked.includes(:user).each do |pp|
        Notifications::BroadcastJob.perform_later(
          user_id: pp.user_id,
          kind: "pool_finished",
          title: "🏆 #{pool.name} encerrado!",
          body: "Você terminou em #{pp.rank}º lugar com #{pp.total_points} pontos.",
          notifiable_type: "Pool",
          notifiable_id: pool.id
        )
      end
    end

    # ── Helpers ─────────────────────────────────────────────────────────

    def pools_for_match(match)
      if match.tournament_id.present?
        Pool.where(tournament_id: match.tournament_id)
            .or(Pool.where(match_id: match.id))
      else
        Pool.where(match_id: match.id)
      end
    end

    def goal_scored?(prev_home, prev_away, data)
      return false if data.home_score.nil? || data.away_score.nil?
      (data.home_score + data.away_score) > ((prev_home || 0) + (prev_away || 0))
    end

    def total_new_goals(prev_home, prev_away, data)
      (data.home_score + data.away_score) - ((prev_home || 0) + (prev_away || 0))
    end
  end
end
