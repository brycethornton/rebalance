require File.expand_path('../../spec_helper', __FILE__)

describe Rebalance::Rebalancer do
  describe 'with a single account' do
    before do
      @target = Rebalance::Target.new do
        asset_class 30, 'Some Asset Class'
        asset_class 20, 'Another Asset Class'
        asset_class 50, 'Bonds'
      end

      @account = Rebalance::Account.new 'Test Account' do
        fund 'ABCDE', 'Some Asset Class', 500, 10.00
        fund 'FGHIJ', 'Some Asset Class', 300, 25.00
        fund 'KLMNO', 'Another Asset Class', 75, 300
        fund 'PQRST', 'Bonds', 35.5, 32.00
        fund 'UVWXY', 'Bonds', 75, 5.50
      end

      @rebalance = Rebalance::Rebalancer.new(@target, @account)
      @rebalance.rebalance
    end

    it 'creates a hash of funds by asset class' do
      expected_hash = {
        'Some Asset Class' => [@account.funds['ABCDE'], @account.funds['FGHIJ']],
        'Another Asset Class' => [@account.funds['KLMNO']],
        'Bonds' => [@account.funds['PQRST'], @account.funds['UVWXY']]
      }

      @rebalance.funds_by_asset_class.must_equal expected_hash
    end

    it 'provides the new number of shares for each fund' do
      expected_rebalance = {
        'ABCDE' => 548.2275,
        'FGHIJ' => 219.291,
        'KLMNO' => 24.36566666666667,
        'PQRST' => 285.53515625,
        'UVWXY' => 1661.2954545454545
      }

      @rebalance.rebalanced_shares.must_equal expected_rebalance
    end

    it 'provides the difference in shares for each fund' do
      expected_difference = {
        'ABCDE' => 48.227499999999964,
        'FGHIJ' => -80.709,
        'KLMNO' => -50.63433333333333,
        'PQRST' => 250.03515625,
        'UVWXY' => 1586.2954545454545
      }

      @rebalance.rebalanced_share_difference.must_equal expected_difference
    end

    it 'provides the new value for each fund' do
      expected_rebalance = {
        'ABCDE' => 5482.275,
        'FGHIJ' => 5482.275,
        'KLMNO' => 7309.700000000001,
        'PQRST' => 9137.125,
        'UVWXY' => 9137.125
      }

      @rebalance.rebalanced_values.must_equal expected_rebalance
    end

    it 'provides the difference in value for each fund' do
      expected_difference = {
        'ABCDE' => 482.27499999999964,
        'FGHIJ' => -2017.7250000000004,
        'KLMNO' => -15190.3,
        'PQRST' => 8001.125,
        'UVWXY' => 8724.625
      }

      @rebalance.rebalanced_value_difference.must_equal expected_difference

      total_value = 0
      @rebalance.rebalanced_value_difference.values.each { |value| total_value += value }
      total_value.round(2).must_equal 0.00
    end

    it 'should be rebalanced' do
      assert_rebalanced @rebalance
      assert_accounts_have_same_values_after_rebalance @rebalance
    end
  end

  describe 'with multiple accounts' do
    before do
      @target = Rebalance::Target.new do
        asset_class 30, 'Some Asset Class'
        asset_class 20, 'Another Asset Class'
        asset_class 50, 'Bonds'
      end

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

      @rebalance = Rebalance::Rebalancer.new(@target, @wifes_roth, @my_roth, @my_sep_ira)
      @rebalance.rebalance
    end

    it 'provides the new number of shares for each fund' do
      expected_rebalance = {
        "Wife's Roth" => {
        'ABCDE' => 525.2508906250002,
        'FGHIJ' => 210.1003562500001,
        'KLMNO' => 29.534940625000004,
        'PQRST' => 268.484375,
        'UVWXY' => 1562.090909090909
      },
        "My Roth" => {
        'AAAAA' => 0.0,
        'BBBBB' => 62.608695652173914,
        'FGHIJ' => 57.6
      },
        "My SEP IRA" => {
        'ZZZZZ' => 250.00000000000006
      }
      }

      @rebalance.rebalanced_shares.must_equal expected_rebalance
    end

    it 'provides the share difference for each fund' do
      expected_rebalance = {
        "Wife's Roth" => {
        'ABCDE' => 25.25089062500024,
        'FGHIJ' => -89.89964374999991,
        'KLMNO' => -45.465059374999996,
        'PQRST' => 232.984375,
        'UVWXY' => 1487.090909090909
      },
        "My Roth" => {
        'AAAAA' => -150.0,
        'BBBBB' => 52.608695652173914,
        'FGHIJ' => -42.4
      },
        "My SEP IRA" => {
        'ZZZZZ' => 0.00000000000005684341886080802
      }
      }

      @rebalance.rebalanced_share_difference.must_equal expected_rebalance
    end

    it 'provides the rebalanced values for each fund' do
      expected_rebalance = {
        "Wife's Roth" => {
        'ABCDE' => 5252.508906250003,
        'FGHIJ' => 5252.508906250002,
        'KLMNO' => 8860.482187500002,
        'PQRST' => 8591.5,
        'UVWXY' => 8591.5
      },
        "My Roth" => {
        'AAAAA' => 0.0,
        'BBBBB' => 1440.0,
        'FGHIJ' => 1440.0
      },
        "My SEP IRA" => {
        'ZZZZZ' => 5062.500000000001
      }
      }

      @rebalance.rebalanced_values.must_equal expected_rebalance
    end

    it 'provides the rebalanced value difference for each fund' do
      expected_rebalance = {
        "Wife's Roth" => {
        'ABCDE' => 252.50890625000284,
        'FGHIJ' => -2247.491093749998,
        'KLMNO' => -13639.517812499998,
        'PQRST' => 7455.5,
        'UVWXY' => 8179.0
      },
        "My Roth" => {
        'AAAAA' => -150.0,
        'BBBBB' => 1210.0,
        'FGHIJ' => -1060.0
      },
        "My SEP IRA" => {
        'ZZZZZ' => 0.0000000000009094947017729282
      }
      }

      @rebalance.rebalanced_value_difference.must_equal expected_rebalance
    end

    it 'should be rebalanced' do
      assert_rebalanced @rebalance
      assert_accounts_have_same_values_after_rebalance @rebalance
    end
  end

  describe 'without enough value in an account with a single asset class to hit the target' do
    before do
      @target = Rebalance::Target.new do
        asset_class 90, 'Some Asset Class'
        asset_class 10, 'Another Asset Class'
      end

      @wifes_roth = Rebalance::Account.new "Wife's Roth" do
        fund 'BBBBB', 'Some Asset Class', 10, 23.00  # $230
      end

      @my_roth = Rebalance::Account.new 'My Roth' do
        fund 'KLMNO', 'Another Asset Class', 75, 300 # $22,500
      end

      @rebalance = Rebalance::Rebalancer.new(@target, @wifes_roth, @my_roth)
      @rebalance.rebalance
    end

    it 'should be rebalanced' do
      assert_rebalanced @rebalance
      assert_accounts_have_same_values_after_rebalance @rebalance
    end
  end

  describe 'with a lot of asset classes' do
    before do
      @target = Rebalance::Target.new do
        asset_class 35, 'US Total Market'
        asset_class 18, 'Pacific'
        asset_class 18, 'Europe'
        asset_class 8,  'Real Estate'
        asset_class 8,  'Total Bond Market'
        asset_class 8,  'Inflation-Protected Bonds'
        asset_class 5,  'US Small Cap Value'
      end

      @wifes_roth = Rebalance::Account.new "Wife's Roth" do
        fund 'VIPSX', 'Inflation-Protected Bonds', 285.71, 14.10
        fund 'VBMFX', 'Total Bond Market', 934.20, 11.01
      end

      @my_roth = Rebalance::Account.new 'My Roth' do
        fund 'VISVX', 'US Small Cap Value', 293.85, 13.52
        fund 'VGSIX', 'Real Estate', 231.16, 16.61
        fund 'VTSAX', 'US Total Market', 453.90, 28.42
        fund 'VPACX', 'Pacific', 33.43, 9.17
        fund 'VEURX', 'Europe', 135.25, 21.97
      end

      @my_traditional_ira = Rebalance::Account.new 'My Traditional IRA' do
        fund 'VTSAX', 'US Total Market', 625.33, 28.42
        fund 'VMMXX', 'Cash', 14524.44, 1.00
      end

      @rebalance = Rebalance::Rebalancer.new(@target, @wifes_roth, @my_roth, @my_traditional_ira)
      @rebalance.rebalance
    end

    it 'should be rebalanced' do
      assert_rebalanced @rebalance
      assert_accounts_have_same_values_after_rebalance @rebalance
    end

    it 'should print results in tabular format' do
      results = @rebalance.results.to_s
      results.must_include "| Wife's Roth        | VBMFX | Total Bond Market         | $11.01 | $0.00         | $8,525.09      |"
    end
  end
end
