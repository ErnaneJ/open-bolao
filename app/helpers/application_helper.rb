module ApplicationHelper
  include Pagy::Frontend

  # Single source of truth for the app's display timezone.
  # All user-facing datetimes must go through brt_time() or in_time_zone(BRT).
  BRT = "America/Sao_Paulo"

  # Returns a TimeWithZone in Brasília time, safe to pass to l() or strftime.
  def brt_time(datetime)
    datetime&.in_time_zone(BRT)
  end

  def flash_class(type)
    case type.to_sym
    when :notice  then "bg-green-500"
    when :alert   then "bg-red-500"
    when :warning then "bg-yellow-500"
    else "bg-blue-500"
    end
  end

  def role_badge(role)
    colors = {
      "super_admin" => "bg-purple-100 text-purple-800",
      "admin"       => "bg-blue-100 text-blue-800",
      "user"        => "bg-gray-100 text-gray-700"
    }
    klass = colors[role.to_s] || "bg-gray-100 text-gray-700"
    content_tag(:span, t("roles.#{role}"), class: "text-xs px-2 py-0.5 rounded-full font-medium #{klass}")
  end

  def status_badge(status, model: nil)
    colors = {
      "open"      => "bg-green-100 text-green-800",
      "active"    => "bg-green-100 text-green-800",
      "draft"     => "bg-gray-100 text-gray-600",
      "locked"    => "bg-yellow-100 text-yellow-800",
      "finished"  => "bg-blue-100 text-blue-800",
      "live"      => "bg-red-100 text-red-800 animate-pulse",
      "scheduled" => "bg-gray-100 text-gray-600",
      "cancelled" => "bg-red-100 text-red-800",
      "postponed" => "bg-orange-100 text-orange-800"
    }
    klass = colors[status.to_s] || "bg-gray-100 text-gray-600"
    content_tag(:span, status.to_s.humanize, class: "text-xs px-2 py-0.5 rounded-full font-medium #{klass}")
  end

  def rank_trend_icon(trend)
    case trend.to_s
    when "up"   then content_tag(:span, "↑", class: "text-green-500 font-bold")
    when "down" then content_tag(:span, "↓", class: "text-red-500 font-bold")
    else             content_tag(:span, "—", class: "text-gray-400")
    end
  end

  # Team avatar: logo > flag > initials placeholder
  # sizes: :xs (w-6 h-6), :sm (w-8 h-8), :md (w-10 h-10), :lg (w-14 h-14)
  TEAM_AVATAR_SIZES = {
    xs:  { outer: "w-6 h-6 rounded-md text-[8px]",   img: "w-6 h-6 object-contain rounded-md" },
    sm:  { outer: "w-8 h-8 rounded-lg text-[9px]",    img: "w-8 h-8 object-contain rounded-lg" },
    md:  { outer: "w-10 h-10 rounded-xl text-[10px]", img: "w-10 h-10 object-contain rounded-xl" },
    lg:  { outer: "w-14 h-14 rounded-2xl text-xs",    img: "w-14 h-14 object-contain rounded-2xl" }
  }.freeze

  def team_avatar(team, size: :sm)
    cfg   = TEAM_AVATAR_SIZES[size] || TEAM_AVATAR_SIZES[:sm]
    url   = team.display_image_url
    title = team.name

    if url.present?
      image_tag(url, alt: title, class: cfg[:img], title: title,
                onerror: "this.style.display='none';this.nextElementSibling.style.display='flex'") +
        content_tag(:div, team.initials,
                    class: "hidden #{cfg[:outer]} bg-pitch-100 dark:bg-pitch-700 items-center justify-center font-bold font-mono text-pitch-500 shrink-0",
                    title: title)
    else
      content_tag(:div, team.initials,
                  class: "#{cfg[:outer]} bg-pitch-100 dark:bg-pitch-700 flex items-center justify-center font-bold font-mono text-pitch-500 shrink-0",
                  title: title)
    end
  end

  # Tournament logo: logo > badge > initials
  TOURNAMENT_LOGO_SIZES = {
    xs:  { outer: "w-7 h-7 rounded-lg text-[9px]",   img: "w-7 h-7 object-contain rounded-lg" },
    sm:  { outer: "w-9 h-9 rounded-xl text-[10px]",   img: "w-9 h-9 object-contain rounded-xl" },
    md:  { outer: "w-12 h-12 rounded-2xl text-xs",    img: "w-12 h-12 object-contain rounded-2xl" },
    lg:  { outer: "w-16 h-16 rounded-2xl text-sm",    img: "w-16 h-16 object-contain rounded-2xl" }
  }.freeze

  # User avatar: photo > initials fallback
  # sizes: :sm (w-8 h-8), :md (w-10 h-10), :lg (w-14 h-14)
  USER_AVATAR_SIZES = {
    sm: { outer: "w-8 h-8 rounded-full text-[11px]",  img: "w-8 h-8 rounded-full object-cover" },
    md: { outer: "w-10 h-10 rounded-full text-sm",    img: "w-10 h-10 rounded-full object-cover" },
    lg: { outer: "w-14 h-14 rounded-full text-lg",    img: "w-14 h-14 rounded-full object-cover" }
  }.freeze

  def user_avatar(user, size: :sm, css: "")
    cfg = USER_AVATAR_SIZES[size] || USER_AVATAR_SIZES[:sm]
    if user.avatar.attached?
      image_tag(
        url_for(user.avatar.variant(resize_to_fill: [ size == :lg ? 56 : size == :md ? 40 : 32,
                                                      size == :lg ? 56 : size == :md ? 40 : 32 ])),
        alt: user.display_name,
        class: "#{cfg[:img]} shrink-0 #{css}"
      )
    else
      content_tag(:div, user.display_name.first.upcase,
                  class: "#{cfg[:outer]} bg-pitch-600 dark:bg-pitch-500 flex items-center justify-center font-bold text-white shrink-0 #{css}")
    end
  end

  def tournament_logo(tournament, size: :sm)
    cfg   = TOURNAMENT_LOGO_SIZES[size] || TOURNAMENT_LOGO_SIZES[:sm]
    url   = tournament.display_image_url
    title = tournament.name

    if url.present?
      image_tag(url, alt: title, class: cfg[:img], title: title,
                onerror: "this.style.display='none';this.nextElementSibling.style.display='flex'") +
        content_tag(:div, tournament.initials,
                    class: "hidden #{cfg[:outer]} bg-neon-400/20 items-center justify-center font-bold font-display text-neon-600 dark:text-neon-300 shrink-0",
                    title: title)
    else
      content_tag(:div, tournament.initials,
                  class: "#{cfg[:outer]} bg-neon-400/20 flex items-center justify-center font-bold font-display text-neon-600 dark:text-neon-300 shrink-0",
                  title: title)
    end
  end
end
