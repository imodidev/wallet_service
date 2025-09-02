class CreateWallets < ActiveRecord::Migration[8.0]
  def change
    create_table :wallets do |t|
      t.references :owner, polymorphic: true, null: false
      t.integer :balance_cents, default: 0, null: false
      t.string :currency, default: 'USD', null: false

      t.timestamps
    end
    
    add_index :wallets, [:owner_type, :owner_id], unique: true
  end
end
