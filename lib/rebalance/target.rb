module Rebalance
  class Target
    attr_accessor :asset_classes

    def initialize(&block)
      self.asset_classes = {}
      instance_eval &block
    end

    def asset_class(percentage, asset_class)
      self.asset_classes[asset_class] = percentage
    end

    def calculate_target_asset_class_values(*accounts)
      total_value = total_value_of_all_accounts(*accounts)

      target_values = {}
      asset_classes.each do |asset_class, percentage|
        target_values[asset_class] = (total_value * (percentage.to_f/100)).round(2)
      end
      target_values
    end

    def calculate_current_asset_class_values(*accounts)
      current_values = {}
      accounts.each do |account|
        account.funds.each do |symbol, fund|
          current_values[fund.asset_class] = 0 if current_values[fund.asset_class].nil?
          current_values[fund.asset_class] += fund.value
        end
      end
      current_values
    end

    def calculate_current_asset_class_percentages(*accounts)
      current_percentages = {}
      current_values = calculate_current_asset_class_values(*accounts)
      total_value = total_value_of_all_accounts(*accounts)

      current_values.each do |asset_class, asset_class_value|
        current_percentages[asset_class] = ((asset_class_value / total_value)*100).round(4)
      end
      current_percentages
    end

    def total_value_of_all_accounts(*accounts)
      value = 0
      accounts.each do |account|
        value += account.total_value
      end
      value
    end

    # get each account's asset class percentage breakdown in relation
    # to all the accounts
    def asset_class_percentages_across_all_accounts(*accounts)
      total_value_of_all_accounts = total_value_of_all_accounts(*accounts)
      account_percentages = {}

      accounts.each do |account|
        account.funds.each do |symbol, fund|
          asset_class_total = 0
          account.find_by_asset_class(fund.asset_class).each do |asset_class_fund|
            asset_class_total += asset_class_fund.value
          end
          account_percentages[account.name] = {} if account_percentages[account.name].nil?
          account_percentages[account.name][fund.asset_class] = ((asset_class_total / total_value_of_all_accounts) * 100).round(4)
        end
      end
      account_percentages
    end
  end
end
