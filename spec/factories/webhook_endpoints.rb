FactoryBot.define do
  factory :webhook_endpoint do
    association :owner, factory: :pool
    url { "https://example.com/webhook" }
    events { ["goal"] }
    active { true }
  end
end
