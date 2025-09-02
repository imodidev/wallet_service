require 'rails_helper'

RSpec.describe 'Wallets API', type: :request do
  let(:user) { create(:user) }
  let(:user_wallet) { user.ensure_wallet! }
  let(:team) { create(:team) }
  let(:team_wallet) { team.ensure_wallet! }
  
  before do
    # Add some balance to user wallet for testing
    CreditTransaction.create_for_wallet(user_wallet, 10000)
  end
  
  describe 'GET /wallets/:id' do
    it 'returns wallet information' do
      get "/wallets/#{user_wallet.id}", headers: auth_headers(user)
      
      expect_success_response
      expect(json_response['wallet']['id']).to eq(user_wallet.id)
      expect(json_response['wallet']['balance_cents']).to eq(10000)
      expect(json_response['wallet']).to have_key('balance')
    end
    
    it 'returns not found for non-existent wallet' do
      get "/wallets/99999", headers: auth_headers(user)
      
      expect_error_response(:not_found)
    end
  end
  
  describe 'GET /wallets/owner/:owner_type/:owner_id' do
    it 'returns wallet for User owner' do
      get "/wallets/owner/User/#{user.id}", headers: auth_headers(user)
      
      expect_success_response
      expect(json_response['wallet']['owner_type']).to eq('User')
      expect(json_response['wallet']['owner_id']).to eq(user.id)
    end
    
    it 'returns wallet for Team owner' do
      get "/wallets/owner/Team/#{team.id}", headers: auth_headers(user)
      
      expect_success_response
      expect(json_response['wallet']['owner_type']).to eq('Team')
      expect(json_response['wallet']['owner_id']).to eq(team.id)
    end
  end
  
  describe 'POST /wallets/:id/credit' do
    it 'credits the wallet' do
      post "/wallets/#{user_wallet.id}/credit", 
           params: { amount_cents: 5000, description: 'Test credit' },
           headers: auth_headers(user)
      
      expect_success_response
      expect(json_response['transaction']['transaction_type']).to eq('Credit')
      expect(json_response['transaction']['amount_cents']).to eq(5000)
      expect(json_response['new_balance']).to eq('150.00')
    end
    
    it 'returns error for invalid amount' do
      post "/wallets/#{user_wallet.id}/credit",
           params: { amount_cents: 0 },
           headers: auth_headers(user)
      
      expect_error_response(:bad_request)
    end
  end
  
  describe 'POST /wallets/:id/debit' do
    it 'debits the wallet' do
      post "/wallets/#{user_wallet.id}/debit",
           params: { amount_cents: 3000, description: 'Test debit' },
           headers: auth_headers(user)
      
      expect_success_response
      expect(json_response['transaction']['transaction_type']).to eq('Debit')
      expect(json_response['transaction']['amount_cents']).to eq(3000)
      expect(json_response['new_balance']).to eq('70.00')
    end
    
    it 'returns error for insufficient funds' do
      post "/wallets/#{user_wallet.id}/debit",
           params: { amount_cents: 15000 },
           headers: auth_headers(user)
      
      expect_error_response(:bad_request)
      expect(json_response['error']).to include('Insufficient funds')
    end
  end
  
  describe 'POST /wallets/:id/transfer' do
    it 'transfers money between wallets' do
      post "/wallets/#{user_wallet.id}/transfer",
           params: { 
             target_wallet_id: team_wallet.id, 
             amount_cents: 4000, 
             description: 'Test transfer' 
           },
           headers: auth_headers(user)
      
      expect_success_response
      expect(json_response['transaction']['transaction_type']).to eq('Transfer')
      expect(json_response['transaction']['amount_cents']).to eq(4000)
      expect(json_response['source_balance']).to eq('60.00')
      expect(json_response['target_balance']).to eq('40.00')
    end
    
    it 'returns error for non-existent target wallet' do
      post "/wallets/#{user_wallet.id}/transfer",
           params: { target_wallet_id: 99999, amount_cents: 1000 },
           headers: auth_headers(user)
      
      expect_error_response(:not_found)
      expect(json_response['error']).to eq('Target wallet not found')
    end
    
    it 'returns error for insufficient funds' do
      post "/wallets/#{user_wallet.id}/transfer",
           params: { target_wallet_id: team_wallet.id, amount_cents: 15000 },
           headers: auth_headers(user)
      
      expect_error_response(:bad_request)
      expect(json_response['error']).to include('Insufficient funds')
    end
  end
  
  describe 'GET /wallets/:id/transactions' do
    before do
      # Create some transactions
      DebitTransaction.create_for_wallet(user_wallet, 2000, 'Test debit')
      TransferTransaction.create_transfer(user_wallet, team_wallet, 1000, 'Test transfer')
    end
    
    it 'returns transaction history' do
      get "/wallets/#{user_wallet.id}/transactions", headers: auth_headers(user)
      
      expect_success_response
      expect(json_response['transactions']).to be_an(Array)
      expect(json_response['transactions'].length).to eq(3) # 1 credit + 1 debit + 1 transfer
      expect(json_response).to have_key('total_count')
    end
    
    it 'supports pagination' do
      get "/wallets/#{user_wallet.id}/transactions?limit=2&offset=1", 
          headers: auth_headers(user)
      
      expect_success_response
      expect(json_response['transactions'].length).to eq(2)
    end
  end
  
  context 'without authentication' do
    it 'returns unauthorized' do
      get "/wallets/#{user_wallet.id}"
      
      expect_error_response(:unauthorized)
    end
  end
end
