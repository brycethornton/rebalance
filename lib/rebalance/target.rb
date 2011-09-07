module Rebalance
  class Target
    attr_accessor :asset_classes, :rebalanced_shares

    def initialize(&block)
      self.asset_classes = {}
      self.rebalanced_shares = {}

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
      account.asset_class_hash.each do |asset_class, fund_hash|
        asset_class_value = 0
        fund_hash.each do |fund_array|
          fund_array.each do |symbol, value|
            asset_class_value += value
          end
        end
        current_values[asset_class] = asset_class_value.round(2)
      end
      current_values
    end

    def rebalance(account)
      target_asset_class_values   = calculate_target_asset_class_values(account)
      current_asset_class_values  = calculate_current_asset_class_values(account)

      target_asset_class_values.each do |asset_class, target_value|
        if target_value < current_asset_class_values[asset_class]
          overage = (current_asset_class_values[asset_class] - target_value).round(2)
          puts "We are over-invested in #{asset_class} by #{overage.to_s}"
        end
      end
    end
  end
end
