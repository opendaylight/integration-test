*** Settings ***
Documentation     Test suite to validate ITM VTEP auto-configuration functionality in openstack integrated environment.
Suite Setup       BuiltIn.Run Keywords    Genius.Genius Suite Setup
...               AND    OvsManager.Verify Ovs Version Greater Than Or Equal To    ${OVS_VERSION}    @{TOOLS_SYSTEM_ALL_IPS}
Suite Teardown    Genius.Genius Suite Teardown
Test Setup        Genius Test Setup
Test Teardown     Genius Test Teardown    ${data_models}
Library           OperatingSystem
Library           RequestsLibrary
Library           SSHLibrary
Library           String
Resource          ../../libraries/Genius.robot
Resource          ../../libraries/KarafKeywords.robot
Resource          ../../libraries/OVSDB.robot
Resource          ../../libraries/OvsManager.robot
Resource          ../../libraries/Utils.robot
Resource          ../../libraries/VpnOperations.robot
Resource          ../../variables/netvirt/Variables.robot
Resource          ../../variables/Variables.robot
Variables         ../../variables/genius/Modules.py

*** Variables ***
${CHANGE_TRANSPORT_ZONE}    sudo ovs-vsctl set O . external_ids:transport-zone
${TZA_JSON}       ${GENIUS_VAR_DIR}/Itm_Auto_Tunnel_Create.json
${DELETE_TRANSPORT_ZONE}    sudo ovs-vsctl remove O . external_ids transport-zone
${GET_EXTERNAL_IDS}    sudo ovsdb-client dump -f list Open_vSwitch | grep external_ids
${GET_NETWORK_TOPOLOGY_URL}    ${OPERATIONAL_API}/network-topology:network-topology/topology/ovsdb:1/
${OVS_VERSION}    2.5
${SHOW_OTHER_CONFIG}    sudo ovsdb-client dump -f list Open_vSwitch | grep other_config
${STATUS_CHECK}    DOWN
${TRANSPORT_ZONE}    TZA
${TRANSPORTZONE_POST_URL}    ${CONFIG_API}/itm:transport-zones

*** Test Cases ***
Verify TEP in controller and transport zone in OVSDB table of compute nodes
    [Documentation]    Set local ip in compute nodes and verify default transport zone tunnels are up in controller
    @{LOCAL_IPS} =    BuiltIn.Create List
    : FOR    ${ip}    IN    @{TOOLS_SYSTEM_ALL_IPS}
    \    ${localip} =    Utils.Run Command On Remote System    ${ip}    ${SET_LOCAL_IP}${ip}
    : FOR    ${node_ip}    IN    @{TOOLS_SYSTEM_ALL_IPS}
    \    ${ip} =    OvsManager.Get OVS Local Ip    ${node_ip}
    \    Collections.Append To List    ${LOCAL_IPS}    ${ip}
    BuiltIn.Set Suite Variable    @{LOCAL_IPS}
    BuiltIn.Wait Until Keyword Succeeds    3x    10 sec    Genius.Verify Tunnel Status as Up

Verify TEPs with transport zone configured from OVS will be added to corresponding transport zone
    [Documentation]    To Verify transport zone name change in external id field of ovsdb and check status when moved from tep nohosted zone to TZA
    Change Transport Zone In Compute    ${TOOLS_SYSTEM_1_IP}    ${TRANSPORT_ZONE}
    ${get_nohosted_data} =    BuiltIn.Wait Until Keyword Succeeds    3x    10 sec    Utils.Get Data From URI    session    ${TEP_NOT_HOSTED_ZONE_URL}
    BuiltIn.Should Contain    ${get_nohosted_data}    ${TRANSPORT_ZONE}
    BuiltIn.Should Contain    ${get_nohosted_data}    @{DPN_ID_LIST}[0]
    Utils.Post Elements To URI From File    ${TRANSPORTZONE_POST_URL}    ${TZA_JSON}
    : FOR    ${node_number}    IN RANGE    2    ${NUM_TOOLS_SYSTEM}+1
    \    Change Transport Zone In Compute    ${TOOLS_SYSTEM_${node_number}_IP}    ${TRANSPORT_ZONE}
    : FOR    ${node}    IN    @{TOOLS_SYSTEM_ALL_IPS}
    \    ${output} =    Utils.Run Command On Remote System    ${node}    ${GET_EXTERNAL_IDS}
    \    BuiltIn.Should Contain    ${output}    ${TRANSPORT_ZONE}
    ${get_hosted_data} =    BuiltIn.Wait Until Keyword Succeeds    3x    10 sec    Utils.Get Data From URI    session    ${TRANSPORT_ZONE_ENDPOINT_URL}/${TRANSPORT_ZONE}
    BuiltIn.Should Contain    ${get_hosted_data}    ${TRANSPORT_ZONE}
    BuiltIn.Should Contain    ${get_hosted_data}    @{DPN_ID_LIST}[0]
    BuiltIn.Wait Until Keyword Succeeds    3x    10 sec    Genius.Verify Tunnel Status as Up

Verify other-config-key and transport zone value in controller operational datastore
    [Documentation]    validate local_ip and transport-zone value from controller datastore and Verify value of external-id-key with transport_zone in Controller operational datastore
    ${controller-data} =    Utils.Get Data From URI    session    ${GET_NETWORK_TOPOLOGY_URL}
    : FOR    ${node_ip}    IN    @{LOCAL_IPS}
    \    BuiltIn.Should Contain    ${controller-data}    "other-config-value":"${node_ip}"
    BuiltIn.Should Contain    ${controller-data}    "external-id-value":"${TRANSPORT_ZONE}"

Delete transport zone on OVS and check ovsdb update to controller
    [Documentation]    To verify transport zone moves to default zone after deleting zone name in compute nodes
    : FOR    ${node}    IN    @{TOOLS_SYSTEM_ALL_IPS}
    \    Utils.Run Command On Remote System    ${node}    ${DELETE_TRANSPORT_ZONE}
    ${tep_show_output} =    KarafKeywords.Issue Command On Karaf Console    ${TEP_SHOW}
    BuiltIn.Should Contain    ${tep_show_output}    ${DEFAULT_TRANSPORT_ZONE}
    BuiltIn.Wait Until Keyword Succeeds    3x    10 sec    Genius.Verify Tunnel Status as Up
    VpnOperations.ITM Delete Tunnel    ${TRANSPORT_ZONE}

*** Keywords ***
Change Transport Zone In Compute
    [Arguments]    ${compute_ip}    ${zone_name}
    [Documentation]    Change transport zone in Compute and verify its configuration
    Utils.Run Command On Remote System    ${compute_ip}    ${CHANGE_TRANSPORT_ZONE}=${zone_name}
    ${output} =    Utils.Run Command On Remote System    ${compute_ip}    ${GET_EXTERNAL_IDS}
    BuiltIn.Should Contain    ${output}    ${zone_name}
