class Transaction < ApplicationRecord
  self.inheritance_column = :type

  belongs_to :source_wallet, class_name: "Wallet", optional: true
  belongs_to :target_wallet, class_name: "Wallet", optional: true
  belongs_to :created_by, class_name: "User", optional: true

  validates :type, :amount, :currency, :occurred_at, presence: true
  validates :amount, numericality: { greater_than: 0 }
  validates :status, inclusion: { in: %w[posted reversed pending failed] }
  validate  :currency_match
  validate  :wallet_rules
  validate  :different_wallets_for_transfer

  private

  def currency_match
    if source_wallet && source_wallet.currency != currency
      errors.add(:currency, "must match source_wallet currency")
    end
    if target_wallet && target_wallet.currency != currency
      errors.add(:currency, "must match target_wallet currency")
    end
  end

  def wallet_rules
    case type
    when "DepositTransaction"
      errors.add(:source_wallet, "must be nil for deposit") if source_wallet_id.present?
      errors.add(:target_wallet, "required") if target_wallet_id.blank?
    when "WithdrawalTransaction"
      errors.add(:target_wallet, "must be nil for withdrawal") if target_wallet_id.present?
      errors.add(:source_wallet, "required") if source_wallet_id.blank?
    when "TransferTransaction"
      errors.add(:base, "source and target required") if source_wallet_id.blank? || target_wallet_id.blank?
    else
      errors.add(:type, "unknown transaction type")
    end
  end

  def different_wallets_for_transfer
    if type == "TransferTransaction" && source_wallet_id.present? && source_wallet_id == target_wallet_id
      errors.add(:base, "source and target cannot be the same wallet")
    end
  end
end
