require "spec_helper"
require "vsphere_clients/vm_folder_client"
require "vsphere_clients/connection_clients"

describe VsphereClients::VmFolderClient do
  let(:test_playground_folder) { "vm_folder_client_spec_playground" }
  let(:parent_folder) { "#{test_playground_folder}/foo" }
  let(:nested_folder) { "#{parent_folder}/bargle" }

  before(:all) do
    config = fixture_yaml("config-#{`hostname`.strip}.yml")
    @datacenter = VsphereClients::ConnectionClients.from_config(config).datacenter
  end

  after(:all) do
    subject.delete_folder(test_playground_folder)
  end

  subject { described_class.new(@datacenter) }

  context "when it can successfully create folder" do
    after do
      folder = @datacenter.vmFolder.find(test_playground_folder)
      folder.Destroy_Task.wait_for_completion if folder
    end

    it "creates and deletes the given VM folder" do
      @datacenter.vmFolder.traverse(nested_folder).should be_nil

      subject.create_folder(nested_folder)
      @datacenter.vmFolder.traverse(nested_folder).should_not be_nil

      subject.delete_folder(nested_folder)
      @datacenter.vmFolder.traverse(nested_folder).should be_nil
    end

    it "propagates rbvmomi errors" do
      @datacenter
        .stub(:vmFolder)
        .and_raise(RbVmomi::Fault.new("error", nil))

      expect {
        subject.delete_folder(nested_folder)
      }.to raise_error(RbVmomi::Fault)

      # unstub to make sure that after block does not fail
      @datacenter.unstub(:vmFolder)
    end

    it "doesn't delete parent folders" do
      subject.create_folder(nested_folder)
      subject.delete_folder(nested_folder)
      @datacenter.vmFolder.traverse(nested_folder).should be_nil
      @datacenter.vmFolder.traverse(parent_folder).should_not be_nil
      @datacenter.vmFolder.traverse(test_playground_folder).should_not be_nil
    end

    it "doesn't delete sibling folders" do
      subject.create_folder(nested_folder)
      nested_sibling = "#{parent_folder}/snake"

      subject.create_folder(nested_sibling)
      subject.delete_folder(nested_folder)
      @datacenter.vmFolder.traverse(nested_folder).should be_nil
      @datacenter.vmFolder.traverse(nested_sibling).should_not be_nil
    end

    context "when there is a folder with slashes in the name " +
            "that is the same as the nested path" do
      let(:unnested_folder_with_slashes) { nested_folder.gsub("/", "%2f") }

      before do
        # creates a single top level folder whose name is something/with/slashes
        # does not create a nested structure
        # NB: the name of this object when retrieved by RbVmomi will be something%2fwith%2fslashes
        @datacenter.vmFolder.CreateFolder(name: nested_folder)
      end

      after { @datacenter.vmFolder.traverse(unnested_folder_with_slashes).Destroy_Task.wait_for_completion }

      it "doesn't delete the folder with slashes in its name" do
        @datacenter.vmFolder.traverse(unnested_folder_with_slashes).should_not be_nil
        @datacenter.vmFolder.traverse(nested_folder).should be_nil

        subject.create_folder(nested_folder)
        @datacenter.vmFolder.traverse(unnested_folder_with_slashes).should_not be_nil
        @datacenter.vmFolder.traverse(nested_folder).should_not be_nil

        subject.delete_folder(nested_folder)
        @datacenter.vmFolder.traverse(unnested_folder_with_slashes).should_not be_nil
        @datacenter.vmFolder.traverse(nested_folder).should be_nil
      end
    end
  end

  context "when the given VM folder path is invalid" do
    generally_bad_paths = [nil, "", "\\bosh_vms", "C:\\\\vms",
                           "/bosh_vms", "bosh vms", "a"*81, "colon:name",
                           "exciting!/folder", "questionable?/folder",
                           "whatthef&^%$#",]

    generally_bad_paths.each do |bad_input|
      it "raises an ArgumentError instead of trying to create #{bad_input.inspect}" do
        expect {
          subject.create_folder(bad_input)
        }.to raise_error(ArgumentError)
      end

      it "raises an ArgumentError instead of trying to delete #{bad_input.inspect}" do
        expect {
          subject.delete_folder(bad_input)
        }.to raise_error(ArgumentError)
      end

      it "raises an ArgumentError instead of checking for existance #{bad_input.inspect}" do
        expect {
          subject.folder_exists?(bad_input)
        }.to raise_error(ArgumentError)
      end

      it "raises an ArgumentError instead of looking for VMs #{bad_input.inspect}" do
        expect {
          subject.find_vms_by_folder_name(bad_input)
        }.to raise_error(ArgumentError)
      end
    end
  end

  describe "#delete_folder" do
    context "when folder does not exist" do
      it "doesn't raise an error so that action is idempotent" do
        expect {
          subject.delete_folder(nested_folder)
        }.not_to raise_error
      end
    end

    context "when folder exists" do
      context "when folder is empty" do
        before do
          subject.create_folder(test_playground_folder)
        end

        it "deletes the folder" do
          subject.delete_folder(test_playground_folder)
          @datacenter.vmFolder.traverse(test_playground_folder).should be_nil
        end
      end

      context "when folder does not contain VMs" do
        before do
          subject.create_folder(test_playground_folder)
          subject.create_folder("#{test_playground_folder}/folder1")
          subject.create_folder("#{test_playground_folder}/folder2")
        end

        it "deletes the folder and all sub-folders" do
          subject.delete_folder(test_playground_folder)
          @datacenter.vmFolder.traverse(test_playground_folder).should be_nil
          @datacenter.vmFolder.traverse("#{test_playground_folder}/folder1").should be_nil
          @datacenter.vmFolder.traverse("#{test_playground_folder}/folder2").should be_nil
        end
      end

      context "when folder contains VMs" do
        let(:vim_task)    { double(:vim_task, wait_for_completion: true) }

        let(:vm_runtime1) { double(:runtime1) }
        let(:vm1)         { double(:vm1, name: "vm-name1", runtime: vm_runtime1) }

        let(:vm_runtime2) { double(:runtime2) }
        let(:vm2)         { double(:vm2, name: "vm-name2", runtime: vm_runtime2) }

        let(:folder)        { double(:folder, name: "vm-folder") }
        let(:sub_folder)    { double(:sub_folder, name: "sub-folder") }

        before do
          @datacenter.stub_chain(:vmFolder, :traverse).with(test_playground_folder) { folder }
          sub_folder.stub_chain(:childEntity, :grep).with(RbVmomi::VIM::VirtualMachine) { [vm2] }
          sub_folder.stub_chain(:childEntity, :grep).with(RbVmomi::VIM::Folder) { [] }
        end


        context "when VMs are in folder" do
          before  do
            folder.stub_chain(:childEntity, :grep).with(RbVmomi::VIM::VirtualMachine) { [vm1, vm2] }
            folder.stub_chain(:childEntity, :grep).with(RbVmomi::VIM::Folder) { [] }
          end

          it "deletes folder with powered ON VMs" do
            vm_runtime1.should_receive(:powerState).once.ordered { "non-powered-off" }
            vm1.should_receive(:PowerOffVM_Task).once.ordered { vim_task }
            vm_runtime2.should_receive(:powerState).once.ordered { "non-powered-off" }
            vm2.should_receive(:PowerOffVM_Task).once.ordered { vim_task }
            folder.should_receive(:Destroy_Task).once { vim_task }

            subject.delete_folder(test_playground_folder)
          end

          it "deletes folder with powered OFF VMs" do
            vm_runtime1.should_receive(:powerState).once.ordered { "poweredOff" }
            vm1.should_not_receive(:PowerOffVM_Task)
            vm_runtime2.should_receive(:powerState).once.ordered { "poweredOff" }
            vm2.should_not_receive(:PowerOffVM_Task)
            folder.should_receive(:Destroy_Task).once { vim_task }

            subject.delete_folder(test_playground_folder)
          end
        end

        context "when VMs are in sub-folders" do
          before  do
            folder.stub_chain(:childEntity, :grep).with(RbVmomi::VIM::VirtualMachine) { [vm1] }
            folder.stub_chain(:childEntity, :grep).with(RbVmomi::VIM::Folder) { [sub_folder] }
          end

          it "deletes folder with powered ON VMs" do
            vm_runtime1.should_receive(:powerState).once.ordered { "non-powered-off" }
            vm1.should_receive(:PowerOffVM_Task).once.ordered { vim_task }
            vm_runtime2.should_receive(:powerState).once.ordered { "non-powered-off" }
            vm2.should_receive(:PowerOffVM_Task).once.ordered { vim_task }
            folder.should_receive(:Destroy_Task).once { vim_task }

            subject.delete_folder(test_playground_folder)
          end

          it "delete folder with powered OFF VMs" do
            vm_runtime1.should_receive(:powerState).once.ordered { "poweredOff" }
            vm1.should_not_receive(:PowerOffVM_Task)
            vm_runtime2.should_receive(:powerState).once.ordered { "poweredOff" }
            vm2.should_not_receive(:PowerOffVM_Task)
            folder.should_receive(:Destroy_Task).once { vim_task }

            subject.delete_folder(test_playground_folder)
          end
        end
      end
    end
  end

  describe "#folder_exists?" do
    context "when the folder exists" do
      before do
        subject.delete_folder(test_playground_folder)
        subject.create_folder(test_playground_folder)
      end

      it "returns true" do
        subject.folder_exists?(test_playground_folder).should == true
      end
    end

    context "when the folder doesn't exist" do
      before do
        subject.delete_folder(test_playground_folder)
      end

      it "returns false" do
        subject.folder_exists?(test_playground_folder).should == false
      end
    end
  end

  describe "#find_vms_by_folder_name" do
    context "when folder is not found" do
      it "does not raise exception" do
        expect {
          subject.find_vms_by_folder_name("does_not_exist_folder").should == []
        }.not_to raise_error
      end
    end

    context "when folder is found" do
      let(:vm1) { double(:vm1) }
      let(:vm2) { double(:vm2) }

      let(:folder)      { double(:folder) }
      let(:sub_folder)  { double(:sub_folder) }

      before do
        @datacenter.stub_chain(:vmFolder, :traverse).with(test_playground_folder) { folder }
      end

      context "when folder has no VMs" do
        before do
          sub_folder.stub_chain(:childEntity, :grep).with(RbVmomi::VIM::VirtualMachine) { [] }
          sub_folder.stub_chain(:childEntity, :grep).with(RbVmomi::VIM::Folder) { [] }

          folder.stub_chain(:childEntity, :grep).with(RbVmomi::VIM::VirtualMachine) { [] }
        end

        it "returns empty array when folder is empty" do
          folder.stub_chain(:childEntity, :grep).with(RbVmomi::VIM::Folder) { [] }
          subject.find_vms_by_folder_name(test_playground_folder).should == []
        end

        it "returns empty array when folder has only an empty sub-folder" do
          folder.stub_chain(:childEntity, :grep).with(RbVmomi::VIM::Folder) { [sub_folder] }
          subject.find_vms_by_folder_name(test_playground_folder).should == []
        end
      end

      context "when folder has VMs" do
        before do
          sub_folder.stub_chain(:childEntity, :grep).with(RbVmomi::VIM::VirtualMachine) { [vm2] }
          sub_folder.stub_chain(:childEntity, :grep).with(RbVmomi::VIM::Folder) { [] }

          folder.stub_chain(:childEntity, :grep).with(RbVmomi::VIM::VirtualMachine) { [vm1] }
        end

        it "returns VMs in folder" do
          folder.stub_chain(:childEntity, :grep).with(RbVmomi::VIM::Folder) { [] }
          subject.find_vms_by_folder_name(test_playground_folder).should == [vm1]
        end

        it "returns VMs in folder and sub-folder" do
          folder.stub_chain(:childEntity, :grep).with(RbVmomi::VIM::Folder) { [sub_folder] }
          subject.find_vms_by_folder_name(test_playground_folder).should == [vm1, vm2]
        end
      end
    end
  end
end
