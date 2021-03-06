require 'spec_helper'
require 'vsphere_clients/vm_power_manager'

module VsphereClients
  describe VmPowerManager do
    describe '#power_off' do
      subject(:vm_power_manager) { VmPowerManager.new(vm, Logger.new(STDERR).tap { |l| l.level = Logger::FATAL }) }
      let(:vm) { instance_double('RbVmomi::VIM::VirtualMachine', name: 'vm-name', runtime: vm_runtime) }
      let(:vm_runtime) { double(:runtime) }

      context 'when runtime is not powered off' do
        before { allow(vm_runtime).to receive_messages(powerState: 'non-powered-off') }
        let(:power_off_task) { instance_double('RbVmomi::VIM::Task') }

        it 'powers the vm off' do
          expect(vm).to receive(:PowerOffVM_Task)
                        .and_return(power_off_task)
          expect(power_off_task)
          .to receive(:wait_for_completion)
          vm_power_manager.power_off
        end

        error = RuntimeError.new(
          'InvalidPowerState: message for invalid power state')

        it "tries to power off vm one more time if first power off fails with '#{error}'" do
          expect(vm).to receive(:PowerOffVM_Task)
                        .twice
                        .and_return(power_off_task)
          expect(power_off_task)
          .to receive(:wait_for_completion)
              .twice
              .and_raise(error)
          expect { vm_power_manager.power_off }.to raise_error(error)
        end
      end

      context 'when runtime is powered off' do
        before { allow(vm_runtime).to receive_messages(powerState: 'poweredOff') }

        it "doesn't try to power off the machine" do
          expect(vm).not_to receive(:PowerOffVM_Task)
          vm_power_manager.power_off
        end
      end
    end
  end
end
