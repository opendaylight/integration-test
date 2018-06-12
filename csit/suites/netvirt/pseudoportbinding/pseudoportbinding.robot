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
${PSEUDO_SECURITY_GROUP}    pseudo_sg
@{PSEUDO_NETWORKS}    pseudo_net_1
@{PSEUDO_SUBNETS}    pseudo_sub_1    pseudo_sub_2    pseudo_sub_3
@{PSEUDO_SUBNET_CIDRS}    51.1.1.0/24    52.1.1.0/24    53.1.1.0/24
@{PSEUDO_NET_1_PORTS}    pseudo_net_1_port_1    pseudo_net_1_port_2
@{PSEUDO_NET_1_VMS}    pseudo_net_1_vm_1    pseudo_net_1_vm_2
${PSEUDO_HOST_TYPE}    ODL%20L2
${MATCH_OVS}      \\\"vif_type\\\": \\\"ovs\\\"
${MATCH_VNIC_TYPE}    \\\"vnic_type\\\": \\\"normal\\\"
${MATCH_OVS_ODL}    "vif_type": "ovs"
${MATCH_VNIC_TYPE_ODL}    "vnic_type": "normal"

*** Test Cases ***
Verify Host Configuration For OVS And ODL
    [Documentation]    verify host configuration for ovs and odl
    ...    Bring up two VMs and check the VM ports have come up with host configuration.
    ...    Verify the ports binding_vif_type is ovs and
    ...    Verify Ping traffic is successful
    ${ovs_external_ids} =    OVSDB.Get OVS External Ids Configuration    ${OS_CMP1_CONN_ID}    ${OS_COMPUTE_1_IP}
    BuiltIn.Should Contain    ${ovs_external_ids}    ${OS_CMP1_HOSTNAME}
    BuiltIn.Should Contain    ${ovs_external_ids}    ${MATCH_OVS}
    BuiltIn.Should Contain    ${ovs_external_ids}    ${MATCH_VNIC_TYPE}
    ${json} =    Utils.Get JSON Elements From URI    ${NUETRON_HOSTCONFIG_URI}/${OS_CMP1_HOSTNAME}/${PSEUDO_HOST_TYPE}
    ${keyValue}=    Get From Dictionary    ${json}    hostconfig
    ${passed}=    Run Keyword And Return Status    Evaluate    type(${keyValue}[0])
    ${type}=    Run Keyword If    ${passed}    Evaluate    type(${keyValue}[0])
    ${keyValue1}=    Get From Dictionary    ${keyValue[0]}    config
    Should Contain    ${keyValue1}    ${MATCH_OVS_ODL}
    Should Contain    ${keyValue1}    ${MATCH_VNIC_TYPE_ODL}
    OpenStackOperations.Create Vm Instance With Port On Compute Node    @{PSEUDO_NET_1_PORTS}[0]    @{PSEUDO_NET_1_VMS}[0]    ${OS_CMP1_HOSTNAME}    sg=${PSEUDO_SECURITY_GROUP}
    OpenStackOperations.Create Vm Instance With Port On Compute Node    @{PSEUDO_NET_1_PORTS}[1]    @{PSEUDO_NET_1_VMS}[1]    ${OS_CMP2_HOSTNAME}    sg=${PSEUDO_SECURITY_GROUP}
    @{pseudo_net_1_vm_ips}    ${pseudo_net_1_dhcp_ip} =    OpenStackOperations.Get VM IPs    @{PSEUDO_NET_1_VMS}
    BuiltIn.Should Not Contain    ${pseudo_net_1_vm_ips}    None
    BuiltIn.Should Not Contain    ${pseudo_net_1_dhcp_ip}    None
    ${output} =    OpenStackOperations.Execute Command on VM Instance    @{PSEUDO_NETWORKS}[0]    @{pseudo_net_1_vm_ips}[0]    ping -c 5 @{pseudo_net_1_vm_ips}[1]
    BuiltIn.Should Contain    ${output}    64 bytes
    Verify Port Binding Vif Type And Vnic Type    @{PSEUDO_NET_1_PORTS}[0]
    Verify Port Binding Vif Type And Vnic Type    @{PSEUDO_NET_1_PORTS}[1]    

*** Keywords ***
Verify Port Binding Vif Type And Vnic Type
    [Documentation]    Verifys port Vif and Vnic Type details for the booted VM is ovs and normal respectively.
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
    OpenStackOperations.Create Allow All SecurityGroup    ${PSEUDO_SECURITY_GROUP}
    OpenStackOperations.Create Network    @{PSEUDO_NETWORKS}[0]
    OpenStackOperations.Create SubNet    @{PSEUDO_NETWORKS}[0]    @{PSEUDO_SUBNETS}[0]    @{PSEUDO_SUBNET_CIDRS}[0]
    OpenStackOperations.Create Port    @{PSEUDO_NETWORKS}[0]    @{PSEUDO_NET_1_PORTS}[0]    sg=${PSEUDO_SECURITY_GROUP}
    OpenStackOperations.Create Port    @{PSEUDO_NETWORKS}[0]    @{PSEUDO_NET_1_PORTS}[1]    sg=${PSEUDO_SECURITY_GROUP}
    BuiltIn.Wait Until Keyword Succeeds    3s    1s    Utils.Check For Elements At URI    ${PORT_URL}    ${PSEUDO_NET_1_PORTS}