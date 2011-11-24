require 'minitest/autorun'

require 'rebalance/target'
require 'rebalance/account'
require 'rebalance/fund'
require 'rebalance/rebalancer'

module MiniTest
  module Assertions
    def assert_rebalanced rebalance
      target = rebalance.target
      accounts = rebalance.accounts

      target_values = target.calculate_target_asset_class_values(*accounts)

      # Allow the rebalance to be off by half a percent of the total value of all accounts
      acceptable_delta = target.total_value_of_all_accounts(*accounts) * 0.005

      rebalance.calculate_rebalanced_asset_class_values.each do |asset_class, rebalanced_value|
        if !target_values[asset_class].nil?
          rebalanced_value.must_be_within_delta target_values[asset_class], acceptable_delta, "Failed for asset class: #{asset_class}"
        end
      end
    end

    def assert_accounts_have_same_values_after_rebalance rebalance
      rebalance.accounts.each do |account|
        if rebalance.accounts.size > 1
          values = rebalance.rebalanced_values[account.name].values
        else
          values = rebalance.rebalanced_values.values
        end
        rebalanced_total = values.inject{|sum,x| sum + x }
        account.total_value.must_be_within_delta rebalanced_total, 0.10
      end
    end
  end
end
