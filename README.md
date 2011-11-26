Rebalance
====

I don't fancy myself a savvy investor.  Instead, I like to stick to basic rules
and let the magic of time and markets slowly grow my investments.  One way to do
this is investing in passive index funds and sticking to a pre-defined asset allocation.
Then, it's just a matter of rebalancing every once in a while to make sure the
allocations are in line with the goal. Sounds pretty simple, right?

Well, it gets slightly more complex you have multiple accounts with multiple funds
in each.  Trying to figure out the best way rebalance across all of these accounts
can be frustrating and eventually led me to write this gem.  You feed it all of your
investment information (one account or many) and it will tell you exactly what to
buy and sell in order to bring your asset allocation back into line.

## Install ####################################################################

    $ gem install rebalance

## Usage ######################################################################

Here's a basic example of a script using rebalance:

    require 'rubygems'
    require 'reblance'

    target = Rebalance::Target.new do
      asset_class 35, 'US Total Market'
      asset_class 18, 'Pacific'
      asset_class 18, 'Europe'
      asset_class 8,  'Real Estate'
      asset_class 8,  'Total Bond Market'
      asset_class 8,  'Inflation-Protected Bonds'
      asset_class 5,  'US Small Cap Value'
    end

    wifes_roth = Rebalance::Account.new "Wife's Roth" do
      fund 'VIPSX', 'Inflation-Protected Bonds', 200, 14.36
      fund 'VBMFX', 'Total Bond Market', 500, 11.03
    end

    my_roth = Rebalance::Account.new 'My Roth' do
      fund 'VISVX', 'US Small Cap Value', 200, 13.96
      fund 'VGSIX', 'Real Estate', 100, 17.30
      fund 'VTSAX', 'US Total Market', 300, 29.02
      fund 'VPACX', 'Pacific', 300, 8.96
      fund 'VEURX', 'Europe', 50, 21.46
    end

    my_traditional_ira = Rebalance::Account.new 'My Traditional IRA' do
      fund 'VTSAX', 'US Total Market', 500, 29.02
      fund 'VMMXX', 'Cash', 2500, 1.00
    end

    rebalance = Rebalance::Rebalancer.new(target, wifes_roth, my_roth, my_traditional_ira)

## License ###################################################################

(The MIT License)

Copyright (c) 2011 Bryce Thornton

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
'Software'), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED 'AS IS', WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
