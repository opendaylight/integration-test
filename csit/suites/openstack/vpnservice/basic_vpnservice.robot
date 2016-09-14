*** Settings ***
Documentation     Test suite to validate vpnservice functionality in an openstack integrated environment.
...               The assumption of this suite is that the environment is already configured with the proper
...               integration bridges and vxlan tunnels.
Suite Setup       Basic Vpnservice Suite Setup
Suite Teardown    Basic Vpnservice Suite Teardown
Library           SSHLibrary
Library           OperatingSystem
Library           RequestsLibrary
Library           json
Resource          ../../../libraries/KarafKeywords.robot
Resource          ../../../libraries/Utils.robot
Resource          ../../../libraries/OpenStackOperations.robot
Resource          ../../../libraries/DevstackUtils.robot
Variables         ../../../variables/Variables.py
#Variables         ../../../variables/vpnservice/vpnservice_json.py
#Variables         ../../../variables/vpnservice/associate_nwstovpn.py

*** Variables ***
@{NETWORKS}    NET11    NET20
@{SUBNETS}    SUBNET1    SUBNET2
@{SUBNET_CIDR}    10.1.1.0/24    20.1.1.0/24
@{PORT_LIST}    PORT11    PORT21    PORT12    PORT22
@{VM_INSTANCES}    VM11a    VM21a    VM12    VM22
@{ROUTERS}    ROUTER_1    ROUTER_2
@{NET10_VM_IPS}    10.1.1.2    10.1.1.3
@{NET20_VM_IPS}    20.1.1.2    20.1.1.3
${bridge_ref_info_api}    /restconf/operational/odl-interface-meta:bridge-ref-info
${RESTCONF_OPERATIONS_URI}      /restconf/operations/
${VPN_CONFIG_DIR}    ${CURDIR}/../../../variables/vpnservice
#${associate_network}    associate_nwstovpn.py
${USER_HOME}    /home/mininet

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






#Create L3 VPN Instance
#    [Arguments]    ${vpn_instance}
#    [Documentation]    Creates L3 VPN Instance through restconf
#    [Tags]    Post
#    ${body}    OperatingSystem.Get File    ${VPN_CONFIG_DIR}/${vpn_instance}
#    ${resp}    RequestsLibrary.Post Request    session    ${REST_CON_OP}neutronvpn:createL3VPN
#    ...   data=${body}
#    Log    ${resp.content}
#    Should Be Equal As Strings    ${resp.status_code}    204

#Verify L3 vpn instance
#    [Arguments]    ${vpnid_instance}
#    [Documentation]    Verify L3 VPN Instance through restconf
#    [Tags]    Get
#    ${body}    OperatingSystem.Get File    ${VPN_CONFIG_DIR}/${vpnid_instance}
#    ${resp}    RequestsLibrary.Get Request    session    ${REST_CON_OP}neutronvpn:getL3VPN
#    ...  data=${body}       headers=  ${ACCEPT_XML}
#    Log    ${resp.content}
#    Should Be Equal As Strings    ${resp.status_code}    200

#Delete L3 VPNs instances
#    [Documentation]    Delete L3 VPN instance
#    ${resp}    RequestsLibrary.Delete Request    session    ${REST_CON}l3vpn:vpn-instances
#    Log    ${resp.content}
#    Should Be Equal As Strings    ${resp.status_code}    200

#Create L3 VM-VPN interface
#    [Arguments]  ${body}
#    [Documentation]    Creates vm-vpn interface for the corresponding ietf interface
#    [Tags]    Post
#    ${resp}    RequestsLibrary.Post Request    session    ${REST_CON}l3vpn:vpn-interfaces/
#    ...   data=${body}
#    Should Be Equal As Strings    ${resp.status_code}    204






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

Create L3VPN
    [Documentation]    Create L3VPN.
    [Tags]    exclude
    Log    This test will be added in the next patch

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
