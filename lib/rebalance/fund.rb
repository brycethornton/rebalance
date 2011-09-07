module Rebalance
  class Fund
    attr_accessor :symbol, :name, :asset_class, :shares, :cost

    def initialize(symbol, asset_class, shares, cost)
      self.symbol      = symbol
      self.asset_class = asset_class
      self.shares      = shares
      self.cost        = cost
    end

    def value
      (cost * shares).round(2)
    end
  end
end
