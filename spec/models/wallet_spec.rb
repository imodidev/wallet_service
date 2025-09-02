require 'rails_helper'

RSpec.describe Wallet, type: :model do
  describe 'validations' do
    subject { build(:wallet) }
    
    it { should validate_presence_of(:balance_cents) }
    it { should validate_presence_of(:currency) }
    it { should validate_presence_of(:owner) }
    it { should validate_uniqueness_of(:owner_id).scoped_to(:owner_type) }
    it { should validate_numericality_of(:balance_cents).is_greater_than_or_equal_to(0) }
  end
  
  describe 'associations' do
    it { should belong_to(:owner) }
    it { should have_many(:outgoing_transactions).class_name('Transaction') }
    it { should have_many(:incoming_transactions).class_name('Transaction') }
  end
  
  describe 'monetization' do
    let(:wallet) { create(:wallet) }
    
    before do
      # Create a completed credit transaction to give the wallet balance
      create(:transaction, transaction_type: 'Credit', target_wallet: wallet, 
             amount_cents: 1500, status: 'completed')
    end
    
    it 'monetizes balance_cents' do
      expect(wallet.balance).to eq(Money.new(1500))
      expect(wallet.balance.format).to eq('15.00')
    end
  end
  
  describe '#calculate_balance' do
    let(:wallet) { create(:wallet) }
    let(:other_wallet) { create(:wallet) }
    
    before do
      # Create completed credit transaction (incoming)
      create(:transaction, :credit, :completed, target_wallet: wallet, amount_cents: 5000)
      
      # Create completed debit transaction (outgoing)
      create(:transaction, :debit, :completed, source_wallet: wallet, amount_cents: 2000)
      
      # Create pending transaction (should not affect balance)
      create(:transaction, :credit, target_wallet: wallet, amount_cents: 1000)
    end
    
    it 'calculates balance from completed transactions' do
      expect(wallet.calculate_balance).to eq(3000) # 5000 - 2000
    end
  end
  
  describe '#update_balance!' do
    let(:wallet) { create(:wallet) }
    
    before do
      create(:transaction, :credit, :completed, target_wallet: wallet, amount_cents: 5000)
    end
    
    it 'updates the wallet balance' do
      expect { wallet.update_balance! }.to change { wallet.balance_cents }.to(5000)
    end
  end
  
  describe '#sufficient_balance?' do
    let(:wallet) { create(:wallet) }
    
    before do
      # Create a completed credit transaction to give the wallet balance
      create(:transaction, transaction_type: 'Credit', target_wallet: wallet, 
             amount_cents: 1000, status: 'completed')
    end
    
    it 'returns true when balance is sufficient' do
      expect(wallet.sufficient_balance?(500)).to be true
      expect(wallet.sufficient_balance?(1000)).to be true
      expect(wallet.sufficient_balance?(Money.new(500))).to be true
    end
    
    it 'returns false when balance is insufficient' do
      expect(wallet.sufficient_balance?(1500)).to be false
      expect(wallet.sufficient_balance?(Money.new(1500))).to be false
    end
    
    it 'returns false for invalid amounts' do
      expect(wallet.sufficient_balance?(nil)).to be false
      expect(wallet.sufficient_balance?(0)).to be false
      expect(wallet.sufficient_balance?(-100)).to be false
    end
  end
  
  describe '#all_transactions' do
    let(:wallet) { create(:wallet) }
    let(:other_wallet) { create(:wallet) }
    
    before do
      @credit = create(:transaction, :credit, target_wallet: wallet)
      @debit = create(:transaction, :debit, source_wallet: wallet)
      @transfer_in = create(:transaction, :transfer, target_wallet: wallet, source_wallet: other_wallet)
      @transfer_out = create(:transaction, :transfer, source_wallet: wallet, target_wallet: other_wallet)
      @unrelated = create(:transaction, :transfer, source_wallet: other_wallet, target_wallet: create(:wallet))
    end
    
    it 'returns all transactions related to the wallet' do
      transactions = wallet.all_transactions
      expect(transactions).to include(@credit, @debit, @transfer_in, @transfer_out)
      expect(transactions).not_to include(@unrelated)
    end
  end
end
