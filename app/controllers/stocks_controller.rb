require_dependency "#{Rails.root}/lib/latest_stock_price/client"

class StocksController < ApplicationController
  before_action :require_auth!

  def price
    symbol = params[:symbol].to_s.upcase
    data = LatestStockPrice::Client.new.price(symbol)
    render json: data
  end

  def prices
    symbols = params[:symbols].to_s.split(",").map(&:upcase)
    data = LatestStockPrice::Client.new.prices(symbols)
    render json: data
  end

  def price_all
    data = LatestStockPrice::Client.new.price_all
    render json: data
  end
end
