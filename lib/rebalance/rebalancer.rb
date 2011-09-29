module Rebalance
  class Rebalancer
    attr_accessor :rebalanced_shares,
      :rebalanced_values,
      :rebalanced_share_difference,
      :rebalanced_value_difference

    def initialize(target, *accounts)
      @target = target
      @accounts = accounts

      initialize_result_values
    end

    def initialize_result_values(accounts=[])
      if accounts.size <= 1
        self.rebalanced_shares = {}
        self.rebalanced_values = {}
        self.rebalanced_share_difference = {}
        self.rebalanced_value_difference = {}
      elsif accounts.size > 1
        accounts.each do |account|
          self.rebalanced_shares[account.name] = {}
          self.rebalanced_values[account.name] = {}
          self.rebalanced_share_difference[account.name] = {}
          self.rebalanced_value_difference[account.name] = {}
        end
      end
    end

    def rebalance
      initialize_result_values(@accounts)

      if @accounts.size == 1
        single_account_rebalance(@accounts.first)
      elsif @accounts.size > 1
        multiple_account_rebalance(@accounts)
      end
    end

    private
    def single_account_rebalance(account)
      target_asset_class_values   = @target.calculate_target_asset_class_values(account)

      target_asset_class_values.each do |asset_class, target_value|
        rebalanced_asset_class = rebalance_asset_class_within_account(account, asset_class, target_value)

        self.rebalanced_shares.merge!(rebalanced_asset_class['rebalanced_shares'])
        self.rebalanced_share_difference.merge!(rebalanced_asset_class['rebalanced_share_difference'])
        self.rebalanced_values.merge!(rebalanced_asset_class['rebalanced_values'])
        self.rebalanced_value_difference.merge!(rebalanced_asset_class['rebalanced_value_difference'])
      end
    end

    def multiple_account_rebalance(accounts)
      # First, rebalance account by asset class percentage
      account_percentages = rebalance_account_percentages(accounts)

      total_value = @target.total_value_of_all_accounts(*accounts)

      # Now, turn those asset class percentages back into balanced funds
      accounts.each do |account|
        target_asset_class_percentages = account_percentages[account.name]

        # Convert the percentages into values
        target_asset_class_values = {}
        target_asset_class_percentages.each do |asset_class, percentage|
          target_value = total_value * (percentage * 0.01)
          target_asset_class_values[asset_class] = target_value
        end

        target_asset_class_values.each do |asset_class, target_value|
          rebalanced_asset_class = rebalance_asset_class_within_account(account, asset_class, target_value)

          self.rebalanced_shares[account.name].merge!(rebalanced_asset_class['rebalanced_shares'])
          self.rebalanced_share_difference[account.name].merge!(rebalanced_asset_class['rebalanced_share_difference'])
          self.rebalanced_values[account.name].merge!(rebalanced_asset_class['rebalanced_values'])
          self.rebalanced_value_difference[account.name].merge!(rebalanced_asset_class['rebalanced_value_difference'])
        end
      end
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

    def rebalance_account_percentages(accounts)
      working_account_percentages = @target.asset_class_percentages_across_all_accounts(*accounts)
      working_asset_class_percentages = @target.calculate_current_asset_class_percentages(*accounts)

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
                    #p "Minor adjustment to #{temp_class_name} in #{account_name} by #{percent_to_change}"
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
