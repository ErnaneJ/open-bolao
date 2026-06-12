class OgImageService
  WIDTH  = 1200
  HEIGHT = 630

  # Colors
  BG          = "#04091a"
  CARD_BG     = "#0c152e"
  BORDER      = "#1a2848"
  WHITE       = "#ffffff"
  NEON        = "#b8ff3c"
  NEON_DARK   = "#04091a"
  MUTED       = "#5a74a8"
  MUTED_DARK  = "#3a4f80"
  RED         = "#ef4444"

  # System fonts installed via fonts-liberation
  FONT_BOLD = "/usr/share/fonts/truetype/liberation/LiberationSans-Bold.ttf"
  FONT_REG  = "/usr/share/fonts/truetype/liberation/LiberationSans-Regular.ttf"

  # ── Public API ────────────────────────────────────────────────────────────

  def self.home
    Rails.cache.fetch("og_image/home/v1", expires_in: 12.hours) do
      new.render_home
    end
  end

  def self.pool(pool)
    cache_key = "og_image/pool/#{pool.id}/#{pool.updated_at.to_i}"
    Rails.cache.fetch(cache_key, expires_in: 1.hour) do
      new.render_pool(pool)
    end
  end

  def self.match(match)
    cache_key = "og_image/match/#{match.id}/#{match.updated_at.to_i}"
    Rails.cache.fetch(cache_key, expires_in: 3.minutes) do
      new.render_match(match)
    end
  end

  # ── Renderers ─────────────────────────────────────────────────────────────

  def render_home
    with_tempfile do |out|
      c = build_canvas
      # Green radial glow at top
      glow_overlay(c, NEON, 0.08)
      # Top eyebrow
      pill(c, 410, 62, 380, 40, CARD_BG, NEON, 0.35)
      dot(c, 432, 82, 6, NEON)
      label(c, 448, 90, "COPA DO MUNDO 2026", 13, NEON, spacing: 4)
      # Main headline
      text_centered(c, 0, -90, "BOLÃO",  155, WHITE)
      text_centered(c, 0,  65, "ONLINE", 155, NEON)
      # Subtitle
      text_centered(c, 0, 215,
        "Crie bolões, convide amigos e dispute palpites da Copa 2026.",
        19, MUTED)
      # Branding
      pill(c, 540, 560, 120, 34, NEON, nil, nil)
      text_centered(c, 0, 283, "OpenBolão", 14, NEON_DARK)
      c << out
      c.call
    end
  end

  def render_pool(pool)
    with_tempfile do |out|
      c = build_canvas
      glow_overlay(c, NEON, 0.06)
      # Left accent bar
      c.fill(NEON)
      c.draw("rectangle 0,0 5,#{HEIGHT}")
      # Eyebrow
      label(c, 80, 78, "VOCÊ FOI CONVIDADO PARA", 12, NEON, spacing: 4)
      # Pool name
      name_up = pool.name.upcase
      fs = case name_up.length
      when 0..13  then 105
      when 14..22 then 78
      when 23..32 then 58
      else 44
      end
      text(c, 80, 170 + fs, name_up, fs, WHITE)
      # Description
      if pool.description.present?
        text(c, 80, 310, pool.description.truncate(70), 20, MUTED)
      end
      sy = pool.description.present? ? 390 : 355
      # Stats
      stat_card(c, 80,  sy, 220, 88, pool.pool_participants.active.count.to_s, "PARTICIPANTES")
      stat_card(c, 318, sy, 190, 88, pool.pool_scope_tournament? ? "TORNEIO" : "JOGO", "TIPO", font_size: 26)
      status_text  = pool.status_open? ? "ABERTO" : "ENCERRADO"
      status_color = pool.status_open? ? "#34d399" : MUTED
      stat_card(c, 522, sy, 210, 88, status_text, "STATUS", value_color: status_color)
      # Admin
      label(c, 80, sy + 130, "Admin: #{pool.admin.display_name}", 16, MUTED)
      # Branding
      pill(c, 1040, 560, 120, 34, NEON, nil, nil)
      text(c, 1064, 583, "OpenBolão", 14, NEON_DARK)
      c << out
      c.call
    end
  end

  def render_match(match)
    ht = match.home_team
    at = match.away_team
    is_live     = match.status_live?
    is_finished = match.status_finished?
    score_color = is_live ? RED : WHITE
    stage       = match.stage&.name || match.tournament&.name || "Copa do Mundo 2026"
    scheduled   = match.scheduled_at&.in_time_zone("America/Sao_Paulo")

    with_tempfile do |out|
      c = build_canvas
      glow_overlay(c, is_live ? RED : NEON, 0.06)
      # Stage label
      text_centered(c, 0, -250, stage.upcase, 13, MUTED, spacing: 3)
      # Home team flag
      team_flag(c, ht, 110, 130, 160)
      # Away team flag
      team_flag(c, at, 930, 130, 160)
      # Home team name
      hn = (ht.short_name || ht.name).upcase
      hfs = name_font_size(hn)
      text_centered(c, -410, 115 + hfs, hn, hfs, WHITE)
      # Away team name
      an = (at.short_name || at.name).upcase
      afs = name_font_size(an)
      text_centered(c, 410, 115 + afs, an, afs, WHITE)
      # Center: score or time
      if is_finished || is_live
        score = "#{match.home_score}  –  #{match.away_score}"
        text_centered(c, 0, -55, score, 100, score_color, font: FONT_BOLD, spacing: -2)
        if is_live
          dot(c, 556, 322, 8, RED)
          label(c, 572, 328, "AO VIVO", 16, RED, spacing: 2)
        else
          text_centered(c, 0, 42, "ENCERRADO", 14, MUTED, spacing: 3)
        end
      elsif scheduled
        text_centered(c, 0, -50, scheduled.strftime("%H:%M"), 90, WHITE)
        text_centered(c, 0,  52, scheduled.strftime("%d/%m/%Y"), 20, MUTED)
      end
      # Venue
      if match.venue.present?
        text_centered(c, 0, 215, "📍 #{match.venue}", 16, MUTED_DARK)
      end
      # Branding
      pill(c, 540, 560, 120, 34, NEON, nil, nil)
      text_centered(c, 0, 283, "OpenBolão", 14, NEON_DARK)
      c << out
      c.call
    end
  end

  private

  # ── Canvas & primitives ───────────────────────────────────────────────────

  def build_canvas
    c = MiniMagick::Tool::Convert.new
    c.size("#{WIDTH}x#{HEIGHT}")
    c << "xc:#{BG}"
    c
  end

  def with_tempfile
    tmpfile = Tempfile.new([ "og", ".png" ])
    yield tmpfile.path
    data = File.binread(tmpfile.path)
    tmpfile.unlink
    data
  ensure
    tmpfile&.close
  end

  def glow_overlay(c, color, opacity)
    r, g, b = hex_to_rgb(color)
    c.fill("rgba(#{r},#{g},#{b},#{opacity})")
    c.draw("circle #{WIDTH / 2},#{-HEIGHT / 2} #{WIDTH / 2},#{HEIGHT / 2}")
  end

  def pill(c, x, y, w, h, fill, stroke_color, stroke_opacity)
    r = h / 2
    c.fill(fill)
    c.draw("roundrectangle #{x},#{y} #{x + w},#{y + h} #{r},#{r}")
    if stroke_color && stroke_opacity
      r2, g2, b2 = hex_to_rgb(stroke_color)
      c.fill("none")
      c.stroke("rgba(#{r2},#{g2},#{b2},#{stroke_opacity})")
      c.strokewidth("1.5")
      c.draw("roundrectangle #{x},#{y} #{x + w},#{y + h} #{r},#{r}")
      c.stroke("none")
      c.strokewidth("0")
    end
  end

  def dot(c, x, y, r, color)
    c.fill(color)
    c.draw("circle #{x},#{y} #{x + r},#{y}")
  end

  def label(c, x, y, txt, size, color, spacing: 0)
    c.font(FONT_BOLD)
    c.pointsize(size)
    c.fill(color)
    c.gravity("NorthWest")
    c.annotate("+#{x}+#{y}", txt.encode("UTF-8"))
  end

  def text(c, x, y, txt, size, color, font: FONT_BOLD)
    c.font(font)
    c.pointsize(size)
    c.fill(color)
    c.gravity("NorthWest")
    c.annotate("+#{x}+#{y}", txt.encode("UTF-8"))
  end

  def text_centered(c, dx, dy, txt, size, color, font: FONT_BOLD, spacing: 0)
    c.font(font)
    c.pointsize(size)
    c.fill(color)
    c.gravity("Center")
    sign_x = dx >= 0 ? "+" : ""
    sign_y = dy >= 0 ? "+" : ""
    c.annotate("#{sign_x}#{dx}#{sign_y}#{dy}", txt.encode("UTF-8"))
  end

  def stat_card(c, x, y, w, h, value, label_text, value_color: WHITE, font_size: 38)
    c.fill(CARD_BG)
    c.stroke(BORDER)
    c.strokewidth("1.5")
    c.draw("roundrectangle #{x},#{y} #{x + w},#{y + h} 16,16")
    c.stroke("none")
    c.strokewidth("0")
    cx = x + w / 2
    c.font(FONT_BOLD)
    c.pointsize(font_size)
    c.fill(value_color)
    c.gravity("NorthWest")
    # Center text within card manually
    c.annotate("+#{cx - (value.length * font_size * 0.28).to_i}+#{y + 14}", value.encode("UTF-8"))
    c.pointsize(12)
    c.fill(MUTED)
    c.annotate("+#{cx - (label_text.length * 12 * 0.28).to_i}+#{y + 58}", label_text)
  end

  def team_flag(c, team, x, y, size)
    flag_url = team.flag_url.presence || team.logo_url.presence
    if flag_url.present?
      begin
        flag_data = URI.open(flag_url, read_timeout: 3).read # rubocop:disable Security/Open
        flag_tmp = Tempfile.new([ "flag", ".png" ])
        flag_tmp.binmode
        flag_tmp.write(flag_data)
        flag_tmp.flush
        # Resize and composite
        c.stack do |s|
          s.size("#{size}x#{size}")
          s << flag_tmp.path
          s.resize("#{size}x#{size}")
        end
        c.geometry("+#{x}+#{y}")
        c.composite
        flag_tmp.unlink
        return
      rescue StandardError
        # fall through to initials
      end
    end
    # Fallback: initials box
    c.fill(CARD_BG)
    c.stroke(BORDER)
    c.strokewidth("2")
    c.draw("roundrectangle #{x},#{y} #{x + size},#{y + size} 20,20")
    c.stroke("none")
    c.strokewidth("0")
    c.font(FONT_BOLD)
    c.pointsize(52)
    c.fill(MUTED_DARK)
    c.gravity("NorthWest")
    initials = team.initials.to_s
    cx = x + size / 2 - (initials.length * 18)
    c.annotate("+#{cx}+#{y + size / 2 - 28}", initials)
  end

  def name_font_size(name)
    case name.length
    when 0..5  then 52
    when 6..9  then 40
    when 10..14 then 32
    else 26
    end
  end

  def hex_to_rgb(hex)
    hex = hex.gsub("#", "")
    [ hex[0..1].to_i(16), hex[2..3].to_i(16), hex[4..5].to_i(16) ]
  end
end
