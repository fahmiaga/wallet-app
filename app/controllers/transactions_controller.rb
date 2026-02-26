class TransactionsController < ApplicationController
  def new
    @transaction = Transaction.new
  end
  def create
    Transaction.create!(transaction_params)
  end

   private

  def transaction_params
    params.require(:transaction).permit(:amount, :currency, :from_wallet_id, :to_wallet_id)
  end
end
