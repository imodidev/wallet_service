require 'rails_helper'

RSpec.describe LatestStockPrice do
  let(:mock_response) { double('response') }
  
  before do
    LatestStockPrice.configure do |config|
      config.api_key = 'test_api_key'
      config.base_url = 'https://test.example.com'
    end
  end
  
  describe '.configure' do
    it 'allows configuration of api_key and base_url' do
      LatestStockPrice.configure do |config|
        config.api_key = 'new_key'
        config.base_url = 'https://new.example.com'
      end
      
      expect(LatestStockPrice.api_key).to eq('new_key')
      expect(LatestStockPrice.base_url).to eq('https://new.example.com')
    end
  end
  
  describe '.api_key' do
    it 'returns the configured api_key' do
      expect(LatestStockPrice.api_key).to eq('test_api_key')
    end
    
    it 'falls back to ENV variable' do
      LatestStockPrice.api_key = nil
      allow(ENV).to receive(:[]).with('RAPIDAPI_KEY').and_return('env_key')
      expect(LatestStockPrice.api_key).to eq('env_key')
    end
  end
  
  describe LatestStockPrice::Client do
    let(:client) { LatestStockPrice::Client.new }
    
    describe '#initialize' do
      it 'raises error when api_key is missing' do
        LatestStockPrice.api_key = nil
        allow(ENV).to receive(:[]).with('RAPIDAPI_KEY').and_return(nil)
        
        expect {
          LatestStockPrice::Client.new
        }.to raise_error(LatestStockPrice::ConfigurationError, 'API key is required')
      end
    end
    
    describe '#price' do
      before do
        allow(LatestStockPrice::Client).to receive(:get).and_return(mock_response)
      end
      
      context 'with successful response' do
        let(:price_data) { [{ 'symbol' => 'AAPL', 'price' => 150.0 }] }
        
        before do
          allow(mock_response).to receive(:code).and_return(200)
          allow(mock_response).to receive(:parsed_response).and_return(price_data)
        end
        
        it 'returns price data for a symbol' do
          result = client.price('AAPL')
          expect(result).to eq(price_data.first)
          expect(LatestStockPrice::Client).to have_received(:get).with('/price', query: { Identifier: 'AAPL' })
        end
      end
      
      context 'with error responses' do
        it 'raises APIError for 401 Unauthorized' do
          allow(mock_response).to receive(:code).and_return(401)
          expect { client.price('AAPL') }.to raise_error(LatestStockPrice::APIError, 'Unauthorized - check your API key')
        end
        
        it 'raises APIError for 404 Not Found' do
          allow(mock_response).to receive(:code).and_return(404)
          expect { client.price('INVALID') }.to raise_error(LatestStockPrice::APIError, 'Stock not found')
        end
        
        it 'raises APIError for 429 Rate Limit' do
          allow(mock_response).to receive(:code).and_return(429)
          expect { client.price('AAPL') }.to raise_error(LatestStockPrice::APIError, 'Rate limit exceeded')
        end
        
        it 'raises APIError for other error codes' do
          allow(mock_response).to receive(:code).and_return(500)
          allow(mock_response).to receive(:message).and_return('Internal Server Error')
          expect { client.price('AAPL') }.to raise_error(LatestStockPrice::APIError, 'API error: 500 - Internal Server Error')
        end
      end
    end
    
    describe '#prices' do
      before do
        allow(LatestStockPrice::Client).to receive(:get).and_return(mock_response)
        allow(mock_response).to receive(:code).and_return(200)
        allow(mock_response).to receive(:parsed_response).and_return([])
      end
      
      it 'requests prices for multiple symbols' do
        client.prices('AAPL', 'GOOGL', 'MSFT')
        expect(LatestStockPrice::Client).to have_received(:get).with('/prices', query: { Identifiers: 'AAPL,GOOGL,MSFT' })
      end
      
      it 'handles array of symbols' do
        client.prices(['AAPL', 'GOOGL'])
        expect(LatestStockPrice::Client).to have_received(:get).with('/prices', query: { Identifiers: 'AAPL,GOOGL' })
      end
    end
    
    describe '#price_all' do
      before do
        allow(LatestStockPrice::Client).to receive(:get).and_return(mock_response)
        allow(mock_response).to receive(:code).and_return(200)
        allow(mock_response).to receive(:parsed_response).and_return([])
      end
      
      it 'requests all stock prices' do
        client.price_all
        expect(LatestStockPrice::Client).to have_received(:get).with('/any')
      end
    end
  end
  
  describe 'convenience class methods' do
    before do
      # Clear the memoized client instance before each test
      LatestStockPrice.instance_variable_set(:@client, nil)
    end
    
    describe '.price' do
      it 'delegates to client instance' do
        client_instance = instance_double(LatestStockPrice::Client)
        allow(LatestStockPrice::Client).to receive(:new).and_return(client_instance)
        allow(client_instance).to receive(:price).with('AAPL').and_return({})
        
        LatestStockPrice.price('AAPL')
        expect(client_instance).to have_received(:price).with('AAPL')
      end
    end
    
    describe '.prices' do
      it 'delegates to client instance' do
        client_instance = instance_double(LatestStockPrice::Client)
        allow(LatestStockPrice::Client).to receive(:new).and_return(client_instance)
        allow(client_instance).to receive(:prices).with('AAPL', 'GOOGL').and_return([])
        
        LatestStockPrice.prices('AAPL', 'GOOGL')
        expect(client_instance).to have_received(:prices).with('AAPL', 'GOOGL')
      end
    end
    
    describe '.price_all' do
      it 'delegates to client instance' do
        client_instance = instance_double(LatestStockPrice::Client)
        allow(LatestStockPrice::Client).to receive(:new).and_return(client_instance)
        allow(client_instance).to receive(:price_all).and_return([])
        
        LatestStockPrice.price_all
        expect(client_instance).to have_received(:price_all)
      end
    end
  end
end
