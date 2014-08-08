require 'rbvmomi'

module VsphereClients
  class Configuration
    def self.from_hash(config)
      new(
        config['vcenter_ip'],
        config['username'],
        config['password'],
        config['datacenter_name'],
        config['datastore_name'],
      )
    end

    attr_reader :vcenter_ip, :username, :password, :datastore_name

    def initialize(vcenter_ip, username, password, datacenter_name, datastore_name)
      @vcenter_ip = vcenter_ip
      @username = username
      @password = password
      @datacenter_name = datacenter_name
      @datastore_name = datastore_name
    end

    def datacenter
      @datacenter ||= connection.serviceInstance.find_datacenter(@datacenter_name)
    end

    private

    def connection
      @connection ||= RbVmomi::VIM.connect(
        host: vcenter_ip,
        user: username,
        password: password,
        ssl: true,
        insecure: true,
      )
    end
  end
end
