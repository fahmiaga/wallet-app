class Wallet < ApplicationRecord
  belongs_to :owner, polymorphic: true
  has_many :outgoing_transactions, class_name: "Transaction", foreign_key: :source_wallet_id, dependent: :nullify
  has_many :incoming_transactions, class_name: "Transaction", foreign_key: :target_wallet_id, dependent: :nullify

  validates :currency, presence: true
  validates :locked, inclusion: { in: [ true, false ] }

  def balance
    credits = incoming_transactions.where(status: "posted").sum(:amount)
    debits  = outgoing_transactions.where(status: "posted").sum(:amount)
    credits - debits
  end

  def lock!
    update!(locked: true)
  end

  def unlock!
    update!(locked: false)
  end
end
