class TransferTransaction < Transaction
  validates :source_wallet, presence: true
  validates :target_wallet, presence: true
  
  def self.create_transfer(source_wallet, target_wallet, amount, description = nil)
    transaction do
      transfer = create!(
        transaction_type: 'Transfer',
        source_wallet: source_wallet,
        target_wallet: target_wallet,
        amount_cents: amount.is_a?(Money) ? amount.cents : amount,
        description: description || "Transfer from wallet ##{source_wallet.id} to wallet ##{target_wallet.id}"
      )
      transfer.complete!
      source_wallet.update_balance!
      target_wallet.update_balance!
      transfer
    end
  end
end
