module Sync
  # Refreshes team metadata (logo, badge, fanart, stadium, etc.) for all teams
  # that are already linked to this tournament via match data.
  #
  # IMPORTANT: lookup_all_teams.php is intentionally NOT used here because it
  # returns wrong data for several leagues (e.g. World Cup returns English clubs).
  # Team IDs are always derived from actual match data — either from the DB
  # (if matches were imported first) or from the API match endpoints (round/season).
  #
  # Recommended order: "Importar jogos" first, then "Importar times".
  class ImportTournamentTeamsJob < ApplicationJob
    queue_as :default
    sidekiq_options retry: 5

    PROVIDER_NAME = "thesportsdb"

    def perform(tournament_id:, league_id:, season: nil, created_by_id: nil)
      @tournament  = Tournament.find(tournament_id)
      @adapter     = build_adapter
      @created_by  = User.find_by(id: created_by_id) || User.find_by(role: :super_admin)
      season     ||= @tournament.season || Time.current.year.to_s

      # ── 1. Collect team IDs — NEVER from lookup_all_teams.php ────────
      db_ids  = team_ids_from_db_matches
      api_ids = db_ids.empty? ? discover_ids_from_api(league_id, season) : []
      all_ids = (db_ids + api_ids).uniq.compact.reject(&:blank?)

      if all_ids.empty?
        Rails.logger.warn("ImportTournamentTeams [#{@tournament.name}]: nenhum ID encontrado. " \
                          "Importe os jogos primeiro (etapa 3) para que os times possam ser descobertos.")
        return
      end

      Rails.logger.info("ImportTournamentTeams [#{@tournament.name}]: #{all_ids.size} IDs " \
                        "(#{db_ids.size} do DB + #{api_ids.size} descobertos da API)")

      # ── 2. Fetch full metadata for each team ─────────────────────────
      failed_ids = []

      all_ids.each do |tid|
        td = @adapter.fetch_team(tid)
        if td
          team = upsert_team(td)
          TournamentTeam.find_or_create_by!(tournament: @tournament, team: team)
        else
          failed_ids << tid
          Rails.logger.warn("ImportTournamentTeams: time #{tid} falhou (1ª tentativa)")
        end
      end

      # ── 3. Retry failures ─────────────────────────────────────────────
      if failed_ids.any?
        Rails.logger.info("ImportTournamentTeams: retrying #{failed_ids.size} times after 10s...")
        sleep 10

        failed_ids.each do |tid|
          td = @adapter.fetch_team(tid)
          if td
            team = upsert_team(td)
            TournamentTeam.find_or_create_by!(tournament: @tournament, team: team)
          else
            Rails.logger.warn("ImportTournamentTeams: time #{tid} falhou definitivamente")
          end
        end
      end

      Rails.logger.info("ImportTournamentTeams: concluído — #{@tournament.tournament_teams.count} times no torneio")
    end

    private

    # Team IDs from teams already linked to this tournament's matches in the DB.
    # These always come from eventsround.php / eventsseason.php match data — correct.
    def team_ids_from_db_matches
      team_ids = @tournament.matches.pluck(:home_team_id, :away_team_id).flatten.compact.uniq
      Team.where(id: team_ids, external_provider_name: PROVIDER_NAME)
          .pluck(:external_provider_id).compact
    end

    # Fallback when no matches are in DB yet: fetch match endpoints to extract team IDs.
    # Uses eventsround.php + eventsseason.php — never lookup_all_teams.php.
    def discover_ids_from_api(league_id, season)
      Rails.logger.info("ImportTournamentTeams: nenhuma partida no DB, descobrindo IDs via API match data...")
      round_matches, _ = @adapter.fetch_all_matches_by_round(season, league_id)
      season_matches   = @adapter.fetch_matches_for_season(season, league_id)

      (round_matches + season_matches)
        .flat_map { |md| [ md.home_team_external_id, md.away_team_external_id ] }
        .uniq.compact.reject(&:blank?)
    end

    def upsert_team(td)
      team = Team.find_by(external_provider_id: td.external_tsdb_id, external_provider_name: PROVIDER_NAME)

      unless team
        existing = Team.find_by("name ILIKE ?", td.name)
        if existing && existing.external_provider_id.blank?
          existing.update!(external_provider_id: td.external_tsdb_id, external_provider_name: PROVIDER_NAME)
          team = existing
        end
      end

      team ||= Team.new(
        external_provider_id:   td.external_tsdb_id,
        external_provider_name: PROVIDER_NAME,
        created_by:             @created_by
      )

      team.assign_attributes(
        name:          td.name,
        short_name:    td.short_name,
        country_code:  td.country_code,
        logo_url:      td.logo_url.presence    || team.logo_url,
        flag_url:      td.flag_url.presence    || team.flag_url,
        banner_url:    td.banner_url.presence  || team.banner_url,
        fanart_url:    td.fanart_url.presence  || team.fanart_url,
        primary_color: td.primary_color.presence || team.primary_color,
        formed_year:   td.formed_year          || team.formed_year,
        stadium_name:  td.stadium_name.presence || team.stadium_name,
        description:   td.description.presence  || team.description,
        website:       td.website.presence      || team.website,
        gender:        td.gender.presence       || team.gender
      )
      team.save! if team.new_record? || team.changed?
      team
    end

    def build_adapter
      provider = ApiProvider.find_by(provider_type: :thesportsdb, active: true)
      ApiProviders::ThesportsdbAdapter.new(provider)
    end
  end
end
