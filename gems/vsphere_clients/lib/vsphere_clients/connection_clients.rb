require "rbvmomi"

module VsphereClients
  class ConnectionClients
    def self.from_config(config)
      new(
        microbosh_property(config, "vcenter_ip"),
        microbosh_property(config, "login_credentials")["identity"],
        microbosh_property(config, "login_credentials")["password"],
        microbosh_property(config, "datacenter"),
        microbosh_property(config, "datastore"),
      )
    end

    def self.microbosh_property(config, property_blueprint)
      microbosh = config["components"].find { |c| c["type"] == "microbosh" }
      raise ArgumentError, "missing microbosh component" \
        unless microbosh.is_a?(Hash) && microbosh["properties"].is_a?(Array)

      property = microbosh["properties"].find { |p| p["definition"] == property_blueprint }
      raise ArgumentError, "missing microbosh #{property_blueprint}" \
        unless property.is_a?(Hash)

      property["value"]
    end

    def initialize(ip, user, password, datacenter_name, datastore_name)
      @ip = ip
      @user = user
      @password = password
      @datacenter_name = datacenter_name
      @datastore_name = datastore_name
    end

    def datacenter
      @datacenter ||= connection.serviceInstance.find_datacenter(@datacenter_name)
    end

    attr_reader :user, :password, :datastore_name

    def vm_folder_client
      VsphereClients::VmFolderClient.new(datacenter, Logger.new(STDERR))
    end

    private

    def connection
      @connection ||= RbVmomi::VIM.connect(
        host: @ip,
        user: @user,
        password: @password,
        ssl: true,
        insecure: true,
      )
    end
  end
end
