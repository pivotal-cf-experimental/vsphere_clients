Gem::Specification.new do |spec|
  spec.name          = 'vsphere_clients'
  spec.version       = '0.0.1'
  spec.authors       = ''
  spec.summary       = 'Tools to connect to vSphere'

  spec.files         = Dir['lib/**/*']

  spec.add_dependency 'rbvmomi', '1.6.0'

  spec.add_development_dependency 'bundler', '~> 1.3'
  spec.add_development_dependency 'dotenv'
  spec.add_development_dependency 'rspec'
end
