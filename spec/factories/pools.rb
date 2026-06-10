FactoryBot.define do
  factory :pool do
    sequence(:name) { |n| "Pool #{n}" }
    association :admin, factory: [:user, :admin]
    status { :open }
    visibility { :public_pool }
    pool_scope { :tournament }
    lock_before_minutes { 5 }
    scoring_config { Pool::SCORING_DEFAULTS }
    special_bets_config { Pool::SPECIAL_BETS_DEFAULTS }
    association :tournament

    trait :single_match do
      pool_scope { :single_match }
      tournament { nil }
      special_bets_config { {} }
      association :match
    end

    trait :with_knockout_multiplier do
      scoring_config { Pool::SCORING_DEFAULTS.merge("knockout_multiplier" => 2.0) }
    end
  end
end
