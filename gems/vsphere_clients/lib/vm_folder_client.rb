require "vm_power_manager"

module VsphereClients
  class VmFolderClient
    def initialize(datacenter, logger)
      @datacenter = datacenter
      @logger = logger
    end

    def create_folder(folder_name)
      raise ArgumentError unless folder_name_is_valid?(folder_name)
      raise ArgumentError if folder_exists?(folder_name)
      @datacenter.vmFolder.traverse(folder_name, RbVmomi::VIM::Folder, true)
    end

    def delete_folder(folder_name)
      unless folder = find_folder(folder_name)
        @logger.info("vm_folder_client.delete_folder.missing folder=#{folder_name}")
        return
      end

      vms_in_folder = find_vms(folder)
      vms_in_folder.each do |vm|
        VmPowerManager.new(vm, @logger).power_off
      end

      @logger.info("vm_folder_client.delete_folder.delete folder=#{folder_name}")
      folder.Destroy_Task.wait_for_completion

    rescue RbVmomi::Fault => e
      @logger.error("vm_folder_client.delete_folder.failed folder=#{folder_name}")
      @logger.error(e)
      raise
    end

    def folder_exists?(folder_name)
      !find_folder(folder_name).nil?
    end

    def find_vms_by_folder_name(folder_name)
      unless folder = find_folder(folder_name)
        @logger.info("vm_folder_client.find_vms_in_folder.missing folder=#{folder_name}")
        return []
      end

      find_vms(folder)
    end

    private

    def find_folder(folder_name)
      raise ArgumentError unless folder_name_is_valid?(folder_name)
      @datacenter.vmFolder.traverse(folder_name)
    end

    def find_vms(folder)
      vms = folder.childEntity.grep(RbVmomi::VIM::VirtualMachine)
      vms << folder.childEntity.grep(RbVmomi::VIM::Folder).map do |child|
        find_vms(child)
      end
      vms.flatten
    end

    def folder_name_is_valid?(folder_name)
      /\A([\w-]{1,80}\/)*[\w-]{1,80}\/?\z/.match(folder_name)
    end
  end
end
