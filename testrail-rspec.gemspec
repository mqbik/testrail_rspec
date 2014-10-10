# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'testrail/rspec/version'

Gem::Specification.new do |spec|
  spec.name          = "testrail-rspec"
  spec.version       = Testrail::Rspec::VERSION
  spec.authors       = ["Michal Kubik"]
  spec.email         = ["michal.kubik@boost.no"]
  spec.summary       = %q{RSpec exporter formatter - pushes test run results to TestRail instance.}
  spec.description   = %q{Allow exporting RSpect test run results into TestRail server.}
  spec.homepage      = ""
  spec.license       = "MIT"

  # spec.add_development_dependency ""

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.7"
  spec.add_development_dependency "rake", "~> 10.0"
end
