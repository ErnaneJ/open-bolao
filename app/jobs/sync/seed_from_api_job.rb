module Sync
  class SeedFromApiJob < ApplicationJob
    queue_as :sync

    def perform(tournament_id)
      tournament = Tournament.find(tournament_id)
      adapter = ApiProviders::Worldcup2026Adapter.new

      seed_teams(adapter, tournament)
      seed_matches(adapter, tournament)
    end

    private

    def seed_teams(adapter, tournament)
      adapter.fetch_teams.each do |team_data|
        team = Team.find_or_initialize_by(name: team_data.name)
        team.country_code ||= team_data.country_code
        team.save!

        TournamentTeam.find_or_create_by!(tournament: tournament, team: team) do |tt|
          tt.group_name = team_data.group_name
        end
      end
    end

    def seed_matches(adapter, tournament)
      adapter.fetch_matches.each do |match_data|
        home_team = Team.find_by("name ILIKE ?", match_data.home_team_name)
        away_team = Team.find_by("name ILIKE ?", match_data.away_team_name)
        next unless home_team && away_team

        stage = find_or_create_stage(tournament, match_data.group_name)

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
    end

    def find_or_create_stage(tournament, group_name)
      return nil if group_name.blank?
      tournament.stages.find_or_create_by!(name: group_name) do |s|
        s.stage_type = :group
        s.order_position = tournament.stages.count
      end
    end
  end
end
