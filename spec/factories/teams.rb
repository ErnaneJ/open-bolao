FactoryBot.define do
  factory :team do
    sequence(:name) { |n| "Team #{n}" }
    short_name { name.first(3).upcase }
    country_code { name.downcase.first(3) }
  end
end
