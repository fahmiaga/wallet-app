class TransactionsController < ApplicationController
  def new
  end
  def create
  end

   private

  def transaction_params
    params.require(:transaction).permit(:amount, :currency, :from_wallet_id, :to_wallet_id)
  end
end
