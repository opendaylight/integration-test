*** Settings ***
Documentation     Test suite to validate vpnservice functionality in an openstack integrated environment.
...               The assumption of this suite is that the environment is already configured with the proper
...               integration bridges and vxlan tunnels.
Suite Setup       Basic Vpnservice Suite Setup
Suite Teardown    Basic Vpnservice Suite Teardown
Test Setup        Log Testcase Start To Controller Karaf
Library           SSHLibrary
Library           OperatingSystem
Library           RequestsLibrary
Resource          ../../../libraries/Utils.robot
Resource          ../../../libraries/OpenStackOperations.robot
Resource          ../../../libraries/DevstackUtils.robot

Variables         ../../../variables/Variables.py

*** Variables ***
@{NETWORKS}       NET10    NET20
@{SUBNETS}        SUBNET1    SUBNET2
@{SUBNET_CIDR}    10.1.1.0/24    20.1.1.0/24
@{PORT_LIST}      PORT11    PORT21    PORT12    PORT22
@{VM_INSTANCES}    VM11    VM21    VM12    VM22
@{ROUTERS}        ROUTER_1    ROUTER_2
@{NET10_VM_IPS}    10.1.1.2    10.1.1.3
@{NET20_VM_IPS}    20.1.1.2    20.1.1.3
@{VPN_INSTANCE}    vpn1_instance.json    vpn2_instance.json    vpn3_instance.json
@{VPN_INSTANCE_NAME}    4ae8cd92-48ca-49b5-94e1-b2921a2661c7    4ae8cd92-48ca-49b5-94e1-b2921a266112    4ae8cd92-48ca-49b5-94e1-b2921a2661c5
${VPN_CONFIG_DIR}    ${CURDIR}/../../../variables/vpnservice
${id1}    4ae8cd92-48ca-49b5-94e1-b2921a2661c7
${name1}    vpn1
${route-distinguisher1}    ["2200:1"]
${export-RT1}    ["3300:1","8800:1"]
${import-RT1}    ["3300:1","8800:1"]
${tenant-id1}    6c53df3a-3456-11e5-a151-feff819cdc9f
# Values passed by the calling method to API
${id}    4ae8cd92-48ca-49b5-94e1-b2921a261111
${name}    vpn2
${route-distinguisher}    ["2200:2"]
${export-RT}    ["3300:2","8800:2"]
${import-RT}    ["3300:2","8800:2"]
${tenant-id}    6c53df3a-3456-11e5-a151-feff819c1111
${GETL3VPN}       GETL3vpn.json
*** Test Cases ***
Verify Tunnel Creation
    [Documentation]    Checks that vxlan tunnels have been created properly.
    [Tags]    exclude
    Log    This test case is currently a noop, but work can be added here to validate if needed.    However, as the    suite Documentation notes, it's already assumed that the environment has been configured properly.    If    we do add work in this test case, we need to remove the "exclude" tag for it to run.    In fact, if this
    ...    test case is critical to run, and if it fails we would be dead in the water for the rest of the suite,    we should move it to Suite Setup so that nothing else will run and waste time in a broken environment.

Create Neutron Networks
    [Documentation]    Create two networks
    Create Network    ${NETWORKS[0]}    --provider:network_type local
    Create Network    ${NETWORKS[1]}    --provider:network_type local
    List Networks

Create Neutron Subnets
    [Documentation]    Create two subnets for previously created networks
    Create SubNet    ${NETWORKS[0]}    ${SUBNETS[0]}    ${SUBNET_CIDR[0]}
    Create SubNet    ${NETWORKS[1]}    ${SUBNETS[1]}    ${SUBNET_CIDR[1]}
    List Subnets

Create Neutron Ports
    [Documentation]    Create four ports under previously created subnets
    Create Port    ${NETWORKS[0]}    ${PORT_LIST[0]}
    Create Port    ${NETWORKS[0]}    ${PORT_LIST[1]}
    Create Port    ${NETWORKS[1]}    ${PORT_LIST[2]}
    Create Port    ${NETWORKS[1]}    ${PORT_LIST[3]}

Check OpenDaylight Neutron Ports
    [Documentation]    Checking OpenDaylight Neutron API for known ports
    ${resp}    RequestsLibrary.Get Request    session    ${NEUTRON_PORTS_API}
    Log    ${resp.content}
    Should be Equal As Strings    ${resp.status_code}    200

Create Nova VMs
    [Documentation]    Create two subnets for previously created networks
    Create Vm Instance With Port On Compute Node    ${PORT_LIST[0]}    ${VM_INSTANCES[0]}    ${OS_COMPUTE_1_IP}
    Create Vm Instance With Port On Compute Node    ${PORT_LIST[1]}    ${VM_INSTANCES[1]}    ${OS_COMPUTE_2_IP}
    Create Vm Instance With Port On Compute Node    ${PORT_LIST[2]}    ${VM_INSTANCES[2]}    ${OS_COMPUTE_1_IP}
    Create Vm Instance With Port On Compute Node    ${PORT_LIST[3]}    ${VM_INSTANCES[3]}    ${OS_COMPUTE_2_IP}

Check ELAN Datapath Traffic Within The Networks
    [Documentation]    Checks datapath within the same network with different vlans.
    [Tags]    exclude
    Log    This test will be added in the next patch

Create Routers
    [Documentation]    Create Router
    Create Router    ${ROUTERS[0]}

Add Interfaces To Router
    [Documentation]    Add Interfaces
    : FOR    ${INTERFACE}    IN    @{SUBNETS}
    \    Add Router Interface    ${ROUTERS[0]}    ${INTERFACE}

Check L3_Datapath Traffic Across Networks With Router
    [Documentation]    Datapath Test Across the networks using Router for L3.
    [Tags]    exclude
    Log    This test will be added in the next patch

Delete Router Interfaces
    [Documentation]    Remove Interface to the subnets.
    : FOR    ${INTERFACE}    IN    @{SUBNETS}
    \    Remove Interface    ${ROUTERS[0]}    ${INTERFACE}

Delete Routers
    [Documentation]    Delete Router and Interface to the subnets.
    Delete Router    ${ROUTERS[0]}

VPN L3VPN Creation
    [Documentation]    Create L3VPN.
    VPN Create L3VPN    ${VPN_INSTANCE[0]}    id=${id}      name=${name}     route-distinguisher=${route-distinguisher}
    ...    export-RT=${export-RT}    import-RT=${import-RT}   tenant-id=${tenant-id}

Associate Networks To L3VPN
    [Documentation]    Associate Networks To L3VPN.
    [Tags]    exclude
    Log    This test will be added in the next patch

Check Datapath Traffic Across Networks With L3VPN
    [Documentation]    Datapath Test Across the networks with VPN.
    [Tags]    exclude
    Log    This test will be added in the next patch

Delete Vm Instances
    [Documentation]    Delete Vm instances in the given Instance List
    : FOR    ${VmInstance}    IN    @{VM_INSTANCES}
    \    Delete Vm Instance    ${VmInstance}

Delete Neutron Ports
    [Documentation]    Delete Neutron Ports in the given Port List.
    : FOR    ${Port}    IN    @{PORT_LIST}
    \    Delete Port    ${Port}

Delete Sub Networks
    [Documentation]    Delete Sub Nets in the given Subnet List.
    : FOR    ${Subnet}    IN    @{SUBNETS}
    \    Delete SubNet    ${Subnet}

Delete Networks
    [Documentation]    Delete Networks in the given Net List
    : FOR    ${Network}    IN    @{NETWORKS}
    \    Delete Network    ${Network}

*** Keywords ***
Basic Vpnservice Suite Setup
    Create Session    session    http://${ODL_SYSTEM_IP}:${RESTCONFPORT}    auth=${AUTH}    headers=${HEADERS}

Basic Vpnservice Suite Teardown
    Delete All Sessions
