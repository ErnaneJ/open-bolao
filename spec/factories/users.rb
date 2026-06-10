FactoryBot.define do
  factory :user do
    sequence(:email) { |n| "user#{n}@example.com" }
    name { Faker::Name.name }
    password { "password123!" }
    password_confirmation { "password123!" }
    confirmed_at { Time.current }
    role { :user }
    locale { :pt_br }

    trait :admin do
      role { :admin }
    end

    trait :super_admin do
      role { :super_admin }
    end
  end
end
