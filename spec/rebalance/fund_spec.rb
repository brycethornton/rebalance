require File.expand_path('../../spec_helper', __FILE__)

describe Rebalance::Fund do
  it "knows it's total value" do
    fund = Rebalance::Fund.new('ABC', 'Bonds', 20, 4.51)
    fund.value.must_equal 90.20
  end

  it "will look up the price if none is specified" do
    VCR.use_cassette('price_lookup_for_VISVX', :record => :new_episodes) do
      fund = Rebalance::Fund.new('VISVX', 'US Small Cap Value', 20)
      fund.price.must_equal 15.30
    end
  end

  it "will throw an exception if it can't lookup the price" do
    VCR.use_cassette('price_lookup_for_98765', :record => :new_episodes) do
      proc { fund = Rebalance::Fund.new('98765', 'Nonexistent Asset Class', 20) }.must_raise RuntimeError
    end
  end

  it "handles cash appropriately" do
    VCR.use_cassette('price_lookup_for_VMMXX', :record => :new_episodes) do
      fund = Rebalance::Fund.new('VMMXX', 'Cash', 500)
      fund.price.must_equal 1.00
    end
  end
end
