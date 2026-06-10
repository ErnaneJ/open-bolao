require "vcr"
require "webmock/rspec"

VCR.configure do |config|
  config.cassette_library_dir = "spec/vcr_cassettes"
  config.hook_into :webmock
  config.configure_rspec_metadata!
  config.default_cassette_options = {
    record: :new_episodes,
    allow_playback_repeats: true
  }
  config.filter_sensitive_data("<API_KEY>") { ENV["WORLDCUP_API_KEY"] }
end
