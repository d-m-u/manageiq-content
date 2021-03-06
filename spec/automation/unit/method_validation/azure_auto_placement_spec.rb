describe "azure best fit" do
  let(:cloud_network)     { FactoryBot.create(:cloud_network, :ems_id => ems.network_manager.id, :enabled => true) }
  let(:cloud_subnet)      { FactoryBot.create(:cloud_subnet, :ems_id => ems.network_manager.id, :cloud_network_id => cloud_network.id) }
  let(:ems)               { FactoryBot.create(:ems_azure_with_authentication) }
  let(:m2_small_flavor)   { FactoryBot.create(:flavor_azure, :ems_id => ems.id, :cloud_subnet_required => false) }
  let(:miq_provision)     do
    FactoryBot.create(:miq_provision_azure,
                       :options => options,
                       :userid  => user.userid,
                       :state   => 'active',
                       :status  => 'Ok')
  end
  let(:options) do
    {:src_vm_id      => vm_template.id,
     :placement_auto => [true, 1],
     :instance_type  => [m2_small_flavor.id, m2_small_flavor.name]}
  end
  let(:resource_group)    { FactoryBot.create(:azure_resource_group, :ems_id => ems.id) }
  let(:user)              { FactoryBot.create(:user_with_group) }
  let(:vm_template)       { FactoryBot.create(:template_azure, :ext_management_system => ems) }
  let(:ws) do
    MiqAeEngine.instantiate("/System/Request/Call_Instance_With_Message?" \
                            "namespace=Cloud/VM/Provisioning&class=Placement" \
                            "&instance=default&message=azure&" \
                            "MiqProvision::miq_provision=#{miq_provision.id}", user)
  end

  it "provision task object auto placement for cloud network" do
    Zone.seed
    MiqServer.seed
    cloud_subnet
    resource_group
    ws.root

    expect(miq_provision.reload.options).to include(
      :cloud_network  => [cloud_network.id,  cloud_network.name],
      :cloud_subnet   => [cloud_subnet.id,   cloud_subnet.name],
      :resource_group => [resource_group.id, resource_group.name],
    )
  end
end
