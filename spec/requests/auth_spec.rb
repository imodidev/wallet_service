require 'rails_helper'

RSpec.describe 'Auth API', type: :request do
  describe 'POST /auth/sign_in' do
    let(:user) { create(:user, password: 'password123') }
    
    context 'with valid credentials' do
      it 'returns a session token' do
        post '/auth/sign_in', params: { email: user.email, password: 'password123' }
        
        expect_success_response
        expect(json_response).to have_key('token')
        expect(json_response).to have_key('expires_at')
        expect(json_response['user']['email']).to eq(user.email)
      end
    end
    
    context 'with invalid credentials' do
      it 'returns unauthorized for wrong password' do
        post '/auth/sign_in', params: { email: user.email, password: 'wrong' }
        
        expect_error_response(:unauthorized)
        expect(json_response['error']).to eq('Invalid email or password')
      end
      
      it 'returns unauthorized for non-existent user' do
        post '/auth/sign_in', params: { email: 'nonexistent@example.com', password: 'password' }
        
        expect_error_response(:unauthorized)
        expect(json_response['error']).to eq('Invalid email or password')
      end
    end
  end
  
  describe 'DELETE /auth/sign_out' do
    let(:user) { create(:user) }
    
    it 'destroys the session' do
      session = Session.create_for_user(user)
      
      delete '/auth/sign_out', headers: { 'Authorization' => "Bearer #{session.token}" }
      
      expect_success_response
      expect(json_response['message']).to eq('Signed out successfully')
      expect { session.reload }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end
  
  describe 'GET /auth/profile' do
    let(:user) { create(:user) }
    
    context 'with valid token' do
      it 'returns user profile' do
        get '/auth/profile', headers: auth_headers(user)
        
        expect_success_response
        expect(json_response['user']['email']).to eq(user.email)
        expect(json_response['user']).to have_key('balance')
      end
    end
    
    context 'without token' do
      it 'returns unauthorized' do
        get '/auth/profile'
        
        expect_error_response(:unauthorized)
      end
    end
    
    context 'with expired token' do
      it 'returns unauthorized' do
        session = create(:session, :expired, user: user)
        
        get '/auth/profile', headers: { 'Authorization' => "Bearer #{session.token}" }
        
        expect_error_response(:unauthorized)
      end
    end
  end
end
