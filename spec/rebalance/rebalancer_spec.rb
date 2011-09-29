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

    it 'provides the new number of shares for each fund' do
      expected_rebalance = {
        'ABCDE' => 548.2275,
        'FGHIJ' => 219.291,
        'KLMNO' => 24.3657,
        'PQRST' => 285.5352,
        'UVWXY' => 1661.2955
      }

      @rebalance.rebalanced_shares.must_equal expected_rebalance
    end

    it 'provides the difference in shares for each fund' do
      expected_difference = {
        'ABCDE' => 48.23,
        'FGHIJ' => -80.71,
        'KLMNO' => -50.63,
        'PQRST' => 250.04,
        'UVWXY' => 1586.30
      }

      @rebalance.rebalanced_share_difference.must_equal expected_difference
    end

    it 'provides the new value for each fund' do
      expected_rebalance = {
        'ABCDE' => 5482.28,
        'FGHIJ' => 5482.28,
        'KLMNO' => 7309.70,
        'PQRST' => 9137.13,
        'UVWXY' => 9137.13
      }

      @rebalance.rebalanced_values.must_equal expected_rebalance
    end

    it 'provides the difference in value for each fund' do
      expected_difference = {
        'ABCDE' => 482.28,
        'FGHIJ' => -2017.72,
        'KLMNO' => -15190.30,
        'PQRST' => 8001.13,
        'UVWXY' => 8724.63
      }

      @rebalance.rebalanced_value_difference.must_equal expected_difference

      total_value = 0
      @rebalance.rebalanced_value_difference.values.each { |value| total_value += value }
      total_value.round(2).must_equal 0.02
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
        'ABCDE' => 525.2515,
        'FGHIJ' => 210.1006,
        'KLMNO' => 29.5349,
        'PQRST' => 268.4844,
        'UVWXY' => 1562.0911
      },
        "My Roth" => {
        'AAAAA' => 0.0,
        'BBBBB' => 62.60850,
        'FGHIJ' => 57.59980
      },
        "My SEP IRA" => {
        'ZZZZZ' => 249.9999
      }
      }

      @rebalance.rebalanced_shares.must_equal expected_rebalance
    end

    it 'provides the share difference for each fund' do
      expected_rebalance = {
        "Wife's Roth" => {
        'ABCDE' => 25.25,
        'FGHIJ' => -89.9,
        'KLMNO' => -45.47,
        'PQRST' => 232.98,
        'UVWXY' => 1487.09
      },
        "My Roth" => {
        'AAAAA' => -150.0,
        'BBBBB' => 52.61,
        'FGHIJ' => -42.4
      },
        "My SEP IRA" => {
        'ZZZZZ' => 0.0
      }
      }

      @rebalance.rebalanced_share_difference.must_equal expected_rebalance
    end

    it 'provides the rebalanced values for each fund' do
      expected_rebalance = {
        "Wife's Roth" => {
        'ABCDE' => 5252.52,
        'FGHIJ' => 5252.52,
        'KLMNO' => 8860.48,
        'PQRST' => 8591.50,
        'UVWXY' => 8591.50
      },
        "My Roth" => {
        'AAAAA' => 0,
        'BBBBB' => 1440.00,
        'FGHIJ' => 1440.00
      },
        "My SEP IRA" => {
        'ZZZZZ' => 5062.50
      }
      }

      @rebalance.rebalanced_values.must_equal expected_rebalance
    end

    it 'provides the rebalanced value difference for each fund' do
      expected_rebalance = {
        "Wife's Roth" => {
        'ABCDE' => 252.52,
        'FGHIJ' => -2247.48,
        'KLMNO' => -13639.52,
        'PQRST' => 7455.50,
        'UVWXY' => 8179.00
      },
        "My Roth" => {
        'AAAAA' => -150.00,
        'BBBBB' => 1210.00,
        'FGHIJ' => -1060.00
      },
        "My SEP IRA" => {
        'ZZZZZ' => 0.00
      }
      }

      @rebalance.rebalanced_value_difference.must_equal expected_rebalance
    end

    it 'ensures that each account retains the same value' do
      [@wifes_roth, @my_roth, @my_sep_ira].each do |account|
        rebalanced_total = @rebalance.rebalanced_values[account.name].values.inject{|sum,x| sum + x }
        account.total_value.must_be_within_delta rebalanced_total, 0.10
      end
    end
  end
end
