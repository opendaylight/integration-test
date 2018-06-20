*** Settings ***
Documentation     Test suite to validate ITM VTEP auto-configuration functionality in openstack integrated environment.
Suite Setup       DevstackUtils.Devstack Suite Setup
Library           DebugLibrary
Library           OperatingSystem
Library           RequestsLibrary
Library           String
Library           SSHLibrary
Resource          ../../libraries/DevstackUtils.robot
Resource          ../../libraries/Genius.robot
Resource          ../../libraries/KarafKeywords.robot
Resource          ../../libraries/OpenStackOperations.robot
Resource          ../../libraries/OVSDB.robot
Resource          ../../libraries/SetupUtils.robot
Resource          ../../libraries/Utils.robot
Resource          ../../variables/Variables.py
Resource          ../../variables/Variables.robot
Resource          ../../libraries/VpnOperations.robot
Resource          ../../variables/netvirt/Variables.robot

*** Variables ***
@{COMPUTE-NODE-LIST}    ${OS_COMPUTE_1_IP}    ${OS_COMPUTE_2_IP}
${CHANGE_TZ}      sudo ovs-vsctl set O . external_ids:transport-zone
${CHANGE_LOCAL_IP}    sudo ovs-vsctl set O . other_config:local_ip
${DEFAULT_TRANSPORT_ZONE}    default-transport-zone
${DELETE_TZ}      sudo ovs-vsctl remove O . external_ids transport-zone
@{EXTERNAL_NETWORKS}    itm_ext_1    itm_ext_2
@{EXTERNAL_SUB_NETWORKS}    itm_ext_sub_1    itm_ext_sub_2
@{EXT_SUBNET_CIDRS}    100.100.100.0/24    200.200.200.0/24
${GET_NETWORK_TOPOLOGY}    ${OPERATIONAL_API}/network-topology:network-topology/topology/ovsdb:1/
${GET_DEFAULT_ZONE}    ${CONFIG_API}/itm:transport-zones/transport-zone/${DEFAULT_TRANSPORT_ZONE}
${GET_LOCAL_IP}    sudo ovs-vsctl list Open_vSwitch | grep other_config | grep -oE "\\b([0-9]{1,3}\\.){3}[0-9]{1,3}\\b"
${GET_TRANSPORT_ZONE}    ${CONFIG_API}/itm:transport-zones/transport-zone/${TRANSPORT_ZONE}
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
${TEPNOTHOSTED_ZONE}    ${OPERATIONAL_API}/itm:not-hosted-transport-zones/
${TRANSPORT_ZONE}    TZA
${TUNNEL_LIST}    ${OPERATIONAL_API}/itm-state:tunnels_state
${TUNNEL_NAME}    ${CONFIG_API}/itm-state:tunnel-list/internal-tunnel/
${TUNNEL_CONF_LIST}    ${CONFIG_API}/itm-state:tunnel-list
${TUNNEL_TYPE}    odl-interface:tunnel-type-vxlan

*** Test Cases ***
Verify TEP IP and transport zone in OVSDB table of vSwitch
    [Documentation]    loging to all compuet nodes and Dump OVSDB tables and Verify ovs version, default-transport-zone zone name, auto tunnels and perform ping across DPN VM’s
    Get Ovs Version    @{COMPUTE-NODE-LIST}
    Check Local Ip    @{COMPUTE-NODE-LIST}[0]
    Check Local Ip    @{COMPUTE-NODE-LIST}[1]
    ${DPN_1} =    OVSDB.Get DPID    @{COMPUTE-NODE-LIST}[0]
    BuiltIn.Set Suite Variable    ${DPN1}
    ${DPN1} =    BuiltIn.Convert To String    ${DPN_1}
    ${DPN_2} =    OVSDB.Get DPID    @{COMPUTE-NODE-LIST}[1]
    BuiltIn.Set Suite Variable    ${DPN2}
    ${DPN2} =    BuiltIn.Convert To String    ${DPN_2}
    ${ITM-DATA} =    ITM Get Tunnels
    BuiltIn.Should Contain Any    ${ITM-DATA}    ${DEFAULT_TRANSPORT_ZONE}    ${DPN1}    ${DPN2}
    ${output} =    KarafKeywords.Issue Command On Karaf Console    ${TEP_SHOW_STATE}
    BuiltIn.Should Not Contain    ${output}    DOWN
    BuiltIn.Should Contain Any    ${output}    ${DPN1}    ${DPN2}
    ${ITM_DATA} =    Get Csc Datastore    ${TUNNEL_NAME}${DPN2}/${DPN1}/${TUNNEL_TYPE}
    ${ITM_DATA} =    Get Csc Datastore    ${TUNNEL_NAME}${DPN1}/${DPN2}/${TUNNEL_TYPE}
    OpenStackOperations.Create Allow All SecurityGroup    ${SECURITY_GROUP}
    OpenStackOperations.Create Network    @{NETWORKS}[0]
    OpenStackOperations.Create SubNet    @{NETWORKS}[0]    @{SUBNETS}[0]    @{SUBNET_CIDRS}[0]
    OpenStackOperations.Create Network    @{NETWORKS}[1]
    OpenStackOperations.Create SubNet    @{NETWORKS}[1]    @{SUBNETS}[1]    @{SUBNET_CIDRS}[1]
    OpenStackOperations.Create Port    @{NETWORKS}[0]    @{PORTS}[0]    sg=${SECURITY_GROUP}
    OpenStackOperations.Create Port    @{NETWORKS}[0]    @{PORTS}[2]    sg=${SECURITY_GROUP}
    OpenStackOperations.Create Vm Instance With Port On Compute Node    @{PORTS}[0]    @{NET_1_VMS}[0]    ${OS_CMP1_HOSTNAME}    sg=${SECURITY_GROUP}
    OpenStackOperations.Create Vm Instance With Port On Compute Node    @{PORTS}[2]    @{NET_1_VMS}[1]    ${OS_CMP2_HOSTNAME}    sg=${SECURITY_GROUP}
    ${vm1_ip}    ${dhcp1}    ${console} =    BuiltIn.Wait Until Keyword Succeeds    240s    10s    OpenStackOperations.Get VM IP
    ...    true    @{NET_1_VMS}[0]
    BuiltIn.Set Suite Variable    ${vm1_ip}
    ${vm2_ip}    ${dhcp2}    ${console1} =    BuiltIn.Wait Until Keyword Succeeds    240s    10s    OpenStackOperations.Get VM IP
    ...    true    @{NET_1_VMS}[1]
    BuiltIn.Set Suite Variable    ${vm2_ip}
    ${output} =    OpenStackOperations.Execute Command on VM Instance    @{NETWORKS}[0]    ${vm1_ip}    ping -c 3 ${vm2_ip}
    BuiltIn.Should Contain    ${output}    ${PING_REGEXP}

Verify TEPs with transport zone configured from OVS will be added to corresponding transport zone
    [Documentation]    To Verify transport zone teps configured from ovs will be added to corresponding transport zone, mandatory parameters like zone name and tunnel type and TEPs part of teps-not-hosted-in-transport-zone.
    ${status} =    BuiltIn.Run Keyword And Return Status    Get Csc Datastore    ${GET_TRANSPORT_ZONE}
    ${Match} =    BuiltIn.Convert To String    ${status}
    BuiltIn.Should Be Equal    ${Match}    False
    Change Transport Zone In Css    @{COMPUTE-NODE-LIST}[0]    ${TRANSPORT_ZONE}
    ${ITM_DATA} =    BuiltIn.Wait Until Keyword Succeeds    5 min    5 sec    Get Csc Datastore    ${TEPNOTHOSTED_ZONE}
    BuiltIn.Should Contain Any    ${ITM_DATA}    ${TRANSPORT_ZONE}    ${DPN1}
    Post Tunnel Data    /restconf/config/itm:transport-zones/
    ${ITM_DATA} =    Get Csc Datastore    ${GET_TRANSPORT_ZONE}
    BuiltIn.Should Contain    ${ITM_DATA}    ${TRANSPORT_ZONE}    ${DPN1}
    Change Transport Zone In Css    @{COMPUTE-NODE-LIST}[1]    ${TRANSPORT_ZONE}
    : FOR    ${node}    IN    @{COMPUTE-NODE-LIST}
    \    Check Local Ip    ${node}
    \    Check Transport Zone    ${node}    ${TRANSPORT_ZONE}
    ${IP_1} =    Get Local Ip    @{COMPUTE-NODE-LIST}[0]
    BuiltIn.Set Suite Variable    ${IP1}
    ${IP1} =    BuiltIn.Convert To String    ${IP_1}
    ${IP_2} =    Get Local Ip    @{COMPUTE-NODE-LIST}[1]
    BuiltIn.Set Suite Variable    ${IP2}
    ${IP2} =    BuiltIn.Convert To String    ${IP_2}
    ${ITM_DATA}    Get Csc Datastore    ${GET_TRANSPORT_ZONE}
    BuiltIn.Should Contain Any    ${ITM_DATA}    ${TRANSPORT_ZONE}    ${IP1}    ${IP2}    ${DPN1}    ${DPN2}

Verify other-config-key:local_ip and transport zone value in controller operational datastore
    [Documentation]    check and validate local_ip and transport-zone value from csc datastore and Verify value of external-id-key with transport_zone in CSC operational datastore
    ${csc-data}    Get Csc Datastore    ${GET_NETWORK_TOPOLOGY}
    BuiltIn.Should Contain Any    ${csc-data}    "other-config-value":"${IP1}"    "other-config-value":"${IP2}"    "external-id-value":"${TRANSPORT_ZONE}"

Delete transport zone:TZA on OVS and check ovsdb update to controller
    [Documentation]    To verify transport zone moves to tepsNotHostedInTransportZone after deleting in css and no transport zone configuration from CSS added to default-transport-zone
    : FOR    ${node}    IN    @{COMPUTE-NODE-LIST}
    \    Utils.Run Command On Remote System    ${node}    ${DELETE_TZ}
    ${output} =    KarafKeywords.Issue Command On Karaf Console    ${TEP_SHOW}
    BuiltIn.Should Contain    ${output}    ${DEFAULT_TRANSPORT_ZONE}
    VpnOperations.ITM Delete Tunnel    ${TRANSPORT_ZONE}
    ${ITM_DATA} =    Get Csc Datastore    ${GET_DEFAULT_ZONE}
    BuiltIn.Should Not Contain    ${ITM_DATA}    ${TRANSPORT_ZONE}
    BuiltIn.Should Contain Any    ${ITM_DATA}    ${IP1}    ${IP2}    ${DPN1}    ${DPN2}
    ${output} =    OpenStackOperations.Execute Command on VM Instance    @{NETWORKS}[0]    ${vm1_ip}    ping -c 3 ${vm2_ip}
    BuiltIn.Should Contain    ${output}    ${PING_REGEXP}

*** Keywords ***
Change Transport Zone In Css
    [Arguments]    ${compute_ip}    ${transport_zone}
    [Documentation]    Change transport zone in CSS
    Utils.Run Command On Remote System    ${compute_ip}    ${CHANGE_TZ}=${transport_zone}
    Check Transport Zone    ${compute_ip}    ${transport_zone}

Get Ovs Version
    [Arguments]    @{compute_nodes}
    [Documentation]    Get ovs version on css and verify compatibility
    : FOR    ${ ip}    IN    @{compute_nodes}
    \    ${output} =    Utils.Run Command On Remote System    ${ip}    ifconfig
    \    ${output} =    Utils.Run Command On Remote System    ${ip}    ${SHOW_OVS_VERSION}
    \    ${version} =    String.Get Regexp Matches    ${output}    \[0-9].\[0-9]
    \    ${result} =    BuiltIn.Convert To Number    ${version[0]}
    \    BuiltIn.Should Be True    ${result} > 2.6

Check Local Ip
    [Arguments]    ${compute_node}
    ${localip} =    Get Local Ip    ${compute_node}
    ${output} =    Utils.Run Command On Remote System    ${compute_node}    ${SHOW_OTHER_CONFIG}
    BuiltIn.Should Contain    ${output}    ${localip}

Check Transport Zone
    [Arguments]    ${compute_node}    ${transport-zone}
    ${output} =    Utils.Run Command On Remote System    ${compute_node}    ${GET_EXTERNAL_IDS}
    BuiltIn.Should Contain    ${output}    ${transport-zone}

Get Local Ip
    [Arguments]    ${ip}
    ${cmd-output} =    Utils.Run Command On Remote System    ${ip}    ${GET_LOCAL_IP}
    ${localip} =    String.Get Regexp Matches    ${cmd-output}    (\[0-9]+\.\[0-9]+\.\[0-9]+\.\[0-9]+)
    [Return]    ${localip[0]}

Get Csc Datastore
    [Arguments]    ${url}
    [Documentation]    Get all Tunnels and return the contents
    ${resp} =    RequestsLibrary.Get Request    session    ${url}
    BuiltIn.Should Be Equal As Strings    ${resp.status_code}    200
    [Return]    ${resp.content}

Migrate VM Instance
    [Arguments]    ${vm_name}
    [Documentation]    Show information of a given VM and grep for instance id. VM name should be sent as arguments.
#    ${devstack_conn_id} =    OpenStackOperations.Get ControlNode Connection
#    SSHLibrary.SSHLibrary.Switch Connection    ${devstack_conn_id}
#    ${output} =    DevstackUtils.Write Commands Until Prompt    nova migrate --poll ${vm_name}    60s
#    Sleep    60s
#    ${output} =    DevstackUtils.Write Commands Until Prompt    nova resize-confirm ${vm_name}    30s
#    SSHLibrary.Close Connection
    Utils.Run Command On Remote System    ${OS_COMPUTE_1_IP}    nova migrate --poll ${vm_name}
    Utils.Run Command On Remote System    ${OS_COMPUTE_1_IP}    nova resize-confirm ${vm_name}
    BuiltIn.Wait Until Keyword Succeeds    25s    5s    Verify VM Is ACTIVE    ${vm_name}

Clean Config
    [Documentation]    Delete's all the configuration created by script.
    ${devstack_conn_id} =    OpenStackOperations.Get ControlNode Connection
    SSHLibrary.Switch Connection    ${devstack_conn_id}
    : FOR    ${VmInstance}    IN    @{NET_1_VMS}
    \    BuiltIn.Run Keyword And Ignore Error    Delete Vm Instance    ${VmInstance}
    : FOR    ${Subnet}    IN    @{SUBNETS}
    \    BuiltIn.Run Keyword And Ignore Error    Remove Interface    ${ROUTER}    ${Subnet}
    : FOR    ${Port}    IN    @{PORTS}
    \    BuiltIn.Run Keyword And Ignore Error    Delete Port    ${Port}
    : FOR    ${Subnet}    IN    @{SUBNETS}
    \    BuiltIn.Run Keyword And Ignore Error    Delete SubNet    ${Subnet}
    : FOR    ${ExtSubnet}    IN    @{EXTERNAL_SUB_NETWORKS}
    \    BuiltIn.Run Keyword And Ignore Error    Delete SubNet    ${ExtSubnet}
    : FOR    ${Network}    IN    @{NETWORKS}
    \    BuiltIn.Run Keyword And Ignore Error    Delete Network    ${Network}
    : FOR    ${Network}    IN    @{EXTERNAL_NETWORKS}
    \    BuiltIn.Run Keyword And Ignore Error    Delete Network    ${Network}
    OpenStackOperations.Delete SecurityGroup    ${SECURITY_GROUP}

Post Tunnel Data
    [Arguments]    ${uri}
    &{headers}    BuiltIn.Create Dictionary    Content-Type=application/json; charset=utf-8
    ${json}    OperatingSystem.Get Binary File    ${JSON_DIR}
    ${resp}    RequestsLibrary.Post Request    session    ${uri}    data=${json}    headers=${headers}
    BuiltIn.Should Be Equal As Strings    ${resp.status_code}    204
