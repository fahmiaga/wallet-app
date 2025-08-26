class WalletsController < ApplicationController
  include AuthorizeResource
  before_action :require_auth!
  before_action :set_wallet

  def show
    render json: success_response("Wallet details fetched", {
      wallet_id: @wallet.id,
      owner_type: @wallet.owner_type,
      owner_id: @wallet.owner_id,
      currency: @wallet.currency,
      balance: @wallet.balance.to_s
    })
  end

  def balance
    render json: success_response("Balance fetched", {
      wallet_id: @wallet.id,
      owner: @wallet.owner.name,
      balance: @wallet.balance.to_s,
      currency: @wallet.currency
    })
  end

  def deposit
    tx = mover.deposit!(
      target_wallet: @wallet,
      amount: params[:amount].to_d,
      currency: @wallet.currency,
      reference: params[:reference],
      metadata: params[:metadata] || {}
    )
    render json: success_response("Deposit successful", {
      transaction_id: tx.id,
      wallet_id: @wallet.id,
      new_balance: @wallet.reload.balance.to_s,
      currency: @wallet.currency
    })
  rescue => e
    render json: error_response(e.message), status: :unprocessable_entity
  end

  def withdraw
    tx = mover.withdraw!(
      source_wallet: @wallet,
      amount: params[:amount].to_d,
      currency: @wallet.currency,
      reference: params[:reference],
      metadata: params[:metadata] || {}
    )
    render json: success_response("Withdrawal successful", {
      transaction_id: tx.id,
      wallet_id: @wallet.id,
      new_balance: @wallet.reload.balance.to_s,
      currency: @wallet.currency
    })
  rescue => e
    render json: error_response(e.message), status: :unprocessable_entity
  end

  def transfer
    target = Wallet.find(params[:target_wallet_id])
    tx = mover.transfer!(
      source_wallet: @wallet,
      target_wallet: target,
      amount: params[:amount].to_d,
      currency: @wallet.currency,
      reference: params[:reference],
      metadata: params[:metadata] || {}
    )
    render json: success_response("Transfer successful", {
      transaction_id: tx.id,
      source_wallet_id: @wallet.id,
      target_wallet_id: target.id,
      sender: @wallet.owner.name,
      recipient: target.owner.name,
      new_source_balance: @wallet.reload.balance.to_s,
      new_target_balance: target.reload.balance.to_s,
      currency: @wallet.currency
    })
  rescue => e
    render json: error_response(e.message), status: :unprocessable_entity
  end

  private

  def set_wallet
    @wallet = Wallet.find(params[:id])
    authorized(owner: @wallet.owner)
  end

  def mover
    @mover ||= Wallets::MoneyMover.new(actor: current_user)
  end

  def success_response(message, data = {})
    { status: "success", message: message, data: data }
  end

  def error_response(message)
    { status: "error", message: message }
  end
end
