*** Settings ***
Documentation     Test suite to validate ITM VTEP auto-configuration functionality in openstack integrated environment.
Suite Setup       OpenStackOperations.OpenStack Suite Setup
Suite Teardown    SSHLibrary.Close All Connections
Library           OperatingSystem
Library           RequestsLibrary
Library           String
Library           SSHLibrary
Library           ../../libraries/VpnOperations.robot
Resource          ../../libraries/KarafKeywords.robot
Resource          ../../libraries/OpenStackOperations.robot
Resource          ../../libraries/OVSDB.robot
Resource          ../../libraries/OvsManager.robot
Resource          ../../libraries/Utils.robot
Resource          ../../variables/Variables.robot
Resource          ../../variables/netvirt/Variables.robot

*** Variables ***
${CHANGE_TRANSPORT_ZONE}    sudo ovs-vsctl set O . external_ids:transport-zone
${CHANGE_LOCAL_IP}    sudo ovs-vsctl set O . other_config:local_ip
${DATA_FILE}      ${GENIUS_VAR_DIR}/Itm_Auto_Tunnel_Create.json
${DEFAULT_TRANSPORT_ZONE}    default-transport-zone
${DELETE_TRANSPORT_ZONE}    sudo ovs-vsctl remove O . external_ids transport-zone
${GET_EXTERNAL_IDS}    sudo ovsdb-client dump -f list Open_vSwitch | grep external_ids
${GET_NETWORK_TOPOLOGY_URL}    ${OPERATIONAL_API}/network-topology:network-topology/topology/ovsdb:1/
${OVS_VERSION}    2.6
${REMOVE_LOCAL_IP}    sudo ovs-vsctl remove O . other_config local_ip
${SECURITY_GROUP}    itm_vtep_sg
${SHOW_OTHER_CONFIG}    sudo ovsdb-client dump -f list Open_vSwitch | grep other_config
${STATUS_CHECK}    DOWN
${TRANSPORT_ZONE}    TZA
${TUNNEL_TYPE_KEY_VAL}    odl-interface:tunnel-type-vxlan
${TUNNEL_NAME}    ${TUNNEL_CONF_LIST_URL}/internal-tunnel/
${TRANSPORTZONE_POST_URL}    ${CONFIG_API}/itm:transport-zones/
@{COMPUTE-NODE-LIST}    ${TOOLS_SYSTEM_1_IP}    ${TOOLS_SYSTEM_2_IP}
@{NET_1_VMS}      itm_vm1_1    itm_vm2_2
@{NETWORKS}       itm_net1_1    itm_net2_2
@{PORTS}          itm_port1_1    itm_port2_2
@{SUBNETS}        itm_subnet1_1    itm_subnet2_2
@{SUBNET_CIDRS}    10.1.1.0/24    20.1.1.0/24

*** Test Cases ***
Verify TEP in controller and transport zone in OVSDB table of compute nodes
    [Documentation]    Dump OVSDB table in all compute nodes and Verify ovs version, zone name, tunnel and perform ping across DPN VM’s
    OvsManager.Check Ovs Version Is Higher Than    ${OVS_VERSION}    @{COMPUTE-NODE-LIST}
    : FOR    ${ip}    IN    @{COMPUTE-NODE-LIST}
    \    ${localip} =    OvsManager.Get OVS Local Ip    ${ip}
    \    ${output} =    Utils.Run Command On Remote System    ${ip}    ${SHOW_OTHER_CONFIG}
    \    BuiltIn.Should Contain    ${output}    ${localip}
    ${dpn_1} =    OVSDB.Get DPID    @{COMPUTE-NODE-LIST}[0]
    ${dpn_id1} =    BuiltIn.Convert To String    ${dpn_1}
    Set Suite Variable    ${DPN1}    ${dpn_id1}
    ${dpn_2} =    OVSDB.Get DPID    @{COMPUTE-NODE-LIST}[1]
    ${dpn_id2} =    BuiltIn.Convert To String    ${dpn_2}
    Set Suite Variable    ${DPN2}    ${dpn_id2}
    ${itm_data} =    Utils.Get Data From URI    session    ${TRANSPORTZONE_POST_URL}
    BuiltIn.Should Contain Any    ${itm_data}    ${DEFAULT_TRANSPORT_ZONE}    ${DPN1}    ${DPN2}
    ${tep_show_output} =    KarafKeywords.Issue Command On Karaf Console    ${TEP_SHOW_STATE}
    BuiltIn.Should Not Contain    ${tep_show_output}    ${STATUS_CHECK}
    BuiltIn.Should Contain Any    ${tep_show_output}    ${DPN1}    ${DPN2}
    ${status}    BuiltIn.Run Keyword And Return Status    Utils.Get Data From URI    session    ${TUNNEL_NAME}${DPN2}/${DPN1}/${TUNNEL_TYPE_KEY_VAL}
    BuiltIn.Should Be True    '${status}' == 'True'
    ${status}    BuiltIn.Run Keyword And Return Status    Utils.Get Data From URI    session    ${TUNNEL_NAME}${DPN1}/${DPN2}/${TUNNEL_TYPE_KEY_VAL}
    BuiltIn.Should Be True    '${status}' == 'True'
    OpenStackOperations.Create Allow All SecurityGroup    ${SECURITY_GROUP}
    OpenStackOperations.Create Network    @{NETWORKS}[0]
    OpenStackOperations.Create SubNet    @{NETWORKS}[0]    @{SUBNETS}[0]    @{SUBNET_CIDRS}[0]
    OpenStackOperations.Create Port    @{NETWORKS}[0]    @{PORTS}[0]    sg=${SECURITY_GROUP}
    OpenStackOperations.Create Port    @{NETWORKS}[0]    @{PORTS}[1]    sg=${SECURITY_GROUP}
    OpenStackOperations.Create Vm Instance With Port On Compute Node    @{PORTS}[0]    @{NET_1_VMS}[0]    ${OS_CMP1_HOSTNAME}    sg=${SECURITY_GROUP}
    OpenStackOperations.Create Vm Instance With Port On Compute Node    @{PORTS}[1]    @{NET_1_VMS}[1]    ${OS_CMP2_HOSTNAME}    sg=${SECURITY_GROUP}
    ${VM1_IP}    ${dhcp1}    ${console} =    BuiltIn.Wait Until Keyword Succeeds    240s    10s    OpenStackOperations.Get VM IP
    ...    true    @{NET_1_VMS}[0]
    BuiltIn.Set Suite Variable    ${VM1_IP}
    ${VM2_IP}    ${dhcp2}    ${console1} =    BuiltIn.Wait Until Keyword Succeeds    240s    10s    OpenStackOperations.Get VM IP
    ...    true    @{NET_1_VMS}[1]
    BuiltIn.Set Suite Variable    ${VM2_IP}
    ${output} =    OpenStackOperations.Execute Command on VM Instance    @{NETWORKS}[0]    ${VM1_IP}    ping -c ${DEFAULT_PING_COUNT} ${VM2_IP}
    BuiltIn.Should Contain    ${output}    ${PING_REGEXP}

Verify TEPs with transport zone configured from OVS will be added to corresponding transport zone
    [Documentation]    To Verify transport zone teps configured from ovs will be added to respective zone with zone name, tunnel type and TEPs part of teps-not-hosted-in-transport-zone
    ${status} =    BuiltIn.Run Keyword And Return Status    Utils.Get Data From URI    session    ${TRANSPORT_ZONE_ENDPOINT_URL}/${DEFAULT_TRANSPORT_ZONE}
    BuiltIn.Should Be True    '${status}' == 'True'
    Change Transport Zone In Compute    @{COMPUTE-NODE-LIST}[0]    ${TRANSPORT_ZONE}
    ${get_nohosted_data} =    BuiltIn.Wait Until Keyword Succeeds    1 min    5 sec    Utils.Get Data From URI    session    ${TEP_NOT_HOSTED_ZONE_URL}
    BuiltIn.Should Contain Any    ${get_nohosted_data}    ${TRANSPORT_ZONE}    ${DPN1}
    Utils.Post Elements To URI From File    ${TRANSPORTZONE_POST_URL}    ${DATA_FILE}
    ${get_hosted_data} =    Utils.Get Data From URI    session    ${TRANSPORT_ZONE_ENDPOINT_URL}/${TRANSPORT_ZONE}
    BuiltIn.Should Contain    ${get_hosted_data}    ${TRANSPORT_ZONE}    ${DPN1}
    Change Transport Zone In Compute    @{COMPUTE-NODE-LIST}[1]    ${TRANSPORT_ZONE}
    : FOR    ${node}    IN    @{COMPUTE-NODE-LIST}
    \    ${localip} =    OvsManager.Get OVS Local Ip    ${node}
    \    ${output} =    Utils.Run Command On Remote System    ${node}    ${SHOW_OTHER_CONFIG}
    \    BuiltIn.Should Contain    ${output}    ${localip}
    \    ${output} =    Utils.Run Command On Remote System    ${node}    ${GET_EXTERNAL_IDS}
    \    BuiltIn.Should Contain    ${output}    ${TRANSPORT_ZONE}
    ${ip_1} =    OvsManager.Get OVS Local Ip    @{COMPUTE-NODE-LIST}[0]
    Set Suite Variable    ${IP1}    ${ip_1}
    ${ip_2} =    OvsManager.Get OVS Local Ip    @{COMPUTE-NODE-LIST}[1]
    Set Suite Variable    ${IP2}    ${ip_2}
    ${config_data} =    Utils.Get Data From URI    session    ${TRANSPORT_ZONE_ENDPOINT_URL}/${TRANSPORT_ZONE}
    BuiltIn.Should Contain Any    ${config_data}    ${TRANSPORT_ZONE}    ${IP1}    ${IP2}    ${DPN1}    ${DPN2}

Verify other-config-key and transport zone value in controller operational datastore
    [Documentation]    validate local_ip and transport-zone value from controller datastore and Verify value of external-id-key with transport_zone in Controller operational datastore
    ${controller-data} =    Utils.Get Data From URI    session    ${GET_NETWORK_TOPOLOGY_URL}
    BuiltIn.Should Contain Any    ${controller-data}    "other-config-value":"${IP1}"    "other-config-value":"${IP2}"    "external-id-value":"${TRANSPORT_ZONE}"

Delete transport zone on OVS and check ovsdb update to controller
    [Documentation]    To verify transport zone moves to tepsNotHostedInTransportZone after deleting in compute and no transport zone configuration from Compute added to default-transport-zone
    : FOR    ${node}    IN    @{COMPUTE-NODE-LIST}
    \    Utils.Run Command On Remote System    ${node}    ${DELETE_TRANSPORT_ZONE}
    ${tep_show_output} =    KarafKeywords.Issue Command On Karaf Console    ${TEP_SHOW}
    BuiltIn.Should Contain    ${tep_show_output}    ${DEFAULT_TRANSPORT_ZONE}
    VpnOperations.ITM Delete Tunnel    ${TRANSPORT_ZONE}
    ${default_zone_data} =    Utils.Get Data From URI    session    ${TRANSPORT_ZONE_ENDPOINT_URL}/${DEFAULT_TRANSPORT_ZONE}
    BuiltIn.Should Not Contain    ${default_zone_data}    ${TRANSPORT_ZONE}
    BuiltIn.Should Contain Any    ${default_zone_data}    ${IP1}    ${IP2}    ${DPN1}    ${DPN2}
    ${output} =    OpenStackOperations.Execute Command on VM Instance    @{NETWORKS}[0]    ${VM1_IP}    ping -c ${DEFAULT_PING_COUNT} ${VM2_IP}
    BuiltIn.Should Contain    ${output}    ${PING_REGEXP}

*** Keywords ***
Change Transport Zone In Compute
    [Arguments]    ${compute_ip}    ${zone_name}
    [Documentation]    Change transport zone in Compute and verify its configuration
    Utils.Run Command On Remote System    ${compute_ip}    ${CHANGE_TRANSPORT_ZONE}=${zone_name}
    ${output} =    Utils.Run Command On Remote System    ${compute_ip}    ${GET_EXTERNAL_IDS}
    BuiltIn.Should Contain    ${output}    ${zone_name}
