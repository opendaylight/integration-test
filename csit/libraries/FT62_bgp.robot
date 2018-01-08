*** Settings ***
Documentation     Openstack library. This library is useful for tests to create network, subnet, router and vm instances
Library           SSHLibrary
Library           Collections
Library           RequestsLibrary
Library           String
Library           OperatingSystem
Resource          BgpOperations.robot
Resource          DevstackUtils.robot
Resource          KarafKeywords.robot
Resource          OpenStackOperations.robot
Resource          OVSDB.robot
Resource          SSHKeywords.robot
Resource          TemplatedRequests.robot
Resource          Utils.robot
Resource          VpnOperations.robot
Resource          ../variables/Variables.robot
Resource          ../variables/ft62_variables/ft62_vars.robot

*** Variables ***

*** Keywords ***
Create L3VPN
    [Arguments]    ${NUM_OF_L3VPN}    ${additional_args}=${EMPTY}    ${verbose}=TRUE
    [Documentation]    Create one or multiple L3VPN and return the detailed list of L3VPN ID received
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

Verify Routes Exchange Between ODL And DCGW
    [Documentation]    Verify  the route exchange for vm ips and loopback ip between ODL and DCGW
    ${fib_values} =    Create List    ${LOOPBACK_IP}    @{VM_IPS}
    Wait Until Keyword Succeeds    60s    15s    Check For Elements At URI    ${CONFIG_API}/odl-fib:fibEntries/vrfTables/${DCGW_RD}/    ${fib_values}
    Wait Until Keyword Succeeds    60s    15s    Verify Routes On Quagga    ${DCGW_SYSTEM_IP}    ${DCGW_RD}    ${fib_values}
    [Teardown]    Run Keywords    Report_Failure_Due_To_Bug    7607
    ...    AND    Get Test Teardown Debugs

Associate L3VPN To Networks
    [Arguments]    ${NUM_OF_NET}    ${additional_args}=${EMPTY}    ${verbose}=TRUE
    [Documentation]    Associate  L3VPN to the number of networks received as an argument
    : FOR    ${index}    IN RANGE    0    ${NUM_OF_NET}
    \    ${network_id} =    Get Net Id    ${REQ_NETWORKS[${index}]}    ${devstack_conn_id}
    \    Associate L3VPN To Network    networkid=${network_id}    vpnid=${VPN_INSTANCE_ID[${index}]}
    \    ${resp}=    VPN Get L3VPN    vpnid=${VPN_INSTANCE_ID[0]}
    \    Should Contain    ${resp}    ${network_id}
