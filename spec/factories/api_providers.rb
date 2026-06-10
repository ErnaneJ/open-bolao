FactoryBot.define do
  factory :api_provider do
    name { "Worldcup 2026" }
    provider_type { :worldcup2026 }
    base_url { "https://worldcup26.ir" }
    active { true }
  end
end
