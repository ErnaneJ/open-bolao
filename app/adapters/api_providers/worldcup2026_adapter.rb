module ApiProviders
  class Worldcup2026Adapter
    BASE_URL = "https://worldcup26.ir"

    MatchData = Data.define(:external_id, :home_team_name, :away_team_name,
                            :scheduled_at, :status, :home_score, :away_score, :group_name)
    TeamData  = Data.define(:name, :country_code, :flag_url, :group_name)
    StandingData = Data.define(:group_name, :team_name, :points, :played, :won, :drawn, :lost)

    def initialize(api_provider = nil)
      @api_provider = api_provider
    end

    def fetch_matches
      response = get("/get/games")
      Array(response).map { |g| parse_match(g) }.compact
    end

    def fetch_teams
      response = get("/get/teams")
      Array(response).map { |t| parse_team(t) }.compact
    end

    def fetch_standings
      response = get("/get/groups")
      Array(response).flat_map { |group| parse_group(group) }.compact
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
      return [] unless response.success?
      JSON.parse(response.body)
    rescue Faraday::Error, JSON::ParserError => e
      Rails.logger.error("Worldcup2026Adapter error: #{e.message}")
      []
    end

    def connection
      @connection ||= Faraday.new(url: BASE_URL) do |f|
        f.request :retry, max: 3, interval: 1
        f.response :raise_error
        f.adapter Faraday.default_adapter
        f.headers["Accept"] = "application/json"
      end
    end

    def parse_match(game)
      MatchData.new(
        external_id: game["id"]&.to_s,
        home_team_name: game["home_team"] || game["homeTeam"],
        away_team_name: game["away_team"] || game["awayTeam"],
        scheduled_at: parse_datetime(game["datetime"] || game["date"]),
        status: map_status(game["status"]),
        home_score: game["home_score"]&.to_i,
        away_score: game["away_score"]&.to_i,
        group_name: game["group"]
      )
    rescue => e
      Rails.logger.warn("Failed to parse match: #{e.message} — #{game.inspect}")
      nil
    end

    def parse_team(team)
      TeamData.new(
        name: team["name"],
        country_code: team["name"]&.downcase&.slice(0, 3),
        flag_url: team["flag"],
        group_name: team["group"]
      )
    rescue
      nil
    end

    def parse_group(group)
      group_name = group["group"]
      Array(group["teams"]).map do |team|
        StandingData.new(
          group_name: group_name,
          team_name: team["name"],
          points: team["points"]&.to_i || 0,
          played: team["played"]&.to_i || 0,
          won: team["won"]&.to_i || 0,
          drawn: team["drawn"]&.to_i || 0,
          lost: team["lost"]&.to_i || 0
        )
      end
    end

    def fetch_single_match(match_record)
      return [] if match_record.external_id.blank?
      fetch_matches.select { |m| m.external_id == match_record.external_id }
    end

    def parse_datetime(value)
      return nil if value.blank?
      Time.zone.parse(value.to_s)
    rescue
      nil
    end

    def map_status(status)
      case status.to_s.downcase
      when "finished", "full-time", "ft" then :finished
      when "live", "in-play", "1h", "2h", "ht" then :live
      when "postponed" then :postponed
      when "cancelled", "canceled" then :cancelled
      else :scheduled
      end
    end
  end
end
