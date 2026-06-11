if defined?(RailsRealtimeErd)
  RailsRealtimeErd.configure do |c|
    c.enabled_environments = %w[development test production]
  end
end
