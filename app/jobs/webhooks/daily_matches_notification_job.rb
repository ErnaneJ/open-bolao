module Webhooks
  # Sends a webhook for each active pool that has matches scheduled today,
  # notifying integrations about the day's agenda.
  #
  # Event type: "pool.daily_matches"
  # Payload example:
  #   {
  #     "pool": { "id": 1, "name": "Bolão A", "invite_code": "H98WAWRT",
  #               "admin": "João", "participants_count": 12 },
  #     "matches": [
  #       { "id": 7, "home_team": "Brasil", "away_team": "Argentina",
  #         "scheduled_at": "2026-06-15T18:00:00Z", "stage": "Fase de Grupos",
  #         "venue": "Estádio X", "round_number": 3 },
  #       ...
  #     ],
  #     "match_count": 2,
  #     "date": "2026-06-15"
  #   }
  #
  # Schedule: daily at 8:00 AM BRT (11:00 UTC) via schedule.yml
  class DailyMatchesNotificationJob < ApplicationJob
    queue_as :webhooks

    EVENT_TYPE = "pool.daily_matches"

    def perform(reference_date: nil)
      date = reference_date ? Date.parse(reference_date) : Date.current

      # Find all active pools that have at least one match today
      pools_with_matches = pools_with_matches_on(date)

      Rails.logger.info("DailyMatchesNotification: #{pools_with_matches.size} bolões com jogos em #{date}")
      return if pools_with_matches.empty?

      pools_with_matches.each do |pool, matches|
        # Only dispatch if the pool has active webhook endpoints for this event
        endpoints = pool.webhook_endpoints.for_event(EVENT_TYPE)
        next if endpoints.none?

        payload = build_payload(pool, matches, date)
        key     = "daily_matches_#{pool.id}_#{date}"

        Webhooks::DispatchJob.perform_later(
          event_type:      EVENT_TYPE,
          payload:         payload,
          idempotency_key: key
        )

        Rails.logger.info("DailyMatchesNotification: webhook enfileirado para bolão '#{pool.name}' (#{matches.size} jogo(s))")
      end
    end

    private

    # Returns a Hash { pool => [matches] } for pools with today's scheduled matches
    def pools_with_matches_on(date)
      tz_range = date.beginning_of_day.utc..date.end_of_day.utc

      # Scheduled matches today
      todays_matches = Match.where(scheduled_at: tz_range, status: :scheduled)
                            .includes(:home_team, :away_team, :stage, :tournament)

      result = {}

      # Active, non-finished pools
      Pool.where(status: [:open, :locked])
          .includes(:webhook_endpoints)
          .find_each do |pool|

        pool_matches = matches_for_pool(pool, todays_matches)
        result[pool] = pool_matches if pool_matches.any?
      end

      result
    end

    def matches_for_pool(pool, todays_matches)
      if pool.pool_scope_tournament? && pool.tournament_id.present?
        todays_matches.select { |m| m.tournament_id == pool.tournament_id }
      elsif pool.pool_scope_single_match? && pool.match_id.present?
        # Check if the single match is today
        single = todays_matches.find { |m| m.id == pool.match_id }
        single ? [single] : []
      else
        []
      end
    end

    def build_payload(pool, matches, date)
      {
        "pool" => {
          "id"                 => pool.id,
          "name"               => pool.name,
          "slug"               => pool.slug,
          "invite_code"        => pool.invite_code,
          "admin"              => pool.admin.display_name,
          "participants_count" => pool.pool_participants.active.count
        },
        "matches"     => matches.map { |m| serialize_match(m) },
        "match_count" => matches.size,
        "date"        => date.iso8601
      }
    end

    def serialize_match(match)
      {
        "id"            => match.id,
        "external_id"   => match.external_tsdb_id,
        "home_team"     => match.home_team.name,
        "away_team"     => match.away_team.name,
        "home_team_logo" => match.home_team.display_image_url,
        "away_team_logo" => match.away_team.display_image_url,
        "scheduled_at"  => match.scheduled_at&.iso8601,
        "stage"         => match.stage&.name,
        "round_number"  => match.round_number,
        "venue"         => match.venue,
        "city"          => match.city,
        "tournament"    => match.tournament&.name
      }
    end
  end
end
