module VsphereClients
  class DiskPathClient
    class NonceNotFoundError < StandardError; end
    class CreateError < StandardError; end
    class DeleteError < StandardError; end

    CSRF_NONCE_INPUT = /name="vmware-session-nonce" type="hidden" value="?(?<nonce>[^\s^"]+)"/

    def initialize(user, password, datacenter, logger)
      @user = user
      @password = password
      @datacenter = datacenter
      @datacenter_ref = datacenter._ref
      @logger = logger
    end

    # - Obtain CSRF token from *any* form on the site.
    # - Cannot use cookie from the connection since it's a different api.
    def start_session!
      request = Net::HTTP::Get.new("/mob/?moid=FileManager&method=makeDirectory")
      request.basic_auth(@user, @password)

      @logger.info("disk_path_client.start_session.started")
      response = http_client.request(request)

      @cookie = response["Set-Cookie"]
      @nonce = response.body.scan(CSRF_NONCE_INPUT).flatten.first

      if @nonce.nil?
        @logger.error("disk_path_client.start_session.failed")
        @logger.error(response.body)
        raise(NonceNotFoundError, "Failed to obtain VMware session nonce, you may need to enable vCenter Server Managed Object Browser")
      end
    end

    def path_exists?(datastore_name, disk_path)
      datastore = @datacenter.find_datastore(datastore_name)
      !disk_path.nil? && datastore.exists?(disk_path)
    end

    # - Java API does not provide this functionality
    # - Action is *synchronous*
    def create_path(datastore_name, disk_path)
      raise ArgumentError if path_exists?(datastore_name, disk_path)
      raise ArgumentError unless valid_path?(disk_path)
      create_path!(datastore_name, disk_path)
    end

    # - Unlike Java API, mob api deletes directories regardless their emptiness
    # - Action is *asynchronous*
    def delete_path(datastore_name, disk_path)
      raise ArgumentError unless valid_path?(disk_path)
      delete_path!(datastore_name, disk_path)
    end

    private

    def valid_path?(path)
      /\A[\w\-\%\ ]{1,80}\z/ =~ path
    end

    # same as above, but skip checking for slashes in the path name
    def create_path!(datastore_name, disk_path)
      request = build_nonced_form_post(
        "/mob/?moid=FileManager&method=makeDirectory", {
        name: "[#{datastore_name}] #{disk_path}",
        datacenter: %{<datacenter type="Datacenter" xsi:type="ManagedObjectReference">#{@datacenter_ref}</datacenter>},
        createParentDirectories: true,
      })

      @logger.info("disk_path_client.create_path.started disk_path=#{disk_path}")
      response = http_client.request(request)

      unless response.is_a?(Net::HTTPOK)
        @logger.error("disk_path_client.create_path.failed disk_path=#{disk_path}")
        raise(CreateError, response_error_message("Failed to create disk path '#{disk_path}'", response))
      end
    end

    # same as above, but skip checking for slashes in the path name
    def delete_path!(datastore_name, disk_path)
      request = build_nonced_form_post(
        "/mob/?moid=FileManager&method=deleteFile", {
        name: "[#{datastore_name}] #{disk_path}",
        datacenter: %{<datacenter type="Datacenter" xsi:type="ManagedObjectReference">#{@datacenter_ref}</datacenter>},
      })

      @logger.info("disk_path_client.delete_path.started disk_path=#{disk_path}")
      response = http_client.request(request)

      unless response.is_a?(Net::HTTPOK)
        @logger.error("disk_path_client.delete_path.failed disk_path=#{disk_path}")
        raise(DeleteError, response_error_message("Failed to delete disk path '#{disk_path}'", response))
      end
    end

    def uri
      http = @datacenter._connection.http
      @uri ||= URI.parse("http#{"s" if http.use_ssl?}://#{http.address}:#{http.port}")
    end

    def build_nonced_form_post(request_path, form_attrs)
      Net::HTTP::Post.new(request_path).tap do |r|
        r.basic_auth(@user, @password)
        r["Cookie"] = @cookie
        r["Content-Type"] = "application/x-www-form-urlencoded"
        r.body = URI.encode_www_form(form_attrs.merge("vmware-session-nonce" => @nonce))
      end
    end

    def http_client
      @http_client ||= Net::HTTP.new(uri.host, uri.port).tap do |h|
        h.use_ssl = true
        h.verify_mode = OpenSSL::SSL::VERIFY_NONE
      end
    end

    def response_error_message(msg, response)
      <<-MSG
        #{msg}
        Code: #{response.code}
        Body: <hidden>...#{response.body.split("</style>").last}
      MSG
    end
  end
end
