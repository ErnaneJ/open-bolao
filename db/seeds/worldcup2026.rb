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

adapter = ApiProviders::Worldcup2026Adapter.new

begin
  # --- Teams ---
  teams_data = adapter.fetch_teams
  puts "Fetched #{teams_data.size} teams from API"

  # external_id → Team record map for match seeding
  team_by_external_id = {}

  teams_data.each do |td|
    team = Team.find_or_initialize_by(name: td.name)
    team.assign_attributes(
      country_code: td.country_code,
      flag_url:     td.flag_url
    ) if team.respond_to?(:country_code)
    team.save! if team.new_record? || team.changed?

    TournamentTeam.find_or_create_by!(tournament: tournament, team: team) do |tt|
      tt.group_name   = td.group_name
      tt.external_id  = td.external_id
    end

    team_by_external_id[td.external_id] = team
  end

  puts "Teams seeded: #{tournament.teams.count}"

  # --- Stage helpers ---
  stage_for = lambda do |match_data|
    if match_data.match_type == "group"
      label = match_data.group_name ? "Grupo #{match_data.group_name}" : "Fase de Grupos"
      tournament.stages.find_or_create_by!(name: label) do |s|
        s.stage_type     = :group
        s.order_position = tournament.stages.count
      end
    else
      type_map = {
        "round_of_32"  => [:round_of_32,  "Rodada de 32"],
        "round_of_16"  => [:round_of_16,  "Oitavas de Final"],
        "quarter_final"=> [:quarterfinal, "Quartas de Final"],
        "semi_final"   => [:semifinal,    "Semifinais"],
        "third_place"  => [:third_place,  "Terceiro Lugar"],
        "final"        => [:final,        "Final"]
      }
      stype, sname = type_map[match_data.match_type] || [:round_of_16, match_data.match_type.to_s.humanize]
      tournament.stages.find_or_create_by!(name: sname) do |s|
        s.stage_type     = stype
        s.order_position = tournament.stages.count
      end
    end
  end

  # --- Matches ---
  matches_data = adapter.fetch_matches
  puts "Fetched #{matches_data.size} matches from API"

  matches_data.each do |md|
    home_team = team_by_external_id[md.home_team_external_id] ||
                Team.find_by("name ILIKE ?", md.home_team_name)
    away_team = team_by_external_id[md.away_team_external_id] ||
                Team.find_by("name ILIKE ?", md.away_team_name)
    next unless home_team && away_team

    stage = stage_for.call(md)

    Match.find_or_initialize_by(external_id: md.external_id, tournament: tournament).tap do |m|
      m.home_team   = home_team
      m.away_team   = away_team
      m.scheduled_at = md.scheduled_at
      m.status      = md.status || :scheduled
      m.home_score  = md.home_score
      m.away_score  = md.away_score
      m.stage       = stage
      m.save!
    end
  end

  puts "Matches seeded: #{tournament.matches.count}"
rescue => e
  puts "API unavailable (#{e.message}), skipping live seed."
end

# Seed TheSportsDB as default API provider
ApiProvider.find_or_create_by!(name: "TheSportsDB — Copa 2026") do |ap|
  ap.provider_type = "thesportsdb"
  ap.base_url      = "https://www.thesportsdb.com/api/v1/json"
  ap.active        = true
  ap.config        = { "api_key" => "123", "league_id" => "4429" }
end

puts "TheSportsDB API provider seeded."
