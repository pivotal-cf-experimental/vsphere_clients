Gem::Specification.new do |spec|
  spec.name          = 'vsphere_clients'
  spec.version       = '0.1.0'
  spec.authors       = ''
  spec.summary       = 'Tools to connect to vSphere'

  spec.files         = Dir['lib/**/*']

  spec.add_dependency 'rbvmomi'

  spec.add_development_dependency 'rspec'
end
