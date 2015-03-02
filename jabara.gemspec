# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'jabara/version'

Gem::Specification.new do |spec|
  spec.name          = "jabara"
  spec.version       = Jabara::VERSION
  spec.authors       = ["Yuki Takeichi"]
  spec.email         = ["yuki.takeichi@gmail.com"]
  spec.summary       = "A gem for pluggable data transformation."
  spec.description   = "Nested data to flat, and flat data to nested."
  spec.homepage      = "https://github.com/yuki-takeichi/jabara"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.required_ruby_version = ">= 2.0.0"

  spec.add_dependency "scheman", "0.0.5"
  spec.add_dependency "yajl-ruby", "~> 1.2"
  spec.add_development_dependency "bundler", "~> 1.7"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "minitest"
end
