require 'rails_helper'

RSpec.describe Transaction, type: :model do
  describe 'validations' do
    subject { build(:transaction, :transfer) }
    
    it { should validate_presence_of(:amount_cents) }
    it { should validate_presence_of(:transaction_type) }
    it { should validate_presence_of(:status) }
    it { should validate_presence_of(:currency) }
    it { should validate_numericality_of(:amount_cents).is_greater_than(0) }
    it { should validate_inclusion_of(:transaction_type).in_array(%w[Credit Debit Transfer]) }
    it { should validate_inclusion_of(:status).in_array(%w[pending completed failed]) }
  end
  
  describe 'associations' do
    it { should belong_to(:source_wallet).optional }
    it { should belong_to(:target_wallet).optional }
  end
  
  describe 'monetization' do
    let(:transaction) { create(:transaction, amount_cents: 1500) }
    
    it 'monetizes amount_cents' do
      expect(transaction.amount).to eq(Money.new(1500))
      expect(transaction.amount.format).to eq('15.00')
    end
  end
  
  describe 'wallet requirement validations' do
    context 'for credit transactions' do
      it 'requires target_wallet and prohibits source_wallet' do
        transaction = build(:transaction, :credit)
        expect(transaction).to be_valid
        
        transaction.source_wallet = create(:wallet)
        expect(transaction).not_to be_valid
        expect(transaction.errors[:source_wallet]).to include('must be nil for credit transactions')
        
        transaction.source_wallet = nil
        transaction.target_wallet = nil
        expect(transaction).not_to be_valid
        expect(transaction.errors[:target_wallet]).to include('must be present for credit transactions')
      end
    end
    
    context 'for debit transactions' do
      it 'requires source_wallet and prohibits target_wallet' do
        transaction = build(:transaction, transaction_type: 'Debit')
        transaction.source_wallet = create(:wallet, :with_balance)
        transaction.target_wallet = nil
        
        # This should be valid (without balance validation)
        transaction.valid?
        expect(transaction.errors[:source_wallet]).to be_empty
        expect(transaction.errors[:target_wallet]).to be_empty
        
        transaction.target_wallet = create(:wallet)
        expect(transaction).not_to be_valid
        expect(transaction.errors[:target_wallet]).to include('must be nil for debit transactions')
        
        transaction.target_wallet = nil
        transaction.source_wallet = nil
        expect(transaction).not_to be_valid
        expect(transaction.errors[:source_wallet]).to include('must be present for debit transactions')
      end
    end
    
    context 'for transfer transactions' do
      it 'requires both source_wallet and target_wallet' do
        transaction = build(:transaction, transaction_type: 'Transfer')
        transaction.source_wallet = create(:wallet, :with_balance)
        transaction.target_wallet = create(:wallet)
        
        # This should be valid (without balance validation)
        transaction.valid?
        expect(transaction.errors[:source_wallet]).to be_empty
        expect(transaction.errors[:target_wallet]).to be_empty
        
        transaction.source_wallet = nil
        expect(transaction).not_to be_valid
        expect(transaction.errors[:source_wallet]).to include('must be present for transfer transactions')
        
        transaction.source_wallet = create(:wallet, :with_balance)
        transaction.target_wallet = nil
        expect(transaction).not_to be_valid
        expect(transaction.errors[:target_wallet]).to include('must be present for transfer transactions')
      end
      
      it 'prohibits same source and target wallet' do
        wallet = create(:wallet, :with_balance)
        transaction = build(:transaction, transaction_type: 'Transfer', source_wallet: wallet, target_wallet: wallet)
        expect(transaction).not_to be_valid
        expect(transaction.errors[:target_wallet]).to include('cannot be the same as source wallet')
      end
    end
  end
  
  describe 'sufficient balance validation' do
    let(:source_wallet) { create(:wallet) }
    
    before do
      # Create a completed credit transaction to give the wallet balance
      create(:transaction, transaction_type: 'Credit', target_wallet: source_wallet, 
             amount_cents: 2000, status: 'completed')
      source_wallet.update_balance!
    end
    
    context 'for debit transactions' do
      it 'validates sufficient balance' do
        transaction = build(:transaction, transaction_type: 'Debit', source_wallet: source_wallet, amount_cents: 2500)
        expect(transaction).not_to be_valid
        expect(transaction.errors[:amount]).to include('insufficient balance in source wallet')
      end
      
      it 'allows transaction when balance is sufficient' do
        transaction = build(:transaction, transaction_type: 'Debit', source_wallet: source_wallet, amount_cents: 1500)
        expect(transaction).to be_valid
      end
    end
    
    context 'for transfer transactions' do
      let(:source_wallet) { create(:wallet) }
      let(:target_wallet) { create(:wallet) }
      
      before do
        # Give source wallet balance using WalletService to ensure proper setup
        WalletService.credit(source_wallet, 3000, 'Initial balance')
      end
      
      it 'validates sufficient balance' do
        # Check the balance is set correctly
        current_balance = source_wallet.reload.balance_cents
        
        transaction = build(:transaction, transaction_type: 'Transfer', 
                           source_wallet: source_wallet, target_wallet: target_wallet, 
                           amount_cents: current_balance + 1000) # More than available
        
        expect(transaction.valid?).to be false
        expect(transaction.errors[:amount]).to include('insufficient balance in source wallet')
      end
    end
  end
  
  describe 'scopes' do
    before do
      source_wallet = create(:wallet)
      target_wallet = create(:wallet)
      
      @completed = create(:transaction, transaction_type: 'Transfer', 
                         source_wallet: source_wallet, target_wallet: target_wallet,
                         status: 'completed')
      @pending = create(:transaction, transaction_type: 'Transfer',
                       source_wallet: source_wallet, target_wallet: target_wallet,
                       status: 'pending')
      @failed = create(:transaction, transaction_type: 'Transfer',
                      source_wallet: source_wallet, target_wallet: target_wallet,
                      status: 'failed')
      @credit = create(:transaction, transaction_type: 'Credit', target_wallet: target_wallet)
      @debit = create(:transaction, transaction_type: 'Debit', source_wallet: source_wallet)
    end
    
    it 'filters by status' do
      expect(Transaction.completed).to include(@completed)
      expect(Transaction.pending).to include(@pending)
      expect(Transaction.failed).to include(@failed)
    end
    
    it 'filters by transaction type' do
      expect(Transaction.credits).to include(@credit)
      expect(Transaction.debits).to include(@debit)
      expect(Transaction.transfers).to include(@completed, @pending, @failed)
    end
  end
  
  describe 'status methods' do
    let(:transaction) do 
      source_wallet = create(:wallet)
      target_wallet = create(:wallet)
      create(:transaction, transaction_type: 'Transfer', 
             source_wallet: source_wallet, target_wallet: target_wallet)
    end
    
    describe '#complete!' do
      it 'changes status to completed' do
        expect { transaction.complete! }.to change { transaction.status }.to('completed')
      end
    end
    
    describe '#fail!' do
      it 'changes status to failed' do
        expect { transaction.fail! }.to change { transaction.status }.to('failed')
      end
    end
  end
  
  describe 'type checking methods' do
    it 'correctly identifies transaction types' do
      target_wallet = create(:wallet)
      source_wallet = create(:wallet)
      
      credit = create(:transaction, transaction_type: 'Credit', target_wallet: target_wallet)
      debit = create(:transaction, transaction_type: 'Debit', source_wallet: source_wallet)
      transfer = create(:transaction, transaction_type: 'Transfer', 
                       source_wallet: source_wallet, target_wallet: target_wallet)
      
      expect(credit.credit?).to be true
      expect(credit.debit?).to be false
      expect(credit.transfer?).to be false
      
      expect(debit.credit?).to be false
      expect(debit.debit?).to be true
      expect(debit.transfer?).to be false
      
      expect(transfer.credit?).to be false
      expect(transfer.debit?).to be false
      expect(transfer.transfer?).to be true
    end
  end
end
