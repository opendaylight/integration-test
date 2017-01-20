*** Settings ***
Documentation     Test suite to validate vpnservice functionality in an openstack integrated environment.
...               The assumption of this suite is that the environment is already configured with the proper
...               integration bridges and vxlan tunnels.
Suite Setup       BuiltIn.Run Keywords    SetupUtils.Setup_Utils_For_Setup_And_Teardown
...               AND    DevstackUtils.Devstack Suite Setup
...               AND    Enable ODL Karaf Log
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

*** Test Cases ***
Trial Testcase for Vpn Service Patch Verification
    [Documentation]    Delete router with nonExistentRouter name
    ${devstack_conn_id}=    Get ControlNode Connection
    Switch Connection    ${devstack_conn_id}
    ${output} =    Write Commands Until Prompt    neutron net-list | grep A
    Log     ${output}
    ${output} =    Write Commands Until Prompt    echo trial print2
    Log     ${output}
    ${output} =    Write Commands Until Prompt    echo trial print3
    Log     ${output}
    ${output} =    Write Commands Until Prompt    neutron net-list | grep B
    Log     ${output}
    ${output} =    Write Commands Until Prompt    echo trial print5
    Log     ${output}
    ${output} =    Write Commands Until Prompt    echo trial print6
    Log     ${output}
    ${output} =    Write Commands Until Prompt    neutron net-list | grep C
    Log     ${output}
    ${output} =    Write Commands Until Prompt    echo trial print8
    Log     ${output}
    ${output} =    Write Commands Until Prompt    echo trial print9
    Log     ${output}
    ${output} =    Write Commands Until Prompt    neutron net-list | grep D
    Log     ${output}
    ${output} =    Write Commands Until Prompt    echo trial print11
    Log     ${output}
    ${output} =    Write Commands Until Prompt    echo trial print12
    Log     ${output}
    ${output} =    Write Commands Until Prompt    neutron net-list | grep E
    Log     ${output}
    ${output} =    Write Commands Until Prompt    echo trial print14
    Log     ${output}
    ${output} =    Write Commands Until Prompt    neutron net-list | grep F
    Log     ${output}
    ${output} =    Write Commands Until Prompt    neutron net-list | grep G
    Log     ${output}
    ${output} =    Write Commands Until Prompt    echo trial print17
    Log     ${output}
    ${output} =    Write Commands Until Prompt    echo trial print18
    Log     ${output}
    ${output} =    Write Commands Until Prompt    echo trial print19
    Log     ${output}
    ${output} =    Write Commands Until Prompt    echo trial print20
    Log     ${output}
    ${output} =    Write Commands Until Prompt    echo trial print21
    Log     ${output}
    ${output} =    Write Commands Until Prompt    echo trial print22
    Log     ${output}
    ${output} =    Write Commands Until Prompt    echo trial print23
    Log     ${output}
    ${output} =    Write Commands Until Prompt    echo trial print24
    Log     ${output}
    ${output} =    Write Commands Until Prompt    echo trial print25
    Log     ${output}
    Close Connection

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

Enable ODL Karaf Log
    [Documentation]    Uses log:set TRACE org.opendaylight.netvirt to enable log
    Log    "Enabled ODL Karaf log for org.opendaylight.netvirt"
    ${output}=    Issue Command On Karaf Console    log:set TRACE org.opendaylight.netvirt
    Log    ${output}
