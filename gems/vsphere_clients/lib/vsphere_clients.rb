Dir[File.join(__dir__, "vsphere_clients", "**", "*.rb")].each do |vsphere_clients_file|
  require vsphere_clients_file
end
