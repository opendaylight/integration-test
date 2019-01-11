*** Settings ***
Documentation     Test Suite for BFD tunnel monitoring
Suite Setup       Genius Suite Setup
Suite Teardown    BFD Suite Teardown
Test Setup        Genius Test Setup
Test Teardown     Genius Test Teardown    ${data_models}
Library           OperatingSystem
Library           String
Library           RequestsLibrary
Library           Collections
Library           SSHLibrary
Resource          ../../libraries/DataModels.robot
Resource          ../../libraries/Genius.robot
Resource          ../../libraries/KarafKeywords.robot
Resource          ../../libraries/OVSDB.robot
Resource          ../../libraries/ToolsSystem.robot
Resource          ../../libraries/Utils.robot
Resource          ../../libraries/VpnOperations.robot
Resource          ../../variables/netvirt/Variables.robot
Resource          ../../variables/Variables.robot
Variables         ../../variables/genius/Modules.py

*** Variables ***
${TUNNEL_MONITOR_ON}    Tunnel Monitoring (for VXLAN tunnels): On
${DEFAULT_MONITORING_INTERVAL}    Tunnel Monitoring Interval (for VXLAN tunnels): 1000
${TUNNEL_MONITOR_OFF}    Tunnel Monitoring (for VXLAN tunnels): Off
${INTERVAL_5000}    {"tunnel-monitor-interval":{"interval":5000}}
${OK_201}         201
${ENABLE_MONITORING}    {"tunnel-monitor-params":{"enabled":true,"monitor-protocol":"odl-interface:tunnel-monitoring-type-bfd"}}
${DISABLE_MONITORING}    {"tunnel-monitor-params":{"enabled":"false","monitor-protocol":"odl-interface:tunnel-monitoring-type-bfd"}}
${TUNNEL_MONI_PARAMS_TRUE}    true
${TUNNEL_MONI_PARAMS_FALSE}    false
${INTERFACE_DS_MONI_FALSE}    "odl-interface:monitor-enabled": false
${INTERFACE_DS_MONI_TRUE}    "odl-interface:monitor-enabled": true
${INTERFACE_DS_MONI_INT_1000}    "odl-interface:monitor-interval": 1000
${INTERFACE_DS_MONI_INT_5000}    "odl-interface:monitor-interval": 5000
${TUNNEL_MONI_PROTO}    tunnel-monitoring-type-bfd

*** Test Cases ***
BFD_TC00 Create ITM between DPNs Verify_BFD_Enablement
    [Documentation]    Create ITM between DPNs Verify_BFD_Enablement
    Genius.Create Vteps    ${NO_VLAN}    ${gateway_ip}
    Wait Until Keyword Succeeds    30s    5s    Genius.Verify Tunnel Status As Up

BFD_TC01 Verify by default BFD monitoring is enabled on Controller
    [Documentation]    Verify by default BFD monitoring is enabled on Controller
    Wait Until Keyword Succeeds    10s    2s    Verify Tunnel Monitoring Is On
    Wait Until Keyword Succeeds    10s    2s    Verify Config Ietf Interface Output    ${INTERFACE_DS_MONI_TRUE}    ${INTERFACE_DS_MONI_INT_1000}    ${TUNNEL_MONI_PROTO}

BFD_TC02 Verify that BFD tunnel monitoring interval is set with appropriate default value i.e.,1000
    [Documentation]    This will verify BFD tunnel monitoring default interval
    ${output} =    Issue Command On Karaf Console    ${TEP_SHOW}
    ${tunnel_monitoring} =    Get Lines Containing String    ${output}    Tunnel Monitoring Interval
    Should Be Equal    ${tunnel_monitoring}    ${DEFAULT_MONITORING_INTERVAL}
    Wait Until Keyword Succeeds    10s    2s    Verify Config Ietf Interface Output    ${INTERFACE_DS_MONI_TRUE}    ${INTERFACE_DS_MONI_INT_1000}    ${TUNNEL_MONI_PROTO}

BFD_TC04 Verify that in controller tunnel status is up when ITM tunnel interface is brought up.
    [Documentation]    Verify that in controller tunnel status is up when ITM tunnel interface is brought up.
    Wait Until Keyword Succeeds    10s    2s    Verify Tunnel Monitoring Is On
    Wait Until Keyword Succeeds    10s    1s    Verify Tunnel Status As Up
    Wait Until Keyword Succeeds    10s    2s    Verify Config Ietf Interface Output    ${INTERFACE_DS_MONI_TRUE}    ${INTERFACE_DS_MONI_INT_1000}    ${TUNNEL_MONI_PROTO}

BFD_TC05 Verify BFD tunnel monitoring interval can be changed.
    [Documentation]    Verify BFD tunnel monitoring interval can be changed.
    ${oper_int}    RequestsLibrary.Put Request    session    ${CONFIG_API}/itm-config:tunnel-monitor-interval/    data=${INTERVAL_5000}
    ${Bfd_updated_value}=    Create List    5000
    Wait Until Keyword Succeeds    30s    10s    Check For Elements At URI    ${OPERATIONAL_API}/itm-config:tunnel-monitor-interval/    ${Bfd_updated_value}
    Wait Until Keyword Succeeds    30s    10s    Check For Elements At URI    ${CONFIG_API}/itm-config:tunnel-monitor-interval/    ${Bfd_updated_value}
    Wait Until Keyword Succeeds    10s    2s    Verify Config Ietf Interface Output    ${INTERFACE_DS_MONI_TRUE}    ${INTERFACE_DS_MONI_INT_5000}    ${TUNNEL_MONI_PROTO}
    : FOR    ${tool_system_index}    IN RANGE    ${NUM_TOOLS_SYSTEM}
    \    ${tun_names}    Genius.Get Tunnels On OVS    ${TOOLS_SYSTEM_ALL_CONN_IDS[${tool_system_index}]}
    \    Verify ovs-vsctl Output For Each Tunnel    ${tun_names}    ${tool_system_index}

BFD_TC06 Verify that the tunnel state goes to UNKNOWN when DPN is disconnected
    [Documentation]    Verify that the tunnel state goes to UNKNOWN when DPN is disconnected
    Issue_Command_On_Karaf_Console    ${TEP_SHOW}
    Issue_Command_On_Karaf_Console    ${TEP_SHOW_STATE}
    ToolsSystem.Run Command On All Tools Systems    sudo ovs-vsctl del-controller ${Bridge}
    Issue_Command_On_Karaf_Console    ${TEP_SHOW}
    Issue_Command_On_Karaf_Console    ${TEP_SHOW_STATE}
    Wait Until Keyword Succeeds    10s    1s    Verify Tunnel Status as UNKNOWN
    Wait Until Keyword Succeeds    10s    2s    Verify Config Ietf Interface Output    ${INTERFACE_DS_MONI_TRUE}    ${INTERFACE_DS_MONI_INT_5000}    ${TUNNEL_MONI_PROTO}
    ToolsSystem.Run Command On All Tools Systems    sudo ovs-vsctl set-controller ${Bridge} tcp:${ODL_SYSTEM_IP}:${ODL_OF_PORT}
    Issue_Command_On_Karaf_Console    ${TEP_SHOW}
    Issue_Command_On_Karaf_Console    ${TEP_SHOW_STATE}
    Wait Until Keyword Succeeds    10s    1s    Genius.Verify Tunnel Status As Up
    Wait Until Keyword Succeeds    10s    2s    Verify Config Ietf Interface Output    ${INTERFACE_DS_MONI_TRUE}    ${INTERFACE_DS_MONI_INT_5000}    ${TUNNEL_MONI_PROTO}

BFD_TC07 Verify that BFD monitoring is disabled on Controller
    [Documentation]    Verify that BFD monitoring is disabled on Controller
    ${resp}    RequestsLibrary.Put Request    session    ${CONFIG_API}/itm-config:tunnel-monitor-params/    data=${DISABLE_MONITORING}
    Should Be Equal As Strings    ${resp.status_code}    201
    Wait Until Keyword Succeeds    10s    2s    Verify Tunnel Monitoring Params    ${TUNNEL_MONI_PARAMS_FALSE}
    ${output}=    Issue_Command_On_Karaf_Console    ${TEP_SHOW}
    Should Contain    ${output}    ${TUNNEL_MONITOR_OFF}
    Wait Until Keyword Succeeds    10s    2s    Verify Config Ietf Interface Output    ${INTERFACE_DS_MONI_FALSE}    ${INTERFACE_DS_MONI_INT_5000}    ${TUNNEL_MONI_PROTO}
    Wait Until Keyword Succeeds    10s    1s    Genius.Verify Tunnel Status As Up
    ${resp}    RequestsLibrary.Put Request    session    ${CONFIG_API}/itm-config:tunnel-monitor-params/    data=${ENABLE_MONITORING}
    Should Be Equal As Strings    ${resp.status_code}    200
    Wait Until Keyword Succeeds    10s    2s    Verify Tunnel Monitoring Params    ${TUNNEL_MONI_PARAMS_TRUE}
    Wait Until Keyword Succeeds    10s    2s    Verify Tunnel Monitoring Is On
    Wait Until Keyword Succeeds    10s    2s    Verify Config Ietf Interface Output    ${INTERFACE_DS_MONI_TRUE}    ${INTERFACE_DS_MONI_INT_5000}    ${TUNNEL_MONI_PROTO}

*** Keywords ***
Verify Config Ietf Interface Output
    [Arguments]    ${state}    ${interval}    ${proto}
    [Documentation]    This keyword will get request from config ietf interface and verifies state, interval and proto are present
    ${int_resp}    RequestsLibrary.Get Request    session    ${CONFIG_API}/ietf-interfaces:interfaces/
    ${respjson}    RequestsLibrary.To Json    ${int_resp.content}    pretty_print=True
    Should Contain    ${respjson}    ${state}
    Should Contain    ${respjson}    ${interval}
    Should Contain    ${respjson}    ${proto}

Ovs Tunnel Get
    [Arguments]    ${tools_ip}
    [Documentation]    This keyword will return the tunnel name on OVS
    ${list_interface}    Utils.Run Command On Remote System    ${tools_ip}    sudo ovs-vsctl list interface
    ${tun_line}    ${tun_name}    Should Match Regexp    ${list_interface}    name\\s+: "(tun.*)"
    Log    ${tun_name}
    Should Not Be Empty    ${tun_name}
    [Return]    ${tun_name}

Verify Tunnel Monitoring Params
    [Arguments]    ${flag}
    [Documentation]    This keyword will verify the tunnel monitoring is true or false
    @{checklist}    BuiltIn.Create List    ${flag}
    Check For Elements At URI    ${OPERATIONAL_API}/itm-config:tunnel-monitor-params/    ${checklist}

Verify ovs-vsctl Output For Each Tunnel
    [Arguments]    ${tun_names}    ${tool_system_index}
    ${no.of tunnels}    BuiltIn.Get Length    ${tun_names}
    : FOR    ${each_tun}    IN RANGE    ${no.of tunnels}
    \    ${tun}    Collections.Get From List    ${tun_names}    ${each_tun}
    \    BuiltIn.Wait Until Keyword Succeeds    20    5    OVSDB.Verify Ovs-vsctl Output    list interface ${tun}    5000
    \    ...    ovs_system=@{TOOLS_SYSTEM_ALL_IPS}[${tool_system_index}]
