module Sync
  class FetchResultsJob < ApplicationJob
    queue_as :sync

    def perform(schedulable_id, schedulable_type)
      schedulable = schedulable_type.constantize.find_by(id: schedulable_id)
      return unless schedulable

      schedule = SyncSchedule.find_by(schedulable: schedulable)
      return unless schedule&.api_provider

      log = SyncLog.create!(
        sync_schedule: schedule,
        started_at: Time.current,
        status: :failed
      )

      begin
        adapter = build_adapter(schedule.api_provider)
        results = adapter.fetch_results(schedulable)

        stats = process_results(results, schedulable)
        raw_size = results.to_json.bytesize

        log.update!(
          finished_at: Time.current,
          status: :success,
          matches_checked: stats[:checked],
          matches_updated: stats[:updated],
          goals_detected: stats[:goals],
          raw_response_size_bytes: raw_size
        )

        schedule.record_success!
      rescue => e
        log.update!(
          finished_at: Time.current,
          status: :failed,
          error_message: e.message
        )
        schedule.record_failure!(e.message)
        raise
      end
    end

    private

    def build_adapter(api_provider)
      case api_provider.provider_type
      when "worldcup2026"
        ApiProviders::Worldcup2026Adapter.new(api_provider)
      else
        raise "Unknown provider: #{api_provider.provider_type}"
      end
    end

    def process_results(results, schedulable)
      stats = { checked: 0, updated: 0, goals: 0 }

      results.each do |match_data|
        stats[:checked] += 1
        match = find_match(match_data, schedulable)
        next unless match

        previous_home = match.home_score
        previous_away = match.away_score

        changes = detect_changes(match, match_data)
        next if changes.empty?

        match.update!(changes)
        stats[:updated] += 1

        if goal_scored?(previous_home, previous_away, match_data)
          stats[:goals] += total_new_goals(previous_home, previous_away, match_data)
          broadcast_goal(match)
        end

        if match.status_finished? && changes[:status]
          Matches::RecalculateTipsJob.perform_later(match.id)
        end
      end

      stats
    end

    def find_match(match_data, schedulable)
      case schedulable
      when Tournament
        schedulable.matches.find_by(external_id: match_data.external_id)
      when Match
        schedulable
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

    def goal_scored?(prev_home, prev_away, data)
      return false if data.home_score.nil? || data.away_score.nil?
      (data.home_score + data.away_score) > ((prev_home || 0) + (prev_away || 0))
    end

    def total_new_goals(prev_home, prev_away, data)
      (data.home_score + data.away_score) - ((prev_home || 0) + (prev_away || 0))
    end

    def broadcast_goal(match)
      ActionCable.server.broadcast("match_#{match.id}", {
        event: "goal",
        home_score: match.home_score,
        away_score: match.away_score
      })
    end
  end
end
