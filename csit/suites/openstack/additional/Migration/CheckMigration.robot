*** Settings ***
Documentation     Test suite to verify instance Migration and check communication before and after
...               Migration
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
${net1}           l2_network_1
@{NET_1_VM_INSTANCES}    MyFirstInstance_1    MySecondInstance_1
${SECURITY_GROUP}    sg-connectivity
${SECURITY_GROUP2}    sg-connectivity2
${SECURITY_GROUP3}    default-sg
${NETWORKS_NAME}    l2_network_1
${SUBNETS_NAME}    l2_subnet_1
${ROUTER}         router_1
${SUBNETS_RANGE}    30.0.0.0/24

*** Test Cases ***
Create Zone
    [Documentation]    Create Availabilityzone create for test suite
    ${zone1}=    Create Availabilityzone    hypervisor_ip=${OS_COMPUTE_1_IP}    zone_name=compute1    aggregate_name=Host1
    ${zone2}=    Create Availabilityzone    hypervisor_ip=${OS_COMPUTE_2_IP}    zone_name=compute2    aggregate_name=Host2
    Set Suite Variable    ${zone1}
    Set Suite Variable    ${zone2}
    Should Not Contain    ${zone1}    None
    Should Not Contain    ${zone2}    None

Server Migrate
    [Documentation]    Create server and migrate it to different host.
    Enable Live Migration In All Compute Nodes
    Create Network    ${NETWORKS_NAME}    additional_args=--provider-network-type vxlan
    Create SubNet    ${NETWORKS_NAME}    ${SUBNETS_NAME}    ${SUBNETS_RANGE}
    ${rc}    ${default_sgs}    Run And Return Rc And Output    openstack security group list --project admin | grep "default" | awk '{print $2}'
    ${sg_list}=    Split String    ${default_sgs}    \n
    ${length}=    Get Length    ${sg_list}
    Set Suite Variable    ${sg_list}
    Set Suite Variable    ${length}
    Create Vm Instances    ${NETWORKS_NAME}    ${NET_1_VM_INSTANCES}    image=cirros    flavor=cirros    sg=@{sg_list}[0]    additional_args=--availability-zone ${zone1}
    : FOR    ${vm}    IN    @{NET_1_VM_INSTANCES}
    \    Poll VM Is ACTIVE    ${vm}
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
    ${LOOP_COUNT}    Get Length    ${NET1_DHCP_IP}
    : FOR    ${index}    IN RANGE    0    ${LOOP_COUNT}
    \    Neutron Security Group Rule Create    @{sg_list}[0]    direction=ingress    port_range_max=65535    port_range_min=1    protocol=tcp
    \    ...    remote_ip_prefix=@{NET1_DHCP_IP}[${index}]/32
    ${des_ip_1}=    Create List    @{NET1_VM_IPS}[0]
    : FOR    ${vm}    IN    @{NET_1_VM_INSTANCES}
    \    Poll VM Boot Status    ${vm}
    Test Operations From Vm Instance    ${NETWORKS_NAME}    @{NET1_VM_IPS}[1]    ${des_ip_1}
    Server Migrate    @{NET_1_VM_INSTANCES}[0]    additional_args=--live ${Host2}
    Poll VM Is ACTIVE    @{NET_1_VM_INSTANCES}[0]
    ${output}=    Server Show    @{NET_1_VM_INSTANCES}[0]
    Should Contain    ${output}    ${Host2}
    Test Operations From Vm Instance    ${NETWORKS_NAME}    @{NET1_VM_IPS}[1]    ${des_ip_1}
    Delete Vm Instance    @{NET_1_VM_INSTANCES}[0]
    Delete Vm Instance    @{NET_1_VM_INSTANCES}[1]
    Delete SubNet    ${SUBNETS_NAME}
    Delete Network    ${NETWORKS_NAME}
    Disable Live Migration In All Compute Nodes
    [Teardown]    Run Keywords    Clear L2_Network

Destroy Zone
    [Documentation]    Delete the Availabilityzone create for test suite
    Delete Availabilityzone    hypervisor_ip=${OS_COMPUTE_1_IP}    aggregate_name=Host1
    Delete Availabilityzone    hypervisor_ip=${OS_COMPUTE_2_IP}    aggregate_name=Host2
