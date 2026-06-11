module Sync
  # Runs daily in the early morning to refresh all active tournaments for the
  # current year: updates matches (scores, schedule), team metadata (logos, etc.),
  # and links any new matches/teams that appeared since the last import.
  #
  # Only processes tournaments with:
  #   - external_provider = :thesportsdb
  #   - season matching the current year
  #   - status != :finished
  #
  # Schedule: 3:00 AM BRT (06:00 UTC) via schedule.yml
  class DailyRefreshJob < ApplicationJob
    queue_as :default
    sidekiq_options retry: 2

    def perform
      current_year = Date.current.year.to_s

      tournaments = Tournament.where(
        external_provider: :thesportsdb,
        status:            [:draft, :active]
      ).where(season: current_year)

      Rails.logger.info("DailyRefresh: #{tournaments.count} torneio(s) para atualizar (#{current_year})")

      tournaments.each do |tournament|
        league_id = tournament.external_config&.dig("tsdb_league_id")
        next unless league_id.present?

        Rails.logger.info("DailyRefresh: processando #{tournament.name} (#{tournament.season})")

        # 1. Refresh match data (new matches, updated scores, schedule changes)
        Sync::ImportTournamentMatchesJob.perform_later(
          tournament_id: tournament.id,
          league_id:     league_id,
          season:        tournament.season || current_year
        )

        # 2. Refresh team metadata (logos, stadium info, etc.)
        # Small delay so team job runs after matches (teams discovered from match data)
        Sync::ImportTournamentTeamsJob.set(wait: 30.minutes).perform_later(
          tournament_id: tournament.id,
          league_id:     league_id,
          season:        tournament.season || current_year
        )
      end

      Rails.logger.info("DailyRefresh: #{tournaments.count * 2} jobs enfileirados")
    end
  end
end
