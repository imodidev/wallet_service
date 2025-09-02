class Stock < ApplicationRecord
  has_one :wallet, as: :owner, dependent: :destroy
  
  validates :symbol, presence: true, uniqueness: true
  validates :name, presence: true
  
  def balance
    wallet&.balance || Money.new(0)
  end
  
  def current_price
    LatestStockPrice.price(symbol)
  end
  
  def ensure_wallet!
    return wallet if wallet.present?
    self.wallet = Wallet.new(owner: self)
    wallet.save!
    wallet
  end
  
  private
  
  def create_wallet!
    self.wallet = Wallet.new(owner: self)
    wallet.save!
    wallet
  end
end
