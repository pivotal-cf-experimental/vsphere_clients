Dir[File.expand_path(File.join("..", "support", "*.rb"), __FILE__)].each { |f| require f }
require "fixture_helpers"

RSpec.configure do |config|
  config.expect_with(:rspec) { |c| c.syntax = :expect }
end
