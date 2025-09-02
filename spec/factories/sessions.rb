FactoryBot.define do
  factory :session do
    association :user
    token { SecureRandom.hex(32) }
    expires_at { 24.hours.from_now }
    
    trait :expired do
      # Override the expiration after creation to bypass callbacks
      after(:create) do |session|
        session.update_column(:expires_at, 1.hour.ago)
      end
    end
  end
end
