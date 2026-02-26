class TransactionsController < ApplicationController
  def new
    @transaction = Transaction.new
  end
  def create
    Transaction.create!(transaction_params)
    render json: success_response("Transaction created successfully")
  rescue => e
    render json: error_response(e.message), status: :unprocessable_entity
  end

   private

  def transaction_params
    params.require(:transaction).permit(:amount, :currency, :from_wallet_id, :to_wallet_id)
  end
end
