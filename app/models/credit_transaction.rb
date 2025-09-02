class CreditTransaction < Transaction
  validates :source_wallet, absence: true
  validates :target_wallet, presence: true
  
  def self.create_for_wallet(wallet, amount, description = nil)
    transaction do
      credit = create!(
        transaction_type: 'Credit',
        target_wallet: wallet,
        amount_cents: amount.is_a?(Money) ? amount.cents : amount,
        description: description || "Credit to wallet ##{wallet.id}"
      )
      credit.complete!
      wallet.update_balance!
      credit
    end
  end
end
