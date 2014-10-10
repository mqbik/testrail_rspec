# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'testrail_rspec/version'

Gem::Specification.new do |spec|
  spec.name          = "testrail_rspec"
  spec.version       = TestrailRspec::VERSION
  spec.authors       = ["Michal Kubik"]
  spec.email         = ["michal.kubik@boost.no"]
  spec.summary       = %q{RSpec exporter formatter - pushes test run results to TestRail instance.}
  spec.description   = %q{Allow exporting RSpect test run results into TestRail server.}
  spec.homepage      = "https://github.com/mkubik8080/testrail-rspec"
  spec.license       = "MIT"

  spec.add_runtime_dependency "rubytree", "~> 0.9.4"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.7"
  spec.add_development_dependency "rake", "~> 10.0"
end
