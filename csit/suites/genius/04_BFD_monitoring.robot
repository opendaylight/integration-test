*** Settings ***
Documentation     Test Suite for BFD tunnel monitoring
Suite Setup       Create Session    session    http://${ODL_SYSTEM_IP}:${RESTCONFPORT}    auth=${AUTH}    headers=${HEADERS}
Suite Teardown    Delete All Sessions
Library           OperatingSystem
Library           String
Library           RequestsLibrary
Library           Collections
Library           re
Library           SSHLibrary
Variables         ../../variables/Variables.py
Resource          ../../libraries/Utils.robot
Resource          ../../libraries/VpnOperations.robot
Resource          ../../libraries/KarafKeywords.robot

*** Variables ***
@{itm_created}    TZA
${genius_config_dir}    ${CURDIR}/../../variables/genius
${Bridge-1}       BR1
${Bridge-2}       BR2
${TEP_SHOW}       tep:show
${TEP_SHOW_STATE}    tep:show-state
${TUNNEL_MONITOR_ON}    Tunnel Monitoring (for VXLAN tunnels): On
${DEFAULT_MONITORING_INTERVAL}    Tunnel Monitoring Interval (for VXLAN tunnels): 1000
${TUNNEL_MONITOR_OFF}    Tunnel Monitoring (for VXLAN tunnels): Off
${INTERVAL_5000}    {"tunnel-monitor-interval":{"interval":5000}}
${OK_201}         201
${ENABLE_MONITORING}    {"tunnel-monitor-params":{"enabled":true,"monitor-protocol":"odl-interface:tunnel-monitoring-type-bfd"}}
${DISABLE_MONITORING}    {"tunnel-monitor-params":{"enabled":"false","monitor-protocol":"odl-interface:tunnel-monitoring-type-bfd"}}
${INTERFACE_DS_MON_FALSE}    "odl-interface:monitor-enabled": false
${INTERFACE_DS_MON_TRUE}    "odl-interface:monitor-enabled": true
${INTERFACE_DS_MONI_INT_1000}    "odl-interface:monitor-interval": 1000
${INTERFACE_DS_MONI_INT_5000}    "odl-interface:monitor-interval": 5000
${TUNNEL_MONI_PROTO}    tunnel-monitoring-type-bfd

*** Test Cases ***
BFD_TC00 Create ITM between DPNs Verify_BFD_Enablement
    [Documentation]    Create ITM between DPNs Verify_BFD_Enablement
    ${Dpn_id_1}    Get Dpn Ids    ${conn_id_1}
    ${Dpn_id_2}    Get Dpn Ids    ${conn_id_2}
    Set Global Variable    ${Dpn_id_1}
    Set Global Variable    ${Dpn_id_2}
    ${vlan}=    Set Variable    0
    ${gateway-ip}=    Set Variable    0.0.0.0
    Create Vteps    ${TOOLS_SYSTEM_IP}    ${TOOLS_SYSTEM_2_IP}    ${vlan}    ${gateway-ip}
    SLEEP    5
    Wait Until Keyword Succeeds    30s    5s    Verify Tunnel Status as UP
    SLEEP    5

BFD_TC01 Verify by default BFD monitoring is enabled on Controller
    [Documentation]    Verify by default BFD monitoring is enabled on Controller
    ${output}=    Issue Command On Karaf Console    ${TEP_SHOW}
    Log    ${output}
    Should Contain    ${output}    ${TUNNEL_MONITOR_ON}
    ${int_resp}    RequestsLibrary.Get Request    session    ${CONFIG_API}/ietf-interfaces:interfaces/
    ${respjson}    RequestsLibrary.To Json    ${int_resp.content}    pretty_print=True
    Log    ${respjson}
    Should Contain    ${respjson}    ${INTERFACE_DS_MON_TRUE}
    Should Contain    ${respjson}    ${INTERFACE_DS_MONI_INT_1000}
    Should Contain    ${respjson}    ${TUNNEL_MONI_PROTO}

BFD_TC02 Verify that BFD tunnel monitoring interval is set with appropriate default value i.e.,1000
    [Documentation]    This will verify BFD tunnel monitoring default interval
    ${output}=    Issue Command On Karaf Console    ${TEP_SHOW}
    Log    ${output}
    Should Contain    ${output}    ${DEFAULT_MONITORING_INTERVAL}
    ${int_resp}    RequestsLibrary.Get Request    session    ${CONFIG_API}/ietf-interfaces:interfaces/
    ${respjson}    RequestsLibrary.To Json    ${int_resp.content}    pretty_print=True
    Log    ${respjson}
    Should Contain    ${respjson}    ${INTERFACE_DS_MON_TRUE}
    Should Contain    ${respjson}    ${INTERFACE_DS_MONI_INT_1000}
    Should Contain    ${respjson}    ${TUNNEL_MONI_PROTO}

BFD_TC04 Verify that in controller tunnel status is up when ITM tunnel interface is brought up.
    [Documentation]    Verify that in controller tunnel status is up when ITM tunnel interface is brought up.
    Log    Verifying the BFD based tunnel configuration
    ${output}=    Issue Command On Karaf Console    ${TEP_SHOW}
    Log    ${output}
    Should Contain    ${output}    ${TUNNEL_MONITOR_ON}
    Log    Verifying the tunnel state with show state command
    Wait Until Keyword Succeeds    30s    5s    Verify Tunnel Status as UP
    ${int_resp}    RequestsLibrary.Get Request    session    ${CONFIG_API}/ietf-interfaces:interfaces/
    ${respjson}    RequestsLibrary.To Json    ${int_resp.content}    pretty_print=True
    Log    ${respjson}
    Should Contain    ${respjson}    ${INTERFACE_DS_MON_TRUE}
    Should Contain    ${respjson}    ${INTERFACE_DS_MONI_INT_1000}
    Should Contain    ${respjson}    ${TUNNEL_MONI_PROTO}

BFD_TC05 Verify BFD tunnel monitoring interval can be changed.
    [Documentation]    Verify BFD tunnel monitoring interval can be changed.
    Log    "Value of BFD monitoring interval before updating with new value"
    ${oper_int}    RequestsLibrary.Get Request    session    ${OPERATIONAL_API}/itm-config:tunnel-monitor-interval/
    ${respjson}    RequestsLibrary.To Json    ${oper_int.content}    pretty_print=True
    Log    ${respjson}
    Log    "Value of BFD monitoring interval is getting updated"
    ${oper_int}    RequestsLibrary.Put Request    session    ${CONFIG_API}/itm-config:tunnel-monitor-interval/    data=${INTERVAL_5000}
    SLEEP    5
    Log    "Value of BFD monitoring interval in OPERATIONAL datastore after updating with new value"
    ${oper_int}    RequestsLibrary.Get Request    session    ${OPERATIONAL_API}/itm-config:tunnel-monitor-interval/
    ${respjson}    RequestsLibrary.To Json    ${oper_int.content}    pretty_print=True
    Log    ${respjson}
    Should Contain    ${respjson}    5000
    Log    "Value of BFD monitoring interval in CONFIG datastore after updating with new value"
    ${config_int}    RequestsLibrary.Get Request    session    ${CONFIG_API}/itm-config:tunnel-monitor-interval/
    ${respjson}    RequestsLibrary.To Json    ${config_int.content}    pretty_print=True
    Log    ${respjson}
    Should Contain    ${respjson}    5000
    ${int_resp}    RequestsLibrary.Get Request    session    ${CONFIG_API}/ietf-interfaces:interfaces/
    ${respjson}    RequestsLibrary.To Json    ${int_resp.content}    pretty_print=True
    Log    ${respjson}
    Should Contain    ${respjson}    ${INTERFACE_DS_MON_TRUE}
    Should Contain    ${respjson}    ${INTERFACE_DS_MONI_INT_5000}
    Should Contain    ${respjson}    ${TUNNEL_MONI_PROTO}

BFD_TC06 Verify that the tunnel state goes to UNKNOWN when DPN is disconnected
    [Documentation]    Verify that the tunnel state goes to UNKNOWN when DPN is disconnected
    Log    "Before disconnecting CSS with controller"
    ${output}=    Issue Command On Karaf Console    ${TEP_SHOW}
    Log    ${output}
    ${output}=    Issue Command On Karaf Console    ${TEP_SHOW_STATE}
    Log    ${output}
    Log    "Disconnecting both CSS with controller"
    SSHLibrary.Switch Connection    ${conn_id_1}
    Execute Command    sudo ovs-vsctl del-controller BR1
    SLEEP    2
    SSHLibrary.Switch Connection    ${conn_id_2}
    Execute Command    sudo ovs-vsctl del-controller BR2
    SLEEP    10
    Log    "After disconnecting CSS with controller"
    ${output}=    Issue Command On Karaf Console    ${TEP_SHOW}
    Log    ${output}
    ${output}=    Issue Command On Karaf Console    ${TEP_SHOW_STATE}
    Log    ${output}
    Wait Until Keyword Succeeds    30s    5s    Verify Tunnel Status as UNKNOWN
    ${int_resp}    RequestsLibrary.Get Request    session    ${CONFIG_API}/ietf-interfaces:interfaces/
    ${respjson}    RequestsLibrary.To Json    ${int_resp.content}    pretty_print=True
    Log    ${respjson}
    Should Contain    ${respjson}    ${INTERFACE_DS_MON_TRUE}
    Should Contain    ${respjson}    ${INTERFACE_DS_MONI_INT_5000}
    Should Contain    ${respjson}    ${TUNNEL_MONI_PROTO}
    Log    "Connecting both CSS with controller once again"
    SSHLibrary.Switch Connection    ${conn_id_1}
    Execute Command    sudo ovs-vsctl set-controller BR1 tcp:${ODL_SYSTEM_IP}:6633
    SLEEP    2
    SSHLibrary.Switch Connection    ${conn_id_2}
    Execute Command    sudo ovs-vsctl set-controller BR2 tcp:${ODL_SYSTEM_IP}:6633
    SLEEP    10
    Log    "After connecting CSS with controller"
    ${output}=    Issue Command On Karaf Console    ${TEP_SHOW}
    Log    ${output}
    ${output}=    Issue Command On Karaf Console    ${TEP_SHOW_STATE}
    Log    ${output}
    Wait Until Keyword Succeeds    30s    5s    Verify Tunnel Status as UP
    ${int_resp}    RequestsLibrary.Get Request    session    ${CONFIG_API}/ietf-interfaces:interfaces/
    ${respjson}    RequestsLibrary.To Json    ${int_resp.content}    pretty_print=True
    Log    ${respjson}
    Should Contain    ${respjson}    ${INTERFACE_DS_MON_TRUE}
    Should Contain    ${respjson}    ${INTERFACE_DS_MONI_INT_5000}
    Should Contain    ${respjson}    ${TUNNEL_MONI_PROTO}

BFD_TC07 Verify that BFD monitoring is disabled on Controller
    [Documentation]    Verify that BFD monitoring is disabled on Controller
    ${resp}    RequestsLibrary.Put Request    session    ${CONFIG_API}/itm-config:tunnel-monitor-params/    data=${DISABLE_MONITORING}
    SLEEP    5
    ${oper}    RequestsLibrary.Get Request    session    ${OPERATIONAL_API}/itm-config:tunnel-monitor-params/
    Log    ${oper}
    ${respjson}    RequestsLibrary.To Json    ${oper.content}    pretty_print=True
    Log    ${respjson}
    Should Contain    ${respjson}    false
    ${output}=    Issue Command On Karaf Console    ${TEP_SHOW}
    Log    ${output}
    Should Contain    ${output}    ${TUNNEL_MONITOR_OFF}
    ${int_resp}    RequestsLibrary.Get Request    session    ${CONFIG_API}/ietf-interfaces:interfaces/
    ${respjson}    RequestsLibrary.To Json    ${int_resp.content}    pretty_print=True
    Log    ${respjson}
    Should Contain    ${respjson}    ${INTERFACE_DS_MON_FALSE}
    Should Contain    ${respjson}    ${INTERFACE_DS_MONI_INT_5000}
    Should Contain    ${respjson}    ${TUNNEL_MONI_PROTO}
    Log    "Enabling tunnel monitoring once again"
    ${resp}    RequestsLibrary.Put Request    session    ${CONFIG_API}/itm-config:tunnel-monitor-params/    data=${ENABLE_MONITORING}
    SLEEP    5
    ${oper}    RequestsLibrary.Get Request    session    ${OPERATIONAL_API}/itm-config:tunnel-monitor-params/
    Log    ${oper}
    ${respjson}    RequestsLibrary.To Json    ${oper.content}    pretty_print=True
    Log    ${respjson}
    Should Contain    ${respjson}    true
    ${output}=    Issue Command On Karaf Console    ${TEP_SHOW}
    Log    ${output}
    Should Contain    ${output}    ${TUNNEL_MONITOR_ON}
    ${int_resp}    RequestsLibrary.Get Request    session    ${CONFIG_API}/ietf-interfaces:interfaces/
    ${respjson}    RequestsLibrary.To Json    ${int_resp.content}    pretty_print=True
    Log    ${respjson}
    Should Contain    ${respjson}    ${INTERFACE_DS_MON_TRUE}
    Should Contain    ${respjson}    ${INTERFACE_DS_MONI_INT_5000}
    Should Contain    ${respjson}    ${TUNNEL_MONI_PROTO}

*** Keywords ***
Create Vteps
    [Arguments]    ${TOOLS_SYSTEM_IP}    ${TOOLS_SYSTEM_2_IP}    ${vlan}    ${gateway-ip}
    [Documentation]    This keyword creates VTEPs between ${TOOLS_SYSTEM_IP} and ${TOOLS_SYSTEM_2_IP}
    ${body}    OperatingSystem.Get File    ${genius_config_dir}/Itm_creation_no_vlan.json
    ${substr}    Should Match Regexp    ${TOOLS_SYSTEM_IP}    [0-9]\{1,3}\.[0-9]\{1,3}\.[0-9]\{1,3}\.
    ${subnet}    Catenate    ${substr}0
    Log    ${subnet}
    Set Global Variable    ${subnet}
    ${vlan}=    Set Variable    ${vlan}
    ${gateway-ip}=    Set Variable    ${gateway-ip}
    ${body}    set json    ${TOOLS_SYSTEM_IP}    ${TOOLS_SYSTEM_2_IP}    ${vlan}    ${gateway-ip}    ${subnet}
    ${vtep_body}    Set Variable    ${body}
    Set Global Variable    ${vtep_body}
    ${resp}    RequestsLibrary.Post Request    session    ${CONFIG_API}/itm:transport-zones/    data=${body}
    Log    ${resp.status_code}
    should be equal as strings    ${resp.status_code}    204

set json
    [Arguments]    ${TOOLS_SYSTEM_IP}    ${TOOLS_SYSTEM_2_IP}    ${vlan}    ${gateway-ip}    ${subnet}
    [Documentation]    Sets Json with the values passed for it.
    ${body}    OperatingSystem.Get File    ${genius_config_dir}/Itm_creation_no_vlan.json
    ${body}    replace string    ${body}    1.1.1.1    ${subnet}
    ${body}    replace string    ${body}    "dpn-id": 101    "dpn-id": ${Dpn_id_1}
    ${body}    replace string    ${body}    "dpn-id": 102    "dpn-id": ${Dpn_id_2}
    ${body}    replace string    ${body}    "ip-address": "2.2.2.2"    "ip-address": "${TOOLS_SYSTEM_IP}"
    ${body}    replace string    ${body}    "ip-address": "3.3.3.3"    "ip-address": "${TOOLS_SYSTEM_2_IP}"
    ${body}    replace string    ${body}    "vlan-id": 0    "vlan-id": ${vlan}
    ${body}    replace string    ${body}    "gateway-ip": "0.0.0.0"    "gateway-ip": "${gateway-ip}"
    Log    ${body}
    [Return]    ${body}    # returns complete json that has been updated

Get Dpn Ids
    [Arguments]    ${connection_id}
    [Documentation]    This keyword gets the DPN id of the switch after configuring bridges on it.It returns the captured DPN id.
    Switch connection    ${connection_id}
    ${cmd}    set Variable    sudo ovs-vsctl show | grep Bridge | awk -F "\\"" '{print $2}'
    ${Bridgename1}    Execute command    ${cmd}
    log    ${Bridgename1}
    ${output1}    Execute command    sudo ovs-ofctl show -O Openflow13 ${Bridgename1} | head -1 | awk -F "dpid:" '{ print $2 }'
    log    ${output1}
    ${Dpn_id}    Execute command    echo \$\(\(16\#${output1}\)\)
    log    ${Dpn_id}
    [Return]    ${Dpn_id}

Delete All Sessions
    [Documentation]    This will delete vtep.
    ${resp}    RequestsLibrary.Delete Request    session    ${CONFIG_API}/itm:transport-zones/    data=${vtep_body}
    Log    ${resp.status_code}
    Should Be Equal As Strings    ${resp.status_code}    200
    SLEEP    5
    Log    "Before disconnecting CSS with controller"
    ${output}=    Issue Command On Karaf Console    ${TEP_SHOW}
    Log    ${output}
    ${output}=    Issue Command On Karaf Console    ${TEP_SHOW_STATE}
    Log    ${output}
