*** Settings ***
Documentation     Test Suite for EVPN_In_Intra_DC_Deployments with CSS.
Suite Setup       Start Suite
Suite Teardown    Stop Suite
Library           String
Library           RequestsLibrary
Resource          ../../../libraries/BgpOperations.robot
Resource          ../../../libraries/DevstackUtils.robot
Resource          ../../../libraries/FT62_bgp.robot
Resource          ../../../libraries/KarafKeywords.robot
Resource          ../../../libraries/OpenStackOperations.robot
Resource          ../../../libraries/OVSDB.robot
Resource          ../../../libraries/SetupUtils.robot
Resource          ../../../libraries/Utils.robot
Resource          ../../../libraries/VpnOperations.robot
Resource          ../../../variables/ft62_variables/ft62_vars.robot
Resource          ../../../variables/netvirt/Variables.robot
Resource          ../../../variables/Variables.robot

*** Variables ***
${Req_no_of_net}    3
${Req_no_of_subNet}    3
${Req_no_of_ports}    6
${Req_no_of_vms_per_dpn}    3
${Req_no_of_routers}    1

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
    Delete Setup 
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
    : FOR    ${item}    IN RANGE    0    ${NUM_OF_PORTS}
    \    ${port_name}    Get From List    ${REQ_PORT_LIST}    ${item}
    \    ${match}    Get Regexp Matches    ${port_name}    [A-Z]*(.).*    1
    \    ${net}    Get From List    ${match}    0
    \    ${net}    Convert To Integer    ${net}
    \    ${network}    Get From List    ${REQ_NETWORKS}    ${net-1}
    \    Create Port    ${network}    ${port_name}    sg=${SECURITY_GROUP}
    Wait Until Keyword Succeeds    3s    1s    Check For Elements At URI    ${REQ_PORT_URL}    ${REQ_PORT_LIST}

Check Vm Instances Have Ip Address
    @{VM_IP_NET1}    ${NET1_DHCP_IP} =    Get VM IPs    @{REQ_VM_INSTANCES_NET1}
    @{VM_IP_NET2}    ${NET2_DHCP_IP} =    Get VM IPs    @{REQ_VM_INSTANCES_NET2}
    @{VM_IP_NET3}    ${NET3_DHCP_IP} =    Get VM IPs    @{REQ_VM_INSTANCES_NET3}
    Set Suite Variable    @{VM_IP_NET1}
    Set Suite Variable    @{VM_IP_NET2}
    Set Suite Variable    @{VM_IP_NET3}
    Should Not Contain    ${VM_IP_NET1}    None
    Should Not Contain    ${VM_IP_NET2}    None
    Should Not Contain    ${VM_IP_NET3}    None
    [Teardown]    Run Keywords    Show Debugs    @{REQ_VM_INSTANCES_NET1}    @{REQ_VM_INSTANCES_NET2}    @{REQ_VM_INSTANCES_NET3}    
    ...    AND    Get Test Teardown Debugs

Create Nova VMs
    [Arguments]    ${NUM_OF_VMS_PER_DPN}    ${additional_args}=${EMPTY}    ${verbose}=TRUE
    [Documentation]    Create Vm instances on compute nodes
    : FOR    ${index}    IN RANGE    0    ${NUM_OF_VMS_PER_DPN}
    \    Create Vm Instance With Port On Compute Node    ${REQ_PORT_LIST[${index}]}    ${VM_INSTANCES_DPN1[${index}]}    ${OS_COMPUTE_1_IP}    sg=${SECURITY_GROUP}
    ${start} =    Evaluate    ${index}+1
    ${NUM_OF_VMS_PER_DPN} =    Evaluate    ${start}+${NUM_OF_VMS_PER_DPN}
    : FOR    ${index}    IN RANGE    ${start}    ${NUM_OF_VMS_PER_DPN}
    \    Create Vm Instance With Port On Compute Node    ${REQ_PORT_LIST[${index}]}    ${VM_INSTANCES[${index}]}    ${OS_COMPUTE_2_IP}    sg=${SECURITY_GROUP}
    #List Nova VMs
    #: FOR    ${VM}    IN    @{VM_INSTANCES_DPN1}    @{VM_INSTANCES_DPN2}
    #\    Wait Until Keyword Succeeds    60s    10s    Verify VM Is ACTIVE    ${VM}

Create Setup
    [Documentation]    Create Two Networks, Two Subnets, Four Ports And Four VMs on each DPN
    VM Creation Quota Update    ${NUM_INSTANCES}
    Create Neutron Networks    ${Req_no_of_net}
    Create Neutron Subnets    ${Req_no_of_subNet}
    OpenStackOperations.Create Allow All SecurityGroup    ${SECURITY_GROUP}
    Create Neutron Ports    ${Req_no_of_ports}
    #OpenStackOperations.Create Nano Flavor
    Create Router    ${REQ_ROUTER}
    Create Nova VMs    ${Req_no_of_vms_per_dpn}
    ${VM_IP_NET1}    ${VM_IP_NET2}    ${VM_IP_NET3}    Wait Until Keyword Succeeds    180s    10s
    ...    Check Vm Instances Have Ip Address
    Set Global Variable    ${VM_IP_NET1}
    Set Global Variable    ${VM_IP_NET2}
    Set Global Variable    ${VM_IP_NET3}     
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

Associate L3VPN To Routers
    [Arguments]    ${NUM_OF_ROUTER}    ${additional_args}=${EMPTY}    ${verbose}=TRUE
    [Documentation]    Associating router to L3VPN
    ${devstack_conn_id}=    Get ControlNode Connection
    : FOR    ${index}    IN RANGE    0    ${NUM_OF_ROUTER}
    \    ${router_id}=    Get Router Id    ${REQ_ROUTERS[${index}]}    ${devstack_conn_id}
    \    Associate VPN to Router    routerid=${router_id}    vpnid=${VPN_INSTANCE_ID[0]}
    \    ${resp}=    VPN Get L3VPN    vpnid=${VPN_INSTANCE_ID[0]}
    \    Should Contain    ${resp}    ${router_id}

Delete Setup
    [Documentation]    Delete the setup
    Dissociate L3VPN From Networks    networkid=${net_id}    vpnid=${VPN_INSTANCE_ID[0]}
    Dissociate VPN to Router    routerid=${router_id}    vpnid=${VPN_INSTANCE_ID[0]}
    VPN Delete L3VPN    vpnid=${VPN_INSTANCE_ID[0]}
    Remove Interface    ${REQ_ROUTER}    ${ROUTER_INTERFACE}
    Delete Router    ${REQ_ROUTER}
    ${VM_INSTANCES} =    Create List    @{VM_INSTANCES_NET1}    @{VM_INSTANCES_NET2}    @{VM_INSTANCES_NET3}
    : FOR    ${VmInstance}    IN    @{VM_INSTANCES}
    \    Delete Vm Instance    ${VmInstance}
    : FOR    ${Port}    IN    @{REQ_PORT_LIST}
    \    Delete Port    ${Port}
    : FOR    ${Subnet}    IN    @{REQ_SUBNETS}
    \    Delete SubNet    ${Subnet}
    : FOR    ${Network}    IN    @{REQ_NETWORKS}
    \    Delete Network    ${Network}
    Delete SecurityGroup    ${SECURITY_GROUP}


