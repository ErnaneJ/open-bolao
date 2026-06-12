module ApiProviders
  class ThesportsdbAdapter
    BASE_URL  = "https://www.thesportsdb.com"

    # Maps TheSportsDB strCountry → ISO 3166-1 alpha-2 (used for flagcdn.com)
    COUNTRY_ISO2 = {
      "Afghanistan" => "af", "Albania" => "al", "Algeria" => "dz",
      "Andorra" => "ad", "Angola" => "ao", "Antigua and Barbuda" => "ag",
      "Argentina" => "ar", "Armenia" => "am", "Australia" => "au",
      "Austria" => "at", "Azerbaijan" => "az", "Bahamas" => "bs",
      "Bahrain" => "bh", "Bangladesh" => "bd", "Barbados" => "bb",
      "Belarus" => "by", "Belgium" => "be", "Belize" => "bz",
      "Benin" => "bj", "Bolivia" => "bo", "Bosnia and Herzegovina" => "ba",
      "Botswana" => "bw", "Brazil" => "br", "Bulgaria" => "bg",
      "Burkina Faso" => "bf", "Burundi" => "bi", "Cambodia" => "kh",
      "Cameroon" => "cm", "Canada" => "ca", "Cape Verde" => "cv",
      "Chad" => "td", "Chile" => "cl", "China" => "cn",
      "Colombia" => "co", "Comoros" => "km", "Congo" => "cg",
      "Costa Rica" => "cr", "Croatia" => "hr", "Cuba" => "cu",
      "Curacao" => "cw", "Cyprus" => "cy", "Czech Republic" => "cz",
      "Czechia" => "cz", "Denmark" => "dk", "Djibouti" => "dj",
      "Dominican Republic" => "do", "DR Congo" => "cd", "Ecuador" => "ec",
      "Egypt" => "eg", "El Salvador" => "sv", "England" => "gb-eng",
      "Equatorial Guinea" => "gq", "Eritrea" => "er", "Estonia" => "ee",
      "Eswatini" => "sz", "Ethiopia" => "et", "Faroe Islands" => "fo",
      "Fiji" => "fj", "Finland" => "fi", "France" => "fr",
      "Gabon" => "ga", "Gambia" => "gm", "Georgia" => "ge",
      "Germany" => "de", "Ghana" => "gh", "Gibraltar" => "gi",
      "Greece" => "gr", "Grenada" => "gd", "Guatemala" => "gt",
      "Guinea" => "gn", "Guinea-Bissau" => "gw", "Guyana" => "gy",
      "Haiti" => "ht", "Honduras" => "hn", "Hungary" => "hu",
      "Iceland" => "is", "India" => "in", "Indonesia" => "id",
      "Iran" => "ir", "Iraq" => "iq", "Ireland" => "ie",
      "Israel" => "il", "Italy" => "it", "Ivory Coast" => "ci",
      "Jamaica" => "jm", "Japan" => "jp", "Jordan" => "jo",
      "Kazakhstan" => "kz", "Kenya" => "ke", "Kosovo" => "xk",
      "Kuwait" => "kw", "Kyrgyzstan" => "kg", "Laos" => "la",
      "Latvia" => "lv", "Lebanon" => "lb", "Lesotho" => "ls",
      "Liberia" => "lr", "Libya" => "ly", "Liechtenstein" => "li",
      "Lithuania" => "lt", "Luxembourg" => "lu", "Madagascar" => "mg",
      "Malawi" => "mw", "Malaysia" => "my", "Maldives" => "mv",
      "Mali" => "ml", "Malta" => "mt", "Mauritania" => "mr",
      "Mauritius" => "mu", "Mexico" => "mx", "Moldova" => "md",
      "Montenegro" => "me", "Morocco" => "ma", "Mozambique" => "mz",
      "Myanmar" => "mm", "Namibia" => "na", "Nepal" => "np",
      "Netherlands" => "nl", "New Caledonia" => "nc", "New Zealand" => "nz",
      "Nicaragua" => "ni", "Niger" => "ne", "Nigeria" => "ng",
      "North Korea" => "kp", "North Macedonia" => "mk", "Northern Ireland" => "gb-nir",
      "Norway" => "no", "Oman" => "om", "Pakistan" => "pk",
      "Palestine" => "ps", "Panama" => "pa", "Papua New Guinea" => "pg",
      "Paraguay" => "py", "Peru" => "pe", "Philippines" => "ph",
      "Poland" => "pl", "Portugal" => "pt", "Puerto Rico" => "pr",
      "Qatar" => "qa", "Republic of Ireland" => "ie", "Romania" => "ro",
      "Russia" => "ru", "Rwanda" => "rw", "San Marino" => "sm",
      "Saudi Arabia" => "sa", "Scotland" => "gb-sct", "Senegal" => "sn",
      "Serbia" => "rs", "Sierra Leone" => "sl", "Slovakia" => "sk",
      "Slovenia" => "si", "Solomon Islands" => "sb", "Somalia" => "so",
      "South Africa" => "za", "South Korea" => "kr", "South Sudan" => "ss",
      "Spain" => "es", "Sri Lanka" => "lk", "Sudan" => "sd",
      "Suriname" => "sr", "Sweden" => "se", "Switzerland" => "ch",
      "Syria" => "sy", "Tahiti" => "pf", "Taiwan" => "tw",
      "Tajikistan" => "tj", "Tanzania" => "tz", "Thailand" => "th",
      "Togo" => "tg", "Tonga" => "to", "Trinidad and Tobago" => "tt",
      "Tunisia" => "tn", "Turkey" => "tr", "Turkmenistan" => "tm",
      "Uganda" => "ug", "Ukraine" => "ua", "United Arab Emirates" => "ae",
      "United States" => "us", "Uruguay" => "uy", "Uzbekistan" => "uz",
      "Vanuatu" => "vu", "Venezuela" => "ve", "Vietnam" => "vn",
      "Wales" => "gb-wls", "Yemen" => "ye", "Zambia" => "zm",
      "Zimbabwe" => "zw",
      # TheSportsDB alternate spellings
      "USA" => "us", "Curaçao" => "cw", "Bosnia-Herzegovina" => "ba",
      "Trinidad & Tobago" => "tt", "Korea Republic" => "kr",
      "Korea DPR" => "kp", "Côte d'Ivoire" => "ci"
    }.freeze
    FREE_KEY  = "3"
    PAID_KEY  = "123"
    WC_LEAGUE = "4429"

    # ── Rate-limit constants ─────────────────────────────────────────────
    # Free plan: 30 req/min. We target 24 req/min (comfortable margin).
    # 60_000ms / 24 = 2_500ms minimum interval between ANY two requests,
    # enforced globally across all Sidekiq workers via Redis.
    MIN_INTERVAL_MS = 2_500

    # Lua script: atomically claims the next available request slot.
    # Returns 0 if the caller can proceed immediately, or N (ms) to sleep first.
    # Multiple concurrent workers each get their own slot, queued 2.5s apart.
    THROTTLE_LUA = <<~LUA.freeze
      local key      = KEYS[1]
      local now      = tonumber(ARGV[1])
      local interval = tonumber(ARGV[2])

      local last = tonumber(redis.call('GET', key)) or 0
      local next_slot = math.max(last, now - interval)  -- slot just before now if idle

      -- Advance to the next available slot
      next_slot = next_slot + interval
      local wait = next_slot - now

      -- Store the slot we just claimed (TTL: 5 min)
      redis.call('SET', key, next_slot, 'PX', 300000)

      if wait <= 0 then return 0 else return wait end
    LUA

    # ── HTTP retry constants ─────────────────────────────────────────────
    MAX_RETRIES  = 3
    BASE_BACKOFF = 60  # seconds — on 429, wait a full minute before retry

    # ── Data structs ─────────────────────────────────────────────────────
    MatchData = Data.define(
      :external_id, :external_tsdb_id,
      :home_team_name, :away_team_name,
      :home_team_external_id, :away_team_external_id,
      :scheduled_at, :status,
      :home_score, :away_score,
      :home_score_ht, :away_score_ht,
      :home_score_et, :away_score_et,
      :home_score_penalties, :away_score_penalties,
      :group_name, :match_type,
      :stadium_name, :city,
      :thumb_url, :stream_url,
      :season, :round, :round_number,
      :referee, :attendance
    )

    TeamData = Data.define(
      :external_tsdb_id, :name, :short_name, :country_code,
      :flag_url, :logo_url, :banner_url, :fanart_url,
      :primary_color, :secondary_color, :tertiary_color,
      :formed_year, :stadium_name, :stadium_capacity,
      :description, :website, :gender
    )

    LeagueData = Data.define(
      :external_tsdb_id, :name, :country, :sport,
      :formed_year, :current_season,
      :logo_url, :badge_url, :banner_url, :fanart_url, :trophy_url,
      :description, :gender, :website
    )

    def initialize(api_provider = nil)
      @api_provider = api_provider
      @api_key      = api_provider&.config&.dig("api_key") || PAID_KEY
    end

    # ── League ───────────────────────────────────────────────────────────
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

    MAX_CONSECUTIVE_EMPTY = 3

    def fetch_all_matches_by_round(season, league_id = WC_LEAGUE, max_rounds: 60)
      all               = []
      consecutive_empty = 0
      total_rounds      = 0
      error_rounds      = 0

      (1..max_rounds).each do |round|
        events = fetch_round("eventsround.php", id: league_id, r: round.to_s, s: season)
        total_rounds += 1

        if events.nil?
          error_rounds += 1
          Rails.logger.warn("TheSportsDB: error on round #{round}, skipping")
          next
        end

        if events.empty?
          consecutive_empty += 1
          break if consecutive_empty >= MAX_CONSECUTIVE_EMPTY
        else
          consecutive_empty = 0
          all.concat(events.map { |e| parse_match(e) }.compact)
        end
      end

      rate_limited = all.empty? && total_rounds > 0 && error_rounds == total_rounds
      [ all, rate_limited ]
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
    # NOTE: lookup_all_teams.php intentionally NOT exposed as a public method.
    # It returns wrong data for several leagues. Team IDs must always come from
    # match data (eventsround / eventsseason), then individual lookupteam.php calls.

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

        # Full season batch — catches final scores and schedule changes
        season_matches = fetch_matches_for_season(season, league)

        # For matches currently in the live window, supplement with real-time
        # lookupevent.php data (more frequently updated than eventsseason.php)
        live_overrides = fetch_live_overrides(schedulable)
        if live_overrides.any?
          live_ids = live_overrides.map(&:external_id).to_set
          season_matches.reject! { |m| live_ids.include?(m.external_id) }
          season_matches + live_overrides
        else
          season_matches
        end
      when Match
        return [] if schedulable.external_tsdb_id.blank?
        m = fetch_match(schedulable.external_tsdb_id)
        m ? [ m ] : []
      else
        []
      end
    end

    private

    # ── Live override helper ─────────────────────────────────────────────
    # Fetches real-time data for matches that are currently in progress.
    # eventsseason.php caches between updates; lookupevent.php reflects live state.
    # Window: started in the last 2.5 hours and not yet finished in our DB.
    def fetch_live_overrides(tournament)
      live_window = tournament.matches
        .where(status: [ :scheduled, :live ])
        .where(scheduled_at: 2.5.hours.ago..Time.current)
        .where.not(external_tsdb_id: [ nil, "" ])

      return [] if live_window.none?

      live_window.filter_map { |m| fetch_match(m.external_tsdb_id) }
    end

    # ── Rate limiting — token-slot approach ──────────────────────────────
    # Acquires the next available request slot globally across all Sidekiq workers.
    # Uses one Redis connection per adapter instance (cached in @redis_conn).
    # Always uses the `redis` gem's Redis class — avoids redis-client API differences.
    def throttle!
      now_ms  = (Time.now.to_f * 1000).to_i
      wait_ms = redis_conn.eval(
        THROTTLE_LUA,
        keys: [ "tsdb:req_slot" ],
        argv: [ now_ms.to_s, MIN_INTERVAL_MS.to_s ]
      ).to_i

      if wait_ms > 0
        wait_sec = (wait_ms / 1000.0).ceil + 0.05
        Rails.logger.info("TheSportsDB: throttle #{wait_sec.round(1)}s (slot queued)")
        sleep(wait_sec)
      end
    rescue => e
      Rails.logger.warn("TheSportsDB: throttle fallback — #{e.class}: #{e.message}")
      sleep(MIN_INTERVAL_MS / 1000.0)
    end

    # One `Redis` instance per adapter (= per job). Reconnects automatically.
    # Uses the `redis` gem directly so `.eval(script, keys:, argv:)` works reliably.
    def redis_conn
      @redis_conn ||= Redis.new(
        url:            ENV.fetch("REDIS_URL", "redis://localhost:6379/0"),
        timeout:        2,
        reconnect_attempts: 1
      )
    end

    # ── HTTP layer ───────────────────────────────────────────────────────
    # get() throttles BEFORE each attempt (not once before the loop).
    # On 429: sleeps a full BASE_BACKOFF minute to let the rate-limit window reset.
    def get(endpoint, **params)
      path = "/api/v1/json/#{@api_key}/#{endpoint}"

      MAX_RETRIES.times do |attempt|
        throttle!
        resp = connection.get(path, params)
        return JSON.parse(resp.body) if resp.success?

        if resp.status == 429
          wait = BASE_BACKOFF * (attempt + 1)  # 60s, 120s, 180s
          Rails.logger.warn("TheSportsDB: 429 on #{endpoint} (attempt #{attempt + 1}/#{MAX_RETRIES}), sleeping #{wait}s")
          sleep(wait)
        else
          Rails.logger.error("TheSportsDB: HTTP #{resp.status} on #{endpoint}")
          return {}
        end
      end

      Rails.logger.error("TheSportsDB: gave up after #{MAX_RETRIES} attempts on #{endpoint}")
      {}
    rescue Faraday::Error => e
      Rails.logger.error("TheSportsDB connection error on #{endpoint}: #{e.message}")
      {}
    rescue JSON::ParserError => e
      Rails.logger.error("TheSportsDB parse error on #{endpoint}: #{e.message}")
      {}
    end

    # Like get() but returns nil on non-429 errors (so callers distinguish "empty" from "error").
    def fetch_round(endpoint, **params)
      path = "/api/v1/json/#{@api_key}/#{endpoint}"

      MAX_RETRIES.times do |attempt|
        throttle!
        resp = connection.get(path, params)
        return Array(JSON.parse(resp.body)["events"]) if resp.success?

        if resp.status == 429
          wait = BASE_BACKOFF * (attempt + 1)
          Rails.logger.warn("TheSportsDB: 429 on #{endpoint} (attempt #{attempt + 1}/#{MAX_RETRIES}), sleeping #{wait}s")
          sleep(wait)
        else
          Rails.logger.error("TheSportsDB: HTTP #{resp.status} on #{endpoint}")
          return nil
        end
      end

      Rails.logger.error("TheSportsDB: gave up after #{MAX_RETRIES} attempts on #{endpoint}")
      nil
    rescue Faraday::Error, JSON::ParserError => e
      Rails.logger.error("TheSportsDB fetch_round error: #{e.message}")
      nil
    end

    def connection
      # No Faraday retry middleware — our own loop handles all retries with throttling.
      @connection ||= Faraday.new(url: BASE_URL) do |f|
        f.options.timeout      = 30
        f.options.open_timeout = 10
        f.adapter Faraday.default_adapter
        f.headers["Accept"]     = "application/json"
        f.headers["User-Agent"] = "OpenBolao/1.0"
      end
    end

    # ── Parsers ───────────────────────────────────────────────────────────
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
        home_score_ht:           e["intHomeScoreHalf"].presence&.to_i,
        away_score_ht:           e["intAwayScoreHalf"].presence&.to_i,
        home_score_et:           e["intHomeScoreExtraTime"].presence&.to_i,
        away_score_et:           e["intAwayScoreExtraTime"].presence&.to_i,
        home_score_penalties:    e["intHomeScorePenalty"].presence&.to_i,
        away_score_penalties:    e["intAwayScorePenalty"].presence&.to_i,
        group_name:              e["strGroup"] || e["strRound"],
        match_type:              map_match_type(e["strRound"]),
        stadium_name:            e["strVenue"],
        city:                    e["strCity"],
        thumb_url:               e["strThumb"],
        stream_url:              e["strVideo"].presence,
        season:                  e["strSeason"],
        round:                   e["intRound"],
        round_number:            e["intRound"].presence&.to_i,
        referee:                 e["strReferee"].presence,
        attendance:              e["intAttendance"].presence&.to_i
      )
    rescue => ex
      Rails.logger.warn("TheSportsDB parse_match: #{ex.message}")
      nil
    end

    def parse_team(t)
      country_name = t["strCountry"].to_s.strip
      iso2         = COUNTRY_ISO2[country_name]
      TeamData.new(
        external_tsdb_id:  t["idTeam"].to_s,
        name:              t["strTeam"].to_s.strip,
        short_name:        t["strTeamShort"].presence,
        country_code:      iso2&.upcase || country_name.slice(0, 3).upcase.presence,
        flag_url:          iso2 ? "https://flagcdn.com/w160/#{iso2}.png" : nil,
        logo_url:          t["strBadge"].presence || t["strLogo"].presence,
        banner_url:        t["strBanner"].presence,
        fanart_url:        (t["strFanart1"] || t["strFanart2"] || t["strFanart3"] || t["strFanart4"]).presence,
        primary_color:     t["strColour1"].presence,
        secondary_color:   t["strColour2"].presence,
        tertiary_color:    t["strColour3"].presence,
        formed_year:       t["intFormedYear"].presence&.to_i,
        stadium_name:      t["strStadium"].presence,
        stadium_capacity:  t["intStadiumCapacity"].presence&.to_i,
        description:       (t["strDescriptionPT"] || t["strDescriptionEN"]).presence,
        website:           t["strWebsite"].presence,
        gender:            t["strGender"].presence
      )
    rescue => ex
      Rails.logger.warn("TheSportsDB parse_team: #{ex.message}")
      nil
    end

    def parse_league(l)
      LeagueData.new(
        external_tsdb_id: l["idLeague"].to_s,
        name:             l["strLeague"].to_s,
        country:          l["strCountry"].presence,
        sport:            l["strSport"].presence,
        formed_year:      l["intFormedYear"].presence&.to_i,
        current_season:   l["strCurrentSeason"].presence || l["intCurrentSeason"]&.to_s,
        logo_url:         l["strLogo"].presence,
        badge_url:        l["strBadge"].presence,
        banner_url:       l["strBanner"].presence,
        fanart_url:       (l["strFanart1"] || l["strFanart2"] || l["strFanart3"] || l["strFanart4"]).presence,
        trophy_url:       l["strTrophy"].presence,
        description:      (l["strDescriptionPT"] || l["strDescriptionEN"]).presence,
        gender:           l["strGender"].presence,
        website:          l["strWebsite"].presence
      )
    end

    def parse_timestamp(value)
      return nil if value.blank?
      str = value.to_s.strip
      # TSDB returns timestamps like "2026-06-11T19:00:00+00:00", "...Z", or "2026-06-11".
      # Only append +00:00 when there is NO timezone info already in the string,
      # so we never double-interpret an offset (old bug: forced " UTC" overwrote real offsets).
      unless str.match?(/[Zz]$|[+\-]\d{2}:?\d{2}$/)
        str = "#{str}+00:00"
      end
      Time.parse(str).utc
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

    def map_match_type(round_str)
      return "group" if round_str.blank?
      case round_str.to_s.downcase
      when /round.*32|32.*round/ then "round_of_32"
      when /round.*16|16.*round/ then "round_of_16"
      when /quarter/             then "quarterfinal"
      when /semi/                then "semifinal"
      when /third|3rd/           then "third_place"
      when /final/               then "final"
      else "group"
      end
    end
  end
end
