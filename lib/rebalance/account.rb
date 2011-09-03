module Rebalance
  class Account
    attr_accessor :funds

    def initialize(&block)
      self.funds = []

      instance_eval &block
    end

    def fund(symbol, asset_class, shares, cost)
      new_fund = Fund.new(symbol, asset_class, shares, cost)
      self.funds << new_fund
    end

    def total_value
      total_value = 0
      funds.each do |fund|
        total_value = total_value + fund.value
      end
      total_value
    end

    def calculate_percentages
      percentages = {}
      funds.each do |fund|
        percentages[fund.symbol] = fund.value / total_value * 100
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
