# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "rebalance/version"

Gem::Specification.new do |s|
  s.name        = "rebalance"
  s.version     = Rebalance::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Bryce Thornton"]
  s.email       = ["brycethornton@gmail.com"]
  s.homepage    = ""
  s.summary     = %q{Target asset allocation rebalancer}
  s.description = %q{Rebalances mutual fund accounts to match your target asset allocation}

  s.add_dependency "ruport"
  s.add_dependency "json"
  s.add_development_dependency "vcr"
  s.add_development_dependency "webmock"

  s.rubyforge_project = "rebalance"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]
end
