# coding: utf-8
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "vsphere_clients/version"

Gem::Specification.new do |spec|
  spec.name          = "vsphere_clients"
  spec.version       = VsphereClients::VERSION
  spec.authors       = ["Pivotal CF"]
  spec.email         = ["cfaccounts+rubygems@pivotallabs.com"]
  spec.description   = %q{Tools to connect to vSphere}
  spec.summary       = %q{Tools to connect to vSphere}
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = Dir.glob("{bin,lib}/**/*") + %w(LICENSE.txt README.md)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec"

  spec.add_dependency "rbvmomi", "1.6.0"
end
