require "net/http"
require "json"

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
  teams_data = adapter.fetch_teams
  puts "Fetched #{teams_data.size} teams from API"

  teams_data.each do |team_data|
    team = Team.find_or_initialize_by(name: team_data.name)
    team.save! if team.new_record?

    TournamentTeam.find_or_create_by!(tournament: tournament, team: team) do |tt|
      tt.group_name = team_data.group_name
    end
  end

  puts "Teams seeded: #{tournament.teams.count}"

  matches_data = adapter.fetch_matches
  puts "Fetched #{matches_data.size} matches from API"

  matches_data.each do |match_data|
    home_team = Team.find_by("name ILIKE ?", match_data.home_team_name)
    away_team = Team.find_by("name ILIKE ?", match_data.away_team_name)
    next unless home_team && away_team

    stage = tournament.stages.find_or_create_by!(name: match_data.group_name || "Fase de Grupos") do |s|
      s.stage_type = match_data.group_name ? :group : :round_of_16
      s.order_position = tournament.stages.count
    end

    Match.find_or_initialize_by(external_id: match_data.external_id, tournament: tournament).tap do |m|
      m.home_team = home_team
      m.away_team = away_team
      m.scheduled_at = match_data.scheduled_at
      m.status = match_data.status || :scheduled
      m.home_score = match_data.home_score
      m.away_score = match_data.away_score
      m.stage = stage
      m.save!
    end
  end

  puts "Matches seeded: #{tournament.matches.count}"
rescue => e
  puts "API unavailable (#{e.message}), skipping live seed. Use demo data instead."
end
