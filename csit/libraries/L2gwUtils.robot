*** Keywords ***
Validate Hwvtep Configuration
    [Arguments]    ${hwvtep_conn_id}    ${bridge_name}    ${vtep_ip}    ${port_list}
    [Documentation]    Verify the physical switch and ports are created correctly after hwvtep configurarion
    Switch Connection    ${hwvtep_conn_id}
    ${stdout}=    Write Commands Until Prompt    ${VTEP LIST} ${PHYSICAL_SWITCH_TABLE}    30s
    Should Contain    ${stdout}    ${bridge_name}
    Should Contain    ${stdout}    ${vtep_ip}
    ${stdout}=    Write Commands Until Prompt    ${VTEP LIST} ${PHYSICAL_PORT_TABLE}    30s
    : FOR    ${port}    IN    @{port_list}
    \    Should Contain    ${stdout}    ${port}

Create And Get Hwvtep Connection Id
    [Arguments]    ${hwvtep_ip}
    [Documentation]    To create connection and return connection id for hwvtep_ip received
    ${conn_id}=    SSHLibrary.Open Connection    ${hwvtep_ip}    prompt=${DEFAULT_LINUX_PROMPT}    timeout=30s
    Flexible SSH Login    ${DEFAULT_USER}    ${DEFAULT_PASSWORD}
    [Return]    ${conn_id}

Cleanup Hwvtep Configuration
    [Arguments]    ${conn_id}    ${hwvtep_bridge}
    [Documentation]    Cleanup any existing VTEP, VSWITCHD or OVSDB processes.
    Switch Connection    ${conn_id}
    Write Commands Until Prompt    ${DEL_OVS_BRIDGE} ${hwvtep_bridge}    30s
    Write Commands Until Prompt    ${KILL_VTEP_PROC}    30s
    Write Commands Until Prompt    ${KILL_VSWITCHD_PROC}    30s
    Write Commands Until Prompt    ${KILL_OVSDB_PROC}    30s
    Write Commands Until Prompt    ${KILL_DHCLIENT_PROC}
    ${stdout}=    Write Commands Until Prompt    ${GREP_OVS}    30s
    Log    ${stdout}
    Write Commands Until Prompt    ${REM_OVSDB}    30s
    Write Commands Until Prompt    ${REM_VTEPDB}    30s

Cleanup Namespace Configuration
    [Arguments]    ${conn_id}    ${port_list}    ${ns_list}
    [Documentation]    Cleanup the existing namespaces and ports.
    Switch Connection    ${conn_id}
    ${stdout}=    Write Commands Until Prompt    ${IP_LINK}    30s
    Log    ${stdout}
    : FOR    ${port}    IN    @{port_list}
    \    Write Commands Until Prompt    ${IP_LINK_DEL} ${port}    30s
    : FOR    ${ns}    IN    @{ns_list}
    \    Write Commands Until Prompt    ${NETNS_DEL} ${ns}    30s
    ${stdout}=    Write Commands Until Prompt    ${NETNS}    30s
    Log    ${stdout}

Create And Configure Hwvtep
    [Arguments]    ${conn_id}    ${hwvtep_ip}    ${hwvtep_bridge}
    [Documentation]    Configure the Hwvtep Emulation
    Switch Connection    ${conn_id}
    Write Commands Until Prompt    ${CREATE_OVSDB}    30s
    Write Commands Until Prompt    ${CREATE VTEP}    30s
    Write Commands Until Prompt    ${START_OVSDB_SERVER}    30s
    ${stdout}=    Write Commands Until Prompt    ${GREP_OVS}    30s
    Log    ${stdout}
    Write Commands Until Prompt    ${INIT_VSCTL}    30s
    Write Commands Until Prompt    ${DETACH_VSWITCHD}    30s
    Write Commands Until Prompt    ${CREATE_OVS_BRIDGE} ${hwvtep_bridge}    30s
    ${stdout}=    Write Commands Until Prompt    ${OVS_SHOW}    30s
    Log    ${stdout}
    Write Commands Until Prompt    ${ADD_VTEP_PS} ${hwvtep_bridge}    30s
    Write Commands Until Prompt    ${SET_VTEP_PS} ${hwvtep_bridge} tunnel_ips=${hwvtep_ip}    30s
    Write Commands Until Prompt    ${START_OVSVTEP} ${hwvtep_bridge}    30s
    ${stdout}=    Write Commands Until Prompt    ${GREP_OVS}    30s
    Log    ${stdout}

Create Namespace And Port
    [Arguments]    ${conn_id}    ${ns_name}    ${ns_port_name}    ${tap_port_name}    ${hwvtep_bridge}
    [Documentation]    Namespace configuration to create veth pair and add to hwvtep bridge
    Switch Connection    ${conn_id}
    Write Commands Until Prompt    ${NETNS_ADD} ${ns_name}    30s
    Write Commands Until Prompt    ${IP_LINK_ADD} ${tap_port_name} type veth peer name ${ns_port_name}    30s
    Write Commands Until Prompt    ${CREATE_OVS_PORT} ${hwvtep_bridge} ${ns_port_name}    30s
    Write Commands Until Prompt    ${IP_LINK_SET} ${tap_port_name} netns ${ns_name}    30s
    Write Commands Until Prompt    ${NETNS_EXEC} ${ns_name} ${IPLINK_SET} ${tap_port_name} up    30s
    Write Commands Until Prompt    sudo ${IPLINK_SET} ${ns_port_name} up    30s
    ${stdout}=    Write Commands Until Prompt    ${NETNS_EXEC} ${ns_name} ${IFCONF}    30s
    Log    ${stdout}
