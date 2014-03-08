require "rbvmomi"
require "vsphere_integration"

module VsphereIntegrationHelpers
  def create_vsphere_environment(config)
    VsphereIntegration::Environment.from_config(config)
  end
end

RSpec.configure do |config|
  config.include(VsphereIntegrationHelpers)
end
