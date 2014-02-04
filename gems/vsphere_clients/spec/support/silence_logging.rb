require "logger_factory"

RSpec.configure do |config|
  config.before(:each) { VsphereClients::LoggerFactory.stub(logger: Logger.new("/dev/null")) }
end
