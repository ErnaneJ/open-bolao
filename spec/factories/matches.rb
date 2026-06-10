FactoryBot.define do
  factory :match do
    association :home_team, factory: :team
    association :away_team, factory: :team
    scheduled_at { 1.day.from_now }
    status { :scheduled }

    trait :finished do
      status { :finished }
      home_score { 2 }
      away_score { 1 }
    end

    trait :live do
      status { :live }
      home_score { 1 }
      away_score { 0 }
    end

    trait :with_tournament do
      association :tournament
    end
  end
end
