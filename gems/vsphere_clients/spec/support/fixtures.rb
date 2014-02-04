require "yaml"

module FixtureHelpers
  def fixture_path(basename)
    File.expand_path(File.join("..", "..", "fixtures", basename), __FILE__)
  end

  def fixture_yaml(basename)
    YAML.load_file(fixture_path(basename)).tap do |yaml|
      raise ArgumentError, "Fixture '#{basename}' contains empty hash" \
      unless yaml.is_a?(Hash)
    end
  end
end

RSpec.configure do |config|
  config.include(FixtureHelpers)
end
