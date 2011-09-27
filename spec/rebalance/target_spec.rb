require File.expand_path('../../spec_helper', __FILE__)

describe Rebalance::Target do
  before do
    @target = Rebalance::Target.new do
      asset_class 30, 'Some Asset Class'
      asset_class 20, 'Another Asset Class'
      asset_class 50, 'Bonds'
    end
  end

  it 'allows asset_class to be called' do
    @target.asset_classes.size.must_equal 3
  end

  it 'remembers the asset class description' do
    @target.asset_classes['Some Asset Class'].must_equal 30
  end

  describe 'with account information' do
    before do
      @account = Rebalance::Account.new 'Test Account' do
        fund 'ABCDE', 'Some Asset Class', 500, 10.00
        fund 'FGHIJ', 'Some Asset Class', 300, 25.00
        fund 'KLMNO', 'Another Asset Class', 75, 300
        fund 'PQRST', 'Bonds', 35.5, 32.00
        fund 'UVWXY', 'Bonds', 75, 5.50
      end
    end

    it 'calculates the target value for each asset class' do
      target_values = @target.calculate_target_asset_class_values(@account)

      expected_target_values = {
        'Some Asset Class' => 10964.55,
        'Another Asset Class' => 7309.70,
        'Bonds' => 18274.25
      }

      target_values.must_equal expected_target_values
    end

    it 'calculates the current value for each asset class' do
      current_values = @target.calculate_current_asset_class_values(@account)

      expected_current_values = {
        'Some Asset Class' => 12500.00,
        'Another Asset Class' => 22500.00,
        'Bonds' => 1548.50
      }

      current_values.must_equal expected_current_values
    end

    describe 'after a rebalance' do
      before do
        @target.rebalance(@account)
      end

      it 'provides the new number of shares for each fund' do
        expected_rebalance = {
          'ABCDE' => 548.2275,
          'FGHIJ' => 219.291,
          'KLMNO' => 24.3657,
          'PQRST' => 285.5352,
          'UVWXY' => 1661.2955
        }

        @target.rebalanced_shares.must_equal expected_rebalance
      end

      it 'provides the difference in shares for each fund' do
        expected_difference = {
          'ABCDE' => 48.23,
          'FGHIJ' => -80.71,
          'KLMNO' => -50.63,
          'PQRST' => 250.04,
          'UVWXY' => 1586.30
        }

        @target.rebalanced_share_difference.must_equal expected_difference
      end

      it 'provides the new value for each fund' do
        expected_rebalance = {
          'ABCDE' => 5482.28,
          'FGHIJ' => 5482.28,
          'KLMNO' => 7309.70,
          'PQRST' => 9137.13,
          'UVWXY' => 9137.13
        }

        @target.rebalanced_values.must_equal expected_rebalance
      end

      it 'provides the difference in value for each fund' do
        expected_difference = {
          'ABCDE' => 482.28,
          'FGHIJ' => -2017.72,
          'KLMNO' => -15190.30,
          'PQRST' => 8001.13,
          'UVWXY' => 8724.63
        }

        @target.rebalanced_value_difference.must_equal expected_difference

        total_value = 0
        @target.rebalanced_value_difference.values.each { |value| total_value += value }
        total_value.round(2).must_equal 0.02
      end
    end
  end

  describe 'with multiple accounts' do
    before do
      @wifes_roth = Rebalance::Account.new "Wife's Roth" do
        fund 'ABCDE', 'Some Asset Class', 500, 10.00 # $5,000
        fund 'FGHIJ', 'Some Asset Class', 300, 25.00 # $7,500
        fund 'KLMNO', 'Another Asset Class', 75, 300 # $22,500
        fund 'PQRST', 'Bonds', 35.5, 32.00           # $1,136
        fund 'UVWXY', 'Bonds', 75, 5.50              # $412.50
      end

      @my_roth = Rebalance::Account.new 'My Roth' do
        fund 'AAAAA', 'Cash', 150, 1.00              # $150
        fund 'BBBBB', 'Some Asset Class', 10, 23.00  # $230
        fund 'FGHIJ', 'Some Asset Class', 100, 25.00 # $2,500
      end

      @my_sep_ira = Rebalance::Account.new 'My SEP IRA' do
        fund 'ZZZZZ', 'Bonds', 250, 20.25            # $5,062.50
      end
    end

    it 'calculates the total value of all accounts' do
      @target.total_value_of_all_accounts([@wifes_roth, @my_roth, @my_sep_ira]).must_equal 44491.00
    end

    it 'calculates the target value for each asset class' do
      target_values = @target.calculate_target_asset_class_values(@wifes_roth, @my_roth, @my_sep_ira)

      expected_target_values = {
        'Some Asset Class' => 13347.30,
        'Another Asset Class' => 8898.20,
        'Bonds' => 22245.50
      }

      target_values.must_equal expected_target_values
    end

    it 'calculates the current value for each asset class' do
      current_values = @target.calculate_current_asset_class_values(@wifes_roth, @my_roth, @my_sep_ira)

      expected_current_values = {
        'Some Asset Class' => 15230.00,
        'Another Asset Class' => 22500.00,
        'Bonds' => 6611.00,
        'Cash' => 150.00
      }

      current_values.must_equal expected_current_values
    end

    it 'calculates the current percentage for each asset class' do
      current_values = @target.calculate_current_asset_class_percentages(@wifes_roth, @my_roth, @my_sep_ira)

      expected_current_values = {
        'Some Asset Class' => 34.2316,
        'Another Asset Class' => 50.5720,
        'Bonds' => 14.8592,
        'Cash' => 0.3371
      }

      current_values.must_equal expected_current_values
    end

    it 'calculates the asset class percentages across all accounts' do
      expected_percentages = {
        "Wife's Roth" => {
          "Some Asset Class" => 28.0956,
          "Another Asset Class" => 50.5720,
          "Bonds" => 3.4805
        },
        "My Roth" => {
          "Cash" => 0.3371,
          "Some Asset Class" => 6.1361
        },
        "My SEP IRA" => {
          "Bonds" => 11.3787
        }
      }

      @target.asset_class_percentages_across_all_accounts([@wifes_roth, @my_roth, @my_sep_ira]).must_equal expected_percentages
    end

    describe 'after a rebalance' do
      before do
        @target.rebalance(@wifes_roth, @my_roth, @my_sep_ira)
      end

      it 'provides the new number of shares for each fund' do
        expected_rebalance = {
          "Wife's Roth" => {
            'ABCDE' => 548.2275,
            'FGHIJ' => 219.291,
            'KLMNO' => 24.3657,
            'PQRST' => 285.5352,
            'UVWXY' => 1661.2955
          },
          "My Roth" => {
            'AAAAA' => 0,
            'BBBBB' => 0,
            'FGHIJ' => 0
          },
          "My SEP IRA" => {
            'ZZZZZ' => 0
          }
        }

        @target.rebalanced_shares.must_equal expected_rebalance
      end
    end
  end
end
