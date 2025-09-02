class DebitTransaction < Transaction
  validates :source_wallet, presence: true
  validates :target_wallet, absence: true
  
  def self.create_for_wallet(wallet, amount, description = nil)
    transaction do
      debit = create!(
        transaction_type: 'Debit',
        source_wallet: wallet,
        amount_cents: amount.is_a?(Money) ? amount.cents : amount,
        description: description || "Debit from wallet ##{wallet.id}"
      )
      debit.complete!
      wallet.update_balance!
      debit
    end
  end
end
