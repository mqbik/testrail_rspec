# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

Gem::Specification.new do |spec|
  spec.name          = "testrail_rspec"

  spec.version       = '0.0.6'

  spec.authors       = ["Michal Kubik"]
  spec.email         = ["michal.kubik@boost.no"]
  spec.homepage      = "https://github.com/mkubik8080/testrail_rspec"

  spec.license       = "MIT"
  spec.summary       = %q{RSpec exporter formatter - pushes test run results to TestRail instance.}
  spec.description   = %q{Allow exporting RSpect test run results into TestRail server.}

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_dependency         'rspec',    '~> 3.0'
  spec.add_runtime_dependency "rubytree", "~> 0.9.4"

  spec.add_development_dependency "bundler", "~> 1.7"
  spec.add_development_dependency "rake", "~> 10.0"
end
