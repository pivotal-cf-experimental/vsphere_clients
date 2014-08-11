require 'spec_helper'
require 'vsphere_clients/cached_ovf_deployer'

describe VsphereClients::CachedOvfDeployer do

  describe '#resource_pool' do
    let(:cluster) { double('cluster', resourcePool: cluster_resource_pool) }
    let(:cluster_resource_pool) { double("vSphere cluster's (hidden) resource pool",
                                         resourcePool: resource_pools) }

    let(:resource_pools) { [honey_badger_pool, chicken_little_pool] }
    let(:honey_badger_pool) { double(name: 'honey badger') }
    let(:chicken_little_pool) { double(name: 'chicken little') }

    let(:badger_deployer) { described_class.new(double, double, cluster, 'honey badger', double, double, double) }
    let(:chicken_deployer) { described_class.new(double, double, cluster, 'chicken little', double, double, double) }

    it 'finds the resource pool with the specified name' do
      expect(badger_deployer.resource_pool).to eq(honey_badger_pool)
      expect(chicken_deployer.resource_pool).to eq(chicken_little_pool)
    end
  end
end
