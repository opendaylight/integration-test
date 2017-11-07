*** Settings ***
Documentation     Test Suite for EVPN_In_Intra_DC_Deployments with CSS.
Suite Setup       Start Suite
Suite Teardown    Stop Suite
Library           String
Library           RequestsLibrary
Resource          ../../../libraries/OpenStackOperations.robot
Resource          ../../../libraries/DevstackUtils.robot
Resource          ../../../libraries/SetupUtils.robot
Resource          ../../../libraries/KarafKeywords.robot
Resource          ../../../libraries/OVSDB.robot
Resource          ../../../libraries/VpnOperations.robot
Resource          ../../../libraries/BgpOperations.robot
Resource          ../../../libraries/EVPN_In_Intra_DC_Deployments.robot
Resource          ../../../variables/Intra-DC_Deployments_TestPlan_Var/EVPN_In_Intra_DC_Deployments_vars.robot
Variables         ../../../variables/netvirt/Variables.robot
Variables         ../../../variables/Variables.robot

*** Variables ***
${DCGW_SYSTEM_IP}    ${TOOLS_SYSTEM_1_IP}
${Req_no_of_net}    8
${Req_no_of_subNet}    8
${Req_no_of_ports}    16
${Req_no_of_vms_per_dpn}    8
${Req_no_of_routers}    2

*** Keywords ***
Start Suite
    [Documentation]    Test Suite for EVPN_In_Intra_DC_Deployments with CSS.
    SetupUtils.Setup_Utils_For_Setup_And_Teardown
    DevstackUtils.Devstack Suite Setup
    Start Quagga Processes On ODL    ${ODL_SYSTEM_IP}
    Start Quagga Processes On DCGW    ${DCGW_SYSTEM_IP}
    Create Setup

Stop Suite
    [Documentation]    Run after the tests execution
    Close All Connections

Create Neutron Networks
    [Arguments]    ${NUM_OF_NETWORK}
    [Documentation]    Create required number of networks
    ${REQUIRED_NETWORKS}=    Get Slice From List    ${REQ_NETWORKS}    0    ${NUM_OF_NETWORK}
    Log To Console    "REQUIRED NETWORKS IS ${REQUIRED_NETWORKS}"
    : FOR    ${NET}    IN    @{REQUIRED_NETWORKS}
    \    Create Network    ${NET}
    ${NET_LIST}    List Networks
    Log    ${NET_LIST}
    : FOR    ${index}    IN RANGE    0    ${NUM_OF_NETWORK}
    \    Should Contain    ${NET_LIST}    ${REQ_NETWORKS[${index}]}
    Wait Until Keyword Succeeds    3s    1s    Check For Elements At URI    ${REQ_NETWORK_URL}    ${REQ_NETWORKS}

Create Neutron Subnets
    [Arguments]    ${NUM_OF_NETWORK}    ${additional_args}=${EMPTY}    ${verbose}=TRUE
    [Documentation]    Create required number of subnets for previously created networks
    : FOR    ${index}    IN RANGE    0    ${NUM_OF_NETWORK}
    \    Create SubNet    ${REQ_NETWORKS[${index}]}    ${REQ_SUBNETS[${index}]}    ${REQ_SUBNET_CIDR[${index}]}
    ${SUB_LIST}    List Subnets
    Log    ${SUB_LIST}
    Log To Console    "REQUIRED SUBNET IS"
    Log To Console    ${SUB_LIST}
    : FOR    ${index}    IN RANGE    0    ${NUM_OF_NETWORK}
    \    Should Contain    ${SUB_LIST}    ${REQ_SUBNETS[${index}]}
    Wait Until Keyword Succeeds    3s    1s    Check For Elements At URI    ${REQ_SUBNETWORK_URL}    ${REQ_SUBNETS}

Create Neutron Ports
    [Arguments]    ${NUM_OF_PORTS}    ${additional_args}=${EMPTY}    ${verbose}=TRUE
    [Documentation]    Create required number of ports under previously created subnets
    Log    ${REQ_PORT_LIST}
    ${REQUIRED_PORT_LIST}=    Get Slice From List    ${REQ_PORT_LIST}    0    ${NUM_OF_PORTS}
    Log    ${REQUIRED_PORT_LIST}
    Log To Console    "REQUIRED PORT LIST IS"
    Log To Console    ${REQUIRED_PORT_LIST}
    : FOR    ${item}    IN RANGE    0    ${NUM_OF_PORTS}
    \    ${port_name}    Get From List    ${REQ_PORT_LIST}    ${item}
    \    ${match}    Get Regexp Matches    ${port_name}    [A-Z]*(.).*    1
    \    ${net}    Get From List    ${match}    0
    \    ${net}    Convert To Integer    ${net}
    \    ${network}    Get From List    ${REQ_NETWORKS}    ${net-1}
    \    Create Port    ${network}    ${port_name}    sg=${SECURITY_GROUP}
    Wait Until Keyword Succeeds    3s    1s    Check For Elements At URI    ${REQ_PORT_URL}    ${REQ_PORT_LIST}

Verify VMs received IP
    [Documentation]    Verify VM received IP
    ${status}    ${message}    Run Keyword And Ignore Error    Wait Until Keyword Succeeds    60s    5s    Collect VM IP Addresses
    ...    true    @{REQ_VM_INSTANCES_NET1}
    ${status}    ${message}    Run Keyword And Ignore Error    Wait Until Keyword Succeeds    60s    5s    Collect VM IP Addresses
    ...    true    @{REQ_VM_INSTANCES_NET2}
    ${status}    ${message}    Run Keyword And Ignore Error    Wait Until Keyword Succeeds    60s    5s    Collect VM IP Addresses
    ...    true    @{REQ_VM_INSTANCES_NET3}
    ${status}    ${message}    Run Keyword And Ignore Error    Wait Until Keyword Succeeds    60s    5s    Collect VM IP Addresses
    ...    true    @{REQ_VM_INSTANCES_NET4}
    ${VM_IP_NET1}    ${DHCP_IP1}    Collect VM IP Addresses    false    @{REQ_VM_INSTANCES_NET1}
    ${VM_IP_NET2}    ${DHCP_IP2}    Collect VM IP Addresses    false    @{REQ_VM_INSTANCES_NET2}
    ${VM_IP_NET3}    ${DHCP_IP3}    Collect VM IP Addresses    false    @{REQ_VM_INSTANCES_NET3}
    ${VM_IP_NET4}    ${DHCP_IP4}    Collect VM IP Addresses    false    @{REQ_VM_INSTANCES_NET4}
    Log    ${VM_IP_NET1}
    Log    ${VM_IP_NET2}
    Log    ${VM_IP_NET3}
    Log    ${VM_IP_NET4}
    Should Not Contain    ${VM_IP_NET2}    None
    Should Not Contain    ${VM_IP_NET1}    None
    Should Not Contain    ${VM_IP_NET3}    None
    Should Not Contain    ${VM_IP_NET4}    None
    [Return]    ${VM_IP_NET1}    ${VM_IP_NET2}    ${VM_IP_NET3}    ${VM_IP_NET4}

Create Nova VMs
    [Arguments]    ${NUM_OF_VMS_PER_DPN}    ${additional_args}=${EMPTY}    ${verbose}=TRUE
    [Documentation]    Create Vm instances on compute nodes
    : FOR    ${index}    IN RANGE    0    ${NUM_OF_VMS_PER_DPN}
    \    Create Vm Instance With Port On Compute Node    ${REQ_PORT_LIST[${index}]}    ${VM_INSTANCES_DPN1[${index}]}    ${OS_COMPUTE_1_IP}    sg=${SECURITY_GROUP}
    ${start} =    Evaluate    ${index}+1
    ${NUM_OF_VMS_PER_DPN} =    Evaluate    ${start}+${NUM_OF_VMS_PER_DPN}
    : FOR    ${index}    IN RANGE    ${start}    ${NUM_OF_VMS_PER_DPN}
    \    Create Vm Instance With Port On Compute Node    ${REQ_PORT_LIST[${index}]}    ${VM_INSTANCES[${index}]}    ${OS_COMPUTE_2_IP}    sg=${SECURITY_GROUP}
    List Nova VMs
    : FOR    ${VM}    IN    @{VM_INSTANCES_DPN1}    @{VM_INSTANCES_DPN2}
    \    Wait Until Keyword Succeeds    60s    10s    Verify VM Is ACTIVE    ${VM}

Create Setup
    [Documentation]    Create Two Networks, Two Subnets, Four Ports And Four VMs on each DPN
    VM Creation Quota Update    ${NUM_INSTANCES}
    Create Neutron Networks    ${Req_no_of_net}
    Create Neutron Subnets    ${Req_no_of_subNet}
    OpenStackOperations.Create Allow All SecurityGroup    ${SECURITY_GROUP}
    Create Neutron Ports    ${Req_no_of_ports}
    OpenStackOperations.Create Nano Flavor
    Create Nova VMs    ${Req_no_of_vms_per_dpn}
    ${VM_IP_NET1}    ${VM_IP_NET2}    ${VM_IP_NET3}    ${VM_IP_NET4}    Wait Until Keyword Succeeds    180s    10s
    ...    Verify VMs received IP
    Set Global Variable    ${VM_IP_NET2}
    Set Global Variable    ${VM_IP_NET1}
    Set Global Variable    ${VM_IP_NET3}
    Set Global Variable    ${VM_IP_NET4}
    Create Routers    ${Req_no_of_routers}
    Log    CREATE EVPN FROM THE REST API WITH PROPER L3VNI ID
    ${Req_no_of_L3VPN} =    Evaluate    1
    Create L3VPN    ${Req_no_of_L3VPN}
    Log    ASSOCIATE net1 AND net2 TO EVPN FROM CSC
    ${Req_no_of_net} =    Evaluate    2
    Associate L3VPN To Networks    ${Req_no_of_net}
    Log    ADD BGP NEIGHBOUR ( ASR AS DCGW ) AND CHECK BGP CONNECTION
    ${output}=    Issue Command On Karaf Console    ${BGP_CONFIG_SERVER_CMD}
    Create BGP Config On ODL
    Create BGP Config On DCGW
    Log    VERIFY TUNNELS BETWEEN DPNS IS UP
    Wait Until Keyword Succeeds    60s    10s    Verify Tunnel Status as UP
    Log    VERIFY FLOWS ARE PRESENT ON THE DPNS
    Wait Until Keyword Succeeds    60s    10s    Verify Flows Are Present    ${OS_COMPUTE_1_IP}
    Wait Until Keyword Succeeds    60s    10s    Verify Flows Are Present    ${OS_COMPUTE_2_IP}
    Log    VERIFY THE VM IS ACTIVE
    : FOR    ${VM}    IN    @{VM_INSTANCES}
    \    Wait Until Keyword Succeeds    25s    5s    Verify VM Is ACTIVE    ${VM}
    Log    CREATE EXTERNAL TUNNEL ENDPOINT BTW ODL AND DCGW
    Create External Tunnel Endpoint
    LOG    LIST ROUTES ON QUAGGA
    ${output} =    Execute Show Command On quagga    ${DCGW_SYSTEM_IP}    show ip bgp vrf ${DCGW_RD}
    Log    ${output}

Create Routers
    [Arguments]    ${NUM_OF_ROUTERS}
    [Documentation]    Create Router
    : FOR    ${index}    IN RANGE    0    ${NUM_OF_ROUTERS}
    \    Create Router    ${REQ_ROUTERS[${index}]}
    ${router_output} =    List Router
    Log    ${router_output}
    : FOR    ${index}    IN RANGE    0    ${NUM_OF_ROUTERS}
    \    Should Contain    ${router_output}    ${REQ_ROUTERS[${index}]}
    Wait Until Keyword Succeeds    3s    1s    Check For Elements At URI    ${CONFIG_API}/neutron:neutron/routers/    ${REQ_ROUTERS}

Create L3VPN
    [Arguments]    ${NUM_OF_L3VPN}    ${additional_args}=${EMPTY}    ${verbose}=TRUE
    [Documentation]    Creates L3VPN and verify the same
    ${net_id} =    Get Net Id    @{REQ_NETWORKS}[0]    ${devstack_conn_id}
    ${tenant_id} =    Get Tenant ID From Network    ${net_id}
    : FOR    ${index}    IN RANGE    0    ${NUM_OF_L3VPN}
    \    VPN Create L3VPN    vpnid=${VPN_INSTANCE_ID[${index}]}    name=${VPN_NAME[${index}]}    rd=${CREATE_RD[${index}]}    exportrt=${CREATE_EXPORT_RT[${index}]}    importrt=${CREATE_IMPORT_RT[${index}]}
    \    ...    l3vni=${CREATE_L3VNI[${index}]}    tenantid=${tenant_id}
    \    ${resp}=    VPN Get L3VPN    vpnid=${VPN_INSTANCE_ID[${index}]}
    \    Should Contain    ${resp}    ${VPN_INSTANCE_ID[${index}]}
    \    Should Match Regexp    ${resp}    .*export-RT.*\\n.*${CREATE_EXPORT_RT[${index}]}.*
    \    Should Match Regexp    ${resp}    .*import-RT.*\\n.*${CREATE_IMPORT_RT[${index}]}.*
    \    Should Match Regexp    ${resp}    .*route-distinguisher.*\\n.*${CREATE_RD[${index}]}.*
    \    Should Match Regexp    ${resp}    .*l3vni.*${CREATE_l3VNI[${index}]}.*

Create BGP Config On ODL
    [Documentation]    Configure BGP Config on ODL
    Create BGP Configuration On ODL    localas=${AS_ID}    routerid=${ODL_SYSTEM_IP}
    AddNeighbor To BGP Configuration On ODL    remoteas=${AS_ID}    neighborAddr=${DCGW_SYSTEM_IP}
    ${output} =    Get BGP Configuration On ODL    session
    Log    ${output}
    Should Contain    ${output}    ${DCGW_SYSTEM_IP}

Create BGP Config On DCGW
    [Documentation]    Configure BGP on DCGW
    Configure BGP And Add Neighbor On DCGW    ${DCGW_SYSTEM_IP}    ${AS_ID}    ${DCGW_SYSTEM_IP}    ${ODL_SYSTEM_IP}    ${VPN_NAME[0]}    ${DCGW_RD}
    ...    ${LOOPBACK_IP}
    Add Loopback Interface On DCGW    ${DCGW_SYSTEM_IP}    lo    ${LOOPBACK_IP}
    ${output} =    Execute Show Command On Quagga    ${DCGW_SYSTEM_IP}    show running-config
    Log    ${output}
    ${output} =    Wait Until Keyword Succeeds    180s    10s    Verify BGP Neighbor Status On Quagga    ${DCGW_SYSTEM_IP}    ${ODL_SYSTEM_IP}
    Log    ${output}
    ${output1} =    Execute Show Command On Quagga    ${DCGW_SYSTEM_IP}    show ip bgp vrf ${DCGW_RD}
    Log    ${output1}

Delete BGP Config On ODL
    [Documentation]    Delete BGP Configuration on ODL
    Delete BGP Configuration On ODL    session
    ${output} =    Get BGP Configuration On ODL    session
    Log    ${output}
    ${output}=    Run Command On Remote System    ${ODL_SYSTEM_IP}    sudo cp /opt/quagga/var/log/quagga/zrpcd.init.log /tmp/
    Log    ${output}
    ${output}=    Run Command On Remote System    ${ODL_SYSTEM_IP}    sudo ls -la /tmp/
    Log    ${output}

Create External Tunnel Endpoint
    [Documentation]    Create and verify external tunnel endpoint between ODL and GWIP
    Create External Vxlan Tunnel Endpoint Configuration    destIp=${DCGW_SYSTEM_IP}
    ${output} =    Get External Tunnel Endpoint Configuration    ${DCGW_SYSTEM_IP}
    Should Contain    ${output}    ${DCGW_SYSTEM_IP}

Associate L3VPN To Networks
    [Arguments]    ${NUM_OF_NET}    ${additional_args}=${EMPTY}    ${verbose}=TRUE
    [Documentation]    Associates L3VPN to networks and verify
    : FOR    ${index}    IN RANGE    0    ${NUM_OF_NET}
    \    ${network_id} =    Get Net Id    ${REQ_NETWORKS[${index}]}    ${devstack_conn_id}
    \    Associate L3VPN To Network    networkid=${network_id}    vpnid=${VPN_INSTANCE_ID[0]}
    \    ${resp}=    VPN Get L3VPN    vpnid=${VPN_INSTANCE_ID[0]}
    \    Should Contain    ${resp}    ${network_id}
