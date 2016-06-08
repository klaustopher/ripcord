# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'ripcord/version'

Gem::Specification.new do |spec|
  spec.name          = "ripcord"
  spec.version       = Ripcord::VERSION
  spec.authors       = ["Klaus Zanders", "Pavel Forkert"]
  spec.email         = ["coding@kgz.me", "fxposter@gmail.com"]

  spec.summary       = %q{This is a JSON-RPC 2.0 client implementation with some specific additions (custom auth schemes, etc)}
  spec.description   = %q{JSON-RPC 2.0 client implementation}
  spec.homepage      = "https://github.com/klaustopher/ripcord"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.12"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.0"
end
