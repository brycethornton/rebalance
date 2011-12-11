module Rebalance
  class Account
    attr_accessor :name, :funds, :rebalanced_funds

    def initialize(name, &block)
      self.name = name
      self.funds = {}
      self.rebalanced_funds = {}

      instance_eval &block
    end

    def fund(symbol, asset_class, shares, price=nil)
      new_fund = Fund.new(symbol, asset_class, shares, price)
      self.funds[new_fund.symbol] = new_fund
    end

    def total_value
      total_value = 0
      funds.each do |symbol, fund|
        total_value = total_value + fund.value
      end
      total_value
    end

    def calculate_percentages
      percentages = {}
      funds.each do |symbol, fund|
        percentages[fund.symbol] = (fund.value / total_value * 100).round(2)
      end
      percentages
    end

    def find_by_asset_class(asset_class)
      asset_class_funds = []
      funds.each do |symbol, fund|
        asset_class_funds << fund if fund.asset_class == asset_class
      end
      asset_class_funds
    end
  end
end
