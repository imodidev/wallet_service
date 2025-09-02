class Team < ApplicationRecord
  has_one :wallet, as: :owner, dependent: :destroy
  
  validates :name, presence: true, uniqueness: true
  
  def balance
    wallet&.balance || Money.new(0)
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
