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
@{NET10_VM_IPS}    10.1.1.3    10.1.1.4
@{NET20_VM_IPS}    20.1.1.3    20.1.1.4
@{GATEWAY_IPS}    10.0.0.1    20.0.0.1
@{DHCP_IPS}       10.0.0.2    20.0.0.2
${bridge_ref_info_api}    /restconf/operational/odl-interface-meta:bridge-ref-info


*** Test Cases ***
Verify Tunnel Creation
    [Documentation]    Checks that vxlan tunnels have been created properly.
    ${node_1_dpid}=    Get DPID For Compute Node    ${OS_COMPUTE_1_IP}
    ${node_2_dpid}=    Get DPID For Compute Node    ${OS_COMPUTE_2_IP}
    ${node_1_adapter}=    Get Ethernet Adapter From Compute Node    ${OS_COMPUTE_1_IP}
    ${node_2_adapter}=    Get Ethernet Adapter From Compute Node    ${OS_COMPUTE_2_IP}
    ${first_two_octets}    ${third_octet}    ${last_octet}=    Split String From Right    ${OS_COMPUTE_1_IP}    .    2
    ${subnet}=    Set Variable    ${first_two_octets}.0.0/16
    ${gateway}=    Get Default Gateway    ${OS_COMPUTE_1_IP}
    Create TEP For Compute Node    ${OS_COMPUTE_1_IP}    ${node_1_dpid}    ${node_1_adapter}    ${subnet}    ${gateway}
    Create TEP For Compute Node    ${OS_COMPUTE_2_IP}    ${node_2_dpid}    ${node_2_adapter}    ${subnet}    ${gateway}

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
    [Documentation]    Create NOVA VM from compute node 
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

Verify Tunnel Deletion
    [Documentation]    Checks that vxlan tunnels have been deleted properly.
    Delete All TEP

*** Keywords ***
Basic Vpnservice Suite Setup
    Create Session    session    http://${ODL_SYSTEM_IP}:${RESTCONFPORT}    auth=${AUTH}    headers=${HEADERS}

Basic Vpnservice Suite Teardown
    Delete All Sessions

Get DPID For Compute Node
    [Arguments]    ${ip}
    [Documentation]    Returns the decimal form of the dpid of br-int as found in bridge-ref-info API
    ...    that matches the ovs UUID for the given ${ip}
    ${found_dpid}=    Set Variable    ${EMPTY}
    Create Session    odl_session    http://${ODL_SYSTEM_IP}:${RESTCONFPORT}    auth=${AUTH}    headers=${HEADERS}
    ${uuid}=    Run Command On Remote System    ${ip}    sudo ovs-vsctl show | head -1
    ${resp}=    RequestsLibrary.Get Request    odl_session    ${bridge_ref_info_api}
    Log    ${resp.content}
    ${resp_json}=    To Json    ${resp.content}
    ${bride_ref_info}=    Get From Dictionary    ${resp_json}    bridge-ref-info
    ${bridge_list}=    Get From Dictionary    ${bride_ref_info}    bridge-ref-entry
    : FOR    ${bridge}    IN    @{bridge_list}
    \    ${ref}=    Get From Dictionary    ${bridge}    bridge-reference
    \    ${dpid}=    Get From Dictionary    ${bridge}    dpid
    \    ${found_dpid}=    Set Variable If    """${uuid}""" in """${ref}"""    ${dpid}    ${found_dpid}
    [Return]    ${found_dpid}

Get Ethernet Adapter From Compute Node
    [Arguments]    ${ip}
    [Documentation]    Returns the adapter name on the system for the provided ${ip}
    ${adapter}=    Run Command On Remote System    ${ip}    /usr/sbin/ip addr show
    Log    ${adapter}
    ${adapter}=    Run Command On Remote System    ${ip}    /usr/sbin/ip addr show | grep ${ip} | cut -d " " -f 11
    [Return]    ${adapter}

Get Default Gateway
    [Arguments]    ${ip}
    [Documentation]    Returns the default gateway used by ${ip}
    ${gateway}=    Run Command On Remote System    ${ip}    /usr/sbin/route -n
    Log    ${gateway}
    ${gateway}=    Run Command On Remote System    ${ip}    /usr/sbin/route -n | grep '^0.0.0.0' | cut -d " " -f 10
    [Return]    ${gateway}

Create TEP For Compute Node
    [Arguments]    ${ip}    ${dpid}    ${adapter}    ${subnet}    ${gateway}
    [Documentation]    Uses tep:add and tep:commit karaf console command to create tep for given values
    ...  and verify tunnel by checking the status is UP (tep:show-state)
    Issue Command On Karaf Console    tep:add ${dpid} ${adapter} 0 ${ip} ${subnet} ${gateway} TZA
    Issue Command On Karaf Console    tep:commit
    ${resp}    Sleep    30
    ${output}=    Issue Command On Karaf Console    tep:show-state | grep ${ip}
    Log    ${output}
    Should Contain    ${output}    UP

Delete All TEP
    [Documentation]    Uses tep:deletedatastore to delete All tunnel
    ${output}=    Issue Command On Karaf Console    tep:deletedatastore
    Log    ${output}
    Should Not Contain    ${output}    ${OS_COMPUTE_1_IP}
    Should Not Contain    ${output}    ${OS_COMPUTE_2_IP}

