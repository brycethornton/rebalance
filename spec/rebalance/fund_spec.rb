require File.expand_path('../../spec_helper', __FILE__)

describe Rebalance::Fund do
  before do
    @fund = Rebalance::Fund.new('ABC', 'Bonds', 20, 4.51)
  end

  it "knows it's total value" do
    @fund.value.must_equal 90.20
  end
end
