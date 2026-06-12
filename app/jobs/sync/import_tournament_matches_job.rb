module Sync
  # Imports all matches for a tournament from TheSportsDB.
  #
  # Strategy:
  #   1. Fetch matches via eventsround.php for all rounds (avoids season endpoint caps).
  #   2. ALSO fetch via eventsseason.php as supplemental source.
  #   3. Merge both sets by external_tsdb_id (round data wins for richer metadata).
  #   4. For each match, resolve teams from cache / DB / API (imports missing teams).
  #   5. Create or update Match records.
  class ImportTournamentMatchesJob < ApplicationJob
    queue_as :default
    sidekiq_options retry: 8

    PROVIDER_NAME    = "thesportsdb"
    MAX_ROUNDS       = 60   # covers most domestic leagues (38 rounds) + buffer
    MIN_ROUNDS_CHECK = 10   # always check at least this many rounds

    def perform(tournament_id:, league_id:, season:, created_by_id: nil)
      @tournament   = Tournament.find(tournament_id)
      @adapter      = build_adapter
      @created_by   = User.find_by(id: created_by_id) || User.find_by(role: :super_admin)
      @team_cache   = build_team_cache

      # ── 1. Fetch by round (primary, most complete) ────────────────────
      round_matches, rate_limited = @adapter.fetch_all_matches_by_round(
        season, league_id, max_rounds: MAX_ROUNDS
      )

      if round_matches.empty? && rate_limited
        raise Sync::RateLimitedError, "TheSportsDB rate limit ao buscar rodadas para liga #{league_id}"
      end

      # ── 2. Fetch by season endpoint (supplemental) ────────────────────
      season_matches = @adapter.fetch_matches_for_season(season, league_id)

      # ── 3. Merge — round data wins on duplicate external_id ───────────
      all_matches = merge_by_id(round_matches, season_matches)
      Rails.logger.info("ImportTournamentMatches [#{@tournament.name}]: #{all_matches.size} jogos "\
                        "(#{round_matches.size} por rodada + #{season_matches.size} por temporada)")

      if all_matches.empty?
        Rails.logger.warn("ImportTournamentMatches: nenhum jogo encontrado — verifique league_id=#{league_id} season=#{season}")
        return
      end

      # ── 4. Import matches ─────────────────────────────────────────────
      stage_cache = {}
      imported    = 0
      skipped     = 0

      all_matches.each do |md|
        home_team = resolve_team(md.home_team_external_id, md.home_team_name)
        away_team = resolve_team(md.away_team_external_id, md.away_team_name)

        unless home_team && away_team
          Rails.logger.warn("ImportTournamentMatches: pulando #{md.home_team_name} × #{md.away_team_name}")
          skipped += 1
          next
        end

        stage = resolve_stage(md, stage_cache)

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
          tournament:             @tournament,
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

      Rails.logger.info("ImportTournamentMatches: #{all_matches.size} verificados, #{imported} importados, #{skipped} pulados")

      # ── 5. Ensure SyncSchedule exists ────────────────────────────────
      provider = ApiProvider.find_by(provider_type: :thesportsdb, active: true)
      if provider && @tournament.sync_schedule.nil?
        SyncSchedule.create!(
          schedulable:            @tournament,
          api_provider:           provider,
          enabled:                true,
          interval_seconds:       90,
          active_from:            nil,
          active_until:           nil,
          run_only_on_match_days: false
        )
      end
    end

    private

    # Pre-load all TSDB teams linked to this tournament so we avoid repeated DB lookups
    def build_team_cache
      cache = {}
      @tournament.teams
                 .where.not(external_provider_id: nil)
                 .where(external_provider_name: PROVIDER_NAME)
                 .each { |t| cache[t.external_provider_id] = t }
      cache
    end

    def resolve_team(external_id, name)
      return @team_cache[external_id] if @team_cache[external_id]

      team = Team.find_by(external_provider_id: external_id, external_provider_name: PROVIDER_NAME) ||
             Team.find_by("name ILIKE ?", name)

      if team
        @team_cache[external_id] = team
        # Link to tournament if not already linked
        TournamentTeam.find_or_create_by!(tournament: @tournament, team: team)
        return team
      end

      # Last resort: import from API on the fly
      td = @adapter.fetch_team(external_id)
      return nil unless td

      team = import_team_from_api(td)
      TournamentTeam.find_or_create_by!(tournament: @tournament, team: team)
      @team_cache[external_id] = team
      team
    end

    def import_team_from_api(td)
      team = Team.find_by(external_provider_id: td.external_tsdb_id, external_provider_name: PROVIDER_NAME) ||
             Team.new(external_provider_id: td.external_tsdb_id, external_provider_name: PROVIDER_NAME,
                      created_by: @created_by)
      team.assign_attributes(
        name:          td.name, short_name: td.short_name, country_code: td.country_code,
        flag_url:      td.flag_url.presence || team.flag_url,
        logo_url:      td.logo_url.presence || team.logo_url,
        banner_url:    td.banner_url.presence || team.banner_url,
        fanart_url:    td.fanart_url.presence || team.fanart_url,
        primary_color: td.primary_color.presence || team.primary_color,
        formed_year:   td.formed_year || team.formed_year,
        stadium_name:  td.stadium_name.presence || team.stadium_name,
        description:   td.description.presence || team.description,
        website:       td.website.presence || team.website,
        gender:        td.gender.presence || team.gender
      )
      team.save! if team.new_record? || team.changed?
      team
    end

    # Merge two match arrays: primary wins on duplicate external_tsdb_id
    def merge_by_id(primary, secondary)
      seen = {}
      primary.each  { |m| seen[m.external_tsdb_id] = m }
      secondary.each { |m| seen[m.external_tsdb_id] ||= m }
      seen.values
    end

    def resolve_stage(md, stage_cache)
      label = stage_label(md)
      stage_cache[label] ||= @tournament.stages.find_or_create_by!(name: label) do |s|
        s.stage_type     = classify_stage(label)
        s.order_position = @tournament.stages.count
      end
    end

    def stage_label(md)
      return md.group_name if md.group_name.present? && md.group_name.match?(/group|grupo/i)

      round = md.group_name.presence || md.round_number&.to_s
      return "Rodada #{round}" if round.present?

      case md.match_type.to_s.downcase
      when "round_of_32"  then "Rodada de 32"
      when "round_of_16"  then "Oitavas de Final"
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
