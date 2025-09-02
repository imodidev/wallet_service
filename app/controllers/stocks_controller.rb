class StocksController < ApplicationController
  before_action :set_stock, only: [:show, :price, :wallet]
  
  def index
    stocks = Stock.includes(:wallet).all
    render_success({
      stocks: stocks.map { |stock| stock_json(stock) }
    })
  end
  
  def show
    render_success({ stock: stock_json(@stock) })
  end
  
  def create
    stock = Stock.new(stock_params)
    
    if stock.save
      render_success({ stock: stock_json(stock) }, :created)
    else
      render_error(stock.errors.full_messages.join(', '))
    end
  end
  
  def price
    begin
      price_data = LatestStockPrice.price(@stock.symbol)
      render_success({ price_data: price_data })
    rescue LatestStockPrice::APIError => e
      render_error("Stock price API error: #{e.message}")
    rescue LatestStockPrice::ConfigurationError => e
      render_error("Stock price service not configured: #{e.message}")
    end
  end
  
  def prices
    symbols = params[:symbols]&.split(',') || []
    
    if symbols.empty?
      return render_error('Symbols parameter is required')
    end
    
    begin
      prices_data = LatestStockPrice.prices(symbols)
      render_success({ prices_data: prices_data })
    rescue LatestStockPrice::APIError => e
      render_error("Stock price API error: #{e.message}")
    rescue LatestStockPrice::ConfigurationError => e
      render_error("Stock price service not configured: #{e.message}")
    end
  end
  
  def price_all
    begin
      all_prices = LatestStockPrice.price_all
      render_success({ all_prices: all_prices })
    rescue LatestStockPrice::APIError => e
      render_error("Stock price API error: #{e.message}")
    rescue LatestStockPrice::ConfigurationError => e
      render_error("Stock price service not configured: #{e.message}")
    end
  end
  
  def wallet
    render_success({
      wallet: {
        id: @stock.wallet.id,
        balance: @stock.balance.format,
        balance_cents: @stock.wallet.balance_cents
      }
    })
  end
  
  private
  
  def set_stock
    @stock = Stock.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render_error('Stock not found', :not_found)
  end
  
  def stock_params
    params.require(:stock).permit(:symbol, :name)
  end
  
  def stock_json(stock)
    {
      id: stock.id,
      symbol: stock.symbol,
      name: stock.name,
      balance: stock.balance.format,
      balance_cents: stock.wallet&.balance_cents || 0,
      created_at: stock.created_at
    }
  end
end
