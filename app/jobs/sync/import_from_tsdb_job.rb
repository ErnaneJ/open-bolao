module Sync
  class ImportFromTsdbJob < ApplicationJob
    queue_as :default

    PROVIDER_NAME = "thesportsdb"
    LEAGUE_ID     = "4429"
    SEASON        = "2026"

    def perform(season: SEASON, league_id: LEAGUE_ID)
      provider = ApiProvider.find_by(provider_type: :thesportsdb, active: true)
      return Rails.logger.warn("ImportFromTsdbJob: no active TheSportsDB provider") unless provider

      adapter = ApiProviders::ThesportsdbAdapter.new(provider)
      tournament = Tournament.find_by("name ILIKE ?", "%Copa%2026%") ||
                   Tournament.find_by(external_provider: :worldcup2026_api)
      return Rails.logger.warn("ImportFromTsdbJob: Copa 2026 tournament not found") unless tournament

      # Sync teams
      teams_data = adapter.fetch_teams(league_id)
      team_cache = {}
      teams_data.each do |td|
        team = Team.find_or_initialize_by(
          external_provider_id: td.external_tsdb_id,
          external_provider_name: PROVIDER_NAME
        )
        team.assign_attributes(name: td.name, short_name: td.short_name,
                               country_code: td.country_code)
        team.save! if team.new_record? || team.changed?
        TournamentTeam.find_or_create_by!(tournament: tournament, team: team)
        team_cache[td.external_tsdb_id] = team
      end

      # Sync matches
      matches_data = adapter.fetch_matches_for_season(season, league_id)
      updated = 0

      matches_data.each do |md|
        home_team = team_cache[md.home_team_external_id] ||
                    Team.find_by("name ILIKE ?", md.home_team_name)
        away_team = team_cache[md.away_team_external_id] ||
                    Team.find_by("name ILIKE ?", md.away_team_name)
        next unless home_team && away_team

        match = Match.find_or_initialize_by(
          external_tsdb_id: md.external_tsdb_id,
          external_provider_name: PROVIDER_NAME
        )

        changed = match.new_record? ||
                  match.status.to_s != md.status.to_s ||
                  match.home_score != md.home_score ||
                  match.away_score != md.away_score

        if changed
          match.assign_attributes(
            home_team:              home_team,
            away_team:              away_team,
            scheduled_at:           md.scheduled_at,
            status:                 md.status || :scheduled,
            home_score:             md.home_score,
            away_score:             md.away_score,
            tournament:             tournament,
            stream_url:             md.stream_url.presence
          )
          match.save!
          updated += 1

          # Trigger recalculation if finished
          if md.status == :finished
            pools_for_match(match).each do |pool|
              Matches::RecalculateTipsJob.perform_later(match.id)
            end
          end
        end
      end

      Rails.logger.info("ImportFromTsdbJob: #{matches_data.size} checked, #{updated} updated")
    end

    private

    def pools_for_match(match)
      Pool.joins(:pool_matches).where(pool_matches: { match_id: match.id })
          .or(Pool.where(tournament_id: match.tournament_id))
    end
  end
end
