*** Settings ***
Documentation     Test suite to check North-South connectivity in L3 using a router and an external network
Suite Setup       Suite Setup
Suite Teardown    OpenStackOperations.OpenStack Suite Teardown
Test Setup        SetupUtils.Setup_Test_With_Logging_And_Without_Fast_Failing
Test Teardown     OpenStackOperations.Get Test Teardown Debugs
Force Tags        skip_if_${ODL_SNAT_MODE}
Library           Collections
Library           SSHLibrary
Library           OperatingSystem
Library           RequestsLibrary
Resource          ../../../libraries/DevstackUtils.robot
Resource          ../../../libraries/DataModels.robot
Resource          ../../../libraries/OpenStackOperations.robot
Resource          ../../../libraries/SetupUtils.robot
Resource          ../../../libraries/Utils.robot
Resource          ../../../variables/netvirt/Variables.robot

*** Variables ***
${SECURITY_GROUP}    l3_ext_sg
@{NETWORKS}       l3_ext_net_1    l3_ext_net_2
@{SUBNETS}        l3_ext_sub_1    l3_ext_sub_2
@{ROUTERS}        l3_ext_router_1    l3_ext_router_2
@{NET1_FIP_VMS}    l3_ext_net_1_fip_vm_1    l3_ext_net_1_fip_vm_2    l3_ext_net_1_fip_vm_3
@{NET1_SNAT_VMS}    l3_ext_net_1_snat_vm_1    l3_ext_net_1_snat_vm_2
@{NET2_SNAT_VMS}    l3_ext_net_2_snat_vm_3
@{SNAT_VMS}       @{NET1_SNAT_VMS}    @{NET2_SNAT_VMS}
@{SUBNET_CIDRS}    41.0.0.0/24    42.0.0.0/24
# Parameter values below are based on releng/builder - changing them requires updates in releng/builder as well
${EXTERNAL_GATEWAY}    10.10.10.250
${EXTERNAL_PNF}    10.10.10.253
${EXTERNAL_SUBNET}    10.10.10.0/24
${EXTERNAL_SUBNET_ALLOCATION_POOL}    start=10.10.10.2,end=10.10.10.249
${EXTERNAL_INTERNET_ADDR}    10.9.9.9

*** Test Cases ***
Initial Ping To External Network PNF from Vm Instance 1
    [Documentation]    Check reachability of External Network PNF from VM instance (with ttl=1 to make sure no router hops)
    ${expect_ping_to_work} =    Set Variable If    "skip_if_controller" in @{TEST_TAGS}    False    True
    ${dst_ip}=    BuiltIn.Create List    ${EXTERNAL_PNF}
    OpenStackOperations.Test Operations From Vm Instance    @{NETWORKS}[0]    @{NET1_FIP_VM_IPS}[0]    ${dst_ip}    ttl=1    ping_should_succeed=${expect_ping_to_work}    ping_tries=8

Initial Ping To External Network PNF from Vm Instance 2
    [Documentation]    Check reachability of External Network PNF from VM instance (with ttl=1 to make sure no router hops)
    ${expect_ping_to_work} =    Set Variable If    "skip_if_controller" in @{TEST_TAGS}    False    True
    ${dst_ip}=    BuiltIn.Create List    ${EXTERNAL_PNF}
    OpenStackOperations.Test Operations From Vm Instance    @{NETWORKS}[0]    @{NET1_FIP_VM_IPS}[1]    ${dst_ip}    ttl=1    ping_should_succeed=${expect_ping_to_work}    ping_tries=8

Create And Associate Floating IPs for VMs
    [Documentation]    Create and associate a floating IP for the VM
    ${VM_FLOATING_IPS} =    OpenStackOperations.Create And Associate Floating IPs    ${EXTERNAL_NET_NAME}    @{NET1_FIP_VMS}
    BuiltIn.Set Suite Variable    ${VM_FLOATING_IPS}
    [Teardown]    BuiltIn.Run Keywords    OpenStackOperations.Show Debugs    @{NET1_FIP_VMS}
    ...    AND    OpenStackOperations.Get Test Teardown Debugs

Ping External Gateway From Control Node
    [Documentation]    Check reachability of external gateway by pinging it from the control node.
    OpenStackOperations.Ping Vm From Control Node    ${EXTERNAL_GATEWAY}    additional_args=-I ${EXTERNAL_INTERNET_ADDR}

Ping Vm Instance1 Floating IP From Control Node
    [Documentation]    Check reachability of VM instance through floating IP by pinging them.
    OpenStackOperations.Ping Vm From Control Node    @{VM_FLOATING_IPS}[0]    additional_args=-I ${EXTERNAL_INTERNET_ADDR}

Ping Vm Instance2 Floating IP From Control Node
    [Documentation]    Check reachability of VM instance through floating IP by pinging them.
    OpenStackOperations.Ping Vm From Control Node    @{VM_FLOATING_IPS}[1]    additional_args=-I ${EXTERNAL_INTERNET_ADDR}

Ping Vm Instance2 Floating IP From Vm Instance1 With Floating IP (Hairpinning)
    [Documentation]    Check reachability of VM instance floating IP from another VM instance with FIP (with ttl=1 to make sure no router hops)
    ${dst_ip} =    BuiltIn.Create List    @{VM_FLOATING_IPS}[1]
    OpenStackOperations.Test Operations From Vm Instance    @{NETWORKS}[0]    @{NET1_FIP_VM_IPS}[0]    ${dst_ip}    ttl=1

Connectivity Tests To Vm Instance2 Floating IP From Vm Instance3 With Floating IP (FIP-FIP in the same compute node)
    [Documentation]    Check reachability of VM instance floating IP from another VM instance with FIP (FIP-FIP in the same compute node)
    BuiltIn.Pass Execution    pass this test until ovs 2.9 is ready
    ${dst_ip} =    BuiltIn.Create List    @{VM_FLOATING_IPS}[1]
    OpenStackOperations.Test Netcat Operations From Vm Instance    @{NETWORKS}[0]    @{NET1_FIP_VM_IPS}[2]    ${dst_ip}

Ping Vm Instance1 Floating IP From SNAT VM Instance1
    [Documentation]    Check reachability of VM instance floating IP from another VM without Floating IP
    ${expect_ping_to_work} =    Set Variable If    "skip_if_controller" in @{TEST_TAGS}    False    True
    ${dst_ip} =    BuiltIn.Create List    @{VM_FLOATING_IPS}[0]
    OpenStackOperations.Test Operations From Vm Instance    @{NETWORKS}[0]    @{NET1_SNAT_VM_IPS}[0]    ${dst_ip}    ttl=1    ping_should_succeed=${expect_ping_to_work}
    OpenStackOperations.Test Operations From Vm Instance    @{NETWORKS}[1]    @{NET2_SNAT_VM_IPS}[0]    ${dst_ip}    ttl=1    ping_should_succeed=${expect_ping_to_work}

Ping Vm Instance1 Floating IP From SNAT VM Instance2
    [Documentation]    Check reachability of VM instance floating IP from another VM without Floating IP
    ${expect_ping_to_work} =    Set Variable If    "skip_if_controller" in @{TEST_TAGS}    False    True
    ${dst_ip} =    BuiltIn.Create List    @{VM_FLOATING_IPS}[0]
    OpenStackOperations.Test Operations From Vm Instance    @{NETWORKS}[0]    @{NET1_SNAT_VM_IPS}[1]    ${dst_ip}    ttl=1    ping_should_succeed=${expect_ping_to_work}

Ping Vm Instance2 Floating IP From SNAT VM Instance1
    [Documentation]    Check reachability of VM instance floating IP from another VM without Floating IP
    ${expect_ping_to_work} =    Set Variable If    "skip_if_controller" in @{TEST_TAGS}    False    True
    ${dst_ip} =    BuiltIn.Create List    @{VM_FLOATING_IPS}[1]
    OpenStackOperations.Test Operations From Vm Instance    @{NETWORKS}[0]    @{NET1_SNAT_VM_IPS}[0]    ${dst_ip}    ttl=1    ping_should_succeed=${expect_ping_to_work}
    OpenStackOperations.Test Operations From Vm Instance    @{NETWORKS}[1]    @{NET2_SNAT_VM_IPS}[0]    ${dst_ip}    ttl=1    ping_should_succeed=${expect_ping_to_work}

Ping Vm Instance2 Floating IP From SNAT VM Instance2
    [Documentation]    Check reachability of VM instance floating IP from another VM without Floating IP
    ${expect_ping_to_work} =    Set Variable If    "skip_if_controller" in @{TEST_TAGS}    False    True
    ${dst_ip} =    BuiltIn.Create List    @{VM_FLOATING_IPS}[1]
    OpenStackOperations.Test Operations From Vm Instance    @{NETWORKS}[0]    @{NET1_SNAT_VM_IPS}[1]    ${dst_ip}    ttl=1    ping_should_succeed=${expect_ping_to_work}

Ping External Network PNF from Vm Instance 1 After Floating IP Assignment
    [Documentation]    Check reachability of External Network PNF from VM instance (with ttl=1 to make sure no router hops)
    ${dst_ip} =    BuiltIn.Create List    ${EXTERNAL_PNF}
    OpenStackOperations.Test Operations From Vm Instance    @{NETWORKS}[0]    @{NET1_FIP_VM_IPS}[0]    ${dst_ip}    ttl=1    ping_tries=8

SNAT - TCP connection to External Gateway From SNAT VM Instance1
    [Documentation]    Login to the VM instance and test TCP connection to the controller via SNAT
    [Tags]    NON_GATE
    OpenStackOperations.Test Netcat Operations From Vm Instance    @{NETWORKS}[0]    @{NET1_SNAT_VM_IPS}[0]    ${EXTERNAL_GATEWAY}

SNAT - UDP connection to External Gateway From SNAT VM Instance1
    [Documentation]    Login to the VM instance and test UDP connection to the controller via SNAT
    [Tags]    NON_GATE
    OpenStackOperations.Test Netcat Operations From Vm Instance    @{NETWORKS}[0]    @{NET1_SNAT_VM_IPS}[0]    ${EXTERNAL_GATEWAY}    -u

SNAT - TCP connection to External Gateway From SNAT VM Instance2
    [Documentation]    Login to the VM instance and test TCP connection to the controller via SNAT
    [Tags]    NON_GATE
    OpenStackOperations.Test Netcat Operations From Vm Instance    @{NETWORKS}[0]    @{NET1_SNAT_VM_IPS}[1]    ${EXTERNAL_GATEWAY}

SNAT - UDP connection to External Gateway From SNAT VM Instance2
    [Documentation]    Login to the VM instance and test UDP connection to the controller via SNAT
    [Tags]    NON_GATE
    OpenStackOperations.Test Netcat Operations From Vm Instance    @{NETWORKS}[0]    @{NET1_SNAT_VM_IPS}[1]    ${EXTERNAL_GATEWAY}    -u

SNAT - TCP connection to External Gateway From SNAT VM Instance3
    [Documentation]    Login to the VM instance and test TCP connection to the controller via SNAT
    [Tags]    NON_GATE
    OpenStackOperations.Test Netcat Operations From Vm Instance    @{NETWORKS}[1]    @{NET2_SNAT_VM_IPS}[0]    ${EXTERNAL_GATEWAY}

SNAT - UDP connection to External Gateway From SNAT VM Instance3
    [Documentation]    Login to the VM instance and test UDP connection to the controller via SNAT
    [Tags]    NON_GATE
    OpenStackOperations.Test Netcat Operations From Vm Instance    @{NETWORKS}[1]    @{NET2_SNAT_VM_IPS}[0]    ${EXTERNAL_GATEWAY}    -u

Ping External Network PNF from SNAT VM Instance1
    [Documentation]    Check reachability of External Network PNF from SNAT VM Instance1
    [Tags]    NON_GATE
    ${expect_ping_to_work} =    Set Variable If    "skip_if_controller" in @{TEST_TAGS}    False    True
    ${dst_ip} =    BuiltIn.Create List    ${EXTERNAL_PNF}
    OpenStackOperations.Test Operations From Vm Instance    @{NETWORKS}[0]    @{NET1_SNAT_VM_IPS}[0]    ${dst_ip}    ping_should_succeed=${expect_ping_to_work}

Ping External Network PNF from SNAT VM Instance2
    [Documentation]    Check reachability of External Network PNF from SNAT VM Instance2
    [Tags]    NON_GATE
    ${expect_ping_to_work} =    Set Variable If    "skip_if_controller" in @{TEST_TAGS}    False    True
    ${dst_ip} =    BuiltIn.Create List    ${EXTERNAL_PNF}
    OpenStackOperations.Test Operations From Vm Instance    @{NETWORKS}[0]    @{NET1_SNAT_VM_IPS}[1]    ${dst_ip}    ping_should_succeed=${expect_ping_to_work}

Remove Floating Ip from VM Instance 1
    [Documentation]    Delete FIP from VM Instance 1
    [Tags]    NON_GATE
    OpenStackOperations.Remove Floating Ip From Vm    @{NET1_FIP_VMS}[0]    @{VM_FLOATING_IPS}[0]

Remove Floating Ip from VM Instance 2
    [Documentation]    Delete FIP from VM Instance 2
    [Tags]    NON_GATE
    OpenStackOperations.Remove Floating Ip From Vm    @{NET1_FIP_VMS}[1]    @{VM_FLOATING_IPS}[1]

Ping External Network PNF from Vm Instance 1 After Floating IP Removal
    [Documentation]    Check reachability of External Network PNF from VM instance (with ttl=1 to make sure no router hops)
    [Tags]    NON_GATE
    ${expect_ping_to_work} =    Set Variable If    "skip_if_controller" in @{TEST_TAGS}    False    True
    ${dst_ip} =    BuiltIn.Create List    ${EXTERNAL_PNF}
    OpenStackOperations.Test Operations From Vm Instance    @{NETWORKS}[0]    @{NET1_FIP_VM_IPS}[0]    ${dst_ip}    ttl=1    ping_should_succeed=${expect_ping_to_work}

Ping External Network PNF from Vm Instance 2 After Floating IP Removal
    [Documentation]    Check reachability of External Network PNF from VM instance (with ttl=1 to make sure no router hops)
    [Tags]    NON_GATE
    ${expect_ping_to_work} =    Set Variable If    "skip_if_controller" in @{TEST_TAGS}    False    True
    ${dst_ip} =    BuiltIn.Create List    ${EXTERNAL_PNF}
    OpenStackOperations.Test Operations From Vm Instance    @{NETWORKS}[0]    @{NET1_FIP_VM_IPS}[1]    ${dst_ip}    ttl=1    ping_should_succeed=${expect_ping_to_work}

*** Keywords ***
Suite Setup
    OpenStackOperations.OpenStack Suite Setup
    : FOR    ${network}    IN    @{NETWORKS}
    \    OpenStackOperations.Create Network    ${network}
    : FOR    ${network}    ${subnet}    ${cidr}    IN ZIP    ${NETWORKS}    ${SUBNETS}
    ...    ${SUBNET_CIDRS}
    \    OpenStackOperations.Create SubNet    ${network}    ${subnet}    ${cidr}
    OpenStackOperations.Create Allow All SecurityGroup    ${SECURITY_GROUP}
    OpenStackOperations.Create Vm Instance On Compute Node    @{NETWORKS}[0]    @{NET1_FIP_VMS}[0]    ${OS_CMP1_HOSTNAME}    sg=${SECURITY_GROUP}
    OpenStackOperations.Create Vm Instance On Compute Node    @{NETWORKS}[0]    @{NET1_FIP_VMS}[1]    ${OS_CMP2_HOSTNAME}    sg=${SECURITY_GROUP}
    OpenStackOperations.Create Vm Instance On Compute Node    @{NETWORKS}[0]    @{NET1_FIP_VMS}[2]    ${OS_CMP2_HOSTNAME}    sg=${SECURITY_GROUP}
    OpenStackOperations.Create Vm Instance On Compute Node    @{NETWORKS}[0]    @{NET_1_SNAT_VMS}[0]    ${OS_CMP1_HOSTNAME}    sg=${SECURITY_GROUP}
    OpenStackOperations.Create Vm Instance On Compute Node    @{NETWORKS}[0]    @{NET_1_SNAT_VMS}[1]    ${OS_CMP1_HOSTNAME}    sg=${SECURITY_GROUP}
    OpenStackOperations.Create Vm Instance On Compute Node    @{NETWORKS}[1]    @{NET_2_SNAT_VMS}[0]    ${OS_CMP2_HOSTNAME}    sg=${SECURITY_GROUP}
    @{NET1_FIP_VM_IPS}    ${NET1_FIP_DHCP_IP} =    OpenStackOperations.Get VM IPs    @{NET1_FIP_VMS}
    @{NET1_SNAT_VM_IPS}    ${NET1_SNAT_DHCP_IP} =    OpenStackOperations.Get VM IPs    @{NET1_SNAT_VMS}
    @{NET2_SNAT_VM_IPS}    ${NET2_SNAT_DHCP_IP} =    OpenStackOperations.Get VM IPs    @{NET2_SNAT_VMS}
    BuiltIn.Set Suite Variable    @{NET1_FIP_VM_IPS}
    BuiltIn.Set Suite Variable    @{NET1_SNAT_VM_IPS}
    BuiltIn.Set Suite Variable    @{NET2_SNAT_VM_IPS}
    BuiltIn.Should Not Contain    ${NET1_FIP_VM_IPS}    None
    BuiltIn.Should Not Contain    ${NET1_SNAT_VM_IPS}    None
    BuiltIn.Should Not Contain    ${NET2_SNAT_VM_IPS}    None
    BuiltIn.Should Not Contain    ${NET1_FIP_DHCP_IP}    None
    BuiltIn.Should Not Contain    ${NET1_SNAT_DHCP_IP}    None
    BuiltIn.Should Not Contain    ${NET2_SNAT_DHCP_IP}    None
    OpenStackOperations.Create Network    ${EXTERNAL_NET_NAME}    --provider-network-type flat --provider-physical-network ${PUBLIC_PHYSICAL_NETWORK}
    OpenStackOperations.Update Network    ${EXTERNAL_NET_NAME}    --external
    OpenStackOperations.Create Subnet    ${EXTERNAL_NET_NAME}    ${EXTERNAL_SUBNET_NAME}    ${EXTERNAL_SUBNET}    --gateway ${EXTERNAL_GATEWAY} --allocation-pool ${EXTERNAL_SUBNET_ALLOCATION_POOL}
    : FOR    ${router}    IN    @{ROUTERS}
    \    OpenStackOperations.Create Router    ${router}
    : FOR    ${router}    ${interface}    IN ZIP    ${ROUTERS}    ${SUBNETS}
    \    OpenStackOperations.Add Router Interface    ${router}    ${interface}
    : FOR    ${router}    IN    @{ROUTERS}
    \    OpenStackOperations.Add Router Gateway    ${router}    ${EXTERNAL_NET_NAME}
    ${data}    Utils.Get Data From URI    1    ${NEUTRON_ROUTERS_API}
    BuiltIn.Log    ${data}
    : FOR    ${router}    IN    @{ROUTERS}
    \    Should Contain    ${data}    ${router}
    OpenStackOperations.Show Debugs    @{NET1_FIP_VMS}    @{NET1_SNAT_VMS}    @{NET2_SNAT_VMS}
