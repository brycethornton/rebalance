require File.expand_path('../../spec_helper', __FILE__)

describe Rebalance::Fund do
  it "knows it's total value" do
    fund = Rebalance::Fund.new('ABC', 'Bonds', 20, 4.51)
    fund.value.must_equal 90.20
  end

  it "will look up the price if none is specified" do
    VCR.use_cassette('yql_for_VISVX', :record => :new_episodes) do
      fund = Rebalance::Fund.new('VISVX', 'US Small Cap Value', 20)
      fund.price.must_equal 15.30
    end
  end
end
