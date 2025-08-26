class CreateWallets < ActiveRecord::Migration[8.0]
  def change
    create_table :wallets do |t|
      t.references :owner, polymorphic: true, null: false, index: true
      t.string :currency, null: false, default: "IDR"
      t.boolean :locked, null: false, default: false
      t.string :name
      t.timestamps
    end
    add_index :wallets, [ :owner_type, :owner_id, :name ], unique: true, where: "name IS NOT NULL"
  end
end
