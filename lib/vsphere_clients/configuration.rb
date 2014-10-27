require 'rbvmomi'

module VsphereClients
  class Configuration
    attr_reader :vcenter_ip, :username, :password, :datastore_name

    def initialize(vcenter_ip:, username:, password:, datacenter_name:, datastore_name:)
      @vcenter_ip = vcenter_ip
      @username = username
      @password = password
      @datacenter_name = datacenter_name
      @datastore_name = datastore_name
    end

    def datacenter
      return @datacenter if @datacenter
      match = connection.searchIndex.FindByInventoryPath(inventoryPath: @datacenter_name)
      @datacenter = match if match and match.is_a?(RbVmomi::VIM::Datacenter)
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
