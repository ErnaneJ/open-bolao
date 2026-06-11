puts "Seeding Copa do Mundo 2026..."

super_admin = User.find_by(role: :super_admin)

tournament = Tournament.find_or_initialize_by(name: "Copa do Mundo 2026")
tournament.assign_attributes(
  sport: :football,
  season: "2026",
  status: :active,
  external_provider: :worldcup2026_api,
  created_by: super_admin
)
tournament.save!
puts "Tournament: #{tournament.name}"

# ── Teams from worldcup26.ir (has flag_url + iso2) ──────────────────────────
adapter_wc = ApiProviders::Worldcup2026Adapter.new

begin
  teams_data = adapter_wc.fetch_teams
  puts "Fetched #{teams_data.size} teams from worldcup26.ir"

  team_by_wc_id = {}
  teams_data.each do |td|
    team = Team.find_or_initialize_by(name: td.name)
    team.assign_attributes(
      country_code: td.country_code,
      flag_url: td.flag_url,
      external_provider_id: td.external_id,
      external_provider_name: "worldcup2026"
    )
    team.save! if team.new_record? || team.changed?

    TournamentTeam.find_or_create_by!(tournament: tournament, team: team) do |tt|
      tt.group_name  = td.group_name
      tt.external_id = td.external_id
    end

    team_by_wc_id[td.external_id] = team
  end

  puts "Teams seeded: #{tournament.teams.count}"
rescue => e
  puts "worldcup26.ir teams unavailable (#{e.message})"
end

# ── Matches from TheSportsDB (has correct UTC timestamps) ───────────────────
tsdb = ApiProviders::ThesportsdbAdapter.new
TSDB_LEAGUE = "4429"

begin
  matches_data = tsdb.fetch_matches_for_season("2026", TSDB_LEAGUE)
  puts "Fetched #{matches_data.size} matches from TheSportsDB"

  stage_cache = {}
  stage_for = lambda do |md|
    type  = md.match_type.to_s
    label = case type
            when /final.*round|round.*32/ then "Rodada de 32"
            when /round.*16/              then "Oitavas de Final"
            when /quarter/                then "Quartas de Final"
            when /semi/                   then "Semifinal"
            when /third/                  then "Terceiro Lugar"
            when "final"                  then "Final"
            else
              md.group_name ? "Grupo #{md.group_name}" : "Fase de Grupos"
            end

    stage_cache[label] ||= tournament.stages.find_or_create_by!(name: label) do |s|
      s.stage_type     = label.include?("Grupo") ? :group : :round_of_16
      s.order_position = tournament.stages.count
    end
  end

  matches_data.each do |md|
    home_team = team_by_wc_id.values.find { |t| t.name.downcase == md.home_team_name.downcase } ||
                Team.find_by("name ILIKE ?", md.home_team_name)
    away_team = team_by_wc_id.values.find { |t| t.name.downcase == md.away_team_name.downcase } ||
                Team.find_by("name ILIKE ?", md.away_team_name)
    next unless home_team && away_team

    stage = stage_for.call(md)

    # Deduplicate by external_id + provider
    match = Match.find_or_initialize_by(
      external_tsdb_id:       md.external_tsdb_id,
      external_provider_name: "thesportsdb"
    )
    match.assign_attributes(
      home_team:   home_team,
      away_team:   away_team,
      scheduled_at: md.scheduled_at,  # UTC from TheSportsDB — correct!
      status:      md.status || :scheduled,
      home_score:  md.home_score,
      away_score:  md.away_score,
      stage:       stage,
      tournament:  tournament,
      stream_url:  md.stream_url.presence,  # left empty; set manually when stream goes live
      venue:       md.stadium_name,
      thumb_url:   md.thumb_url
    )
    match.save! if match.new_record? || match.changed?
  end

  puts "Matches seeded: #{tournament.matches.count}"
rescue => e
  puts "TheSportsDB unavailable (#{e.message}), skipping match import."
end

# ── Seed TheSportsDB as default API provider ────────────────────────────────
tsdb_provider = ApiProvider.find_or_initialize_by(name: "TheSportsDB — Copa 2026")
tsdb_provider.assign_attributes(
  provider_type: :thesportsdb,
  base_url:      "https://www.thesportsdb.com/api/v1/json",
  active:        true,
  config:        { "api_key" => "123", "league_id" => "4429" }
)
tsdb_provider.save!
puts "TheSportsDB API provider: #{tsdb_provider.name}"

# ── Configure SyncSchedule for tournament (daily updates) ───────────────────
schedule = SyncSchedule.find_or_initialize_by(
  schedulable: tournament,
  api_provider: tsdb_provider
)
schedule.assign_attributes(
  enabled:               true,
  interval_seconds:      300,        # every 5 min during active window
  active_from:           Time.current.change(hour: 13, min: 0),
  active_until:          Time.current.change(hour: 23, min: 59),
  run_only_on_match_days: false,
  consecutive_failures:  0
)
schedule.save!
puts "SyncSchedule: #{schedule.enabled? ? 'active' : 'inactive'} every #{schedule.interval_seconds}s"
