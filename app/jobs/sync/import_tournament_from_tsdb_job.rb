module Sync
  # Imports a full tournament from TheSportsDB.
  #
  # Strategy:
  #   1. Fetch league info → upsert Tournament with all metadata/images.
  #   2. Fetch all matches by round (eventsround.php) — avoids the 15-match cap.
  #   3. Extract unique teams from match data (idHomeTeam/idAwayTeam) — each team fetched
  #      individually via lookupteam.php to get full metadata + images.
  #   4. Upsert teams (find_or_create by external_tsdb_id, associate by name if unknown).
  #   5. Create/update matches with all available metadata.
  #
  # Usage: Sync::ImportTournamentFromTsdbJob.perform_now(league_id: "4351", season: "2026")
  class RateLimitedError < StandardError; end

  class ImportTournamentFromTsdbJob < ApplicationJob
    queue_as :default
    sidekiq_options retry: 8  # exponential backoff: ~30s, ~2min, ~5min, ~15min, ~45min...

    PROVIDER_NAME = "thesportsdb"

    def perform(league_id:, season: nil, created_by_id: nil)
      @adapter    = build_adapter
      @created_by = User.find_by(id: created_by_id) || User.find_by(role: :super_admin)

      # ── 1. League info ────────────────────────────────────────────────
      league = @adapter.fetch_league(league_id)
      unless league
        Rails.logger.warn("ImportTournamentFromTsdb: league #{league_id} not found")
        return
      end
      season ||= league.current_season || Time.current.year.to_s

      # ── 2. Upsert Tournament with full metadata ───────────────────────
      tournament = Tournament.find_or_initialize_by(name: league.name, season: season)

      # If finding by name+season, also try by external_config to avoid duplicates
      unless tournament.persisted?
        by_config = Tournament.where(
          "external_config @> ?",
          { "tsdb_league_id" => league_id.to_s }.to_json
        ).where(season: season).first
        tournament = by_config if by_config
      end

      tournament.assign_attributes(
        sport:             :football,
        status:            :active,
        external_provider: :thesportsdb,
        external_config:   (tournament.external_config || {}).merge(
          "tsdb_league_id" => league_id.to_s,
          "season"         => season
        ),
        created_by:        @created_by,
        country:           league.country,
        description:       league.description,
        gender:            league.gender,
        website:           league.website,
        formed_year:       league.formed_year,
        logo_url:          league.logo_url.presence    || tournament.logo_url,
        badge_url:         league.badge_url.presence   || tournament.badge_url,
        banner_url:        league.banner_url.presence  || tournament.banner_url,
        fanart_url:        league.fanart_url.presence  || tournament.fanart_url,
        trophy_url:        league.trophy_url.presence  || tournament.trophy_url
      )
      tournament.save!
      Rails.logger.info("ImportTournamentFromTsdb: tournament → #{tournament.name} #{season}")

      # ── 3. Fetch ALL matches by round ─────────────────────────────────
      Rails.logger.info("ImportTournamentFromTsdb: fetching matches by round for season #{season}...")
      matches_data, rate_limited = @adapter.fetch_all_matches_by_round(season, league_id)

      if matches_data.empty? && rate_limited
        raise RateLimitedError, "TheSportsDB rate limit hit for league #{league_id}. Sidekiq will retry automatically."
      end

      if matches_data.empty?
        matches_data = @adapter.fetch_matches_for_season(season, league_id)
        Rails.logger.warn("ImportTournamentFromTsdb: rounds empty, fell back to eventsseason (#{matches_data.size} matches)")
      end

      Rails.logger.info("ImportTournamentFromTsdb: #{matches_data.size} jogos encontrados")

      # ── 4. Upsert teams ───────────────────────────────────────────────
      # Collect unique team IDs from match data and fetch each individually
      # (lookup_all_teams.php returns wrong data for some leagues).
      @team_cache = {}
      team_ids    = matches_data.flat_map { |md|
        [ md.home_team_external_id, md.away_team_external_id ]
      }.uniq.compact.reject(&:blank?)

      Rails.logger.info("ImportTournamentFromTsdb: #{team_ids.size} times únicos, buscando metadados...")

      team_ids.each_with_index do |tid, _idx|
        next if @team_cache[tid]

        td = @adapter.fetch_team(tid)
        unless td
          Rails.logger.warn("ImportTournamentFromTsdb: time #{tid} não encontrado na API")
          next
        end

        team = upsert_team(td)
        TournamentTeam.find_or_create_by!(tournament: tournament, team: team)
        @team_cache[tid] = team
      end

      Rails.logger.info("ImportTournamentFromTsdb: #{@team_cache.size} times sincronizados")

      # ── 5. Create/update matches ──────────────────────────────────────
      stage_cache = {}
      imported    = 0
      skipped     = 0

      matches_data.each do |md|
        home_team = resolve_team(md.home_team_external_id, md.home_team_name)
        away_team = resolve_team(md.away_team_external_id, md.away_team_name)

        unless home_team && away_team
          Rails.logger.warn("ImportTournamentFromTsdb: pulando #{md.home_team_name} × #{md.away_team_name} — times não resolvidos")
          skipped += 1
          next
        end

        stage = resolve_stage(tournament, md, stage_cache)

        match = Match.find_or_initialize_by(
          external_tsdb_id:       md.external_tsdb_id,
          external_provider_name: PROVIDER_NAME
        )
        match.assign_attributes(
          home_team:              home_team,
          away_team:              away_team,
          scheduled_at:           md.scheduled_at,
          status:                 md.status || :scheduled,
          home_score:             md.home_score,
          away_score:             md.away_score,
          home_score_ht:          md.home_score_ht,
          away_score_ht:          md.away_score_ht,
          home_score_et:          md.home_score_et,
          away_score_et:          md.away_score_et,
          home_score_penalties:   md.home_score_penalties,
          away_score_penalties:   md.away_score_penalties,
          stage:                  stage,
          tournament:             tournament,
          venue:                  md.stadium_name,
          city:                   md.city,
          thumb_url:              md.thumb_url,
          stream_url:             md.stream_url.presence,
          season:                 md.season,
          round_number:           md.round_number,
          referee:                md.referee,
          attendance:             md.attendance,
          external_id:            md.external_tsdb_id,
          external_provider_name: PROVIDER_NAME
        )
        if match.new_record? || match.changed?
          match.save!
          imported += 1
        end
      end

      Rails.logger.info("ImportTournamentFromTsdb: #{matches_data.size} verificados, #{imported} importados, #{skipped} pulados")

      # ── 6. SyncSchedule ───────────────────────────────────────────────
      provider = ApiProvider.find_by(provider_type: :thesportsdb, active: true)
      if provider && tournament.sync_schedule.nil?
        SyncSchedule.create!(
          schedulable:            tournament,
          api_provider:           provider,
          enabled:                true,
          interval_seconds:       300,
          active_from:            Time.current.change(hour: 12),
          active_until:           Time.current.change(hour: 23, min: 59),
          run_only_on_match_days: false
        )
      end
    end

    private

    def resolve_team(external_id, name)
      return @team_cache[external_id] if @team_cache[external_id]

      team = Team.find_by(external_provider_id: external_id, external_provider_name: PROVIDER_NAME) ||
             Team.find_by("name ILIKE ?", name)
      @team_cache[external_id] = team if team
      team
    end

    def upsert_team(td)
      team = Team.find_by(external_provider_id: td.external_tsdb_id, external_provider_name: PROVIDER_NAME)

      unless team
        # Try to associate an existing team by name
        existing = Team.find_by("name ILIKE ?", td.name)
        if existing && existing.external_provider_id.blank?
          existing.update!(
            external_provider_id:   td.external_tsdb_id,
            external_provider_name: PROVIDER_NAME
          )
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
        logo_url:      td.logo_url.presence   || team.logo_url,
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

    def resolve_stage(tournament, md, stage_cache)
      label = stage_label(md)
      stage_cache[label] ||= tournament.stages.find_or_create_by!(name: label) do |s|
        s.stage_type     = classify_stage(label)
        s.order_position = tournament.stages.count
      end
    end

    def stage_label(md)
      return md.group_name if md.group_name.present? && md.group_name.match?(/group|grupo/i)

      round = md.group_name.presence || md.round_number&.to_s
      return "Rodada #{round}" if round.present?

      case md.match_type.to_s.downcase
      when "round_of_32" then "Rodada de 32"
      when "round_of_16" then "Oitavas de Final"
      when "quarterfinal" then "Quartas de Final"
      when "semifinal"    then "Semifinal"
      when "third_place"  then "Terceiro Lugar"
      when "final"        then "Final"
      else "Fase de Grupos"
      end
    end

    def classify_stage(label)
      case label.downcase
      when /rodada|grupo|group|fase/ then :group
      when /oitava/                  then :round_of_16
      when /quarta/                  then :quarterfinal
      when /semi/                    then :semifinal
      when /terceiro/                then :third_place
      when /final/                   then :final
      else :group
      end
    end

    def build_adapter
      provider = ApiProvider.find_by(provider_type: :thesportsdb, active: true)
      ApiProviders::ThesportsdbAdapter.new(provider)
    end
  end
end
