*** Settings ***
Documentation     Test suite to validate ITM VTEP auto-configuration functionality in openstack integrated environment.
Suite Setup       DevstackUtils.Devstack Suite Setup
Library           DebugLibrary
Library           OperatingSystem
Library           RequestsLibrary
Resource          ../../libraries/DevstackUtils.robot
Resource          ../../libraries/Genius.robot
Resource          ../../libraries/KarafKeywords.robot
Resource          ../../libraries/OpenStackOperations.robot
Resource          ../../libraries/OVSDB.robot
Resource          ../../libraries/SetupUtils.robot
Resource          ../../libraries/Utils.robot
Library           ../../variables/Variables.py
Resource          ../../variables/Variables.robot
Resource          ../../libraries/VpnOperations.robot
Library           ../../variables/netvirt/Variables.robot

*** Variables ***
@{COMPUTE-NODE-LIST}    ${OS_COMPUTE_1_IP}    ${OS_COMPUTE_2_IP}
${CHANGE_TZ}      sudo ovs-vsctl set O . external_ids:transport-zone
${CHANGE_LOCAL_IP}    sudo ovs-vsctl set O . other_config:local_ip
${DEFAULT_TRANSPORT_ZONE}    default-transport-zone
${DELETE_TZ}      sudo ovs-vsctl remove O . external_ids transport-zone
@{EXTERNAL_NETWORKS}    itm_ext_1    itm_ext_2
@{EXTERNAL_SUB_NETWORKS}    itm_ext_sub_1    itm_ext_sub_2
@{EXT_SUBNET_CIDRS}    100.100.100.0/24    200.200.200.0/24
${GET_NETWORK_TOPOLOGY}    /restconf/operational/network-topology:network-topology/topology/ovsdb:1/
${GET_DEFAULT_ZONE}    /restconf/config/itm:transport-zones/transport-zone/${DEFAULT_TRANSPORT_ZONE}
${GET_TRANSPORT_ZONE}    /restconf/config/itm:transport-zones/transport-zone/${TRANSPORT_ZONE}
${GET_EXTERNAL_IDS}    sudo ovsdb-client dump -f list Open_vSwitch | grep external_ids
${JSON_DIR}       ${CURDIR}/../../variables/genius/Itm_Auto_Tunnel_Create.json
@{LOCAL_IP}       192.168.113.222    192.168.113.223
@{NET_1_VMS}      itm_vm_1    itm_vm_2    itm_vm_3    itm_vm_4
@{NETWORKS}       itm_net_1    itm_net_2    itm_net_3    itm_net_4
@{PORTS}          itm_port_1    itm_port_2    itm_port_3    itm_port_4
${REMOVE_LOCAL_IP}    sudo ovs-vsctl remove O . other_config local_ip
${SECURITY_GROUP}    itm_sg
${SHOW_OVS_VERSION}    sudo ovs-vsctl show | grep version
${SHOW_OTHER_CONFIG}    sudo ovsdb-client dump -f list Open_vSwitch | grep other_config
@{SUBNETS}        itm_subnet_1    itm_subnet_2    itm_subnet_3
@{SUBNET_CIDRS}    10.1.1.0/24    20.1.1.0/24    30.1.1.0/24    40.1.1.0/24    50.1.1.0/24
${TEPNOTHOSTED_ZONE}    /restconf/operational/itm:not-hosted-transport-zones/
${TEP_SHOW}       tep:show
${TRANSPORT_ZONE}    TZA
${TUNNEL_LIST}    /restconf/operational/itm-state:tunnels_state
${TUNNEL_NAME}    /restconf/config/itm-state:tunnel-list/internal-tunnel/
${TUNNEL_CONF_LIST}    /restconf/config/itm-state:tunnel-list
${TUNNEL_TYPE}    odl-interface:tunnel-type-vxlan

*** Test Cases ***
Verify TEP IP and transport zone in OVSDB table of vSwitch
    [Documentation]    loging to all compuet nodes and Dump OVSDB tables and Verify ovs version, default-transport-zone zone name, auto tunnels and perform ping across DPN VM’s
    Get Ovs Version    @{COMPUTE-NODE-LIST}
    Check Local Ip    @{COMPUTE-NODE-LIST}[0]
    Check Local Ip    @{COMPUTE-NODE-LIST}[1]
    ${DPN_1} =    Get DPID    @{COMPUTE-NODE-LIST}[0]
    set suite variable    ${DPN1}
    ${DPN1} =    Convert To String     ${DPN_1}
    ${DPN_2} =    Get DPID    @{COMPUTE-NODE-LIST}[1]
    set suite variable    ${DPN2}
    ${DPN2} =    Convert To String     ${DPN_2}
    ${ITM-DATA} =    ITM Get Tunnels
    Should Contain Any    ${ITM-DATA}    ${DEFAULT_TRANSPORT_ZONE}    ${DPN1}    ${DPN2}
    ${output} =    Issue Command On Karaf Console    ${TEP_SHOW_STATE}
    Should Not Contain    ${output}    DOWN
    Should Contain Any    ${output}    ${DPN1}    ${DPN2}
    ${ITM_DATA} =    Get Csc Datastore    ${TUNNEL_NAME}${DPN2}/${DPN1}/odl-interface:tunnel-type-vxlan
    ${ITM_DATA} =    Get Csc Datastore    ${TUNNEL_NAME}${DPN1}/${DPN2}/odl-interface:tunnel-type-vxlan
    OpenStackOperations.Create Allow All SecurityGroup    ${SECURITY_GROUP}
    OpenStackOperations.Create Network    @{NETWORKS}[0]
    OpenStackOperations.Create SubNet    @{NETWORKS}[0]    @{SUBNETS}[0]    @{SUBNET_CIDRS}[0]
    OpenStackOperations.Create Network    @{NETWORKS}[1]
    OpenStackOperations.Create SubNet    @{NETWORKS}[1]    @{SUBNETS}[1]    @{SUBNET_CIDRS}[1]
    Create Port    @{NETWORKS}[0]    @{PORTS}[0]    sg=${SECURITY_GROUP}
    Create Port    @{NETWORKS}[0]    @{PORTS}[2]    sg=${SECURITY_GROUP}
    OpenStackOperations.Create Vm Instance With Port On Compute Node    @{PORTS}[0]    @{NET_1_VMS}[0]    ${OS_CMP1_HOSTNAME}    sg=${SECURITY_GROUP}
    OpenStackOperations.Create Vm Instance With Port On Compute Node    @{PORTS}[2]    @{NET_1_VMS}[1]    ${OS_CMP2_HOSTNAME}    sg=${SECURITY_GROUP}
    ${vm1_ip}    ${dhcp1}    ${console} =    Wait Until Keyword Succeeds    240s    10s    OpenStackOperations.Get VM IP
    ...    true    @{NET_1_VMS}[0]
    set suite variable    ${vm1_ip}
    ${vm2_ip}    ${dhcp2}    ${console1} =    Wait Until Keyword Succeeds    240s    10s    OpenStackOperations.Get VM IP
    ...    true    @{NET_1_VMS}[1]
    set suite variable    ${vm2_ip}
    ${output} =    OpenStackOperations.Execute Command on VM Instance    @{NETWORKS}[0]    ${vm1_ip}    ping -c 3 ${vm2_ip}
    Should Contain    ${output}    ${PING_REGEXP}

Verify TEPs with transport zone configured from OVS will be added to corresponding transport zone
    [Documentation]    To Verify transport zone teps configured from ovs will be added to corresponding transport zone, mandatory parameters like zone name and tunnel type and TEPs part of teps-not-hosted-in-transport-zone.
    ${status} =    Run Keyword And Return Status    Get Csc Datastore    ${GET_TRANSPORT_ZONE}
    ${Match} =    Convert To String    ${status}
    Should Be Equal    ${Match}    False
    Change Transport Zone In Css    @{COMPUTE-NODE-LIST}[0]    ${TRANSPORT_ZONE}
    ${ITM_DATA} =   Wait Until Keyword Succeeds   5 min   5 sec    Get Csc Datastore    ${TEPNOTHOSTED_ZONE}
    Should Contain Any    ${ITM_DATA}    ${TRANSPORT_ZONE}    ${DPN1}
    Post Tunnel Data    /restconf/config/itm:transport-zones/
    ${ITM_DATA} =    Get Csc Datastore    ${GET_TRANSPORT_ZONE}
    Should Contain    ${ITM_DATA}    ${TRANSPORT_ZONE}    ${DPN1}
    Change Transport Zone In Css    @{COMPUTE-NODE-LIST}[1]    ${TRANSPORT_ZONE}
    : FOR    ${node}    IN    @{COMPUTE-NODE-LIST}
    \    Check Local Ip    ${node}
    \    Check Transport Zone    ${node}    ${TRANSPORT_ZONE}
    ${IP_1} =    Get Local Ip    @{COMPUTE-NODE-LIST}[0]
    set suite variable    ${IP1}
    ${IP1} =    Convert To String     ${IP_1}
    ${IP_2} =    Get Local Ip    @{COMPUTE-NODE-LIST}[1]
    set suite variable    ${IP2}
    ${IP2} =    Convert To String     ${IP_2}
    ${ITM_DATA}    Get Csc Datastore    ${GET_TRANSPORT_ZONE}
    Should Contain Any    ${ITM_DATA}    ${TRANSPORT_ZONE}    ${IP1}    ${IP2}    ${DPN1}    ${DPN2}

Verify other-config-key:local_ip and transport zone value in controller operational datastore when ovs is connected to controller
    [Documentation]    check and validate local_ip and transport-zone value from csc datastore and Verify value of external-id-key with transport_zone in CSC operational datastore when ovs is disconnected
    ${csc-data}    Get Csc Datastore    ${GET_NETWORK_TOPOLOGY}
    Should Contain Any    ${csc-data}    "other-config-value":"${IP1}"    "other-config-value":"${IP2}"    "external-id-value":"${TRANSPORT_ZONE}"

Delete transport zone:TZA on OVS and check ovsdb update to controller
    [Documentation]    To verify transport zone moves to tepsNotHostedInTransportZone after deleting in css and no transport zone configuration from CSS added to default-transport-zone
    : FOR    ${node}    IN    @{COMPUTE-NODE-LIST}
    \    Run Command On Remote System    ${node}    ${DELETE_TZ}
    ${output} =    Issue Command On Karaf Console    ${TEP_SHOW}
    Should Contain    ${output}    ${DEFAULT_TRANSPORT_ZONE}
    ITM Delete Tunnel    ${TRANSPORT_ZONE}
    ${ITM_DATA} =    Get Csc Datastore    /restconf/config/itm:transport-zones/transport-zone/${DEFAULT_TRANSPORT_ZONE}
    should not contain    ${ITM_DATA}    ${TRANSPORT_ZONE}
    Should Contain Any    ${ITM_DATA}    ${IP1}    ${IP2}    ${DPN1}    ${DPN2}
    ${output} =    OpenStackOperations.Execute Command on VM Instance    @{NETWORKS}[0]    ${vm1_ip}    ping -c 3 ${vm2_ip}
    Should Contain    ${output}    ${PING_REGEXP}

** Keywords ***

Change Transport Zone In Css
    [Arguments]    ${compute_ip}    ${transport_zone}
    [Documentation]    Change transport zone in CSS
    Run Command On Remote System    ${compute_ip}    ${CHANGE_TZ}=${transport_zone}
    Check Transport Zone    ${compute_ip}    ${transport_zone}

Get Ovs Version
    [Arguments]    @{compute_nodes}
    : FOR    ${ ip}    IN    @{compute_nodes}
    \    ${output} =    Run Command On Remote System    ${ip}    ifconfig
    \    ${output} =    Run Command On Remote System    ${ip}    ${SHOW_OVS_VERSION}
    \    ${version} =    Get Regexp Matches    ${output}    \[0-9].\[0-9]
    \    ${result} =    Convert To Number    ${version[0]}
    \    Should Be True    ${result} > 2.6

Check Local Ip
    [Arguments]    ${compute_node}
    ${localip} =    Get Local Ip    ${compute_node}
    ${output} =    Run Command On Remote System    ${compute_node}    ${SHOW_OTHER_CONFIG}
    Should Contain    ${output}    ${localip}

Change Local Ip
    [Arguments]    ${compute_node}    ${local_ip}
    ${output} =    Run Command On Remote System    ${compute_node}    ${CHANGE_LOCAL_IP}=${local_ip}
    Run Command On Remote System    ${compute_node}    ifconfig br-prv down
    Run Command On Remote System    ${compute_node}    ifconfig br-prv ${local_ip}/24
    Run Command On Remote System    ${compute_node}    ifconfig br-prv up
    ${localip} =    Get Local Ip    ${compute_node}
    Should Be Equal    ${localip}    ${local_ip}

Check Transport Zone
    [Arguments]    ${compute_node}    ${transport-zone}
    ${output} =    Run Command On Remote System    ${compute_node}    ${GET_EXTERNAL_IDS}
    Should Contain    ${output}    ${transport-zone}

Get Local Ip
    [Arguments]    ${ip}
    ${cmd-output} =    Run Command On Remote System    ${ip}    sudo ovs-vsctl list Open_vSwitch | grep other_config | grep -oE "\\b([0-9]{1,3}\\.){3}[0-9]{1,3}\\b"
    ${localip} =    Get Regexp Matches    ${cmd-output}    (\[0-9]+\.\[0-9]+\.\[0-9]+\.\[0-9]+)
    [Return]    ${localip[0]}

Get Csc Datastore
    [Arguments]    ${url}
    [Documentation]    Get all Tunnels and return the contents
    ${resp} =    RequestsLibrary.Get Request    session    ${url}
    Should Be Equal As Strings    ${resp.status_code}    200
    [Return]    ${resp.content}

Reconnect Css With Zone Change
    [Arguments]    ${compute_ip}    ${transport_zone}    ${local_ip}
    ${manager} =    Run Command On Remote System    ${compute_ip}    sudo ovs-vsctl show | grep Manager | awk '{print $2}'
    Run Command On Remote System    ${compute_ip}    sudo ovs-vsctl del-manager
    Run Command On Remote System    ${compute_ip}    ${REMOVE_LOCAL_IP}
    Change Local Ip    ${compute_ip}    ${local_ip}
    Change Transport Zone In Css    ${compute_ip}    ${transport_zone}
    Run Command On Remote System    ${compute_ip}    sudo ovs-vsctl set-manager "tcp:${OS_CONTROL_NODE_IP}:6640"
    ${cmd-output1} =    Run Command On Remote System    ${compute_ip}    sudo ovs-vsctl show | grep Manager | awk '{print $2}'
    Should Contain    ${cmd-output1}    ${OS_CONTROL_NODE_IP}

Migrate VM Instance
    [Arguments]    ${vm_name}
    [Documentation]    Show information of a given VM and grep for instance id. VM name should be sent as arguments.
    ${devstack_conn_id} =    Get ControlNode Connection
    SSHLibrary.Switch Connection    ${devstack_conn_id}
    ${output} =    Write Commands Until Prompt    nova migrate --poll ${vm_name}    60s
    Sleep    60s
    ${output} =    Write Commands Until Prompt    nova resize-confirm ${vm_name}    30s
    SSHLibrary.Close Connection
    Wait Until Keyword Succeeds    25s    5s    Verify VM Is ACTIVE    ${vm_name}

Clean Config
    [Documentation]    Delete's all the configuration created by script.
    ${devstack_conn_id} =    Get ControlNode Connection
    Switch Connection    ${devstack_conn_id}
    : FOR    ${VmInstance}    IN    @{NET_1_VMS}
    \    Run Keyword And Ignore Error    Delete Vm Instance    ${VmInstance}
    : FOR    ${Subnet}    IN    @{SUBNETS}
    \    Run Keyword And Ignore Error    Remove Interface    ${ROUTER}    ${Subnet}
    : FOR    ${Port}    IN    @{PORTS}
    \    Run Keyword And Ignore Error    Delete Port    ${Port}
    : FOR    ${Subnet}    IN    @{SUBNETS}
    \    Run Keyword And Ignore Error    Delete SubNet    ${Subnet}
    : FOR    ${ExtSubnet}    IN    @{EXTERNAL_SUB_NETWORKS}
    \    Run Keyword And Ignore Error    Delete SubNet    ${ExtSubnet}
    : FOR    ${Network}    IN    @{NETWORKS}
    \    Run Keyword And Ignore Error    Delete Network    ${Network}
    : FOR    ${Network}    IN    @{EXTERNAL_NETWORKS}
    \    Run Keyword And Ignore Error    Delete Network    ${Network}
    Delete SecurityGroup    ${SECURITY_GROUP}

Post Tunnel Data
   [Arguments]    ${uri}
   &{headers}  Create Dictionary  Content-Type=application/json; charset=utf-8
   ${json}  Get Binary File  ${JSON_DIR}
   ${resp}    Post Request    session   ${uri}   data=${json}    headers=${headers}    
   Should Be Equal As Strings    ${resp.status_code}    204 
