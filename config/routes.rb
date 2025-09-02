Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Authentication routes
  post 'auth/sign_in', to: 'auth#sign_in'
  delete 'auth/sign_out', to: 'auth#sign_out'
  get 'auth/profile', to: 'auth#profile'
  
  # Wallet routes
  resources :wallets, only: [:show] do
    member do
      post :credit
      post :debit
      post :transfer
      get :transactions
    end
  end
  
  # Owner-specific wallet routes
  get 'wallets/owner/:owner_type/:owner_id', to: 'wallets#show'
  post 'wallets/owner/:owner_type/:owner_id/credit', to: 'wallets#credit'
  post 'wallets/owner/:owner_type/:owner_id/debit', to: 'wallets#debit'
  post 'wallets/owner/:owner_type/:owner_id/transfer', to: 'wallets#transfer'
  get 'wallets/owner/:owner_type/:owner_id/transactions', to: 'wallets#transactions'
  
  # Stock routes
  resources :stocks, only: [:index, :show, :create] do
    member do
      get :price
      get :wallet
    end
    
    collection do
      get :prices
      get :price_all
    end
  end
  
  # Team routes
  resources :teams, only: [:index, :show, :create] do
    member do
      get :wallet
    end
  end

  # Defines the root path route ("/")
  root "rails/health#show"
end
