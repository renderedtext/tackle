# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'tackle/version'

Gem::Specification.new do |spec|
  spec.name          = "rt-tackle"
  spec.version       = Tackle::VERSION
  spec.licenses      = ['MIT']
  spec.authors       = ["Rendered Text"]
  spec.email         = ["devops@renderedtext.com"]

  spec.summary       = %q{RabbitMQ based single-thread worker}
  spec.description   = %q{RabbitMQ based single-thread worker}
  spec.homepage      = "https://semaphoreci.com"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency             "bunny"

  spec.add_development_dependency "bundler", "~> 1.10"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec"
  spec.add_development_dependency "byebug"
end
