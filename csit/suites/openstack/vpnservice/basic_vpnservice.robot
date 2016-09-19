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
Resource          ../../../libraries/VpnOperations.robot
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
@{EXTRA_NW_IP}    40.1.1.2    50.1.1.2
${EXT_RT1}    destination=40.1.1.0/24,nexthop=10.1.1.2      
${EXT_RT2}    destination=50.1.1.0/24,nexthop=20.1.1.2   #TODO  PUT in array
${RT_OPTIONS}    --routes type=dict list=true 
${UPDATE_RTR}    neutron router-update 
${CONFIG_EXTRA_ROUTE_IP1}    sudo ifconfig eth0:1 @{EXTRA_NW_IP}[0] up 
${CONFIG_EXTRA_ROUTE_IP2}    sudo ifconfig eth0:1 @{EXTRA_NW_IP}[1] up
${bridge_ref_info_api}    /restconf/operational/odl-interface-meta:bridge-ref-info
${RESTCONF_OPERATIONS_URI}      /restconf/operations/
${VPN_CONFIG_DIR}    ${CURDIR}/../../../variables/vpnservice
${RT_CLEAR}    --routes action=clear

#L3VPN related varables
${VPN_INSTANCE_DELETE}    vpn1_instance_delete.json
@{VPN_INSTANCE}    vpn1_instance.json    vpn2_instance.json    vpn3_instance.json
@{VPN_INSTANCE_NAME}    4ae8cd92-48ca-49b5-94e1-b2921a2661c7    4ae8cd92-48ca-49b5-94e1-b2921a266112    4ae8cd92-48ca-49b5-94e1-b2921a2661c5
${GETL3VPN}       GETL3vpn.json
${GETL3VPN1}       GETL3vpn1.json
${CREATE_RESP_CODE}    200
${CREATE_ID_DEFAULT}    "4ae8cd92-48ca-49b5-94e1-b2921a2661c7"
${CREATE_NAME_DEFAULT}    "vpn1"
${CREATE_ROUTER_DISTINGUISHER_DEFAULT}    ["2200:1"]
${CREATE_EXPORT_RT_DEFAULT}    ["3300:1","8800:1"]
${CREATE_IMPORT_RT_DEFAULT}    ["3300:1","8800:1"]
${CREATE_TENANT_ID_DEFAULT}    "6c53df3a-3456-11e5-a151-feff819cdc9f"

# Values passed by the calling method to API
${CREATE_ID}    "4ae8cd92-48ca-49b5-94e1-b2921a261111"
${CREATE_NAME}    "vpn2"
${CREATE_ROUTER_DISTINGUISHER}    ["2200:2"]
${CREATE_EXPORT_RT}    ["3300:2","8800:2"]
${CREATE_IMPORT_RT}    ["3300:2","8800:2"]
${CREATE_TENANT_ID}    "6c53df3a-3456-11e5-a151-feff819c1111"


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
    [Documentation]    Create Vm instances on compute node with port
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

VPN L3VPN Creation
    [Documentation]    Create L3VPN.
    VPN Create L3VPN    ${VPN_INSTANCE[0]}     CREATE_ID=${CREATE_ID}
    ...    CREATE_EXPORT_RT=${CREATE_EXPORT_RT}    CREATE_IMPORT_RT=${CREATE_IMPORT_RT}   CREATE_TENANT_ID=${CREATE_TENANT_ID}

VPN L3VPN Get
    [Documentation]    Get L3VPN.
    VPN Get L3VPN    ${CREATE_ID}

Networks associated to VPN3
     [Documentation]    Associate Networks to VPN
     ${devstack_conn_id}=    Get ControlNode Connection
     ${network1_id} =     Get Net Id    ${NETWORKS[0]}    ${devstack_conn_id}
     ${network2_id} =     Get Net Id    ${NETWORKS[1]}    ${devstack_conn_id}
     Associate Network to VPN    ${CREATE_ID}    ${network1_id}
     Associate Network to VPN    ${CREATE_ID}    ${network2_id}

Networks dissociated to VPN3
     [Documentation]    dissociate Networks to VPN
     ${devstack_conn_id}=    Get ControlNode Connection
     ${network1_id} =     Get Net Id    ${NETWORKS[0]}    ${devstack_conn_id}
     ${network2_id} =     Get Net Id    ${NETWORKS[1]}    ${devstack_conn_id}
     Dissociate Network to VPN    ${CREATE_ID}    ${network1_id}
     Dissociate Network to VPN    ${CREATE_ID}    ${network2_id}

Associate VPN to Routers
    [Tags]    Associate
    ${devstack_conn_id}=    Get ControlNode Connection
    ${router_id}=    Get Router Id    ${ROUTERS[0]}    ${devstack_conn_id}
    Associate VPN to Router    ${router_id}     ${CREATE_ID}

Dissociate VPN to Routers
    [Tags]    Dissociate
    ${devstack_conn_id}=    Get ControlNode Connection
    ${router_id}=    Get Router Id    ${ROUTERS[0]}    ${devstack_conn_id}
    Dissociate VPN to Router    ${router_id}     ${CREATE_ID}


Check L3_Datapath Traffic Across Networks With Router
    [Documentation]    Datapath Test Across the networks using Router for L3.
    [Tags]    exclude
    Log    This test will be added in the next patch

Add Extra Routes
    [Documentation]    Add  Extra Routes
    Log    "Adding extra route"
    ${cmd}=    Catenate    ${UPDATE_RTR}    @{ROUTERS}[0]    ${RT_OPTIONS}    ${EXT_RT1}
    Update Router    @{ROUTERS}[0]    ${cmd}
    Execute Command on VM Instance    ${PORT_LIST[0]}    @{NET10_VM_IPS}[0]    ${CONFIG_EXTRA_ROUTE_IP1}

Delete Extra Routes
    [Documentation]    Delete Extra Routes
    Log    "Deleting extra route"
    ${cmd}=    Catenate    ${UPDATE_RTR}    @{ROUTERS}[0]    ${RT_CLEAR}
    Update Router    @{ROUTERS}[0]    ${cmd}


Delete Router Interfaces
    [Documentation]    Remove Interface to the subnets.
    : FOR    ${INTERFACE}    IN    @{SUBNETS}
    \    Remove Interface    ${ROUTERS[0]}    ${INTERFACE}

Delete Routers
    [Documentation]    Delete Router and Interface to the subnets.
    Delete Router    ${ROUTERS[0]}


VPN L3VPN Delete
    [Documentation]    Delete L3VPN.
    VPN Delete L3VPN     ${CREATE_ID} 

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
    ${adapter}=    Run Command On Remote System    ${ip}    ip addr show
    Log    ${adapter}
    ${adapter}=    Run Command On Remote System    ${ip}    ip addr show | grep ${ip} | cut -d " " -f 11
    [Return]    ${adapter}

Get Default Gateway
    [Arguments]    ${ip}
    [Documentation]    Returns the default gateway used by ${ip}
    ${gateway}=    Run Command On Remote System    ${ip}    route -n
    Log    ${gateway}
    ${gateway}=    Run Command On Remote System    ${ip}    route -n | grep '^0.0.0.0' | cut -d " " -f 10
    [Return]    ${gateway}

Create TEP For Compute Node
    [Arguments]    ${ip}    ${dpid}    ${adapter}    ${subnet}    ${gateway}
    [Documentation]    Uses tep:add and tep:commit karaf console command to create tep for given values 
    ...  and verify tunnel by checking the status is UP (tep:show-state) 
    Issue Command On Karaf Console    tep:add ${dpid} ${adapter} 0 ${ip} ${subnet} ${gateway} TZA
    Issue Command On Karaf Console    tep:commit
    ${resp}    Sleep    30
    ${output}=    Issue Command On Karaf Console    tep:show-state | grep ${ip}    
    Should Contain    ${output}    UP

Execute Command on VM Instance
   [Arguments]    ${port_name}    ${src_ip}    ${cmd}    ${user}=cirros
    ...    ${password}=cubswin:)
    [Documentation]    Login to the vm instance using ssh in the network.
    ${devstack_conn_id}=    Get ControlNode Connection
    Switch Connection    ${devstack_conn_id}
    ${port_id}=    Get Port Id    ${port_name}      ${devstack_conn_id}
    ${output}=    Write Commands Until Expected Prompt    sudo ip netns exec qdhcp-${port_id} ssh ${user}@${src_ip} -o ConnectTimeout=10 -o StrictHostKeyChecking=no    d:
    Log    ${output}
    ${output}=    Write Commands Until Expected Prompt    ${password}    ${OS_SYSTEM_PROMPT}
    Log    ${output}
    ${rcode}=    Run Keyword And Return Status    Check If Console Is VmInstance
    Run Keyword If    ${rcode}    Write Commands Until Expected Prompt    ${cmd}    ${OS_SYSTEM_PROMPT}

Update Router
    [Arguments]    ${router_name}    ${cmd}
    [Documentation]    Update router
    ${devstack_conn_id}=    Get ControlNode Connection
    Switch Connection    ${devstack_conn_id}
    ${output}=    Write Commands Until Prompt    ${cmd}    30s
    Close Connection

