Gem::Specification.new do |spec|
  spec.name          = "vsphere_clients"
  spec.version       = "0.0.0"
  spec.authors       = ""
  spec.summary       = "Tools to connect to vSphere"

  spec.files         = Dir["lib/**/*"]

  spec.add_dependency "rbvmomi", "1.6.0"

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rspec"
  spec.add_development_dependency "rspec-instafail"
  spec.add_development_dependency "fixture_helpers"
  spec.add_development_dependency "vsphere_integration"
end
