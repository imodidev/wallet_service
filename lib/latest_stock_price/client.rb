module LatestStockPrice
  class Client
    include HTTParty
    
    def initialize
      raise ConfigurationError, "API key is required" unless LatestStockPrice.api_key
      
      self.class.base_uri LatestStockPrice.base_url
      self.class.headers({
        'X-RapidAPI-Key' => LatestStockPrice.api_key,
        'X-RapidAPI-Host' => 'latest-stock-price.p.rapidapi.com'
      })
    end
    
    def price(symbol)
      response = self.class.get("/price", query: { Identifier: symbol })
      handle_response(response)&.first
    end
    
    def prices(*symbols)
      identifiers = symbols.flatten.join(',')
      response = self.class.get("/prices", query: { Identifiers: identifiers })
      handle_response(response)
    end
    
    def price_all
      response = self.class.get("/any")
      handle_response(response)
    end
    
    private
    
    def handle_response(response)
      case response.code
      when 200
        response.parsed_response
      when 401
        raise APIError, "Unauthorized - check your API key"
      when 404
        raise APIError, "Stock not found"
      when 429
        raise APIError, "Rate limit exceeded"
      else
        raise APIError, "API error: #{response.code} - #{response.message}"
      end
    rescue JSON::ParserError
      raise APIError, "Invalid JSON response"
    end
  end
  
  # Convenience class methods
  def self.price(symbol)
    client.price(symbol)
  end
  
  def self.prices(*symbols)
    client.prices(*symbols)
  end
  
  def self.price_all
    client.price_all
  end
  
  private
  
  def self.client
    @client ||= Client.new
  end
end
