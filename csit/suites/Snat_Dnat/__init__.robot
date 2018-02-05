*** Settings ***
Documentation     Test Suite for SDN L3 Forwarding services
Suite Setup       Start Suite
Suite Teardown    Stop Suite
Library           DebugLibrary
Library           OperatingSystem
Library           RequestsLibrary
Library           String
Resource          ../../libraries/OpenStackOperations.robot
Resource          ../../libraries/DevstackUtils.robot
Resource          ../../libraries/SetupUtils.robot
Resource          ../../libraries/KarafKeywords.robot
Resource          ../../libraries/OVSDB.robot
Resource          ../../libraries/VpnOperations.robot
Resource          ../../libraries/BgpOperations.robot
Resource          ../../variables/Variables.robot

*** Keywords ***
Start Suite
    [Documentation]    Test Suite for SDN L3 Forwarding services
    DevstackUtils.Devstack Suite Setup
    Create External Tunnel Endpoint Configuration
    BgpOperations.Start Quagga Processes On ODL    ${ODL_SYSTEM_IP}
    BgpOperations.Start Quagga Processes On DCGW    ${DCGW_SYSTEM_IP}
    BgpOperations.Create BGP Configuration On ODL    localas=${AS_ID}    routerid=${ODL_SYSTEM_IP}
    Create BGP Config On DCGW    
    Wait Until Keyword Succeeds 60s, 10s  Verify Tunnel Status as UP
    

Stop Suite
    [Documentation]    Run after the tests execution
    Close All Connections


Create BGP Config On DCGW
    [Documentation]    Configure BGP on DCGW
    Configure BGP And Add Neighbor On DCGW    ${DCGW_SYSTEM_IP}    ${AS_ID}    ${DCGW_SYSTEM_IP}    ${ODL_SYSTEM_IP}    ${VPN_NAME[0]}    ${DCGW_RD}
    ...    ${LOOPBACK_IP}
    Add Loopback Interface On DCGW    ${DCGW_SYSTEM_IP}    lo    ${LOOPBACK_IP}
    Add Loopback Interface On DCGW    ${DCGW_SYSTEM_IP}    lo1    ${LOOPBACK_IP1}
    ${output} =    Execute Show Command On Quagga    ${DCGW_SYSTEM_IP}    show running-config
    Log    ${output}
    ${output} =    Wait Until Keyword Succeeds    180s    10s    Verify BGP Neighbor Status On Quagga    ${DCGW_SYSTEM_IP}    ${ODL_SYSTEM_IP}
    Log    ${output}
    ${output1} =    Execute Show Command On Quagga    ${DCGW_SYSTEM_IP}    show ip bgp vrf ${DCGW_RD}
    Log    ${output1}

