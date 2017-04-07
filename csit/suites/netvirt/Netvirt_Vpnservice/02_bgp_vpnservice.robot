*** Settings ***
Documentation     Test suite to validate BGP vpnservice functionality in an openstack integrated environment.
...               The assumption of this suite is that the environment is already configured with the proper
...               integration bridges and vxlan tunnels.
Suite Setup       BGP Vpnservice Suite Setup
Suite Teardown    BGP Vpnservice Suite Teardown
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
Resource          ../../../libraries/BgpOperations.robot
Resource          ../../../variables/Variables.robot
Resource          ../../../variables/netvirt/Variables.robot

*** Variables ***
@{NETWORKS}       NET101    NET102    NET103    NET104
@{SUBNETS}        SUBNET101    SUBNET102    SUBNET103    SUBNET104
@{SUBNET_CIDR}    101.1.1.0/8    102.1.1.0/16    103.1.1.0/24    104.1.1.0/24
@{PORTS}          PORT101    PORT102    PORT103    PORT104
@{VM_NAMES}       VM101    VM102    VM103    VM104
@{VPN_INSTANCE_IDS}    4ae8cd92-48ca-49b5-94e1-b2921a261111    4ae8cd92-48ca-49b5-94e1-b2921a261112
@{RD_LIST}        ["2200:2"]    ["2300:2"]
@{VPN_NAMES}      vpn101    vpn102
${LOOPBACK_IP}    5.5.5.2
${DCGW_SYSTEM_IP}    ${TOOLS_SYSTEM_1_IP}
${AS_ID}          500
${DCGW_RD}        2200:2
${SG_NAME}        sg_bgp_vpnservice

*** Test Cases ***
Create BGP Config On ODL
    [Documentation]    Create BGP Config on ODL
    Create BGP Configuration On ODL    localas=${AS_ID}    routerid=${ODL_SYSTEM_IP}
    AddNeighbor To BGP Configuration On ODL    remoteas=${AS_ID}    neighborAddr=${DCGW_SYSTEM_IP}
    ${output} =    Get BGP Configuration On ODL    session
    Log    ${output}
    Should Contain    ${output}    ${DCGW_SYSTEM_IP}

Create BGP Config On DCGW
    [Documentation]    Configure BGP Config on DCGW
    Configure BGP And Add Neighbor On DCGW    ${DCGW_SYSTEM_IP}    ${AS_ID}    ${DCGW_SYSTEM_IP}    ${ODL_SYSTEM_IP}    ${VPN_NAMES[0]}    ${DCGW_RD}
    ...    ${LOOPBACK_IP}
    Add Loopback Interface On DCGW    ${DCGW_SYSTEM_IP}    lo    ${LOOPBACK_IP}
    ${output} =    Execute Show Command On Quagga    ${DCGW_SYSTEM_IP}    show running-config
    Log    ${output}
    Should Contain    ${output}    ${ODL_SYSTEM_IP}

Verify BGP Neighbor Status
    [Documentation]    Verify BGP status established
    ${output} =    Wait Until Keyword Succeeds    60s    10s    Verify BGP Neighbor Status On Quagga    ${DCGW_SYSTEM_IP}    ${ODL_SYSTEM_IP}
    Log    ${output}
    ${output1} =    Execute Show Command On Quagga    ${DCGW_SYSTEM_IP}    show ip bgp vrf ${DCGW_RD}
    Log    ${output1}
    Should Contain    ${output1}    ${LOOPBACK_IP}

Create External Tunnel Endpoint
    [Documentation]    Create and verify external tunnel endpoint between ODL and GWIP
    Create External Tunnel Endpoint Configuration    destIp=${DCGW_SYSTEM_IP}
    ${output} =    Get External Tunnel Endpoint Configuration    ${DCGW_SYSTEM_IP}
    Should Contain    ${output}    ${DCGW_SYSTEM_IP}

Verify Routes Exchange Between ODL And DCGW
    [Documentation]    Verify routes exchange between ODL and DCGW
    ${fib_values} =    Create List    ${LOOPBACK_IP}    @{VM_IPS}
    Wait Until Keyword Succeeds    60s    5s    Check For Elements At URI    ${CONFIG_API}/odl-fib:fibEntries/vrfTables/${DCGW_RD}/    ${fib_values}
    Wait Until Keyword Succeeds    60s    5s    Verify Routes On Quagga    ${DCGW_SYSTEM_IP}    ${DCGW_RD}    ${fib_values}
    [Teardown]    Run Keywords    Report_Failure_Due_To_Bug    7607
    ...    AND    Get Test Teardown Debugs

Delete External Tunnel Endpoint
    [Documentation]    Delete external tunnel endpoint
    Delete External Tunnel Endpoint Configuration    destIp=${DCGW_SYSTEM_IP}
    ${output} =    Get External Tunnel Endpoint Configuration    ${DCGW_SYSTEM_IP}
    Should Not Contain    ${output}    ${DCGW_SYSTEM_IP}

Delete BGP Config On ODL
    [Documentation]    Delete BGP Configuration on ODL
    Delete BGP Configuration On ODL    session
    ${output} =    Get BGP Configuration On ODL    session
    Log    ${output}
    Should Not Contain    ${output}    ${DCGW_SYSTEM_IP}
    Run Command On Remote System    ${ODL_SYSTEM_IP}    sudo cp /opt/quagga/var/log/quagga/zrpcd.init.log /tmp/

Delete BGP Config On DCGW
    [Documentation]    Delete BGP Configuration on DCGW
    ${output} =    Delete BGP Config On Quagga    ${DCGW_SYSTEM_IP}    ${AS_ID}
    Log    ${output}
    Should Not Contain    ${output}    ${ODL_SYSTEM_IP}

*** Keywords ***
BGP Vpnservice Suite Setup
    SetupUtils.Setup_Utils_For_Setup_And_Teardown
    DevstackUtils.Devstack Suite Setup
    Create And Configure Security Group    ${SG_NAME}
    Start Quagga Processes On ODL    ${ODL_SYSTEM_IP}
    Start Quagga Processes On DCGW    ${DCGW_SYSTEM_IP}
    Create Basic Configuartion for BGP VPNservice Suite

BGP Vpnservice Suite Teardown
    Delete Basic Configuartion for BGP VPNservice Suite
    Delete SecurityGroup    ${SG_NAME}
    Close All Connections

Create Basic Configuartion for BGP VPNservice Suite
    [Documentation]    Create basic configuration for BGP VPNservice suite
    Start Quagga Processes On ODL    ${ODL_SYSTEM_IP}
    : FOR    ${Network}    IN    @{NETWORKS}
    \    Create Network    ${Network}
    Wait Until Keyword Succeeds    3s    1s    Check For Elements At URI    ${NETWORK_URL}    ${NETWORKS}
    ${length}=    Get Length    ${SUBNETS}
    : FOR    ${idx}    IN RANGE    ${length}
    \    Create SubNet    ${NETWORKS[${idx}]}    ${SUBNETS[${idx}]}    ${SUBNET_CIDR[${idx}]}
    Wait Until Keyword Succeeds    3s    1s    Check For Elements At URI    ${SUBNETWORK_URL}    ${SUBNETS}
    : FOR    ${network}    ${port}    IN ZIP    ${NETWORKS}    ${PORTS}
    \    Create Port    ${network}    ${port}    sg=${SG_NAME}
    Wait Until Keyword Succeeds    3s    1s    Check For Elements At URI    ${PORT_URL}    ${PORTS}
    Create Vm Instance With Port On Compute Node    ${PORTS[0]}    ${VM_NAMES[0]}    ${OS_COMPUTE_1_IP}    sg=${SG_NAME}
    Create Vm Instance With Port On Compute Node    ${PORTS[1]}    ${VM_NAMES[1]}    ${OS_COMPUTE_1_IP}    sg=${SG_NAME}
    Create Vm Instance With Port On Compute Node    ${PORTS[2]}    ${VM_NAMES[2]}    ${OS_COMPUTE_2_IP}    sg=${SG_NAME}
    Create Vm Instance With Port On Compute Node    ${PORTS[3]}    ${VM_NAMES[3]}    ${OS_COMPUTE_2_IP}    sg=${SG_NAME}
    : FOR    ${VM}    IN    @{VM_NAMES}
    \    Wait Until Keyword Succeeds    25s    5s    Verify VM Is ACTIVE    ${VM}
    ${VM_IPS}    ${DHCP_IPS}    Wait Until Keyword Succeeds    30s    10s    Collect VM IP Addresses    true
    ...    @{VM_NAMES}
    Log    ${VM_IPS}
    Set Suite Variable    ${VM_IPS}
    ${devstack_conn_id} =    Get ControlNode Connection
    Switch Connection    ${devstack_conn_id}
    ${net_id} =    Get Net Id    @{NETWORKS}[0]    ${devstack_conn_id}
    ${tenant_id} =    Get Tenant ID From Network    ${net_id}
    VPN Create L3VPN    vpnid=${VPN_INSTANCE_IDS[0]}    name=${VPN_NAMES[0]}    rd=${RD_LIST[0]}    exportrt=${RD_LIST[0]}    importrt=${RD_LIST[0]}    tenantid=${tenant_id}
    : FOR    ${network}    IN    @{NETWORKS}
    \    ${network_id} =    Get Net Id    ${network}    ${devstack_conn_id}
    \    Associate L3VPN To Network    networkid=${network_id}    vpnid=${VPN_INSTANCE_IDS[0]}
    ${resp} =    VPN Get L3VPN    vpnid=${VPN_INSTANCE_IDS[0]}
    Log    ${resp}

Delete Basic Configuartion for BGP VPNservice Suite
    [Documentation]    Delete basic configuration for BGP Vpnservice suite
    ${devstack_conn_id} =    Get ControlNode Connection
    : FOR    ${network}    IN    @{NETWORKS}
    \    ${network_id} =    Get Net Id    ${network}    ${devstack_conn_id}
    \    Dissociate L3VPN From Networks    networkid=${network_id}    vpnid=${VPN_INSTANCE_IDS[0]}
    VPN Delete L3VPN    vpnid=${VPN_INSTANCE_IDS[0]}
    : FOR    ${vmName}    IN    @{VM_NAMES}
    \    Delete Vm Instance    ${vmName}
    : FOR    ${port}    IN    @{PORTS}
    \    Delete Port    ${port}
    : FOR    ${Subnet}    IN    @{SUBNETS}
    \    Delete SubNet    ${Subnet}
    : FOR    ${Network}    IN    @{NETWORKS}
    \    Delete Network    ${Network}
