require File.expand_path('../../spec_helper', __FILE__)

describe Rebalance::Account do
  before do
    @account = Rebalance::Account.new 'Test Account' do
      fund 'ABCDE', 'Bonds', 200, 10.00
      fund 'FGHIJ', 'Domestic Stocks', 500, 25.19
      fund 'KLMNO', 'Domestic Stocks', 100, 20.00
    end
  end

  it "knows the account name" do
    @account.name.must_equal 'Test Account'
  end

  it "has the right number of funds" do
    @account.funds.size.must_equal 3
  end

  it "remembers the first fund" do
    @account.funds['ABCDE'].symbol.must_equal 'ABCDE'
  end

  it "knows the total value of all funds" do
    @account.total_value.must_equal 16595.00
  end

  it "knows the percentage of each fund" do
    percentages = @account.calculate_percentages
    percentages['ABCDE'].must_equal 12.051822838204277
  end

  it "finds funds by asset class" do
    @account.find_by_asset_class('Domestic Stocks')[0].symbol.must_equal 'FGHIJ'
    @account.find_by_asset_class('Domestic Stocks')[1].symbol.must_equal 'KLMNO'
  end
end
