
module Wallets
  class MoneyMover
    class Error < StandardError; end
    class InsufficientFunds < Error; end
    class WalletLocked < Error; end

    def initialize(actor:)
      @actor = actor # current_user
    end


    def deposit!(target_wallet:, amount:, currency:, reference: nil, metadata: {})
      raise WalletLocked if target_wallet.locked?
      Transaction.transaction do
        ensure_idempotent!(reference)
        DepositTransaction.create!(
          target_wallet: target_wallet,
          amount: amount,
          currency: currency,
          reference: reference,
          metadata: metadata,
          occurred_at: Time.current,
          created_by: @actor
        )
      end
    end

    def withdraw!(source_wallet:, amount:, currency:, reference: nil, metadata: {})
      raise WalletLocked if source_wallet.locked?
      Transaction.transaction do
        ensure_sufficient!(source_wallet, amount, currency)
        ensure_idempotent!(reference)
        WithdrawalTransaction.create!(
          source_wallet: source_wallet,
          amount: amount,
          currency: currency,
          reference: reference,
          metadata: metadata,
          occurred_at: Time.current,
          created_by: @actor
        )
      end
    end


    def transfer!(source_wallet:, target_wallet:, amount:, currency:, reference: nil, metadata: {})
      raise WalletLocked if source_wallet.locked? || target_wallet.locked?
      Transaction.transaction do
        # Row lock to mitigate race
        source_wallet.lock!
        target_wallet.lock!
        ensure_sufficient!(source_wallet, amount, currency)
        ensure_idempotent!(reference)
        TransferTransaction.create!(
          source_wallet: source_wallet,
          target_wallet: target_wallet,
          amount: amount,
          currency: currency,
          reference: reference,
          metadata: metadata,
          occurred_at: Time.current,
          created_by: @actor
        )
      ensure
        source_wallet.unlock!
        target_wallet.unlock!
      end
    end

    private

    def ensure_sufficient!(wallet, amount, currency)
      raise Error, "currency mismatch" unless wallet.currency == currency
      # SELECT SUM ... FOR UPDATE (soft via transaction + lock flag)
      raise InsufficientFunds, "insufficient funds" if wallet.balance < amount
    end

    def ensure_idempotent!(reference)
      return if reference.blank?
      if Transaction.exists?(reference: reference, status: "posted")
        raise Error, "duplicate reference"
      end
    end
  end
end
