class WalletService
  class InsufficientFundsError < StandardError; end
  class WalletNotFoundError < StandardError; end
  class InvalidAmountError < StandardError; end
  
  def self.credit(wallet, amount, description = nil)
    validate_amount!(amount)
    validate_wallet!(wallet)
    
    ActiveRecord::Base.transaction do
      CreditTransaction.create_for_wallet(wallet, amount, description)
    end
  rescue ActiveRecord::RecordInvalid => e
    raise StandardError, "Credit failed: #{e.message}"
  end
  
  def self.debit(wallet, amount, description = nil)
    validate_amount!(amount)
    validate_wallet!(wallet)
    
    amount_cents = amount.is_a?(Money) ? amount.cents : amount
    raise InsufficientFundsError, "Insufficient funds" unless wallet.sufficient_balance?(amount_cents)
    
    ActiveRecord::Base.transaction do
      DebitTransaction.create_for_wallet(wallet, amount, description)
    end
  rescue ActiveRecord::RecordInvalid => e
    raise StandardError, "Debit failed: #{e.message}"
  end
  
  def self.transfer(source_wallet, target_wallet, amount, description = nil)
    validate_amount!(amount)
    validate_wallet!(source_wallet)
    validate_wallet!(target_wallet)
    
    if source_wallet == target_wallet
      raise StandardError, "Cannot transfer to the same wallet"
    end
    
    amount_cents = amount.is_a?(Money) ? amount.cents : amount
    raise InsufficientFundsError, "Insufficient funds" unless source_wallet.sufficient_balance?(amount_cents)
    
    ActiveRecord::Base.transaction do
      TransferTransaction.create_transfer(source_wallet, target_wallet, amount, description)
    end
  rescue ActiveRecord::RecordInvalid => e
    raise StandardError, "Transfer failed: #{e.message}"
  end
  
  def self.balance(wallet)
    validate_wallet!(wallet)
    wallet.balance
  end
  
  def self.transaction_history(wallet, limit: 100, offset: 0)
    validate_wallet!(wallet)
    
    wallet.all_transactions
          .includes(:source_wallet, :target_wallet)
          .order(created_at: :desc)
          .limit(limit)
          .offset(offset)
  end
  
  private
  
  def self.validate_amount!(amount)
    amount_value = amount.is_a?(Money) ? amount.cents : amount
    raise InvalidAmountError, "Amount must be positive" unless amount_value && amount_value > 0
  end
  
  def self.validate_wallet!(wallet)
    raise WalletNotFoundError, "Wallet not found" unless wallet.is_a?(Wallet)
  end
end
