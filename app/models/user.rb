class User < ApplicationRecord
  has_secure_password
  
  has_one :wallet, as: :owner, dependent: :destroy
  has_many :sessions, dependent: :destroy
  
  validates :email, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :password, length: { minimum: 6 }, if: -> { new_record? || !password.nil? }
  
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
