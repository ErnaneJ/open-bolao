module ApiProviders
  class Worldcup2026Adapter
    BASE_URL = "https://worldcup26.ir"

    MatchData = Data.define(
      :external_id, :home_team_name, :away_team_name, :home_team_external_id,
      :away_team_external_id, :scheduled_at, :status, :home_score, :away_score,
      :group_name, :match_type, :stadium_name
    )
    TeamData = Data.define(:external_id, :name, :country_code, :flag_url, :group_name)
    StandingData = Data.define(:group_name, :team_external_id, :points, :played,
                               :won, :drawn, :lost, :goals_for, :goals_against, :goal_diff)

    def initialize(api_provider = nil)
      @api_provider = api_provider
    end

    def fetch_matches
      response = get("/get/games")
      Array(response["games"]).map { |g| parse_match(g) }.compact
    end

    def fetch_teams
      response = get("/get/teams")
      Array(response["teams"]).map { |t| parse_team(t) }.compact
    end

    def fetch_standings
      response = get("/get/groups")
      Array(response["groups"]).flat_map { |group| parse_group(group) }.compact
    end

    def fetch_stadiums
      response = get("/get/stadiums")
      Array(response["stadiums"])
    end

    def fetch_results(schedulable)
      case schedulable
      when Tournament then fetch_matches
      when Match      then fetch_single_match(schedulable)
      else []
      end
    end

    private

    def get(path)
      response = connection.get(path)
      return {} unless response.success?
      JSON.parse(response.body)
    rescue Faraday::Error, JSON::ParserError => e
      Rails.logger.error("Worldcup2026Adapter error on #{path}: #{e.message}")
      {}
    end

    def connection
      @connection ||= Faraday.new(url: BASE_URL) do |f|
        f.request :retry, max: 2, interval: 1
        f.adapter Faraday.default_adapter
        f.headers["Accept"] = "application/json"
      end
    end

    def parse_match(game)
      MatchData.new(
        external_id:          game["id"].to_s,
        home_team_name:       game["home_team_name_en"].to_s.strip,
        away_team_name:       game["away_team_name_en"].to_s.strip,
        home_team_external_id: game["home_team_id"].to_s,
        away_team_external_id: game["away_team_id"].to_s,
        scheduled_at:         parse_local_date(game["local_date"]),
        status:               map_status(game["finished"], game["time_elapsed"]),
        home_score:           game["home_score"].to_s == "null" ? nil : game["home_score"].to_i,
        away_score:           game["away_score"].to_s == "null" ? nil : game["away_score"].to_i,
        group_name:           game["group"],
        match_type:           game["type"],
        stadium_name:         nil
      )
    rescue => e
      Rails.logger.warn("Worldcup2026Adapter: failed to parse match #{game.inspect}: #{e.message}")
      nil
    end

    def parse_team(team)
      TeamData.new(
        external_id:  team["id"].to_s,
        name:         team["name_en"].to_s.strip,
        country_code: team["iso2"]&.upcase || team["fifa_code"]&.slice(0, 3)&.upcase,
        flag_url:     team["flag"],
        group_name:   team["groups"]
      )
    rescue => e
      Rails.logger.warn("Worldcup2026Adapter: failed to parse team #{team.inspect}: #{e.message}")
      nil
    end

    def parse_group(group)
      group_name = group["name"]
      Array(group["teams"]).map do |entry|
        StandingData.new(
          group_name:      group_name,
          team_external_id: entry["team_id"].to_s,
          points:          entry["pts"].to_i,
          played:          entry["mp"].to_i,
          won:             entry["w"].to_i,
          drawn:           entry["d"].to_i,
          lost:            entry["l"].to_i,
          goals_for:       entry["gf"].to_i,
          goals_against:   entry["ga"].to_i,
          goal_diff:       entry["gd"].to_i
        )
      end
    rescue => e
      Rails.logger.warn("Worldcup2026Adapter: failed to parse group #{group.inspect}: #{e.message}")
      []
    end

    def fetch_single_match(match_record)
      return [] if match_record.external_id.blank?
      fetch_matches.select { |m| m.external_id == match_record.external_id.to_s }
    end

    # API date format: "MM/DD/YYYY HH:MM" in local time (UTC-based assumed)
    def parse_local_date(value)
      return nil if value.blank?
      Time.strptime(value.to_s, "%m/%d/%Y %H:%M").utc
    rescue ArgumentError, TypeError
      nil
    end

    def map_status(finished, time_elapsed)
      return :finished if finished.to_s.upcase == "TRUE"

      case time_elapsed.to_s.downcase
      when "notstarted", "" then :scheduled
      when "1h", "ht", "2h", "live" then :live
      when "finished", "fulltime", "ft" then :finished
      when "postponed" then :postponed
      when "cancelled", "canceled" then :cancelled
      else :scheduled
      end
    end
  end
end
