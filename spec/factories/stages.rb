FactoryBot.define do
  factory :stage do
    association :tournament
    sequence(:name) { |n| "Stage #{n}" }
    stage_type { :group }
    order_position { 0 }

    trait :final do
      stage_type { :final }
      name { "Final" }
    end

    trait :semifinal do
      stage_type { :semifinal }
      name { "Semifinal" }
    end

    trait :knockout do
      stage_type { :round_of_16 }
    end
  end
end
