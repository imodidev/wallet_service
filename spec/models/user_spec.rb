require 'rails_helper'

RSpec.describe User, type: :model do
  describe 'validations' do
    subject { build(:user) }
    
    it { should validate_presence_of(:email) }
    it { should validate_uniqueness_of(:email) }
    it { should validate_presence_of(:password) }
  end
  
  describe 'associations' do
    it { should have_one(:wallet).dependent(:destroy) }
    it { should have_many(:sessions).dependent(:destroy) }
  end
  
  describe 'callbacks' do
    it 'creates a wallet when ensure_wallet! is called' do
      user = create(:user)
      user.ensure_wallet!
      expect(user.wallet).to be_present
      expect(user.wallet.balance_cents).to eq(0)
    end
  end
  
  describe '#balance' do
    let(:user) { create(:user) }
    
    it 'returns wallet balance' do
      user.ensure_wallet!
      expect(user.balance).to eq(Money.new(0))
    end
    
    it 'returns zero when wallet is nil' do
      expect(user.balance).to eq(Money.new(0))
    end
  end
  
  describe '#authenticate' do
    let(:user) { create(:user, password: 'password123') }
    
    it 'returns user when password is correct' do
      expect(user.authenticate('password123')).to eq(user)
    end
    
    it 'returns false when password is incorrect' do
      expect(user.authenticate('wrong')).to be_falsey
    end
  end
end
