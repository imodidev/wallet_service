class CreateTransactions < ActiveRecord::Migration[8.0]
  def change
    create_table :transactions do |t|
      t.integer :amount_cents, null: false
      t.string :transaction_type, null: false
      t.references :source_wallet, null: true, foreign_key: { to_table: :wallets }
      t.references :target_wallet, null: true, foreign_key: { to_table: :wallets }
      t.text :description
      t.string :status, default: 'pending', null: false
      t.string :currency, default: 'USD', null: false

      t.timestamps
    end
    
    add_index :transactions, :transaction_type
    add_index :transactions, :status
    add_index :transactions, :created_at
  end
end
