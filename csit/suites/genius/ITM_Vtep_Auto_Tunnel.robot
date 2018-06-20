*** Settings ***
Documentation     Test suite to validate ITM VTEP auto-configuration functionality in openstack integrated environment.
Suite Setup       BuiltIn.Run Keywords    OpenStackOperations.OpenStack Suite Setup
...               AND    OvsManager.Check Ovs Version Is Higher Than    ${OVS_VERSION}    @{COMPUTE-NODE-LIST}
Suite Teardown    SSHLibrary.Close All Connections
Library           OperatingSystem
Library           RequestsLibrary
Library           String
Library           SSHLibrary
Resource          ../../libraries/KarafKeywords.robot
Resource          ../../libraries/OpenStackOperations.robot
Resource          ../../libraries/OVSDB.robot
Resource          ../../libraries/OvsManager.robot
Resource          ../../libraries/Utils.robot
Resource          ../../libraries/VpnOperations.robot
Resource          ../../variables/netvirt/Variables.robot
Resource          ../../variables/Variables.robot

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
${TUNNEL_NAME}    ${CONFIG_API}/itm-state:dpn-teps-state/dpns-teps
${TRANSPORTZONE_POST_URL}    ${CONFIG_API}/itm:transport-zones
@{COMPUTE-NODE-LIST}    ${OS_COMPUTE_1_IP}    ${OS_COMPUTE_2_IP}
@{NET_1_VMS}      itm_vm1_1    itm_vm2_2
@{NETWORKS}       itm_net1_1    itm_net2_2
@{PORTS}          itm_port1_1    itm_port2_2
@{SUBNETS}        itm_subnet1_1    itm_subnet2_2
@{SUBNET_CIDRS}    10.1.1.0/24    20.1.1.0/24

*** Test Cases ***
Verify TEP in controller and transport zone in OVSDB table of compute nodes
    [Documentation]    Dump OVSDB table in all compute nodes and Verify ovs version, zone name, tunnel and perform ping across DPN VM’s
    : FOR    ${ip}    IN    @{COMPUTE-NODE-LIST}
    \    ${localip} =    OvsManager.Get OVS Local Ip    ${ip}
    \    ${output} =    Utils.Run Command On Remote System    ${ip}    ${SHOW_OTHER_CONFIG}
    \    BuiltIn.Should Contain    ${output}    ${localip}
    ${dpn} =    OVSDB.Get DPID    @{COMPUTE-NODE-LIST}[0]
    ${dpn} =    BuiltIn.Convert To String    ${dpn}
    Set Suite Variable    ${DPN1}    ${dpn}
    ${dpn} =    OVSDB.Get DPID    @{COMPUTE-NODE-LIST}[1]
    ${dpn} =    BuiltIn.Convert To String    ${dpn}
    Set Suite Variable    ${DPN2}    ${dpn}
    @{tep_data} =    BuiltIn.Create List    ${DPN1}    ${DPN2}    ${DEFAULT_TRANSPORT_ZONE}
    ${itm_data} =    Utils.Get Data From URI    session    ${TRANSPORTZONE_POST_URL}
    : FOR    ${data}    IN    @{tep_data}
    \    BuiltIn.Should Contain    ${itm_data}    ${data}
    ${tep_show_output} =    KarafKeywords.Issue Command On Karaf Console    ${TEP_SHOW_STATE}
    BuiltIn.Should Not Contain    ${tep_show_output}    ${STATUS_CHECK}
    BuiltIn.Should Contain    ${tep_show_output}    ${DPN1}
    BuiltIn.Should Contain    ${tep_show_output}    ${DPN2}
    Utils.Get Data From URI    session    ${TUNNEL_NAME}/${DPN2}/remote-dpns/${DPN1}
    Utils.Get Data From URI    session    ${TUNNEL_NAME}/${DPN1}/remote-dpns/${DPN2}
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
    Utils.Get Data From URI    session    ${TRANSPORT_ZONE_ENDPOINT_URL}/${DEFAULT_TRANSPORT_ZONE}
    Change Transport Zone In Compute    @{COMPUTE-NODE-LIST}[0]    ${TRANSPORT_ZONE}
    ${get_nohosted_data} =    BuiltIn.Wait Until Keyword Succeeds    1 min    5 sec    Utils.Get Data From URI    session    ${TEP_NOT_HOSTED_ZONE_URL}
    BuiltIn.Should Contain    ${get_nohosted_data}    ${TRANSPORT_ZONE}
    BuiltIn.Should Contain    ${get_nohosted_data}    ${DPN1}
    Utils.Post Elements To URI From File    ${TRANSPORTZONE_POST_URL}    ${DATA_FILE}
    ${get_hosted_data} =    Utils.Get Data From URI    session    ${TRANSPORT_ZONE_ENDPOINT_URL}/${TRANSPORT_ZONE}
    BuiltIn.Should Contain    ${get_hosted_data}    ${TRANSPORT_ZONE}
    BuiltIn.Should Contain    ${get_hosted_data}    ${DPN1}
    Change Transport Zone In Compute    @{COMPUTE-NODE-LIST}[1]    ${TRANSPORT_ZONE}
    : FOR    ${node}    IN    @{COMPUTE-NODE-LIST}
    \    ${localip} =    OvsManager.Get OVS Local Ip    ${node}
    \    ${output} =    Utils.Run Command On Remote System    ${node}    ${SHOW_OTHER_CONFIG}
    \    BuiltIn.Should Contain    ${output}    ${localip}
    \    ${output} =    Utils.Run Command On Remote System    ${node}    ${GET_EXTERNAL_IDS}
    \    BuiltIn.Should Contain    ${output}    ${TRANSPORT_ZONE}
    ${ip} =    OvsManager.Get OVS Local Ip    @{COMPUTE-NODE-LIST}[0]
    Set Suite Variable    ${IP1}    ${ip}
    ${ip} =    OvsManager.Get OVS Local Ip    @{COMPUTE-NODE-LIST}[1]
    Set Suite Variable    ${IP2}    ${ip}
    @{tep_data} =    BuiltIn.Create List    ${DPN1}    ${DPN2}    ${TRANSPORT_ZONE}    ${IP1}    ${IP2}
    ${config_data} =    Utils.Get Data From URI    session    ${TRANSPORT_ZONE_ENDPOINT_URL}/${TRANSPORT_ZONE}
    : FOR    ${data}    IN    @{tep_data}
    \    BuiltIn.Should Contain    ${config_data}    ${data}

Verify other-config-key and transport zone value in controller operational datastore
    [Documentation]    validate local_ip and transport-zone value from controller datastore and Verify value of external-id-key with transport_zone in Controller operational datastore
    ${controller-data} =    Utils.Get Data From URI    session    ${GET_NETWORK_TOPOLOGY_URL}
    BuiltIn.Should Contain    ${controller-data}    "other-config-value":"${IP1}"
    BuiltIn.Should Contain    ${controller-data}    "other-config-value":"${IP2}"
    BuiltIn.Should Contain    ${controller-data}    "external-id-value":"${TRANSPORT_ZONE}"

Delete transport zone on OVS and check ovsdb update to controller
    [Documentation]    To verify transport zone moves to tepsNotHostedInTransportZone after deleting in compute and transport zone configuration from Compute added to default-transport-zone
    : FOR    ${node}    IN    @{COMPUTE-NODE-LIST}
    \    Utils.Run Command On Remote System    ${node}    ${DELETE_TRANSPORT_ZONE}
    ${tep_show_output} =    KarafKeywords.Issue Command On Karaf Console    ${TEP_SHOW}
    BuiltIn.Should Contain    ${tep_show_output}    ${DEFAULT_TRANSPORT_ZONE}
    VpnOperations.ITM Delete Tunnel    ${TRANSPORT_ZONE}
    @{tep_data} =    BuiltIn.Create List    ${DPN1}    ${DPN2}    ${IP1}    ${IP2}
    ${default_zone_data} =    Utils.Get Data From URI    session    ${TRANSPORT_ZONE_ENDPOINT_URL}/${DEFAULT_TRANSPORT_ZONE}
    BuiltIn.Should Not Contain    ${default_zone_data}    ${TRANSPORT_ZONE}
    : FOR    ${data}    IN    @{tep_data}
    \    BuiltIn.Should Contain    ${default_zone_data}    ${data}
    ${output} =    OpenStackOperations.Execute Command on VM Instance    @{NETWORKS}[0]    ${VM1_IP}    ping -c ${DEFAULT_PING_COUNT} ${VM2_IP}
    BuiltIn.Should Contain    ${output}    ${PING_REGEXP}

*** Keywords ***
Change Transport Zone In Compute
    [Arguments]    ${compute_ip}    ${zone_name}
    [Documentation]    Change transport zone in Compute and verify its configuration
    Utils.Run Command On Remote System    ${compute_ip}    ${CHANGE_TRANSPORT_ZONE}=${zone_name}
    ${output} =    Utils.Run Command On Remote System    ${compute_ip}    ${GET_EXTERNAL_IDS}
    BuiltIn.Should Contain    ${output}    ${zone_name}
