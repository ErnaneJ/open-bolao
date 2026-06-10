FactoryBot.define do
  factory :sync_schedule do
    association :schedulable, factory: :tournament
    association :api_provider
    enabled { true }
    interval_seconds { 120 }
    run_only_on_match_days { false }
    consecutive_failures { 0 }
  end
end
