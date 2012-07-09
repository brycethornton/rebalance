require 'open-uri'
require 'json'

module Rebalance
  class Fund
    attr_accessor :symbol, :name, :asset_class, :shares, :price

    def initialize(symbol, asset_class, shares, price=nil)
      self.symbol      = symbol
      self.asset_class = asset_class
      self.shares      = shares

      # Lookup value if not passed in
      if price.nil?
        price = get_fund_price(symbol)
      end

      self.price = price
    end

    def get_fund_price(symbol)
      yql_url = "http://query.yahooapis.com/v1/public/yql?q=select%20*%20from%20yahoo.finance.quotes%20where%20symbol%20in%20(%22#{symbol}%22)&env=store://datatables.org/alltableswithkeys&format=json"
      response = open(yql_url)
      parsed_response = JSON.parse(response.read)

      if !parsed_response['query']['results']['quote']['ErrorIndicationreturnedforsymbolchangedinvalid'].nil?
        raise "The symbol #{symbol} can't be found"
      end

      price = parsed_response['query']['results']['quote']['LastTradePriceOnly']
      price = price.to_f

      # Cash funds don't always return a price, so just assume $1.00
      if asset_class == "Cash"
        price = 1.00
      end

      price
    end

    def value
      (price * shares)
    end
  end
end
