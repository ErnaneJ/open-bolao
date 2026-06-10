Sidekiq.configure_server do |config|
  config.on(:startup) do
    schedule_file = Rails.root.join("config/schedule.yml")
    if schedule_file.exist?
      Sidekiq::Cron::Job.load_from_hash(YAML.load_file(schedule_file))
    end
  end
end
