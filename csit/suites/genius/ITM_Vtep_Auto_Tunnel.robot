*** Settings ***
Documentation     Test suite to validate ITM VTEP auto-configuration functionality in openstack integrated environment.
Suite Setup       BuiltIn.Run Keywords    Genius.Genius Suite Setup
...               AND    OvsManager.Check Ovs Version Is Higher Than    ${OVS_VERSION}    @{COMPUTE-NODE-LIST}
Suite Teardown    Genius.Genius Suite Teardown
Test Setup        Genius Test Setup
Test Teardown     Genius Test Teardown    ${data_models}
Library           OperatingSystem
Library           RequestsLibrary
Library           String
Library           SSHLibrary
Variables         ../../variables/genius/Modules.py
Resource          ../../libraries/Genius.robot
Resource          ../../libraries/KarafKeywords.robot
Resource          ../../libraries/OVSDB.robot
Resource          ../../libraries/OvsManager.robot
Resource          ../../libraries/Utils.robot
Resource          ../../libraries/VpnOperations.robot
Resource          ../../variables/netvirt/Variables.robot
Resource          ../../variables/Variables.robot

*** Variables ***
${CHANGE_TRANSPORT_ZONE}    sudo ovs-vsctl set O . external_ids:transport-zone
${SET_LOCAL_IP}    sudo ovs-vsctl set O . other_config:local_ip=
${DATA_FILE}      ${GENIUS_VAR_DIR}/Itm_Auto_Tunnel_Create.json
${DEFAULT_TRANSPORT_ZONE}    default-transport-zone
${DELETE_TRANSPORT_ZONE}    sudo ovs-vsctl remove O . external_ids transport-zone
${GET_EXTERNAL_IDS}    sudo ovsdb-client dump -f list Open_vSwitch | grep external_ids
${GET_NETWORK_TOPOLOGY_URL}    ${OPERATIONAL_API}/network-topology:network-topology/topology/ovsdb:1/
${OVS_VERSION}    2.5
${REMOVE_LOCAL_IP}    sudo ovs-vsctl remove O . other_config local_ip
${SECURITY_GROUP}    itm_vtep_sg
${SHOW_OTHER_CONFIG}    sudo ovsdb-client dump -f list Open_vSwitch | grep other_config
${STATUS_CHECK}    DOWN
${TRANSPORT_ZONE}    TZA
${TRANSPORTZONE_POST_URL}    ${CONFIG_API}/itm:transport-zones
@{COMPUTE-NODE-LIST}    ${TOOLS_SYSTEM_1_IP}    ${TOOLS_SYSTEM_2_IP}

*** Test Cases ***
Verify TEP in controller and transport zone in OVSDB table of compute nodes
    [Documentation]    Dump OVSDB table in all compute nodes and Verify ovs version, zone name, tunnel and perform ping across DPN VM’s
    : FOR    ${ip}    IN    @{COMPUTE-NODE-LIST}
    \    ${localip} =    Utils.Run Command On Remote System    ${ip}    ${SET_LOCAL_IP}${ip}
    : FOR    ${ip}    IN    @{COMPUTE-NODE-LIST}
    \    ${localip} =    OvsManager.Get OVS Local Ip    ${ip}
    \    ${output} =    Utils.Run Command On Remote System    ${ip}    ${SHOW_OTHER_CONFIG}
    \    BuiltIn.Should Contain    ${output}    ${localip}
    BuiltIn.Wait Until Keyword Succeeds    2 min    5 sec    Genius.Verify Tunnel Status as UP    ${DEFAULT_TRANSPORT_ZONE}
    ${dpn} =    OVSDB.Get DPID    @{COMPUTE-NODE-LIST}[0]
    ${dpn} =    BuiltIn.Convert To String    ${dpn}
    Set Suite Variable    ${DPN1}    ${dpn}
    ${dpn} =    OVSDB.Get DPID    @{COMPUTE-NODE-LIST}[1]
    ${dpn} =    BuiltIn.Convert To String    ${dpn}
    Set Suite Variable    ${DPN2}    ${dpn}
    @{tep_data} =    BuiltIn.Create List    ${DPN1}    ${DPN2}    ${DEFAULT_TRANSPORT_ZONE}
    Utils.Check For Elements At URI    ${TRANSPORTZONE_POST_URL}    ${tep_data}

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
    Utils.Check For Elements At URI    ${TRANSPORT_ZONE_ENDPOINT_URL}/${TRANSPORT_ZONE}    ${tep_data}

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
    Utils.Check For Elements At URI    ${TRANSPORT_ZONE_ENDPOINT_URL}/${DEFAULT_TRANSPORT_ZONE}    ${tep_data}

*** Keywords ***
Change Transport Zone In Compute
    [Arguments]    ${compute_ip}    ${zone_name}
    [Documentation]    Change transport zone in Compute and verify its configuration
    Utils.Run Command On Remote System    ${compute_ip}    ${CHANGE_TRANSPORT_ZONE}=${zone_name}
    ${output} =    Utils.Run Command On Remote System    ${compute_ip}    ${GET_EXTERNAL_IDS}
    BuiltIn.Should Contain    ${output}    ${zone_name}
