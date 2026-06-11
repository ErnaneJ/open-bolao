FactoryBot.define do
  factory :tournament do
    sequence(:name) { |n| "Tournament #{n}" }
    sport { :football }
    season { "2026" }
    status { :active }
    external_provider { :no_provider }
    association :created_by, factory: [ :user, :super_admin ]
  end
end
