FactoryBot.define do
  factory :wallet do
    association :owner, factory: :user
    balance_cents { 0 }
    currency { 'USD' }
    
    trait :with_balance do
      balance_cents { 10000 } # $100.00
    end
  end
end
