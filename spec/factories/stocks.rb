FactoryBot.define do
  factory :stock do
    symbol { Faker::Finance.ticker }
    name { Faker::Company.name }
  end
end
