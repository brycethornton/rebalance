require File.expand_path('../../spec_helper', __FILE__)

describe Rebalance::Target do
  before do
    @target = Rebalance::Target.new do
      asset_class 30, 'Some Asset Class'
      asset_class 20, 'Another Asset Class'
      asset_class 50, 'Bonds'
    end
  end

  it "allows asset_class to be called" do
    @target.asset_classes.size.must_equal 3
  end

  it "remembers the asset class description" do
    @target.asset_classes['Some Asset Class'].must_equal 30
  end

  describe "with account information" do
    before do
      @account = Rebalance::Account.new 'Test Account' do
        fund 'ABCDE', 'Some Asset Class', 500, 10.00
        fund 'FGHIJ', 'Some Asset Class', 300, 25.00
        fund 'KLMNO', 'Another Asset Class', 75, 300
        fund 'PQRST', 'Bonds', 35.5, 32.00
        fund 'UVWXY', 'Bonds', 75, 5.50
      end
    end

    it "calculates the target value for each asset class" do
      target_values = @target.calculate_target_asset_class_values(@account)

      expected_target_values = {
        'Some Asset Class' => 10964.55,
        'Another Asset Class' => 7309.70,
        'Bonds' => 18274.25
      }

      target_values.must_equal expected_target_values
    end

    it "calculates the current value for each asset class" do
      current_values = @target.calculate_current_asset_class_values(@account)

      expected_current_values = {
        'Some Asset Class' => 12500.00,
        'Another Asset Class' => 22500.00,
        'Bonds' => 1548.50
      }

      current_values.must_equal expected_current_values
    end

    it "can rebalance a single account" do
      @target.rebalance(@account)

      expected_rebalance = {
        'ABCDE' => 30,
        'FGHIJ' => 20,
        'KLMNO' => 10,
        'PQRST' => 5,
        'UVWXY' => 30
      }

      @target.rebalanced_shares.must_equal expected_rebalance
    end
  end
end
