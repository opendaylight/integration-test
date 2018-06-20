*** Settings ***
Documentation     Test Suite for Pseudo Port Binding
Suite Setup       Start Suite
Suite Teardown    OpenStackOperations.OpenStack Suite Teardown
Test Setup        Run Keywords    SetupUtils.Setup_Test_With_Logging_And_Without_Fast_Failing
...               AND    OpenStackOperations.Get DumpFlows And Ovsconfig    ${OS_CMP1_CONN_ID}
...               AND    OpenStackOperations.Get DumpFlows And Ovsconfig    ${OS_CMP2_CONN_ID}
Test Teardown     OpenStackOperations.Get Test Teardown Debugs
Library           OperatingSystem
Library           RequestsLibrary
Library           String
Library           Collections
Resource          ../../../libraries/DevstackUtils.robot
Resource          ../../../libraries/KarafKeywords.robot
Resource          ../../../variables/netvirt/Variables.robot
Resource          ../../../libraries/OVSDB.robot
Resource          ../../../libraries/OvsManager.robot
Resource          ../../../libraries/OpenStackOperations.robot
Resource          ../../../libraries/SetupUtils.robot
Resource          ../../../libraries/Utils.robot
Resource          ../../../variables/Variables.robot

*** Variables ***
${pseudo_security_group}    pseudo_sg
@{pseudo_networks}    pseudo_net_1
@{pseudo_subnets}    pseudo_sub_1    pseudo_sub_2    pseudo_sub_3
@{pseudo_subnet_cidrs}    81.1.1.0/24    82.1.1.0/24    83.1.1.0/24
@{pseudo_net_1_ports}    pseudo_net_1_port_1    pseudo_net_1_port_2
@{pseudo_net_1_vms}    pseudo_net_1_vm_1    pseudo_net_1_vm_2
@{table_ids}      51    36
${pseudo_host_type}    ODL%20L2
${match_ovs}      \\\"vif_type\\\": \\\"ovs\\\"
${match_vinic_type}    \\\"vnic_type\\\": \\\"normal\\\"
${match_ovs_odl}    "vif_type": "ovs"
${match_vinic_type_odl}    "vnic_type": "normal"

*** Test Cases ***
Verify Host Configuration For OVS And ODL
    [Documentation]    verify host configuration for ovs and odl
    ...    Bring up two VMs and check the VM ports have come up with host configuration.
    ...    Verify the ports binding_vif_type is ovs and
    ...    Verify Ping traffic is successful
    ${ovs_extrenal_ids} =    OVSDB.Get OVS External Ids Configuration    ${OS_CMP1_CONN_ID}    ${OS_COMPUTE_1_IP}
    BuiltIn.Should Contain    ${ovs_extrenal_ids}    ${OS_CMP1_HOSTNAME}
    BuiltIn.Should Contain    ${ovs_extrenal_ids}    ${match_ovs}
    BuiltIn.Should Contain    ${ovs_extrenal_ids}    ${match_vinic_type}
    ${json} =    OvsManager.Get JSON Elements From URI    ${PSEUDO_GET_CONFIGURATION_URI}/${compute_host_name}/${pseudo_host_type}
    ${keyValue}=    Get From Dictionary    ${json}    hostconfig
    ${passed}=    Run Keyword And Return Status    Evaluate    type(${keyValue}[0])
    ${type}=    Run Keyword If    ${passed}    Evaluate    type(${keyValue}[0])
    ${keyValue1}=    Get From Dictionary    ${keyValue[0]}    config
    Should Contain    ${keyValue1}    ${match_ovs_odl}
    Should Contain    ${keyValue1}    ${match_vinic_type_odl}
    OpenStackOperations.Create Vm Instance With Port On Compute Node    ${pseudo_net_1_ports[0]}    ${pseudo_net_1_vms[0]}    ${OS_CMP1_HOSTNAME}    sg=${pseudo_security_group}
    OpenStackOperations.Create Vm Instance With Port On Compute Node    ${pseudo_net_1_ports[1]}    ${pseudo_net_1_vms[1]}    ${OS_CMP2_HOSTNAME}    sg=${pseudo_security_group}
    @{pseudo_net_1_vm_ips}    ${pseudo_net_1_dhcp_ip} =    OpenStackOperations.Get VM IPs    @{pseudo_net_1_vms}
    BuiltIn.Should Not Contain    ${pseudo_net_1_vm_ips}    None
    BuiltIn.Should Not Contain    ${pseudo_net_1_dhcp_ip}    None
    ${output} =    OpenStackOperations.Execute Command on VM Instance    @{pseudo_networks}[0]    @{pseudo_net_1_vm_ips}[0]    ping -c 5 @{pseudo_net_1_vm_ips}[1]
    BuiltIn.Should Contain    ${output}    64 bytes

*** Keywords ***
Verify Port Binding Vif Type And Vnic Type
    [Arguments]    ${conn_id}    ${port_name}
    [Documentation]    Returns port Vif and Vnic Type details.
    SSHLibrary.Switch Connection    ${conn_id}
    ${output} =    OpenStack CLI    openstack port show ${port_name} | grep binding_vif_type | awk '{print $4}'
    @{list} =    Split String    ${output}
    ${binding_vif_type} =    Set Variable    ${list[0]}
    ${output} =    OpenStack CLI    openstack port show ${port_name} | grep binding_vnic_type | awk '{print $4}'
    @{list} =    Split String    ${output}
    ${binding_vnic_type} =    Set Variable    ${list[0]}
    Should Match    ${binding_vif_type}    ovs
    Should Match    ${binding_vnic_type}    normal

Start Suite
    [Documentation]    Create Basic setup for the feature. Creates single network, subnet, two ports
    OpenStackOperations.OpenStack Suite Setup
    OpenStackOperations.Create Allow All SecurityGroup    ${pseudo_security_group}
    OpenStackOperations.Create Network    @{pseudo_networks}[0]
    OpenStackOperations.Create SubNet    @{pseudo_networks}[0]    @{pseudo_subnets}[0]    ${pseudo_subnet_cidrs[0]}
    OpenStackOperations.Create Port    @{pseudo_networks}[0]    ${pseudo_net_1_ports[0]}    sg=${pseudo_security_group}
    OpenStackOperations.Create Port    @{pseudo_networks}[0]    ${pseudo_net_1_ports[1]}    sg=${pseudo_security_group}
    BuiltIn.Wait Until Keyword Succeeds    3s    1s    Utils.Check For Elements At URI    ${PORT_URL}    ${pseudo_net_1_ports}
