*** Settings ***
Documentation     Test suite to validate vpnservice functionality in an openstack integrated environment.
...               The assumption of this suite is that the environment is already configured with the proper
...               integration bridges and vxlan tunnels.
Suite Setup       Basic Vpnservice Suite Setup
Suite Teardown    Basic Vpnservice Suite Teardown
Test Setup        Log Testcase Start To Controller Karaf
Library           SSHLibrary
Library           OperatingSystem
Library           String
Library           RequestsLibrary
Resource          ../../../libraries/Utils.robot
Resource          ../../../libraries/OpenStackOperations.robot
Resource          ../../../libraries/OpenStackVPNservice.robot
Resource          ../../../libraries/DevstackUtils.robot
Variables         ../../../variables/Variables.py

*** Variables ***
${REST_CON}       /restconf/config/
${VPN_CONFIG_DIR}    ${CURDIR}/../../../variables/openstack/vpnservice
@{NETWORKS}       NETWORK10    NETWORK20
@{NETWORKS_VPN3}       NETWORK30    NETWORK40
@{SUBNETS}        SUBNET1    SUBNET2
@{SUBNETS_VPN3}    SUBNET3    SUBNET4
@{SUBNET_CIDR}    10.1.1.0/24    20.1.1.0/24
@{SUBNET_CIDR_VPN3}    20.1.1.0/24    40.1.1.0/24
@{PORT_LIST}      PORT11    PORT21    PORT12    PORT22
@{PORT_LIST_1}      PORT21    PORT12    PORT22
@{PORT_LIST_VPN3}    PORT13    PORT14
@{VM_INSTANCES}    VM11    VM21    VM12    VM22
@{VM_INSTANCES_VPN3}    VM13    VM14
@{ROUTERS}        ROUTER_1
@{NET_10_VM_IPS}    10.1.1.3    10.1.1.4
@{NET_20_VM_IPS}    20.1.1.3    20.1.1.4
@{NET_30_VM_IPS}    30.1.1.3
@{NET_40_VM_IPS}    40.1.1.3
${PING_PASS}    3 packets recieved
${PING_FAIL}    Network is unreachable
@{PRI_VPNIDS}    4ae8cd92-48ca-49b5-94e1-b2921a2661c5    4ae8cd92-48ca-49b5-94e1-b2921a2661d5
@{SEC_VPNIDS}    4ae8cd92-48ca-49b5-94e1-b2921a2661e5
${TENANTID}    44c8d816-22c4-4140-9c27-8bbc9df9c79c


*** Test Cases ***
Create Neutron Networks
    [Documentation]    SETUP-Create two networks
    Create Network    ${NETWORKS[0]}    --tenant-id ${TENANTID} --provider:network_type local
    Create Network    ${NETWORKS[1]}    --tenant-id ${TENANTID} --provider:network_type local
    List Networks

Create Neutron Subnets
    [Documentation]    SETUP-Create two subnets for previously created networks
    Create SubNet    ${NETWORKS[0]}    ${SUBNETS[0]}    ${SUBNET_CIDR[0]}
    Create SubNet    ${NETWORKS[1]}    ${SUBNETS[1]}    ${SUBNET_CIDR[1]}
    List Subnets

Create Neutron Ports
    [Documentation]    SETUP-Create four ports under previously created subnets
    Create Port    ${NETWORKS[0]}    ${PORT_LIST[0]}
    Create Port    ${NETWORKS[0]}    ${PORT_LIST[1]}
    Create Port    ${NETWORKS[1]}    ${PORT_LIST[2]}
    Create Port    ${NETWORKS[1]}    ${PORT_LIST[3]}

Check OpenDaylight Neutron Ports
    [Documentation]    SETUP-Checking OpenDaylight Neutron API for known ports
    ${resp}    RequestsLibrary.Get Request    session    ${NEUTRON_PORTS_API}
    Log    ${resp.content}
    Should be Equal As Strings    ${resp.status_code}    200

Create Nova VMs
    [Documentation]    SETUP-Boot VM instances on previously created network ports
    Create Vm Instance With Port On Compute Node    ${PORT_LIST[0]}    ${VM_INSTANCES[0]}    ${OS_COMPUTE_1_IP}
    Create Vm Instance With Port On Compute Node    ${PORT_LIST[1]}    ${VM_INSTANCES[1]}    ${OS_COMPUTE_2_IP}
    Create Vm Instance With Port On Compute Node    ${PORT_LIST[2]}    ${VM_INSTANCES[2]}    ${OS_COMPUTE_1_IP}
    Create Vm Instance With Port On Compute Node    ${PORT_LIST[3]}    ${VM_INSTANCES[3]}    ${OS_COMPUTE_2_IP}

Create VPN Instances
    [Documentation]    TC1-STEP1 Creates VPN1 and VPN2 Instance through restconf
    [Tags]    Post
    ${body}    OperatingSystem.Get File    ${VPN_CONFIG_DIR}/vpn_instance.json
    ${body}    Replace String    ${body}    {tntid}    ${TENANTID}
    ${resp}    RequestsLibrary.Post Request    session    ${REST_CON}neutronvpn:createL3VPN/    data=${body}
    Log    ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    204

Associate Networks To L3VPN
    [Documentation]    TC1-STEP2 Associate Networks To L3VPN
    [Tags]    Post
    Associate Network To VPNID    ${NETWORKS[0]}    ${VPN_CONFIG_DIR}    testVpn1-network.json    ${REST_CON}
    Associate Network To VPNID    ${NETWORKS[1]}    ${VPN_CONFIG_DIR}    testVpn2-network.json    ${REST_CON}

Check VM Accessibility Across VPNs Before Import_Export
    [Documentation]    TC1-STEP3 VM accessibility check Across the VPNs without import/export
    Check Ping From VM    ${NETWORKS[0]}    ${NET_10_VM_IPS[0]}    ${NET_20_VM_IPS[0]}    ${PING_FAIL}
    [Teardown]    Report_Failure_Due_To_Bug    6400

Exchange VPN Routes Through Import_Export
    [Documentation]    TC2-STEP1 Import/Export Routes between VPN1 and VPN2
    [Tags]    Post
    ${body}    OperatingSystem.Get File    ${VPN_CONFIG_DIR}/vpn_instance_impex.json
    ${body}    Replace String    ${body}    {tntid}    ${TENANTID}
    ${resp}    RequestsLibrary.Post Request    session    ${REST_CON}neutronvpn:createL3VPN/    data=${body}
    Log    ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    204

Check VM accessibility across VPNs within DPN1
    [Documentation]    TC2-STEP2 VM accessibility check Across the VPNs within DPN1
    Check Ping From VM    ${NETWORKS[0]}    ${NET_10_VM_IPS[0]}    ${NET_20_VM_IPS[0]}    ${PING_PASS}
    Check Ping From VM    ${NETWORKS[1]}    ${NET_20_VM_IPS[0]}    ${NET_10_VM_IPS[0]}    ${PING_PASS}
    [Teardown]    Report_Failure_Due_To_Bug    6400

Check VM accessibility across VPNs within DPN2
    [Documentation]    TC2-STEP3 VM accessibility check Across the VPNs within DPN2
    Check Ping From VM    ${NETWORKS[0]}    ${NET_10_VM_IPS[1]}    ${NET_20_VM_IPS[1]}    ${PING_PASS}
    Check Ping From VM    ${NETWORKS[1]}    ${NET_20_VM_IPS[1]}    ${NET_10_VM_IPS[1]}    ${PING_PASS}
    [Teardown]    Report_Failure_Due_To_Bug    6400


Check VM Accessibility Between VPN On Other DPN
    [Documentation]    TC3-STEP1 VM accessibility check VPN2 can access VPN1 on other DPN
    Check Ping From VM    ${NETWORKS[1]}    ${NET_20_VM_IPS[0]}    ${NET_10_VM_IPS[1]}    ${PING_PASS}
    Check Ping From VM    ${NETWORKS[1]}    ${NET_20_VM_IPS[1]}    ${NET_10_VM_IPS[0]}    ${PING_PASS}
    ${devstack_conn_id}=    Get ControlNode Connection
    Switch Connection    ${devstack_conn_id}
    ${output}=    Write Commands Until Prompt    nova list    30s
    Log    ${output}
    [Teardown]    Report_Failure_Due_To_Bug    6400

Check VPN Route Learning
    [Documentation]    TC4-STEP1 Verify the subnet route is learnt for VPN1 and is shared across the other VPNs
    [Tags]    exclude
    Log    This test will be added in the next patch

Delete Neutron Port from VPN
    [Documentation]    TC5-STEP1 Delete a Neutron port in VPN1
    Delete Port    ${PORT_LIST[0]}

Check VPN Route After Neutron Port Delete
    [Documentation]    TC5-STEP2 Validate that the route for deleted port is withdrawn from VPN1 and VPN2
    [Tags]    exclude
    Log    This test will be added in the next patch

Create Neutron Networks for VPN3
    [Documentation]    TC6-STEP1 Create two networks for VPN3
    Create Network    ${NETWORKS_VPN3[0]}    --provider:network_type local
    Create Network    ${NETWORKS_VPN3[1]}    --provider:network_type local
    List Networks

Create Neutron Subnets for VPN3
    [Documentation]    TC6-STEP2 Create two subnets for previously created networks for VPN3
    Create SubNet    ${NETWORKS_VPN3[0]}    ${SUBNETS_VPN3[0]}    ${SUBNET_CIDR_VPN3[0]}
    Create SubNet    ${NETWORKS_VPN3[1]}    ${SUBNETS_VPN3[1]}    ${SUBNET_CIDR_VPN3[1]}
    List Subnets

Create Neutron Ports for VPN3
    [Documentation]    TC6-STEP3 Create four ports under previously created subnets for VPN3
    Create Port    ${NETWORKS_VPN3[0]}    ${PORT_LIST_VPN3[0]}
    Create Port    ${NETWORKS_VPN3[1]}    ${PORT_LIST_VPN3[1]}
 
Check OpenDaylight Neutron Ports for VPN3
    [Documentation]    TC6-STEP4 Checking OpenDaylight Neutron API for known ports for VPN3
    ${resp}    RequestsLibrary.Get Request    session    ${NEUTRON_PORTS_API}
    Log    ${resp.content}
    Should be Equal As Strings    ${resp.status_code}    200

Create Nova VMs VPN3
    [Documentation]    TC6-STEP5 Boot VM instances on previously created network ports for VPN3
    Create Vm Instance With Port On Compute Node    ${PORT_LIST_VPN3[0]}    ${VM_INSTANCES_VPN3[0]}    ${OS_COMPUTE_1_IP}
    Create Vm Instance With Port On Compute Node    ${PORT_LIST_VPN3[1]}    ${VM_INSTANCES_VPN3[1]}    ${OS_COMPUTE_1_IP}

Create L3VPN for VPN3
    [Documentation]    TC6-STEP6 Creates VPN3 Instance through restconf
    [Tags]    Post
    ${body}    OperatingSystem.Get File    ${VPN_CONFIG_DIR}/vpn_instance_vpn3_impex.json
    ${body}    Replace String    ${body}    {tntid}    ${TENANTID}
    ${resp}    RequestsLibrary.Post Request    session    ${REST_CON}neutronvpn:createL3VPN/    data=${body}
    Log    ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    204

Associate Networks To L3VPN for VPN3
    [Documentation]    TC6-STEP7 Associate Networks To L3VPN for VPN3
    [Tags]    Post
    Associate Network To VPNID    ${NETWORKS_VPN3[0]}    ${VPN_CONFIG_DIR}    testVpn3-network.json    ${REST_CON}
    Associate Network To VPNID    ${NETWORKS_VPN3[1]}    ${VPN_CONFIG_DIR}    testVpn3-network.json    ${REST_CON}

Check Reachability Between Networks In VPN3
    [Documentation]    TC6-STEP8 Check reachability between networks in VPN3
    Check Ping From VM    ${NETWORKS_VPN3[1]}    ${NET_30_VM_IPS[0]}    ${NET_40_VM_IPS[0]}    ${PING_PASS}
    ${devstack_conn_id}=    Get ControlNode Connection
    Switch Connection    ${devstack_conn_id}
    ${output}=    Write Commands Until Prompt    nova list    30s
    Log    ${output}
    [Teardown]    Report_Failure_Due_To_Bug    6400

Dissociate Network From VPN3
    [Documentation]    TC7-STEP1 Dissociate VPN3 from network2
    [Tags]    exclude
    ${devstack_conn_id}=    Get ControlNode Connection
    ${networkid}=    Get Net Id    ${NETWORKS_VPN3[1]}    ${devstack_conn_id}
    ${body}    OperatingSystem.Get File    ${VPN_CONFIG_DIR}/testVpn3-network.json
    ${body}    Replace String    ${body}    {netid}    ${networkid}
    ${resp}    RequestsLibrary.Post Request    session    ${REST_CON}neutronvpn:dissociateNetworks/    data=${body}
    Log    ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    204

Check Reachability Between Networks In VPN3 After dissociating network2
    [Documentation]    TC7-STEP2 Check reachability between network1 and network2 in VPN3
    Check Ping From VM    ${NETWORKS_VPN3[1]}    ${NET_30_VM_IPS[0]}    ${NET_40_VM_IPS[0]}    ${PING_PASS}
    ${devstack_conn_id}=    Get ControlNode Connection
    Switch Connection    ${devstack_conn_id}
    ${output}=    Write Commands Until Prompt    nova list    30s
    Log    ${output}
    [Teardown]    Report_Failure_Due_To_Bug    6400

Create Router
    [Documentation]    TC8-STEP1 Create Router
    Create Router    ${ROUTERS[0]}

Add Interfaces To Router
    [Documentation]    TC8-STEP2 assocaitte 2 interfaces to router
    : FOR    ${INTERFACE}    IN    @{SUBNETS}
    \    Add Router Interface    ${ROUTERS[0]}    ${INTERFACE}

Associtate VPN To Router
    [Documentation]    TC9-STEP1 Associate VPN1 and VPN2 to Router1
    [Tags]    exclude
    : FOR    ${vpnid}    IN    @{PRI_VPNIDS}
    \    Associate VPNID to Router    ${vpnid}   ${ROUTERS[0]}    ${VPN_CONFIG_DIR}    ${REST_CON}

Check VM accessibility across VPNs
    [Documentation]    TC9-STEP2 VM accessibility check Across the VPNs
    Check Ping From VM    ${NETWORKS[0]}    ${NET_10_VM_IPS[1]}    ${NET_20_VM_IPS[0]}    ${PING_PASS}
    Check Ping From VM    ${NETWORKS[1]}    ${NET_20_VM_IPS[0]}    ${NET_20_VM_IPS[1]}    ${PING_PASS}
    [Teardown]    Report_Failure_Due_To_Bug    6400

Restart VM and verify flow reprogramming
    [Documentation]    TC10-STEP1 Restart one VM from VPN1 and VPN2
    Restart VM    ${VM_INSTANCES[1]}
    Restart VM    ${VM_INSTANCES[2]}

Verify Dumpflow
    [Documentation]    TC10-STEP2 verify that the flows are reprogrammed on restarting one VM from VPN1 and VPN2
    [Tags]    exclude
    Log    This test will be added in the next patch

Verify VM rechability after restart
    [Documentation]    TC10-STEP3 Check VMs are reachable once after they are up
    Check Ping From VM    ${NETWORKS[0]}    ${NET_10_VM_IPS[1]}    ${NET_20_VM_IPS[0]}    ${PING_PASS}
    Check Ping From VM    ${NETWORKS[1]}    ${NET_20_VM_IPS[0]}    ${NET_20_VM_IPS[1]}    ${PING_PASS}
    ${devstack_conn_id}=    Get ControlNode Connection
    Switch Connection    ${devstack_conn_id}
    ${output}=    Write Commands Until Prompt    nova list    30s
    Log    ${output}
    [Teardown]    Report_Failure_Due_To_Bug    6400

Delete Router Interfaces
    [Documentation]    CLEANUP-Remove Interface to the subnets
    : FOR    ${INTERFACE}    IN    @{SUBNETS}
    \    Remove Interface    ${ROUTERS[0]}    ${INTERFACE}

Delete Routers
    [Documentation]    CLEANUP-Delete Router and Interface to the subnets
    Delete Router    ${ROUTERS[0]}

Delete Vm Instances
    [Documentation]    CLEANUP-Delete Vm instances in the given Instance List
    : FOR    ${VmInstance}    IN    @{VM_INSTANCES}
    \    Delete Vm Instance    ${VmInstance}
    : FOR    ${VmInstance}    IN    @{VM_INSTANCES_VPN3}
    \    Delete Vm Instance    ${VmInstance}

Delete Neutron Ports
    [Documentation]    CLEANUP-Delete Neutron Ports in the given Port List.
    : FOR    ${Port}    IN    @{PORT_LIST1}
    \    Delete SubNet    ${Port}
    : FOR    ${Port}    IN    @{PORT_LIST_VPN3}
    \    Delete SubNet    ${Port}

Delete Sub Networks
    [Documentation]    CLEANUP-Delete Sub Nets in the given Subnet List.
    : FOR    ${Subnet}    IN    @{SUBNETS}
    \    Delete SubNet    ${Subnet}
    : FOR    ${Subnet}    IN    @{SUBNETS_VPN3}
    \    Delete SubNet    ${Subnet}

Delete Networks
    [Documentation]    CLEANUP-Delete Networks in the given Net List
    : FOR    ${Network}    IN    @{NETWORKS}
    \    Delete Network    ${Network}
    : FOR    ${Network}    IN    @{NETWORKS_VPN3}
    \    Delete Network    ${Network}

*** Keywords ***
Basic Vpnservice Suite Setup
    Create Session    session    http://${ODL_SYSTEM_IP}:${RESTCONFPORT}    auth=${AUTH}    headers=${HEADERS}

Basic Vpnservice Suite Teardown
    Delete All Sessions
