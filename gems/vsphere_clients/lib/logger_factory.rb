module VsphereClients
  class LoggerFactory
    def self.logger
      ::Logger.new(STDERR)
    end
  end
end
