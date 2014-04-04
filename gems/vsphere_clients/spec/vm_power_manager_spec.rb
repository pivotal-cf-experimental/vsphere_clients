require "spec_helper"
require "vm_power_manager"
require "logger"

describe VsphereClients::VmPowerManager do
  describe "#power_off" do
    subject { described_class.new(vm, Logger.new(STDERR).tap { |l| l.level = Logger::FATAL }) }
    let(:vm)         { double(:vm, name: "vm-name", runtime: vm_runtime) }
    let(:vm_runtime) { double(:runtime) }

    def perform
      subject.power_off
    end

    context "when runtime is not powered off" do
      before { vm_runtime.stub(powerState: "non-powered-off") }
      let(:power_off_task) { double(:power_off_task) }

      it "powers the vm off" do
        vm.should_receive(:PowerOffVM_Task)
          .and_return(power_off_task)
        power_off_task
          .should_receive(:wait_for_completion)
        perform
      end

      error = RuntimeError.new(
        "InvalidPowerState: message for invalid power state")

      it "tries to power off vm one more time if first power off fails with '#{error}'" do
        vm.should_receive(:PowerOffVM_Task)
          .twice
          .and_return(power_off_task)
        power_off_task
          .should_receive(:wait_for_completion)
          .twice
          .and_raise(error)
        expect { perform }.to raise_error(error)
      end
    end

    context "when runtime is powered off" do
      before { vm_runtime.stub(powerState: "poweredOff") }

      it "doesn't try to power off the machine" do
        vm.should_not_receive(:PowerOffVM_Task)
        perform
      end
    end
  end
end
