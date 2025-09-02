class Transaction < ApplicationRecord
  monetize :amount_cents
  
  belongs_to :source_wallet, class_name: 'Wallet', optional: true
  belongs_to :target_wallet, class_name: 'Wallet', optional: true
  
  validates :amount_cents, presence: true, numericality: { greater_than: 0 }
  validates :transaction_type, presence: true, inclusion: { in: %w[Credit Debit Transfer] }
  validates :status, presence: true, inclusion: { in: %w[pending completed failed] }
  validates :currency, presence: true
  
  validate :validate_wallet_requirements
  validate :validate_sufficient_balance
  
  before_create :set_default_status
  after_update :update_wallet_balances, if: :saved_change_to_status?
  
  scope :completed, -> { where(status: 'completed') }
  scope :pending, -> { where(status: 'pending') }
  scope :failed, -> { where(status: 'failed') }
  scope :credits, -> { where(transaction_type: 'Credit') }
  scope :debits, -> { where(transaction_type: 'Debit') }
  scope :transfers, -> { where(transaction_type: 'Transfer') }
  
  def complete!
    update!(status: 'completed')
  end
  
  def fail!
    update!(status: 'failed')
  end
  
  def credit?
    transaction_type == 'Credit'
  end
  
  def debit?
    transaction_type == 'Debit'
  end
  
  def transfer?
    transaction_type == 'Transfer'
  end
  
  private
  
  def validate_wallet_requirements
    case transaction_type
    when 'Credit'
      if source_wallet.present?
        errors.add(:source_wallet, 'must be nil for credit transactions')
      end
      if target_wallet.blank?
        errors.add(:target_wallet, 'must be present for credit transactions')
      end
    when 'Debit'
      if source_wallet.blank?
        errors.add(:source_wallet, 'must be present for debit transactions')
      end
      if target_wallet.present?
        errors.add(:target_wallet, 'must be nil for debit transactions')
      end
    when 'Transfer'
      if source_wallet.blank?
        errors.add(:source_wallet, 'must be present for transfer transactions')
      end
      if target_wallet.blank?
        errors.add(:target_wallet, 'must be present for transfer transactions')
      end
      if source_wallet == target_wallet
        errors.add(:target_wallet, 'cannot be the same as source wallet')
      end
    end
  end
  
  def validate_sufficient_balance
    return unless new_record? # Only validate on creation
    return unless source_wallet && (debit? || transfer?)
    
    unless source_wallet.sufficient_balance?(amount_cents)
      errors.add(:amount, 'insufficient balance in source wallet')
    end
  end
  
  def set_default_status
    self.status ||= 'pending'
  end
  
  def update_wallet_balances
    return unless status == 'completed'
    
    # Don't update balance automatically - balance is calculated on demand
    # This prevents the validation error we're seeing
  end
end
