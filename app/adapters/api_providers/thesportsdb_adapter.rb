module ApiProviders
  class ThesportsdbAdapter
    BASE_URL  = "https://www.thesportsdb.com"
    FREE_KEY  = "3"
    PAID_KEY  = "123"
    WC_LEAGUE = "4429"

    MatchData  = Data.define(:external_id, :external_tsdb_id, :home_team_name,
                              :away_team_name, :home_team_external_id, :away_team_external_id,
                              :scheduled_at, :status, :home_score, :away_score,
                              :group_name, :match_type, :stadium_name,
                              :thumb_url, :stream_url, :season, :round)
    TeamData   = Data.define(:external_tsdb_id, :name, :short_name, :country_code,
                              :flag_url, :logo_url, :primary_color)
    LeagueData = Data.define(:external_tsdb_id, :name, :country, :sport, :formed_year,
                              :current_season, :logo_url, :badge_url)

    def initialize(api_provider = nil)
      @api_provider = api_provider
      @api_key = api_provider&.config&.dig("api_key") || PAID_KEY
    end

    # ── League data ──────────────────────────────────────────────────────
    def fetch_league(league_id = WC_LEAGUE)
      res = get("lookupleague.php", id: league_id)
      arr = Array(res["leagues"])
      return nil if arr.empty?
      parse_league(arr.first)
    end

    def fetch_seasons(league_id = WC_LEAGUE)
      res = get("search_all_seasons.php", id: league_id)
      Array(res["seasons"]).map { |s| s["strSeason"] }.compact
    end

    # ── Matches ──────────────────────────────────────────────────────────
    def fetch_matches_for_season(season, league_id = WC_LEAGUE)
      res = get("eventsseason.php", id: league_id, s: season)
      Array(res["events"]).map { |e| parse_match(e) }.compact
    end

    def fetch_live_matches(league_id = WC_LEAGUE)
      res = get("eventslive.php")
      Array(res["events"]).select { |e| e["idLeague"] == league_id.to_s }
                          .map { |e| parse_match(e) }.compact
    end

    def fetch_next_matches(league_id = WC_LEAGUE, count = 15)
      res = get("eventsnextleague.php", id: league_id)
      Array(res["events"]).first(count).map { |e| parse_match(e) }.compact
    end

    def fetch_last_matches(league_id = WC_LEAGUE, count = 15)
      res = get("eventspastleague.php", id: league_id)
      Array(res["events"]).first(count).map { |e| parse_match(e) }.compact
    end

    def fetch_match(event_id)
      res = get("lookupevent.php", id: event_id)
      arr = Array(res["events"])
      arr.empty? ? nil : parse_match(arr.first)
    end

    # ── Teams ────────────────────────────────────────────────────────────
    def fetch_teams(league_id = WC_LEAGUE)
      res = get("lookup_all_teams.php", id: league_id)
      Array(res["teams"]).map { |t| parse_team(t) }.compact
    end

    def fetch_team(team_id)
      res = get("lookupteam.php", id: team_id)
      arr = Array(res["teams"])
      arr.empty? ? nil : parse_team(arr.first)
    end

    def search_teams(query)
      res = get("searchteams.php", t: query)
      Array(res["teams"]).map { |t| parse_team(t) }.compact
    end

    # ── FetchResultsJob interface ────────────────────────────────────────
    def fetch_results(schedulable)
      case schedulable
      when Tournament
        season = schedulable.season || Time.current.year.to_s
        league = schedulable.external_config&.dig("tsdb_league_id") || WC_LEAGUE
        fetch_matches_for_season(season, league)
      when Match
        return [] if schedulable.external_tsdb_id.blank?
        m = fetch_match(schedulable.external_tsdb_id)
        m ? [m] : []
      else
        []
      end
    end

    private

    # Builds endpoint path with API key injected
    def get(endpoint, **params)
      path = "/api/v1/json/#{@api_key}/#{endpoint}"
      resp = connection.get(path, params)
      return {} unless resp.success?
      JSON.parse(resp.body)
    rescue Faraday::Error, JSON::ParserError => e
      Rails.logger.error("TheSportsDB error #{endpoint}: #{e.message}")
      {}
    end

    def connection
      @connection ||= Faraday.new(url: BASE_URL) do |f|
        f.request :retry, max: 2, interval: 1
        f.adapter Faraday.default_adapter
        f.headers["Accept"] = "application/json"
      end
    end

    def parse_match(e)
      status = map_status(e["strStatus"], e["strPostponed"])
      MatchData.new(
        external_id:             e["idEvent"].to_s,
        external_tsdb_id:        e["idEvent"].to_s,
        home_team_name:          e["strHomeTeam"].to_s.strip,
        away_team_name:          e["strAwayTeam"].to_s.strip,
        home_team_external_id:   e["idHomeTeam"].to_s,
        away_team_external_id:   e["idAwayTeam"].to_s,
        scheduled_at:            parse_timestamp(e["strTimestamp"] || e["dateEvent"]),
        status:                  status,
        home_score:              e["intHomeScore"].presence&.to_i,
        away_score:              e["intAwayScore"].presence&.to_i,
        group_name:              e["strGroup"] || e["strRound"],
        match_type:              "group",
        stadium_name:            e["strVenue"],
        thumb_url:               e["strThumb"],
        stream_url:              e["strVideo"].presence,
        season:                  e["strSeason"],
        round:                   e["intRound"]
      )
    rescue => ex
      Rails.logger.warn("TheSportsDB parse_match: #{ex.message}")
      nil
    end

    def parse_team(t)
      TeamData.new(
        external_tsdb_id: t["idTeam"].to_s,
        name:             t["strTeam"].to_s.strip,
        short_name:       t["strTeamShort"],
        country_code:     t["strCountry"]&.slice(0, 3)&.upcase,
        flag_url:         nil,
        logo_url:         t["strBadge"] || t["strLogo"],
        primary_color:    t["strColour1"]
      )
    rescue => ex
      Rails.logger.warn("TheSportsDB parse_team: #{ex.message}")
      nil
    end

    def parse_league(l)
      LeagueData.new(
        external_tsdb_id: l["idLeague"].to_s,
        name:             l["strLeague"].to_s,
        country:          l["strCountry"],
        sport:            l["strSport"],
        formed_year:      l["intFormedYear"]&.to_i,
        current_season:   l["intCurrentSeason"]&.to_s,
        logo_url:         l["strLogo"],
        badge_url:        l["strBadge"]
      )
    end

    def parse_timestamp(value)
      return nil if value.blank?
      # TheSportsDB strTimestamp is UTC
      Time.parse("#{value} UTC")
    rescue ArgumentError, TypeError
      nil
    end

    def map_status(str, postponed)
      return :postponed if postponed.to_s.downcase == "yes"
      case str.to_s.upcase
      when "FT", "AET", "PEN"              then :finished
      when "LIVE", "HT", "1H", "2H", "ET" then :live
      when "PPD"                            then :postponed
      when "CANC"                           then :cancelled
      else :scheduled
      end
    end
  end
end
