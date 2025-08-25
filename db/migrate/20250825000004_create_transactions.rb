class CreateTransactions < ActiveRecord::Migration[8.0]
  def change
    create_table :transactions do |t|
      t.string :type, null: false
      t.references :source_wallet, foreign_key: { to_table: :wallets }
      t.references :target_wallet, foreign_key: { to_table: :wallets }
      t.decimal :amount, precision: 20, scale: 6, null: false
      t.string  :currency, null: false, default: "IDR"
      t.string  :status, null: false, default: "posted"
      t.string  :reference
      t.string  :idempotency_key
      t.jsonb   :metadata, null: false, default: {}
      t.datetime :occurred_at, null: false
      t.references :created_by, foreign_key: { to_table: :users }
      t.timestamps
    end
    add_index :transactions, :idempotency_key, unique: true, where: "idempotency_key IS NOT NULL"
    add_index :transactions, :reference
    add_check_constraint :transactions, "amount > 0", name: "transactions_amount_positive"
  end
end
