require 'httparty'

module LatestStockPrice
  class Error < StandardError; end
  class APIError < Error; end
  class ConfigurationError < Error; end
  
  class << self
    attr_accessor :api_key, :base_url
    
    def configure
      yield self
    end
    
    def api_key
      @api_key ||= ENV['RAPIDAPI_KEY']
    end
    
    def base_url
      @base_url ||= 'https://latest-stock-price.p.rapidapi.com'
    end
  end
end

require_relative 'latest_stock_price/client'
require_relative 'latest_stock_price/version'
