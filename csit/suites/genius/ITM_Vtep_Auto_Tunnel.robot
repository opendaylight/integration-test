*** Settings ***
Documentation     Test suite to validate ITM VTEP auto-configuration functionality in openstack integrated environment.
Suite Setup       OpenStackOperations.OpenStack Suite Setup 
Suite Teardown    Stop Suite
Library           OperatingSystem
Library           RequestsLibrary
Library           String
Library           SSHLibrary
Resource          ../../libraries/KarafKeywords.robot
Resource          ../../libraries/OpenStackOperations.robot
Resource          ../../libraries/OVSDB.robot
Resource          ../../libraries/Utils.robot
Resource          ../../variables/Variables.py
Resource          ../../variables/Variables.robot
Resource          ../../libraries/VpnOperations.robot
Resource          ../../variables/netvirt/Variables.robot

*** Variables ***
${DEFAULT_TRANSPORT_ZONE}    default-transport-zone
${CHANGE_TZ}      sudo ovs-vsctl set O . external_ids:transport-zone
${CHANGE_LOCAL_IP}    sudo ovs-vsctl set O . other_config:local_ip
${DELETE_TZ}      sudo ovs-vsctl remove O . external_ids transport-zone
${GET_NETWORK_TOPOLOGY}    ${OPERATIONAL_API}/network-topology:network-topology/topology/ovsdb:1/
${GET_DEFAULT_ZONE}    ${CONFIG_API}/itm:transport-zones/transport-zone/${DEFAULT_TRANSPORT_ZONE}
${POST_URL}     ${CONFIG_API}/itm:transport-zones/
${GET_LOCAL_IP}    sudo ovs-vsctl list Open_vSwitch | grep other_config | grep -oE "\\b([0-9]{1,3}\\.){3}[0-9]{1,3}\\b"
${GET_TRANSPORT_ZONE}    ${CONFIG_API}/itm:transport-zones/transport-zone/${TRANSPORT_ZONE}
${GET_EXTERNAL_IDS}    sudo ovsdb-client dump -f list Open_vSwitch | grep external_ids
${FILE_DIR}       ${CURDIR}/../../variables/genius/Itm_Auto_Tunnel_Create.json
${REMOVE_LOCAL_IP}    sudo ovs-vsctl remove O . other_config local_ip
${SECURITY_GROUP}    itm_sg
${SHOW_OVS_VERSION}    sudo ovs-vsctl show | grep version
${SHOW_OTHER_CONFIG}    sudo ovsdb-client dump -f list Open_vSwitch | grep other_config
${TEPNOTHOSTED_ZONE}    ${OPERATIONAL_API}/itm:not-hosted-transport-zones/
${TRANSPORT_ZONE}    TZA
${TUNNEL_LIST}    ${OPERATIONAL_API}/itm-state:tunnels_state
${TUNNEL_NAME}    ${CONFIG_API}/itm-state:tunnel-list/internal-tunnel/
${TUNNEL_CONF_LIST}    ${CONFIG_API}/itm-state:tunnel-list
${TUNNEL_TYPE}    odl-interface:tunnel-type-vxlan
@{SUBNETS}        itm_subnet1_1    itm_subnet2_2
@{SUBNET_CIDRS}    10.1.1.0/24    20.1.1.0/24
@{NET_1_VMS}      itm_vm1_1    itm_vm2_2
@{NETWORKS}       itm_net1_1    itm_net2_2
@{PORTS}          itm_port1_1    itm_port2_2
@{COMPUTE-NODE-LIST}    ${OS_COMPUTE_1_IP}    ${OS_COMPUTE_2_IP}

*** Test Cases ***
Verify TEP IP and transport zone in OVSDB table of compute nodes
    [Documentation]    Dump OVSDB table in all compute nodes and Verify ovs version, zone name, tunnels and perform ping across DPN VM’s
    Get Ovs Version    @{COMPUTE-NODE-LIST}
    : FOR    ${ip}    IN    @{COMPUTE-NODE-LIST}
    \    ${localip} =    Get Local Ip    ${ip}
    \    ${output} =    Utils.Run Command On Remote System    ${ip}    ${SHOW_OTHER_CONFIG}
    \    BuiltIn.Should Contain    ${output}    ${localip}
    ${DPN_1} =    OVSDB.Get DPID    @{COMPUTE-NODE-LIST}[0]
    BuiltIn.Set Suite Variable    ${DPN1}
    ${DPN1} =    BuiltIn.Convert To String    ${DPN_1}
    ${DPN_2} =    OVSDB.Get DPID    @{COMPUTE-NODE-LIST}[1]
    BuiltIn.Set Suite Variable    ${DPN2}
    ${DPN2} =    BuiltIn.Convert To String    ${DPN_2}
    ${ITM-DATA} =    ITM Get Tunnels
    BuiltIn.Should Contain Any    ${ITM-DATA}    ${DEFAULT_TRANSPORT_ZONE}    ${DPN1}    ${DPN2}
    ${tep_show_output} =    KarafKeywords.Issue Command On Karaf Console    ${TEP_SHOW_STATE}
    BuiltIn.Should Not Contain    ${tep_show_output}    DOWN
    BuiltIn.Should Contain Any    ${tep_show_output}    ${DPN1}    ${DPN2}
    Get Controller Data    ${TUNNEL_NAME}${DPN2}/${DPN1}/${TUNNEL_TYPE}
    Get Controller Data    ${TUNNEL_NAME}${DPN1}/${DPN2}/${TUNNEL_TYPE}
    OpenStackOperations.Create Allow All SecurityGroup    ${SECURITY_GROUP}
    OpenStackOperations.Create Network    @{NETWORKS}[0]
    OpenStackOperations.Create SubNet    @{NETWORKS}[0]    @{SUBNETS}[0]    @{SUBNET_CIDRS}[0]
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
    [Documentation]    To Verify transport zone teps configured from ovs will be added to respective zone with zone name, tunnel type and TEPs part of teps-not-hosted-in-transport-zone
    ${status} =    BuiltIn.Run Keyword And Return Status    Get Controller Data    ${GET_TRANSPORT_ZONE}
    ${Match} =    BuiltIn.Convert To String    ${status}
    BuiltIn.Should Be Equal    ${Match}    False
    Change Transport Zone In Compute    @{COMPUTE-NODE-LIST}[0]    ${TRANSPORT_ZONE}
    ${get_nohosted_data} =    BuiltIn.Wait Until Keyword Succeeds    1 min    5 sec    Get Controller Data    ${TEPNOTHOSTED_ZONE}
    BuiltIn.Should Contain Any    ${get_nohosted_data}    ${TRANSPORT_ZONE}    ${DPN1}
    Post Tunnel Data    ${POST_URL}
    ${get_hosted_data} =    Get Controller Data    ${GET_TRANSPORT_ZONE}
    BuiltIn.Should Contain    ${get_hosted_data}    ${TRANSPORT_ZONE}    ${DPN1}
    Change Transport Zone In Compute    @{COMPUTE-NODE-LIST}[1]    ${TRANSPORT_ZONE}
    : FOR    ${node}    IN    @{COMPUTE-NODE-LIST}
    \    ${localip} =    Get Local Ip    ${node}
    \    ${output} =    Utils.Run Command On Remote System    ${node}    ${SHOW_OTHER_CONFIG}
    \    BuiltIn.Should Contain    ${output}    ${localip}
    \    ${output} =    Utils.Run Command On Remote System    ${node}    ${GET_EXTERNAL_IDS}
    \    BuiltIn.Should Contain    ${output}    ${TRANSPORT_ZONE}
    ${IP_1} =    Get Local Ip    @{COMPUTE-NODE-LIST}[0]
    BuiltIn.Set Suite Variable    ${IP1}
    ${IP1} =    BuiltIn.Convert To String    ${IP_1}
    ${IP_2} =    Get Local Ip    @{COMPUTE-NODE-LIST}[1]
    BuiltIn.Set Suite Variable    ${IP2}
    ${IP2} =    BuiltIn.Convert To String    ${IP_2}
    ${config_data} =    Get Controller Data    ${GET_TRANSPORT_ZONE}
    BuiltIn.Should Contain Any    ${config_data}    ${TRANSPORT_ZONE}    ${IP1}    ${IP2}    ${DPN1}    ${DPN2}

Verify other-config-key and transport zone value in controller operational datastore
    [Documentation]   validate local_ip and transport-zone value from controller datastore and Verify value of external-id-key with transport_zone in Controller operational datastore
    ${controller-data} =    Get Controller Data    ${GET_NETWORK_TOPOLOGY}
    BuiltIn.Should Contain Any    ${controller-data}    "other-config-value":"${IP1}"    "other-config-value":"${IP2}"    "external-id-value":"${TRANSPORT_ZONE}"

Delete transport zone on OVS and check ovsdb update to controller
    [Documentation]   To verify transport zone moves to tepsNotHostedInTransportZone after deleting in compute and no transport zone configuration from Compute added to default-transport-zone
    : FOR    ${node}    IN    @{COMPUTE-NODE-LIST}
    \    Utils.Run Command On Remote System    ${node}    ${DELETE_TZ}
    ${tep_show_output} =    KarafKeywords.Issue Command On Karaf Console    ${TEP_SHOW}
    BuiltIn.Should Contain    ${tep_show_output}    ${DEFAULT_TRANSPORT_ZONE}
    VpnOperations.ITM Delete Tunnel    ${TRANSPORT_ZONE}
    ${default_zone_data} =    Get Controller Data    ${GET_DEFAULT_ZONE}
    BuiltIn.Should Not Contain    ${default_zone_data}    ${TRANSPORT_ZONE}
    BuiltIn.Should Contain Any    ${default_zone_data}    ${IP1}    ${IP2}    ${DPN1}    ${DPN2}
    ${output} =    OpenStackOperations.Execute Command on VM Instance    @{NETWORKS}[0]    ${vm1_ip}    ping -c 3 ${vm2_ip}
    BuiltIn.Should Contain    ${output}    ${PING_REGEXP}

*** Keywords ***
Change Transport Zone In Compute
    [Arguments]    ${compute_ip}    ${transport_zone}
    [Documentation]    Change transport zone in Compute and verify its configuration
    Utils.Run Command On Remote System    ${compute_ip}    ${CHANGE_TZ}=${transport_zone}
    ${output} =    Utils.Run Command On Remote System    ${compute_ip}   ${GET_EXTERNAL_IDS}
    BuiltIn.Should Contain    ${output}    ${transport-zone}

Get Ovs Version
    [Arguments]    @{compute_nodes}
    [Documentation]    Get ovs version on compute and verify compatibility
    : FOR    ${ ip}    IN    @{compute_nodes}
    \    ${output} =    Utils.Run Command On Remote System    ${ip}    ${SHOW_OVS_VERSION}
    \    ${version} =    String.Get Regexp Matches    ${output}    \[0-9].\[0-9]
    \    ${result} =    BuiltIn.Convert To Number    ${version[0]}
    \    BuiltIn.Should Be True    ${result} > 2.6

Get Local Ip
    [Arguments]    ${ip}
    [Documentation]    Get local ip of compute node ovsdb
    ${cmd-output} =    Utils.Run Command On Remote System    ${ip}    ${GET_LOCAL_IP}
    ${localip} =    String.Get Regexp Matches    ${cmd-output}    (\[0-9]+\.\[0-9]+\.\[0-9]+\.\[0-9]+)
    [Return]    ${localip[0]}

Get Controller Data
    [Arguments]    ${url}
    [Documentation]    Get REST call and return the contents
    ${resp} =    RequestsLibrary.Get Request    session    ${url}
    BuiltIn.Should Be Equal As Strings    ${resp.status_code}    200
    [Return]    ${resp.content}

Post Tunnel Data
    [Arguments]    ${uri}
    [Documentation]    Post REST call with data as file and return the response
    &{headers}    BuiltIn.Create Dictionary    Content-Type=application/json; charset=utf-8
    ${json}    OperatingSystem.Get Binary File    ${FILE_DIR}
    ${resp}    RequestsLibrary.Post Request    session    ${uri}    data=${json}    headers=${headers}
    BuiltIn.Should Be Equal As Strings    ${resp.status_code}    204
