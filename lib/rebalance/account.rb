module Rebalance
  class Account
    attr_accessor :name, :funds, :rebalanced_funds, :asset_class_hash

    def initialize(name, &block)
      self.name = name
      self.funds = {}
      self.rebalanced_funds = {}
      self.asset_class_hash = {}

      instance_eval &block
    end

    def fund(symbol, asset_class, shares, cost)
      new_fund = Fund.new(symbol, asset_class, shares, cost)
      self.funds[new_fund.symbol] = new_fund
      add_to_asset_class_hash new_fund
    end

    def add_to_asset_class_hash(fund)
      self.asset_class_hash[fund.asset_class] ||= []
      self.asset_class_hash[fund.asset_class] << {fund.symbol => fund.value}
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

    def to_s
      output = ''

      funds.each do |new_fund|
        output << "#{new_fund.symbol} - #{new_fund.asset_class} "
        output << "Shares: #{new_fund.shares} Cost: $#{new_fund.cost}\n"
      end

      output
    end
  end
end
