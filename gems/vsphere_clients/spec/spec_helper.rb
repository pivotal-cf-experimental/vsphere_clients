SPEC_ROOT=__dir__.freeze

def fixture_file(fixture_filename)
  File.join(SPEC_ROOT, "fixtures", fixture_filename)
end

Dir[File.expand_path(File.join("..", "support", "*.rb"), __FILE__)].each { |f| require f }

RSpec.configure do |config|
  config.expect_with(:rspec) { |c| c.syntax = :expect }
end
