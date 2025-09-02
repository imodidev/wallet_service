FactoryBot.define do
  factory :team do
    name { Faker::Company.name }
    description { Faker::Lorem.paragraph }
  end
end
