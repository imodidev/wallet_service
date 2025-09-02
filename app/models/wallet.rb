class Wallet < ApplicationRecord
  monetize :balance_cents
  
  belongs_to :owner, polymorphic: true
  has_many :outgoing_transactions, class_name: 'Transaction', foreign_key: 'source_wallet_id', dependent: :restrict_with_error
  has_many :incoming_transactions, class_name: 'Transaction', foreign_key: 'target_wallet_id', dependent: :restrict_with_error
  
  validates :balance_cents, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :currency, presence: true
  validates :owner, presence: true
  validates :owner_id, uniqueness: { scope: :owner_type }
  
  def all_transactions
    Transaction.where("source_wallet_id = ? OR target_wallet_id = ?", id, id)
  end
  
  def calculated_balance_cents
    credits = incoming_transactions.where(status: 'completed').sum(:amount_cents)
    debits = outgoing_transactions.where(status: 'completed').sum(:amount_cents)
    credits - debits
  end
  
  def calculate_balance
    calculated_balance_cents
  end
  
  def balance
    # Always calculate balance from transactions for accuracy
    balance_amount = calculated_balance_cents
    # Don't use empty currency for validation tests
    currency_code = currency.present? ? currency : 'USD'
    Money.new(balance_amount, currency_code)
  end
  
  def update_balance!
    calculated_balance = calculated_balance_cents
    update!(balance_cents: calculated_balance)
  end
  
  def sufficient_balance?(amount)
    return false if amount.nil? || amount <= 0
    amount_cents = amount.is_a?(Money) ? amount.cents : amount
    calculated_balance_cents >= amount_cents
  end
end
