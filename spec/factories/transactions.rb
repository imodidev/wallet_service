FactoryBot.define do
  factory :transaction do
    amount_cents { 1000 }
    transaction_type { 'Transfer' }
    description { 'Test transaction' }
    status { 'pending' }
    currency { 'USD' }
    
    # Skip validation by default for test setup
    to_create { |instance| instance.save(validate: false) }
    
    trait :credit do
      transaction_type { 'Credit' }
      source_wallet { nil }
      association :target_wallet, factory: :wallet
    end
    
    trait :debit do
      transaction_type { 'Debit' }
      association :source_wallet, factory: [:wallet, :with_balance]
      target_wallet { nil }
    end
    
    trait :transfer do
      transaction_type { 'Transfer' }
      association :source_wallet, factory: [:wallet, :with_balance]
      association :target_wallet, factory: :wallet
    end
    
    trait :completed do
      status { 'completed' }
    end
    
    # For tests that specifically need validation
    trait :validated do
      to_create { |instance| instance.save! }
    end
  end
end
