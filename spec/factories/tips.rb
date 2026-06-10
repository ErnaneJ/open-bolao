FactoryBot.define do
  factory :tip do
    association :pool
    association :user
    association :match
    home_score_tip { 1 }
    away_score_tip { 0 }
  end
end
