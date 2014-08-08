SPEC_ROOT=__dir__.freeze

require 'logger'
require 'yaml'

require 'dotenv'
Dotenv.load

def vcenter_config_hash
  {
    'vcenter_ip'      => ENV['VCENTER_IP'],
    'username'        => ENV['USERNAME'],
    'password'        => ENV['PASSWORD'],
    'datacenter_name' => ENV['DATACENTER_NAME'],
    'datastore_name'  => ENV['DATASTORE_NAME'],
  }
end

def wait(retries_left, &blk)
  blk.call
rescue RSpec::Expectations::ExpectationNotMetError, NoMethodError
  retries_left -= 1
  if retries_left > 0
    sleep(1)
    retry
  else
    raise
  end
end

RSpec.configure do |config|
  config.expect_with(:rspec) { |c| c.syntax = :expect }
end
