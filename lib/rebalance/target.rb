module Rebalance
  class Target
    attr_accessor :asset_classes,
                  :rebalanced_shares,
                  :rebalanced_values,
                  :rebalanced_share_difference,
                  :rebalanced_value_difference

    def initialize(&block)
      self.asset_classes = {}
      self.rebalanced_shares = {}
      self.rebalanced_values = {}
      self.rebalanced_share_difference = {}
      self.rebalanced_value_difference = {}

      instance_eval &block
    end

    def asset_class(percentage, asset_class)
      self.asset_classes[asset_class] = percentage
    end

    def to_s
      output = ''
      asset_classes.each do |a_class, percentage|
        output << "#{a_class} - #{percentage}%\n"
      end
      output
    end

    def calculate_target_asset_class_values(account)
      target_values = {}
      asset_classes.each do |asset_class, percentage|
        target_values[asset_class] = (account.total_value * (percentage.to_f/100)).round(2)
      end
      target_values
    end

    def calculate_current_asset_class_values(account)
      current_values = {}
      account.funds.each do |symbol, fund|
        current_values[fund.asset_class] = 0 if current_values[fund.asset_class].nil?
        current_values[fund.asset_class] += fund.value
      end
      current_values
    end

    def rebalance(account)
      target_asset_class_values   = calculate_target_asset_class_values(account)
      current_asset_class_values  = calculate_current_asset_class_values(account)

      target_asset_class_values.each do |asset_class, target_value|
        # sell enough of each fund in the class to get us back to our target
        related_funds = account.find_by_asset_class(asset_class)
        related_fund_target_value = target_value / related_funds.size

        related_funds.each do |related_fund|
          amount_difference = (related_fund.value - related_fund_target_value)

          if amount_difference != 0
            new_shares = ((related_fund.value - amount_difference)/related_fund.cost)
            symbol = related_fund.symbol
            self.rebalanced_shares[symbol] = new_shares.round(4)

            share_difference = (new_shares - related_fund.shares).round(2)
            self.rebalanced_share_difference[symbol] = share_difference
            self.rebalanced_values[symbol] = (new_shares * related_fund.cost).round(2)
            self.rebalanced_value_difference[symbol] = (rebalanced_values[symbol] - related_fund.value).round(2)
          end
        end
      end
    end
  end
end
