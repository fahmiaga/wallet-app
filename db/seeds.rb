# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end

puts "Creating users..."
u1 = User.create!(email: "alice@example.com", password: "secret123", name: "Alice wonder")
u2 = User.create!(email: "bob@example.com",   password: "secret123", name: "Bob Sadin")

t1 = Team.create!(name: "Avengers")

s1 = Stock.create!(symbol: "AAPL")

# Money mover with Alice as actor
mover = Wallets::MoneyMover.new(actor: u1)

mover.deposit!(target_wallet: u1.wallet, amount: 1_000_000, currency: "IDR", reference: "SEED-DEP-ALICE")

mover.transfer!(source_wallet: u1.wallet, target_wallet: u2.wallet, amount: 250_000, currency: "IDR", reference: "SEED-TRX-A2B")

Wallets::MoneyMover.new(actor: u2).transfer!(
  source_wallet: u2.wallet, target_wallet: t1.wallet, amount: 100_000, currency: "IDR", reference: "SEED-TRX-B2T"
)

Wallets::MoneyMover.new(actor: u2).withdraw!(
  source_wallet: t1.wallet, amount: 50_000, currency: "IDR", reference: "SEED-WD-T1"
)

puts "Seed complete!"
