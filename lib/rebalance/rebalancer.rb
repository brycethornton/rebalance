module Rebalance
  class Rebalancer
    attr_accessor :accounts,
      :target,
      :acceptable_asset_class_delta,
      :rebalanced_shares,
      :rebalanced_values,
      :rebalanced_share_difference,
      :rebalanced_value_difference

    def initialize(target, *accounts)
      @target = target
      # make sure we add empty funds where appropriate before we start rebalancing
      # in order to allow all accounts/funds to balance properly
      @accounts = accounts

      @acceptable_asset_class_delta = 1.0

      initialize_result_values
    end

    def initialize_result_values
      @rebalanced_shares = {}
      @rebalanced_values = {}
      @rebalanced_share_difference = {}
      @rebalanced_value_difference = {}

      if @accounts.size > 1
        @accounts.each do |account|
          @rebalanced_shares[account.name] = {}
          @rebalanced_values[account.name] = {}
          @rebalanced_share_difference[account.name] = {}
          @rebalanced_value_difference[account.name] = {}
        end
      end
    end

    def rebalance
      initialize_result_values

      if @accounts.size == 1
        single_account_rebalance
      elsif @accounts.size > 1
        multiple_account_rebalance
      end
    end

    def calculate_rebalanced_asset_class_values
      # First, create a hash of symbols and their asset classes
      symbol_asset_class_hash = {}
      @accounts.each do |account|
        account.funds.each do |symbol, fund|
          symbol_asset_class_hash[symbol] = fund.asset_class
        end
      end

      values = {}
      if @accounts.size > 1
        @rebalanced_values.each do |account, symbol_value_hash|
          symbol_value_hash.each do |symbol, value|
            asset_class = symbol_asset_class_hash[symbol]
            values[asset_class] = 0 if values[asset_class].nil?
            values[asset_class] += value
          end
        end
      else
        @rebalanced_values.each do |symbol, value|
          asset_class = symbol_asset_class_hash[symbol]
          values[asset_class] = 0 if values[asset_class].nil?
          values[asset_class] += value
        end
      end
      values
    end

    def funds_by_asset_class
      asset_class_hash = {}
      @accounts.each do |account|
        account.funds.each do |symbol, fund|
          asset_class_hash[fund.asset_class] = [] if asset_class_hash[fund.asset_class].nil?
          asset_class_hash[fund.asset_class] << fund if !asset_class_hash[fund.asset_class].include?(fund)
        end
      end
      asset_class_hash
    end

    private
    def single_account_rebalance
      account = @accounts.first
      target_asset_class_values = @target.calculate_target_asset_class_values(account)

      target_asset_class_values.each do |asset_class, target_value|
        rebalanced_asset_class = rebalance_asset_class_within_account(account, asset_class, target_value)

        @rebalanced_shares.merge!(rebalanced_asset_class['rebalanced_shares'])
        @rebalanced_share_difference.merge!(rebalanced_asset_class['rebalanced_share_difference'])
        @rebalanced_values.merge!(rebalanced_asset_class['rebalanced_values'])
        @rebalanced_value_difference.merge!(rebalanced_asset_class['rebalanced_value_difference'])
      end
    end

    def multiple_account_rebalance
      # Rebalance accounts by asset class percentage
      account_percentages = rebalance_account_percentages

      # Try to rebalance up to 10 times
      i = 0
      while i < 10 && unbalanced_asset_classes = find_unbalanced_asset_classes(account_percentages)
        i += 1
        @accounts = add_empty_funds(unbalanced_asset_classes)
        account_percentages = rebalance_account_percentages
      end

      total_value = @target.total_value_of_all_accounts(*@accounts)

      # Now, turn those asset class percentages back into balanced funds
      @accounts.each do |account|
        target_asset_class_percentages = account_percentages[account.name]

        # Convert the percentages into values
        target_asset_class_values = {}
        target_asset_class_percentages.each do |asset_class, percentage|
          target_value = total_value * (percentage * 0.01)
          target_asset_class_values[asset_class] = target_value
        end

        target_asset_class_values.each do |asset_class, target_value|
          rebalanced_asset_class = rebalance_asset_class_within_account(account, asset_class, target_value)

          @rebalanced_shares[account.name].merge!(rebalanced_asset_class['rebalanced_shares'])
          @rebalanced_share_difference[account.name].merge!(rebalanced_asset_class['rebalanced_share_difference'])
          @rebalanced_values[account.name].merge!(rebalanced_asset_class['rebalanced_values'])
          @rebalanced_value_difference[account.name].merge!(rebalanced_asset_class['rebalanced_value_difference'])
        end
      end
    end

    def find_unbalanced_asset_classes(account_percentages)
      target_percentages = target.calculate_target_asset_class_percentages(*@accounts)

      rebalanced_asset_classes = {}

      account_percentages.each do |account_name, asset_class_hash|
        asset_class_hash.each do |asset_class, rebalanced_percentage|
          rebalanced_asset_classes[asset_class] = 0 if rebalanced_asset_classes[asset_class].nil?
          rebalanced_asset_classes[asset_class] += rebalanced_percentage
        end
      end

      unbalanced_asset_classes = []

      rebalanced_asset_classes.each do |asset_class, rebalanced_asset_class_percentage|
        if !target_percentages[asset_class].nil?
          if (rebalanced_asset_class_percentage - target_percentages[asset_class]).abs > @acceptable_asset_class_delta
            unbalanced_asset_classes << asset_class
          end
        end
      end

      if !unbalanced_asset_classes.empty?
        unbalanced_asset_classes
      else
        false
      end
    end

    def add_empty_funds(unbalanced_asset_classes)
      # Loop through each account and add an empty fund from
      # a missing asset class to an account that doesn't currently
      # carry it.
      temp_accounts = []
      added_asset_classes = []
      @accounts.each do |account|
        unbalanced_asset_classes.each do |unbalanced_asset_class|
          # If we can't find this asset class in this account
          # then add it
          if account.find_by_asset_class(unbalanced_asset_class).empty? && !added_asset_classes.include?(unbalanced_asset_class)
            asset_class_funds = funds_by_asset_class
            fund_to_add = asset_class_funds[unbalanced_asset_class].first
            added_asset_classes << unbalanced_asset_class
            account.fund(fund_to_add.symbol, unbalanced_asset_class, 0, fund_to_add.cost)
          end
        end
        temp_accounts << account
      end

      temp_accounts
    end

    def rebalance_asset_class_within_account(account, class_name, target_value)
      return_values = {
        'rebalanced_shares' => {},
        'rebalanced_share_difference' => {},
        'rebalanced_values' => {},
        'rebalanced_value_difference' => {}
      }

      funds = account.find_by_asset_class(class_name)
      per_fund_target_value = target_value / funds.size

      funds.each do |fund|
        amount_difference = (fund.value - per_fund_target_value)

        new_shares = ((fund.value - amount_difference)/fund.cost)
        share_difference = (new_shares - fund.shares).round(2)

        symbol = fund.symbol

        return_values['rebalanced_shares'][symbol] = new_shares.round(4)
        return_values['rebalanced_share_difference'][symbol] = share_difference
        return_values['rebalanced_values'][symbol] = (new_shares * fund.cost).round(2)
        return_values['rebalanced_value_difference'][symbol] = (return_values['rebalanced_values'][symbol] - fund.value).round(2)
      end

      return_values
    end

    def rebalance_account_percentages
      working_account_percentages = @target.asset_class_percentages_across_all_accounts(*@accounts)
      working_asset_class_percentages = @target.calculate_current_asset_class_percentages(*@accounts)

      100.times do |num|
        working_account_percentages.each do |account_name, a_classes|
          # We need to deal with single fund accounts seperately
          if a_classes.size > 1
            a_classes.each do |class_name, percentage|
              target_value = @target.asset_classes[class_name] || 0
              diff = target_value - working_asset_class_percentages[class_name]

              # See if the target asset class % is greater than our overall asset class %
              if diff
                if diff > 0
                  diff > 1 ? adjustment_size = 1 : adjustment_size = diff
                else
                  diff < -1 ? adjustment_size = -1 : adjustment_size = diff
                end

                if adjustment_size > 0.1 or adjustment_size < -0.1
                  working_account_percentages[account_name][class_name] += adjustment_size
                  working_asset_class_percentages[class_name] += adjustment_size

                  # Now, go through the rest of the asset classes here and decrement
                  # evenly to keep this account's overall percentage the same
                  percent_to_change = adjustment_size.quo(a_classes.size-1).to_f * -1
                  a_classes.each do |temp_class_name, temp_percentage|
                    next if temp_class_name == class_name
                    working_account_percentages[account_name][temp_class_name] += percent_to_change
                    working_asset_class_percentages[temp_class_name] += percent_to_change
                  end
                end
              end
            end
          end
        end
      end

      working_account_percentages
    end
  end
end
