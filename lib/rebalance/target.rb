module Rebalance
  class Target
    attr_accessor :asset_classes,
      :rebalanced_shares,
      :rebalanced_values,
      :rebalanced_share_difference,
      :rebalanced_value_difference

    def initialize(&block)
      self.asset_classes = {}
      initialize_result_values

      instance_eval &block
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

    def calculate_target_asset_class_values(*accounts)
      total_value = total_value_of_all_accounts(accounts)

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
      total_value = total_value_of_all_accounts(accounts)

      current_values.each do |asset_class, asset_class_value|
        current_percentages[asset_class] = ((asset_class_value / total_value)*100).round(4)
      end
      current_percentages
    end

    def total_value_of_all_accounts(accounts)
      value = 0
      accounts.each do |account|
        value += account.total_value
      end
      value
    end

    # get each account's asset class percentage breakdown in relation
    # to all the accounts
    def asset_class_percentages_across_all_accounts(accounts)
      total_value_of_all_accounts = total_value_of_all_accounts(accounts)
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

    def rebalance(*accounts)
      initialize_result_values(accounts)

      if accounts.size == 1
        single_account_rebalance(accounts.first)
      elsif accounts.size > 1
        multiple_account_rebalance(accounts)
      end
    end

    private
    def single_account_rebalance(account)
      target_asset_class_values   = calculate_target_asset_class_values(account)

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

      total_value = total_value_of_all_accounts(accounts)

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
      working_account_percentages = asset_class_percentages_across_all_accounts(accounts)
      working_asset_class_percentages = calculate_current_asset_class_percentages(*accounts)

      100.times do |num|
        working_account_percentages.each do |account_name, a_classes|
          # We need to deal with single fund accounts seperately
          if a_classes.size > 1
            a_classes.each do |class_name, percentage|
              target_value = asset_classes[class_name] || 0
              diff = target_value - working_asset_class_percentages[class_name]

              #p "Target for #{class_name} is #{target_value}"

              # See if the target asset class % is greater than our overall asset class %
              if diff
                if diff > 0
                  diff > 1 ? adjustment_size = 1 : adjustment_size = diff
                else
                  diff < -1 ? adjustment_size = -1 : adjustment_size = diff
                end

                if adjustment_size > 0.1 or adjustment_size < -0.1
                  #p ""
                  #p "Adjusting #{class_name} in #{account_name} by #{adjustment_size} because it's currently at #{working_asset_class_percentages[class_name]}"
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
