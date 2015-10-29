# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'optimal_payments/version'

Gem::Specification.new do |spec|
  spec.name          = "optimal_payments"
  spec.version       = OptimalPayments::VERSION
  spec.authors       = ["Javier Julio"]
  spec.email         = ["jjfutbol@gmail.com"]

  spec.summary       = %q{Gem to wrap Optimal Payments REST API}
  spec.description   = %q{Gem to wrap Optimal Payments REST API}
  spec.homepage      = "https://github.com/javierjulio/optimal_payments"
  spec.license       = "MIT"

  # Prevent pushing this gem to RubyGems.org by setting 'allowed_push_host', or
  # delete this section to allow pushing this gem to any host.
  if spec.respond_to?(:metadata)
    spec.metadata['allowed_push_host'] = "TODO: Set to 'http://mygemserver.com'"
  else
    raise "RubyGems 2.0 or newer is required to protect against public gem pushes."
  end

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.10"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "dotenv"
  spec.add_development_dependency "minitest"
  spec.add_development_dependency "minitest-reporters"
  spec.add_development_dependency "vcr"
  spec.add_development_dependency "webmock"

  spec.add_dependency "excon"
  spec.add_dependency "http", '~> 0.9.4'

end