*** Settings ***
Documentation     Test suite to verify backup and restore, to check before and after restoring
...               the odl's
Suite Setup       BuiltIn.Run Keywords    SetupUtils.Setup_Utils_For_Setup_And_Teardown
...               AND    DevstackUtils.Devstack Suite Setup
Suite Teardown    Close All Connections
Test Setup        SetupUtils.Setup_Test_With_Logging_And_Without_Fast_Failing
Library           SSHLibrary    #Test Teardown    Get Test Teardown Debugs
Library           OperatingSystem
Library           RequestsLibrary
Resource          ../../../../libraries/DevstackUtils.robot
Resource          ../../../../libraries/DataModels.robot
Resource          ../../../../libraries/OpenStackOperations.robot
Resource          ../../../../libraries/OpenStackOperations_legacy.robot
Resource          ../../../../libraries/SetupUtils.robot
Resource          ../../../../libraries/Utils.robot
Resource          ../../../../libraries/KarafKeywords.robot
Resource          ../../../../variables/netvirt/Variables.robot
Resource          ../../../../../tools/deployment/openstack_ha/libraries/OpenStackInstallUtils.robot

*** Variables ***
${NETWORKS_NAME}    l2_network_1
${SUBNETS_NAME}    l2_subnet_1
@{NET_1_VM_INSTANCES}    NET1-VM1    NET1-VM2
${SUBNETS_RANGE}    30.0.0.0/24
${SECURITY_GROUP}    sg-connectivity

*** Test Cases ***
Create Vitual LAN Networks
    [Documentation]    Create two virtual LAN Networks.
    Create Network    ${NETWORKS_NAME}
    Create SubNet    ${NETWORKS_NAME}    ${SUBNETS_NAME}    ${SUBNETS_RANGE}
    ${VM1}=    Create List    @{NET_1_VM_INSTANCES}[0]
    Neutron Security Group Create    ${SECURITY_GROUP}
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=ingress    port_range_max=65535    port_range_min=1    protocol=tcp
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=egress    port_range_max=65535    port_range_min=1    protocol=icmp
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=ingress    port_range_max=65535    port_range_min=1    protocol=icmp
    Create Vm Instances    ${NETWORKS_NAME}    ${VM1}    image=cirros    flavor=cirros    sg=${SECURITY_GROUP}
    Poll VM Is ACTIVE    @{NET_1_VM_INSTANCES}[0]
    ${status}    ${message}    Run Keyword And Ignore Error    Wait Until Keyword Succeeds    300s    5s    Collect VM IP Addresses
    ...    true    @{VM1}
    ${NET1_VM_IPS}    ${NET1_DHCP_IP}    Collect VM IP Addresses    false    @{VM1}
    Set Suite Variable    ${NET1_VM_IPS}
    Set Suite Variable    ${NET1_DHCP_IP}
    Should Not Contain    ${NET1_VM_IPS}    None
    Should Not Contain    ${NET1_DHCP_IP}    None
    BackUp and Restore ODL In All Control Nodes
    ${VM2}=    Create List    @{NET_1_VM_INSTANCES}[1]
    Create Vm Instances    ${NETWORKS_NAME}    ${VM2}    image=cirros    flavor=cirros    sg=${SECURITY_GROUP}
    Poll VM Is ACTIVE    @{NET_1_VM_INSTANCES}[1]
    ${status}    ${message}    Run Keyword And Ignore Error    Wait Until Keyword Succeeds    300s    5s    Collect VM IP Addresses
    ...    true    @{NET_1_VM_INSTANCES}
    ${NET1_VM_IPS}    ${NET1_DHCP_IP}    Collect VM IP Addresses    false    @{NET_1_VM_INSTANCES}
    ${VM_INSTANCES}=    Collections.Combine Lists    ${NET_1_VM_INSTANCES}
    ${VM_IPS}=    Collections.Combine Lists    ${NET1_VM_IPS}
    ${LOOP_COUNT}    Get Length    ${VM_INSTANCES}
    : FOR    ${index}    IN RANGE    0    ${LOOP_COUNT}
    \    ${status}    ${message}    Run Keyword And Ignore Error    Should Not Contain    @{VM_IPS}[${index}]    None
    \    Run Keyword If    '${status}' == 'FAIL'    Write Commands Until Prompt    openstack console log show @{VM_INSTANCES}[${index}]    30s
    Set Suite Variable    ${NET1_VM_IPS}
    Set Suite Variable    ${NET1_DHCP_IP}
    Should Not Contain    ${NET1_VM_IPS}    None
    Should Not Contain    ${NET1_DHCP_IP}    None
    : FOR    ${vm}    IN    @{NET_1_VM_INSTANCES}
    \    Poll VM Boot Status    ${vm}
    ${des_ip_1}=    Create List    @{NET1_VM_IPS}[1]
    Test Operations From Vm Instance    ${NETWORKS_NAME}    @{NET1_VM_IPS}[0]    ${des_ip_1}
    : FOR    ${VmElement}    IN    @{NET_1_VM_INSTANCES}
    \    Delete Vm Instance    ${VmElement}
    Delete SecurityGroup    ${SECURITY_GROUP}
    Delete Network    ${NETWORKS_NAME}
    [Teardown]    Run Keywords    Clear L2_Network
