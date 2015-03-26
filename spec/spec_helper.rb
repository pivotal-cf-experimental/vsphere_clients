SPEC_ROOT=__dir__.freeze

require 'logger'
require 'yaml'

def vcenter_config_hash
  {
    vcenter_ip: ENV['VCENTER_IP'],
    username: ENV['USERNAME'],
    password: ENV['PASSWORD'],
    datacenter_name: ENV['DATACENTER_NAME'],
    datastore_name: ENV['DATASTORE_NAME'],
  }
end

RSpec.configure do |config|
  config.expect_with(:rspec) { |c| c.syntax = :expect }
end
