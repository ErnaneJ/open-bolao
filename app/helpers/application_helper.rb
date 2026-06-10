module ApplicationHelper
  include Pagy::Frontend

  def flash_class(type)
    case type.to_sym
    when :notice then "bg-green-500"
    when :alert  then "bg-red-500"
    when :warning then "bg-yellow-500"
    else "bg-blue-500"
    end
  end

  def role_badge(role)
    colors = { "super_admin" => "bg-purple-100 text-purple-800", "admin" => "bg-blue-100 text-blue-800", "user" => "bg-gray-100 text-gray-700" }
    klass = colors[role.to_s] || "bg-gray-100 text-gray-700"
    content_tag(:span, t("roles.#{role}"), class: "text-xs px-2 py-0.5 rounded-full font-medium #{klass}")
  end

  def status_badge(status, model: nil)
    colors = {
      "open" => "bg-green-100 text-green-800", "active" => "bg-green-100 text-green-800",
      "draft" => "bg-gray-100 text-gray-600", "locked" => "bg-yellow-100 text-yellow-800",
      "finished" => "bg-blue-100 text-blue-800", "live" => "bg-red-100 text-red-800 animate-pulse",
      "scheduled" => "bg-gray-100 text-gray-600", "cancelled" => "bg-red-100 text-red-800"
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
end
