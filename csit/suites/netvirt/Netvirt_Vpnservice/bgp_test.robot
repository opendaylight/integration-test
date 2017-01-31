*** Settings ***
Documentation     Test suite to validate vpnservice functionality in an openstack integrated environment.
...               The assumption of this suite is that the environment is already configured with the proper
...               integration bridges and vxlan tunnels.
Suite Setup       BuiltIn.Run Keywords    SetupUtils.Setup_Utils_For_Setup_And_Teardown
...               AND    DevstackUtils.Devstack Suite Setup
...               AND    DCGW Suite Setup
...               AND    Start Processes on ODL
...               AND    Start Processes on DCGW
Suite Teardown    Close All Connections
Test Setup        SetupUtils.Setup_Test_With_Logging_And_Without_Fast_Failing
Test Teardown     Get Test Teardown Debugs
Library           OperatingSystem
Library           RequestsLibrary
Resource          ../../../libraries/Utils.robot
Resource          ../../../libraries/OpenStackOperations.robot
Resource          ../../../libraries/DevstackUtils.robot
Resource          ../../../libraries/VpnOperations.robot
Resource          ../../../libraries/OVSDB.robot
Resource          ../../../libraries/SetupUtils.robot
Resource          ../../../variables/Variables.robot

*** Variables ***
@{NETWORKS}       NET10    NET20
@{SUBNETS}        SUBNET1    SUBNET2
@{SUBNET_CIDR}    10.1.1.0/24    20.1.1.0/24
@{PORT_LIST}      PORT11    PORT21    PORT12    PORT22
@{VM_INSTANCES_NET10}    VM11    VM21
@{VM_INSTANCES_NET20}    VM12    VM22
@{ROUTERS}        ROUTER_1    ROUTER_2
@{VPN_INSTANCE_ID}    4ae8cd92-48ca-49b5-94e1-b2921a261111    4ae8cd92-48ca-49b5-94e1-b2921a261112    4ae8cd92-48ca-49b5-94e1-b2921a261113
@{VPN_NAME}       vpn1    vpn2    vpn3
@{CREATE_RD}      ["2200:2"]    ["2300:2"]    ["2400:2"]
@{CREATE_EXPORT_RT}    ["2200:2"]    ["2300:2"]    ["2400:2"]
@{CREATE_IMPORT_RT}    ["2200:2"]    ["2300:2"]    ["2400:2"]
@{EXTRA_NW_IP}    40.1.1.2    50.1.1.2
@{EXTRA_NW_SUBNET}    40.1.1.0/24    50.1.1.0/24
# Values passed for extra routes
${RT_OPTIONS}     --routes type=dict list=true
${RT_CLEAR}       --routes action=clear
${BGP_PROMPT}     \    #
${DCGW_PROMPT}    \>
${VAR_BASE_BGP}    ${CURDIR}/../../../variables/bgpfunctional
${LOOPBACK_IP}    5.5.5.2
${DCGW_SYSTEM_IP}    ${TOOLS_SYSTEM_1_IP}
${AS_ID}          500

*** Test Cases ***
Create Neutron Networks
    [Documentation]    Create two networks
    Create Network    ${NETWORKS[0]}
    Create Network    ${NETWORKS[1]}
    ${NET_LIST}    List Networks
    Log    ${NET_LIST}
    Should Contain    ${NET_LIST}    ${NETWORKS[0]}
    Should Contain    ${NET_LIST}    ${NETWORKS[1]}
    Wait Until Keyword Succeeds    3s    1s    Check For Elements At URI    ${CONFIG_API}/neutron:neutron/networks/    ${NETWORKS}

Create Neutron Subnets
    [Documentation]    Create two subnets for previously created networks
    Create SubNet    ${NETWORKS[0]}    ${SUBNETS[0]}    ${SUBNET_CIDR[0]}
    Create SubNet    ${NETWORKS[1]}    ${SUBNETS[1]}    ${SUBNET_CIDR[1]}
    ${SUB_LIST}    List Subnets
    Log    ${SUB_LIST}
    Should Contain    ${SUB_LIST}    ${SUBNETS[0]}
    Should Contain    ${SUB_LIST}    ${SUBNETS[1]}
    Wait Until Keyword Succeeds    3s    1s    Check For Elements At URI    ${CONFIG_API}/neutron:neutron/subnets/    ${SUBNETS}

Add Ssh Allow Rule
    [Documentation]    Allow all TCP/UDP/ICMP packets for this suite
    Neutron Security Group Create    sg-vpnservice
    Neutron Security Group Rule Create    sg-vpnservice    direction=ingress    port_range_max=65535    port_range_min=1    protocol=tcp    remote_ip_prefix=0.0.0.0/0
    Neutron Security Group Rule Create    sg-vpnservice    direction=egress    port_range_max=65535    port_range_min=1    protocol=tcp    remote_ip_prefix=0.0.0.0/0
    Neutron Security Group Rule Create    sg-vpnservice    direction=ingress    protocol=icmp    remote_ip_prefix=0.0.0.0/0
    Neutron Security Group Rule Create    sg-vpnservice    direction=egress    protocol=icmp    remote_ip_prefix=0.0.0.0/0
    Neutron Security Group Rule Create    sg-vpnservice    direction=ingress    port_range_max=65535    port_range_min=1    protocol=udp    remote_ip_prefix=0.0.0.0/0
    Neutron Security Group Rule Create    sg-vpnservice    direction=egress    port_range_max=65535    port_range_min=1    protocol=udp    remote_ip_prefix=0.0.0.0/0

Create Neutron Ports
    [Documentation]    Create four ports under previously created subnets
    Create Port    ${NETWORKS[0]}    ${PORT_LIST[0]}    sg=sg-vpnservice
    Create Port    ${NETWORKS[0]}    ${PORT_LIST[1]}    sg=sg-vpnservice
    Create Port    ${NETWORKS[1]}    ${PORT_LIST[2]}    sg=sg-vpnservice
    Create Port    ${NETWORKS[1]}    ${PORT_LIST[3]}    sg=sg-vpnservice
    Wait Until Keyword Succeeds    3s    1s    Check For Elements At URI    ${CONFIG_API}/neutron:neutron/ports/    ${PORT_LIST}

Create Nova VMs
    [Documentation]    Create Vm instances on compute node with port
    Create Vm Instance With Port On Compute Node    ${PORT_LIST[0]}    ${VM_INSTANCES_NET10[0]}    ${OS_COMPUTE_1_IP}    sg=sg-vpnservice
    Create Vm Instance With Port On Compute Node    ${PORT_LIST[1]}    ${VM_INSTANCES_NET10[1]}    ${OS_COMPUTE_2_IP}    sg=sg-vpnservice
    Create Vm Instance With Port On Compute Node    ${PORT_LIST[2]}    ${VM_INSTANCES_NET20[0]}    ${OS_COMPUTE_1_IP}    sg=sg-vpnservice
    Create Vm Instance With Port On Compute Node    ${PORT_LIST[3]}    ${VM_INSTANCES_NET20[1]}    ${OS_COMPUTE_2_IP}    sg=sg-vpnservice
    ${VM_INSTANCES} =    Create List    @{VM_INSTANCES_NET10}    @{VM_INSTANCES_NET20}
    : FOR    ${VM}    IN    @{VM_INSTANCES}
    \    Wait Until Keyword Succeeds    25s    5s    Verify VM Is ACTIVE    ${VM}
    Log    Check for routes
    Wait Until Keyword Succeeds    30s    10s    Wait For Routes To Propogate
    ${VM_IP_NET10}    ${DHCP_IP1}    Wait Until Keyword Succeeds    30s    10s    Verify VMs Received DHCP Lease    @{VM_INSTANCES_NET10}
    Log    ${VM_IP_NET10}
    Set Suite Variable    ${VM_IP_NET10}
    ${VM_IP_NET20}    ${DHCP_IP2}    Wait Until Keyword Succeeds    30s    10s    Verify VMs Received DHCP Lease    @{VM_INSTANCES_NET20}
    Log    ${VM_IP_NET20}
    Set Suite Variable    ${VM_IP_NET20}

Create Routers
    [Documentation]    Create Router
    Create Router    ${ROUTERS[0]}
    ${router_output} =    List Router
    Log    ${router_output}
    Should Contain    ${router_output}    ${ROUTERS[0]}
    ${router_list} =    Create List    ${ROUTERS[0]}
    Wait Until Keyword Succeeds    3s    1s    Check For Elements At URI    ${CONFIG_API}/neutron:neutron/routers/    ${router_list}

Add Interfaces To Router
    [Documentation]    Add Interfaces
    ${devstack_conn_id} =    Get ControlNode Connection
    : FOR    ${INTERFACE}    IN    @{SUBNETS}
    \    Add Router Interface    ${ROUTERS[0]}    ${INTERFACE}
    ${interface_output} =    Show Router Interface    ${ROUTERS[0]}
    : FOR    ${INTERFACE}    IN    @{SUBNETS}
    \    ${subnet_id} =    Get Subnet Id    ${INTERFACE}    ${devstack_conn_id}
    \    Should Contain    ${interface_output}    ${subnet_id}

Create L3VPN
    [Documentation]    Creates L3VPN and verify the same
    ${devstack_conn_id} =    Get ControlNode Connection
    Switch Connection    ${devstack_conn_id}
    ${net_id} =    Get Net Id    @{NETWORKS}[0]    ${devstack_conn_id}
    ${tenant_id} =    Get Tenant ID From Network    ${net_id}
    VPN Create L3VPN    vpnid=${VPN_INSTANCE_ID[0]}    name=${VPN_NAME[0]}    rd=${CREATE_RD[0]}    exportrt=${CREATE_EXPORT_RT[0]}    importrt=${CREATE_IMPORT_RT[0]}    tenantid=${tenant_id}
    ${resp}=    VPN Get L3VPN    vpnid=${VPN_INSTANCE_ID[0]}
    Should Contain    ${resp}    ${VPN_INSTANCE_ID[0]}

Associate L3VPN To Routers
    [Documentation]    Associating router to L3VPN
    ${devstack_conn_id}=    Get ControlNode Connection
    ${router_id}=    Get Router Id    ${ROUTERS[0]}    ${devstack_conn_id}
    Associate VPN to Router    routerid=${router_id}    vpnid=${VPN_INSTANCE_ID[0]}
    ${resp}=    VPN Get L3VPN    vpnid=${VPN_INSTANCE_ID[0]}
    Should Contain    ${resp}    ${router_id}

Create BGP Config On ODL
    [Documentation]    Create BGP Config on ODL
    Create BGP Configuration    localas=${AS_ID}    routerid=${ODL_SYSTEM_IP}
    AddNeighbor To BGP Configuration    remoteas=${AS_ID}    neighborAddr=${DCGW_SYSTEM_IP}
    ${output} =    Get BGP Configuration
    Log    ${output}
    Should Contain    ${output}    ${DCGW_SYSTEM_IP}

Create BGP Config On DCGW
    [Documentation]    Configure BGP Config on DCGW
    Add BGP Configuration On DCGW
    Add Loopback Interface On DCGW    ${LOOPBACK_IP}/32
    ${output} =    Execute Command On DCGW    show running-config
    Log    ${output}
    ${output} =    Execute Command On DCGW    show bgp neighbors ${ODL_SYSTEM_IP}
    Log    ${output}
    Should Contain    ${output}    BGP state = Established
    ${output} =    Execute Command On DCGW    show ip bgp vrf ${VPN_NAME[0]}
    Log    ${output}
    Should Contain    ${output}    ${LOOPBACK_IP}

Create External Tunnel Endpoint
    [Documentation]    Create and verify external tunnel endpoint between ODL and GWIP
    Create external tunnel endpoint Configuration    destIp=${DCGW_SYSTEM_IP}
    ${output} =    Get External Tunnel Endpoint Configuration    ${DCGW_SYSTEM_IP}
    Should Contain    ${output}    ${DCGW_SYSTEM_IP}

Verify End To End Datapath with DCGW
    [Documentation]    Verify End to End datapath
    Log    L3 Datapath test across the networks using router
    ${output} =    Execute Command on VM Instance    @{NETWORKS}[0]    ${VM_IP_NET10[1]}    ping -c 3 ${LOOPBACK_IP}
    Should Contain    ${output}    64 bytes
    ${output} =    Execute Command on VM Instance    @{NETWORKS}[1]    ${VM_IP_NET20[1]}    ping -c 3 ${LOOPBACK_IP}
    Should Contain    ${output}    64 bytes

Delete External Tunnel Endpoint
    [Documentation]    Delete external tunnel endpoint
    Delete external tunnel endpoint Configuration    destIp=${DCGW_SYSTEM_IP}
    Get External Tunnel Endpoint Configuration    ${DCGW_SYSTEM_IP}

Delete BGP Config
    [Documentation]    Delete BGP Config
    Delete BGP Configuration
    ${output} =    Get BGP Configuration
    Log    ${output}

Dissociate L3VPN From Routers
    [Documentation]    Dissociating router from L3VPN
    ${devstack_conn_id}=    Get ControlNode Connection
    ${router_id}=    Get Router Id    ${ROUTERS[0]}    ${devstack_conn_id}
    Dissociate VPN to Router    routerid=${router_id}    vpnid=${VPN_INSTANCE_ID[0]}
    ${resp}=    VPN Get L3VPN    vpnid=${VPN_INSTANCE_ID[0]}
    Should Not Contain    ${resp}    ${router_id}

Delete Router And Router Interfaces With L3VPN
    [Documentation]    Delete Router and Interface to the subnets with L3VPN assciate
    # Asscoiate router with L3VPN
    ${devstack_conn_id} =    Get ControlNode Connection
    ${router_id}=    Get Router Id    ${ROUTERS[0]}    ${devstack_conn_id}
    Associate VPN to Router    routerid=${router_id}    vpnid=${VPN_INSTANCE_ID[0]}
    ${resp}=    VPN Get L3VPN    vpnid=${VPN_INSTANCE_ID[0]}
    Should Contain    ${resp}    ${router_id}
    #Delete Interface
    : FOR    ${INTERFACE}    IN    @{SUBNETS}
    \    Remove Interface    ${ROUTERS[0]}    ${INTERFACE}
    ${interface_output} =    Show Router Interface    ${ROUTERS[0]}
    : FOR    ${INTERFACE}    IN    @{SUBNETS}
    \    ${subnet_id} =    Get Subnet Id    ${INTERFACE}    ${devstack_conn_id}
    \    Should Not Contain    ${interface_output}    ${subnet_id}
    # Delete Router and Interface to the subnets.
    Delete Router    ${ROUTERS[0]}
    ${router_output} =    List Router
    Log    ${router_output}
    Should Not Contain    ${router_output}    ${ROUTERS[0]}
    ${router_list} =    Create List    ${ROUTERS[0]}
    Wait Until Keyword Succeeds    3s    1s    Check For Elements Not At URI    ${CONFIG_API}/neutron:neutron/routers/    ${router_list}
    # Verify Router Entry removed from L3VPN
    ${resp}=    VPN Get L3VPN    vpnid=${VPN_INSTANCE_ID[0]}
    Should Not Contain    ${resp}    ${router_id}

Delete L3VPN
    [Documentation]    Delete L3VPN
    VPN Delete L3VPN    vpnid=${VPN_INSTANCE_ID[0]}

Delete Vm Instances
    [Documentation]    Delete Vm instances in the given Instance List
    ${VM_INSTANCES} =    Create List    @{VM_INSTANCES_NET10}    @{VM_INSTANCES_NET20}
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

Wait For Routes To Propogate
    ${devstack_conn_id} =    Get ControlNode Connection
    Switch Connection    ${devstack_conn_id}
    ${net_id} =    Get Net Id    @{NETWORKS}[0]    ${devstack_conn_id}
    ${output} =    Write Commands Until Expected Prompt    sudo ip netns exec qdhcp-${net_id} ip route    ]>
    Should Contain    ${output}    @{SUBNET_CIDR}[0]
    ${net_id} =    Get Net Id    @{NETWORKS}[1]    ${devstack_conn_id}
    ${output} =    Write Commands Until Expected Prompt    sudo ip netns exec qdhcp-${net_id} ip route    ]>
    Should Contain    ${output}    @{SUBNET_CIDR}[1]

Add BGP Configuration On DCGW
    [Arguments]    ${user}=bgpd    ${password}=sdncbgpc
    [Documentation]    Execute cmd on DCGW and returns the ouput.
    DCGW Suite Setup
    Switch Connection    ${dcgw_conn_id}
    ${output} =    Write    telnet localhost ${user}
    Log    ${output}
    ${output} =    Read Until    Password:
    Log    ${output}
    ${output} =    Write    ${password}
    Log    ${output}
    ${output} =    Read
    Log    ${output}
    ${output} =    Write    terminal length 512
    Set Client Configuration    prompt=#
    ${output} =    Write    configure terminal
    ${output} =    Read
    ${output} =    Write    router bgp ${AS_ID}
    ${output} =    Read
    ${output} =    Write    bgp router-id ${DCGW_SYSTEM_IP}
    ${output} =    Read
    ${output} =    Write    redistribute static
    ${output} =    Read
    ${output} =    Write    redistribute connected
    ${output} =    Read
    ${output} =    Write    neighbor ${ODL_SYSTEM_IP} remote-as ${AS_ID}
    ${output} =    Read
    ${output} =    Write    vrf ${VPN_NAME[0]}
    ${output} =    Read
    ${output} =    Write    rd ${CREATE_RD[0]}
    ${output} =    Read
    ${output} =    Write    rt import ${CREATE_IMPORT_RT[0]}
    ${output} =    Read
    ${output} =    Write    rt export ${CREATE_EXPORT_RT[0]}
    ${output} =    Read
    ${output} =    Write    write terminal
    ${output} =    Read Until Prompt
    Log    ${output}
    ${output} =    Write    exit
    ${output} =    Read
    ${output} =    Write    address-family vpnv4 unicast
    ${output} =    Read
    ${output} =    Write    network ${LOOPBACK_IP}/32 rd ${CREATE_RD[0]} tag ${AS_ID}
    ${output} =    Read
    ${output} =    Write    neighbor ${ODL_SYSTEM_IP} activate
    ${output} =    Read
    ${output} =    Write    write terminal
    ${output} =    Read Until Prompt
    Log    ${output}
    Log    ${output}
    ${output} =    Write    end
    ${output} =    Read
    Log    ${output}
    ${output} =    Write    exit
    ${output} =    Read
    Log    ${output}

Start Processes on ODL
    [Documentation]    Execute cmd on DCGW and returns the ouput.
    ${dcgw_conn_id}=    SSHLibrary.Open Connection    ${ODL_SYSTEM_1_IP}    prompt=${DEFAULT_LINUX_PROMPT}
    Set Suite Variable    ${dcgw_conn_id}
    Log    ${dcgw_conn_id}
    Utils.Flexible SSH Login    ${DEFAULT_USER}    ${EMPTY}
    SSHLibrary.Set Client Configuration    timeout=${default_devstack_prompt_timeout}
    ${output} =    Write Commands Until Expected Prompt    sudo /opt/quagga/etc/init.d/zrpcd start    ]>
    ${output} =    Write Commands Until Expected Prompt    ps -ef | grep zrpcd    ]>
    #${output} =    Write Commands Until Expected Prompt    cd /opt/quagga/sbin/    ]>
    #Log    ${output}
    #${output} =    Write    sudo ./bgpd &
    ##${output} =    Read Until    pid
    Log    ${output}
    ##${output} =    Write    sudo ./zebra &
    #${output} =    Read
    #Log    ${output}
    #Sleep    2
    #${output} =    Read
    #Log    ${output}
    ${output} =    Write Commands Until Expected Prompt    ps -ef | grep bgpd    ]>
    ${output} =    Write Commands Until Expected Prompt    ps -ef | grep zebra    ]>
    ${output} =    Write Commands Until Expected Prompt    cd /opt/quagga/etc/    ]>
    ${output} =    Write Commands Until Expected Prompt    ls -lrt    ]>
    Log    ${output}

Start Processes on DCGW
    [Documentation]    Execute cmd on DCGW and returns the ouput.
    DCGW Suite Setup
    Switch Connection    ${dcgw_conn_id}
    ${output} =    Write Commands Until Expected Prompt    sudo /opt/quagga/etc/init.d/zrpcd start    ]>
    ${output} =    Read
    ${output} =    Write Commands Until Expected Prompt    ps -ef | grep zrpcd    ]>
    ${output} =    Write Commands Until Expected Prompt    cd /opt/quagga/sbin/    ]>
    Log    ${output}
    ${output} =    Read
    Log    ${output}
    ${output} =    Write Commands Until Expected Prompt    ls -lrt    ]>
    ${output} =    Write    sudo ./bgpd &
    ${output} =    Read Until    pid
    Log    ${output}
    ${output} =    Write    sudo ./zebra &
    ${output} =    Read
    Log    ${output}
    Sleep    2
    ${output} =    Read
    Log    ${output}
    ${output} =    Write Commands Until Expected Prompt    ps -ef | grep bgpd    ]>
    ${output} =    Write Commands Until Expected Prompt    ps -ef | grep zebra    ]>
    ${output} =    Write Commands Until Expected Prompt    cd /opt/quagga/etc/    ]>
    ${output} =    Write Commands Until Expected Prompt    ls -lrt    ]>
    Log    ${output}

Execute Command On DCGW
    [Arguments]    ${cmd}    ${user}=bgpd    ${password}=sdncbgpc
    [Documentation]    Execute cmd on DCGW and returns the ouput.
    Switch Connection    ${dcgw_conn_id}
    ${output} =    Write    telnet localhost ${user}
    Log    ${output}
    ${output} =    Read Until    Password:
    Log    ${output}
    ${output} =    Write    ${password}
    ${output} =    Read
    ${output} =    Write    terminal length 512
    ${output} =    Read
    ${output} =    Write    ${cmd}
    ${output} =    Read
    Log    ${output}
    Write    exit
    Read
    [Return]    ${output}

Add Loopback Interface On DCGW
    [Arguments]    ${ip}    ${user}=zebra    ${password}=zebra
    [Documentation]    Execute cmd on DCGW and returns the ouput.
    Switch Connection    ${dcgw_conn_id}
    ${output} =    Write    telnet localhost ${user}
    Log    ${output}
    ${output} =    Read Until    Password:
    Log    ${output}
    ${output} =    Write    ${password}
    ${output} =    Read
    ${output} =    Write    terminal length 512
    ${output} =    Read
    ${output} =    Write    enable
    ${output} =    Read
    ${output} =    Write    ${password}
    ${output} =    Read
    Set Client Configuration    prompt=#
    ${output} =    Write    configure terminal
    ${output} =    Read
    ${output} =    Write    interface lo
    ${output} =    Read
    ${output} =    Write    ip address ${LOOPBACK_IP}
    ${output} =    Read
    ${output} =    Write    write terminal
    ${output} =    Read
    Log    ${output}
    Write    end
    Read
    Write    exit
    Read
    [Return]    ${output}

Create BGP Configuration
    [Arguments]    &{Kwargs}
    [Documentation]    Associate the created L3VPN to a network-id received as dictionary argument
    TemplatedRequests.Post_As_Json_Templated    folder=${VAR_BASE_BGP}/create_bgp    mapping=${Kwargs}    session=session

AddNeighbor To BGP Configuration
    [Arguments]    &{Kwargs}
    [Documentation]    Associate the created L3VPN to a network-id received as dictionary argument
    TemplatedRequests.Post_As_Json_Templated    folder=${VAR_BASE_BGP}/addNeighbor_bgp    mapping=${Kwargs}    session=session

AddVRF To BGP Configuration
    [Arguments]    &{Kwargs}
    [Documentation]    Associate the created L3VPN to a network-id received as dictionary argument
    TemplatedRequests.Post_As_Json_Templated    folder=${VAR_BASE_BGP}/addVRF_bgp    mapping=${Kwargs}    session=session

Get BGP Configuration
    [Documentation]    Get bgp configuration
    ${resp} =    RequestsLibrary.Get Request    session    ${CONFIG_API}/ebgp:bgp/
    Log    ${resp.content}
    [Return]    ${resp.content}

Delete BGP Configuration
    [Documentation]    Delete BGP
    ${resp} =    RequestsLibrary.Delete Request    session    ${CONFIG_API}/ebgp:bgp/
    Log    ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200
    [Return]    ${resp.content}

Create External Tunnel Endpoint Configuration
    [Arguments]    &{Kwargs}
    [Documentation]    Create Tunnel End point
    TemplatedRequests.Post_As_Json_Templated    folder=${VAR_BASE_BGP}/create_etep    mapping=${Kwargs}    session=session

Delete External Tunnel Endpoint Configuration
    [Arguments]    &{Kwargs}
    [Documentation]    Delete Tunnel End point
    TemplatedRequests.Post_As_Json_Templated    folder=${VAR_BASE_BGP}/delete_etep    mapping=${Kwargs}    session=session

Get External Tunnel Endpoint Configuration
    [Arguments]    ${ip}
    [Documentation]    Get bgp configuration
    ${resp} =    RequestsLibrary.Get Request    session    ${CONFIG_API}/itm:dc-gateway-ip-list/dc-gateway-ip/${ip}/
    Log    ${resp.content}
    [Return]    ${resp.content}

DCGW Suite Setup
    [Documentation]    Login to the DCGW
    ${dcgw_conn_id}=    SSHLibrary.Open Connection    ${DCGW_SYSTEM_IP}    prompt=${DEFAULT_LINUX_PROMPT}
    Set Suite Variable    ${dcgw_conn_id}
    Log    ${dcgw_conn_id}
    Utils.Flexible SSH Login    ${DEFAULT_USER}    ${EMPTY}
    SSHLibrary.Set Client Configuration    timeout=${default_devstack_prompt_timeout}
