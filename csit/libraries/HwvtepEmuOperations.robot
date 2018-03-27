*** Settings ***
Documentation     Test suite for HWVTEP Setup
Library           SSHLibrary
Library           Collections
Resource          ../variables/Variables.robot
Resource          Utils.robot
Resource          KarafKeywords.robot
Resource          ../variables/l2gw/Variables.robot

*** Variables ***

*** Keywords ***
Hwvtep Initialize
    [Arguments]    ${hwvtep_conn_id}
    [Documentation]    Create OVSDB and VTEP databases and invoke VSWITCHD and OVSDB process.
    Switch Connection    ${hwvtep_conn_id}
    Write Commands Until Prompt    ${CREATE_OVSDB}    30s
    Write Commands Until Prompt    ${CREATE_VTEP}    30s
    Write Commands Until Prompt    mkdir -p /var/run/openvswitch    30s
    Write Commands Until Prompt    chown root:root /var/run/openvswitch/    30s
    Write Commands Until Prompt    chmod 755 /var/run/openvswitch/    30s
    Write Commands Until Prompt    ${START_OVSDB_SERVER}    30s
    ${stdout}=    Write Commands Until Prompt    ${GREP_OVS}    30s
    Log    ${stdout}
    Write Commands Until Prompt    ${INIT_VSCTL}    30s
    Write Commands Until Prompt    ${DETACH_VSWITCHD}    30s

Hwvtep Start
    [Arguments]    ${hwvtep_conn_id}    ${hwvtep_vtep}    ${hwvtep_bridge}    ${num}=1
    [Documentation]    Create ${hwvte_bridge} and start Physical Switch.
    Switch Connection    ${hwvtep_conn_id}
    Write Commands Until Prompt    ${CREATE_OVS_BRIDGE} ${hwvtep_bridge}    30s
    ${stdout}=    Write Commands Until Prompt    ${OVS_SHOW}    30s
    Log    ${stdout}
    Write Commands Until Prompt    ${ADD_VTEP_PS} ${hwvtep_bridge}    30s
    Write Commands Until Prompt    ${SET_VTEP_PS} ${hwvtep_bridge} tunnel_ips=${hwvtep_vtep}    30s
    ${cmd}=    Create OVSVTEP Command    ${num}
    Write Commands Until Prompt    ${cmd} ${hwvtep_bridge}    30s
    ${stdout}=    Write Commands Until Prompt    ${GREP_OVS}    30s
    Log    ${stdout}

Hwvtep Setup
    [Arguments]    ${hwvtep_conn_id}    ${hwvtep_vtep}    ${hwvtep_bridge}
    [Documentation]    Setup the HWVTEP Emulator for L2 Gateway Testcase Verification.
    Hwvtep Cleanup    ${hwvtep_conn_id}
    Hwvtep Initialize    ${hwvtep_conn_id}
    Hwvtep Start    ${hwvtep_conn_id}    ${hwvtep_vtep}    ${hwvtep_bridge}

Hwvtep Stop With PidFile
    [Arguments]    ${hwvtep_conn_id}    ${hwvtep_bridge}    ${pidfile}
    [Documentation]    Cleanup any existing VTEP processes.
    Switch Connection    ${hwvtep_conn_id}
    Write Commands Until Prompt    ${DEL_OVS_BRIDGE} ${hwvtep_bridge}    30s
    Write Commands Until Prompt    kill -9 `cat ${pidfile}`    30s
    ${stdout}=    Write Commands Until Prompt    ${GREP_OVS}    30s
    Log    ${stdout}

Hwvtep Finalize
    [Arguments]    ${hwvtep_conn_id}
    [Documentation]    Cleanup any existing VSWITCHD or OVSDB processes.
    Switch Connection    ${hwvtep_conn_id}
    Write Commands Until Prompt    ${KILL_VSWITCHD_PROC}    30s
    Write Commands Until Prompt    ${KILL_OVSDB_PROC}    30s
    ${stdout}=    Write Commands Until Prompt    ${GREP_OVS}    30s
    Log    ${stdout}
    Write Commands Until Prompt    ${REM_OVSDB}    30s
    Write Commands Until Prompt    ${REM_VTEPDB}    30s

Hwvtep Cleanup
    [Arguments]    ${hwvtep_conn_id}
    [Documentation]    Cleanup any existing VTEP and VSWITCHD and OVSDB process.
    Switch Connection    ${hwvtep_conn_id}
    ${output}=    Write Commands Until Prompt    ps -ef | grep "[p]ython /usr/share/openvswitch/scripts/ovs-vtep" | awk '{print $(NF-2)" "$NF}'
    @{lines}=    Split String    ${output}    \n
    : FOR    ${line}    IN    @{lines}
    \    @{hit}=    Get Regexp Matches    ${line}    --pidfile=
    \    ${hit_length}=    Get Length    ${hit}
    \    Continue For Loop If    '${hit_length}'=='0'
    \    @{tmp}=    Split String    ${line}    ${SPACE}
    \    ${pidfile}=    Replace_String    @{tmp}[0]    --pidfile=    ${EMPTY}
    \    ${hwvtep_bridge}=    Set Variable    @{tmp}[1]
    \    Hwvtep Stop With PidFile    ${hwvtep_conn_id}    ${hwvtep_bridge}    ${pidfile}
    Hwvtep Finalize    ${hwvtep_conn_id}

Create OVSVTEP Command
    [Arguments]    ${num}
    [Documentation]    Create ovs-vtep startup command.
    ${cmd}=    Set Variable    sudo /usr/share/openvswitch/scripts/ovs-vtep
    ${cmd}=    Catenate    SEPARATOR=    ${cmd}    ${SPACE}    --log-file=/var/log/openvswitch/ovs-vtep    ${num}
    ...    .log
    ${cmd}=    Catenate    SEPARATOR=    ${cmd}    ${SPACE}    --pidfile=/var/run/openvswitch/ovs-vtep    ${num}
    ...    .pid
    ${cmd}=    Catenate    SEPARATOR=    ${cmd}    ${SPACE}    --detach
    [Return]    ${cmd}

Create Namespace
    [Arguments]    ${hwvtep_conn_id}    ${ns_name}
    [Documentation]    Create a namespace with ${ns_name}.
    Switch Connection    ${hwvtep_conn_id}
    Log    ${ns_name}
    Write Commands Until Prompt    ${NETNS_ADD} ${ns_name}    30s

Create Namespace Vlan Port
    [Arguments]    ${ns_name}    ${tap_port_name}    ${vlan}
    [Documentation]    Create ${tap_port_name} with ${vlan} on ${ns_name}.
    Write Commands Until Prompt    ${NETNS_EXEC} ${ns_name} ${IP_LINK_ADD} link ${tap_port_name} name ${tap_port_name}.${vlan} type vlan id ${vlan}    30s
    Write Commands Until Prompt    ${NETNS_EXEC} ${ns_name} ${IPLINK_SET} ${tap_port_name}.${vlan} up    30s

Create Namespace Port
    [Arguments]    ${hwvtep_conn_id}    ${ns_name}    ${ovs_port_name}    ${tap_port_name}    ${vlan}    ${hwvtep_bridge}
    [Documentation]    Create an interface and add to ${hwvtep_bridge}.
    Switch Connection    ${hwvtep_conn_id}
    Write Commands Until Prompt    ${IP_LINK_ADD} ${tap_port_name} type veth peer name ${ovs_port_name}    30s
    Write Commands Until Prompt    ${CREATE_OVS_PORT} ${hwvtep_bridge} ${ovs_port_name}    30s
    Write Commands Until Prompt    ${IP_LINK_SET} ${tap_port_name} netns ${ns_name}    30s
    Write Commands Until Prompt    ${NETNS_EXEC} ${ns_name} ${IPLINK_SET} ${tap_port_name} up    30s
    Run Keyword If    "${vlan}"!="${EMPTY}"    Create Namespace Vlan Port    ${ns_name}    ${tap_port_name}    ${vlan}
    Write Commands Until Prompt    sudo ${IPLINK_SET} ${ovs_port_name} up    30s
    ${stdout}=    Write Commands Until Prompt    ${NETNS_EXEC} ${ns_name} ${IFCONF}    30s
    Log    ${stdout}

Cleanup Namespace
    [Arguments]    ${hwvtep_conn_id}    ${ns_name}
    [Documentation]    Delete the namespace of ${ns_name}.
    Switch Connection    ${hwvtep_conn_id}
    Write Commands Until Prompt    ${NETNS_DEL} ${ns_name}    30s
    ${stdout}=    Write Commands Until Prompt    ${IP_LINK}    30s
    Log    ${stdout}

Cleanup All Namespace
    [Arguments]    ${hwvtep_conn_id}
    [Documentation]    Delete all namespaces.
    Switch Connection    ${hwvtep_conn_id}
    ${output}=    Write Commands Until Prompt    ${NETNS} | awk '{print $1}'    30s
    Log    ${output}
    @{lines}=    Split String    ${output}    \n
    : FOR    ${line}    IN    @{lines}
    \    @{hit}=    Get Regexp Matches    ${line}    NS
    \    ${hit_length}=    Get Length    ${hit}
    \    Continue For Loop If    '${hit_length}'=='0'
    \    Cleanup Namespace    ${hwvtep_conn_id}    ${line}

Cleanup Namespace Port
    [Arguments]    ${hwvtep_conn_id}    ${hwvtep_bridge}    ${ovs_port_name}
    [Documentation]    Delete ${ovs_port_name} on ${hwvtep_bridge}.
    Switch Connection    ${hwvtep_conn_id}
    Run Keyword If    '${hwvtep_bridge}'=='${EMPTY}'    Write Commands Until Prompt    ${DEL_OVS_PORT} ${ovs_port_name}    30s
    ...    ELSE    Write Commands Until Prompt    ${DEL_OVS_PORT} ${hwvtep_bridge} ${ovs_port_name}    30s
    Write Commands Until Prompt    ${IP_LINK_DEL} ${ovs_port_name}    30s
    ${stdout}=    Write Commands Until Prompt    ${NETNS}    30s
    Log    ${stdout}

Cleanup All Namespace Port
    [Arguments]    ${hwvtep_conn_id}
    [Documentation]    Delete all Namespace ports on ${hwvtep_conn_id}.
    Switch Connection    ${hwvtep_conn_id}
    ${output}=    Write Commands Until Prompt    ip link show type veth | grep OVSPORT | awk '{print $2}' | awk -F\@ '{print $1}'    30s
    Log    ${output}
    @{lines}=    Split String    ${output}    \n
    : FOR    ${line}    IN    @{lines}
    \    @{hit}=    Get Regexp Matches    ${line}    OVSPORT
    \    ${hit_length}=    Get Length    ${hit}
    \    Continue For Loop If    '${hit_length}'=='0'
    \    Cleanup Namespace Port    ${hwvtep_conn_id}    ${EMPTY}    ${line}

Port Start Hwvtep
    [Arguments]    ${hwvtep_conn_id}    ${hwvtep_bridge}    @{portdictlist}
    [Documentation]    Create and configure the namespace, bridges and ports.
    Switch Connection    ${hwvtep_conn_id}
    : FOR    ${dict}    IN    @{portdictlist}
    \    Log    ${dict}
    \    ${ovs_port_name}=    Collections.Get From Dictionary    ${dict}    ovs_port_name
    \    ${ns_tap_name}=    Collections.Get From Dictionary    ${dict}    ns_tap_name
    \    ${ns_name}=    Collections.Get From Dictionary    ${dict}    ns_name
    \    ${vlan}=    Get From Dictionary Present Default    ${dict}    vlan
    \    Create Namespace    ${hwvtep_conn_id}    ${ns_name}
    \    Create Namespace Port    ${hwvtep_conn_id}    ${ns_name}    ${ovs_port_name}    ${ns_tap_name}    ${vlan}
    \    ...    ${hwvtep_bridge}

Port Setup Hwvtep
    [Arguments]    ${hwvtep_conn_id}    ${hwvtep_bridge}    @{portdictlist}
    [Documentation]    Clear everything and create and configure namespaces, bridges, and ports.
    Switch Connection    ${hwvtep_conn_id}
    Port Cleanup All Hwvtep    ${hwvtep_conn_id}
    Port Start Hwvtep    ${hwvtep_conn_id}    ${hwvtep_bridge}    @{portdictlist}

Port Cleanup All Hwvtep
    [Arguments]    ${hwvtep_conn_id}
    [Documentation]    Cleanup the existing namespaces and ports.
    Switch Connection    ${hwvtep_conn_id}
    Cleanup All Namespace    ${hwvtep_conn_id}
    Cleanup All Namespace Port    ${hwvtep_conn_id}
