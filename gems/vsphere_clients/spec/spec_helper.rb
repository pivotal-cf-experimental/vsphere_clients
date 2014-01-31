require "vsphere_clients"
require "yaml"
require "time"

module FixtureHelpers
  def fixture_path(basename)
    File.expand_path("../fixtures/#{basename}", __FILE__)
  end

  def fixture_yaml(basename)
    YAML.load_file(fixture_path(basename)).tap do |yaml|
      raise ArgumentError, "Fixture '#{basename}' contains empty hash" \
      unless yaml.is_a?(Hash)
    end
  end
end


module WaitHelpers
  def wait(retries_left, interval, &blk)
    blk.call
  rescue
    retries_left -= 1
    if retries_left > 0
      sleep(interval)
      retry
    else
      raise
    end
  end
end

RSpec.configure do |config|
  config.include(FixtureHelpers)
  config.include(WaitHelpers, type: :integration)

  # silence logging output in tests
  config.before(:each) { VsphereClients::LoggerFactory.stub(logger: Logger.new("/dev/null")) }
end
