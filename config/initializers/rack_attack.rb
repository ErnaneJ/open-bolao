class Rack::Attack
  # Throttle login attempts by IP
  throttle("logins/ip", limit: 5, period: 300) do |req|
    req.ip if req.path == "/users/sign_in" && req.post?
  end

  # Throttle login attempts by email
  throttle("logins/email", limit: 5, period: 300) do |req|
    if req.path == "/users/sign_in" && req.post?
      req.params.dig("user", "email")&.downcase&.strip
    end
  end

  # Throttle password reset requests
  throttle("password_resets/ip", limit: 5, period: 3600) do |req|
    req.ip if req.path == "/users/password" && req.post?
  end

  # Throttle general requests per user
  throttle("requests/user", limit: 60, period: 60) do |req|
    # Identify by session cookie (Devise sets warden.user.user.key)
    req.env["rack.session"]&.dig("warden.user.user.key", 0, 0)
  end

  # Throttle API-like endpoints harder
  throttle("webhook/deliveries", limit: 100, period: 60) do |req|
    req.ip if req.path.include?("/webhooks")
  end

  # Return JSON for API responses, HTML for browser
  self.throttled_responder = lambda do |req|
    match_data = req.env["rack.attack.match_data"]
    now = match_data[:epoch_time]
    retry_after = match_data[:period] - (now % match_data[:period])

    if req.env["HTTP_ACCEPT"]&.include?("application/json")
      [ 429, { "Content-Type" => "application/json", "Retry-After" => retry_after.to_s },
       [ { error: "Too many requests" }.to_json ] ]
    else
      [ 429, { "Content-Type" => "text/html", "Retry-After" => retry_after.to_s },
       [ "<h1>Too Many Requests</h1><p>Please try again in #{retry_after} seconds.</p>" ] ]
    end
  end
end
