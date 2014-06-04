require "spec_helper"
require "disk_path_client"
require "logger"

describe VsphereClients::DiskPathClient do
  let(:test_disk_path) { "disk_path_spec_playground" }
  let(:logger) { Logger.new(STDERR).tap { |l| l.level = Logger::FATAL } }
  let(:vsphere_environment) { create_vsphere_environment(fixture_yaml("config-#{`hostname`.strip}.yml")) }
  let(:username) { vsphere_environment.username }
  let(:password) { vsphere_environment.password }
  let(:datacenter) { vsphere_environment.datacenter }
  let(:datastore_name) { vsphere_environment.datastore_name }
  subject { described_class.new(username, password, datacenter, logger).tap(&:start_session!) }

  context "when it can successfully create the disk path" do
    def wait_for_disk_path_to_exist(datastore_name, disk_path)
      wait(5, 1) { expect(datacenter.find_datastore(datastore_name).exists?(disk_path)).to eq(true) }
    end

    def wait_for_disk_path_to_not_exist(datastore_name, disk_path)
      wait(5, 1) { expect(datacenter.find_datastore(datastore_name).exists?(disk_path)).to eq(false) }
    end

    after { subject.delete_path(datastore_name, test_disk_path) }

    it "creates and deletes the given disk path" do
      wait_for_disk_path_to_not_exist(datastore_name, test_disk_path)

      subject.create_path(datastore_name, test_disk_path)
      wait_for_disk_path_to_exist(datastore_name, test_disk_path)

      subject.delete_path(datastore_name, test_disk_path)
      wait_for_disk_path_to_not_exist(datastore_name, test_disk_path)
    end

    it "doesn't raise an error when deleting a non-existent disk path" do
      expect {
        subject.delete_path(datastore_name, test_disk_path)
      }.not_to raise_error
    end

    it "allows files with spaces and percent" do
      valid_file_name = "valid %"

      expect {
        subject.create_path(datastore_name, valid_file_name)
      }.to_not raise_error
      expect {
        subject.delete_path(datastore_name, valid_file_name)
      }.to_not raise_error
    end

    context "when other directories exist" do
      let(:other_path) { "bagels_and_lox" }
      before { subject.create_path(datastore_name, other_path) }
      after { subject.delete_path(datastore_name, other_path) }

      it "doesn't delete other directories" do
        wait_for_disk_path_to_not_exist(datastore_name, test_disk_path)
        wait_for_disk_path_to_exist(datastore_name, other_path)

        subject.create_path(datastore_name, test_disk_path)
        wait_for_disk_path_to_exist(datastore_name, test_disk_path)
        wait_for_disk_path_to_exist(datastore_name, other_path)

        subject.delete_path(datastore_name, test_disk_path)
        wait_for_disk_path_to_not_exist(datastore_name, test_disk_path)
        wait_for_disk_path_to_exist(datastore_name, other_path)
      end
    end
  end

  context "when the given path is invalid" do
    generally_bad_paths = [nil, "", "\\bosh_vms", "C:\\\\vms",
                           "/bosh_vms", "a"*81, "colon:name", "foo\n",
                           "exciting!/folder", "questionable?/folder",
                           "whatthef&^%$#",]
    nested_bad_paths = ["nested/folder", "trailing/", "name space with slash/"]

    (generally_bad_paths + nested_bad_paths).each do |bad_path|
      it "raises an ArgumentError instead of trying to create #{bad_path.inspect}" do
        expect {
          subject.create_path(datastore_name, bad_path)
        }.to raise_error(ArgumentError)
      end

      it "raises an ArgumentError instead of trying to delete #{bad_path.inspect}" do
        expect {
          subject.delete_path(datastore_name, bad_path)
        }.to raise_error(ArgumentError)
      end
    end
  end
end
