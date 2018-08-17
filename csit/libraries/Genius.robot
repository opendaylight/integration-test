*** Settings ***
Documentation     This suite is a common keywords file for genius project.
Library           Collections
Library           OperatingSystem
Library           re
Library           RequestsLibrary
Library           SSHLibrary
Library           string
Resource          ClusterManagement.robot
Resource          DataModels.robot
Resource          KarafKeywords.robot
Resource          ODLTools.robot
Resource          OVSDB.robot
Resource          Utils.robot
Resource          VpnOperations.robot
Resource          ../variables/Variables.robot
Resource          ../variables/netvirt/Variables.robot

*** Variables ***
@{itm_created}    TZA
${genius_config_dir}    ${CURDIR}/../variables/genius
${Bridge-1}       BR1
${Bridge-2}       BR2
${DEFAULT_MONITORING_INTERVAL}    Tunnel Monitoring Interval (for VXLAN tunnels): 1000
@{GENIUS_DIAG_SERVICES}    OPENFLOW    IFM    ITM    DATASTORE    OVSDB
${vlan}           0
${gateway-ip}     0.0.0.0

*** Keywords ***
Genius Suite Setup
    [Documentation]    Create Rest Session to http://${ODL_SYSTEM_IP}:${RESTCONFPORT}
    Start Suite
    Create Session    session    http://${ODL_SYSTEM_IP}:${RESTCONFPORT}    auth=${AUTH}    headers=${HEADERS}    timeout=5

Genius Suite Teardown
    [Documentation]    Delete all sessions
    Delete All Sessions
    Stop Suite

Start Suite
    [Documentation]    Initial setup for Genius test suites
    Run_Keyword_If_At_Least_Oxygen    Wait Until Keyword Succeeds    60    2    ClusterManagement.Check Status Of Services Is OPERATIONAL    @{GENIUS_DIAG_SERVICES}
    Log    Start the tests
    ${conn_id_1}=    Open Connection    ${TOOLS_SYSTEM_IP}    prompt=${DEFAULT_LINUX_PROMPT}    timeout=30s
    Set Global Variable    ${conn_id_1}
    KarafKeywords.Setup_Karaf_Keywords
    ${karaf_debug_enabled}    BuiltIn.Get_Variable_Value    ${KARAF_DEBUG}    ${False}
    BuiltIn.run_keyword_if    ${karaf_debug_enabled}    KarafKeywords.Execute_Controller_Karaf_Command_On_Background    log:set DEBUG org.opendaylight.genius
    BuiltIn.Run Keyword And Ignore Error    KarafKeywords.Log_Test_Suite_Start_To_Controller_Karaf
    Login With Public Key    ${TOOLS_SYSTEM_USER}    ${USER_HOME}/.ssh/${SSH_KEY}    any
    Log    ${conn_id_1}
    Execute Command    sudo ovs-vsctl add-br BR1
    Execute Command    sudo ovs-vsctl set bridge BR1 protocols=OpenFlow13
    Execute Command    sudo ovs-vsctl set-controller BR1 tcp:${ODL_SYSTEM_IP}:6633
    Execute Command    sudo ifconfig BR1 up
    Execute Command    sudo ovs-vsctl add-port BR1 tap8ed70586-6c -- set Interface tap8ed70586-6c type=tap
    Execute Command    sudo ovs-vsctl set-manager tcp:${ODL_SYSTEM_IP}:6640
    ${output_1}    Execute Command    sudo ovs-vsctl show
    Log    ${output_1}
    ${check}    Wait Until Keyword Succeeds    30    10    check establishment    ${conn_id_1}    6633
    log    ${check}
    ${check_2}    Wait Until Keyword Succeeds    30    10    check establishment    ${conn_id_1}    6640
    log    ${check_2}
    Log    >>>>>Switch 2 configuration <<<<<
    ${conn_id_2}=    Open Connection    ${TOOLS_SYSTEM_2_IP}    prompt=${DEFAULT_LINUX_PROMPT}    timeout=30s
    Set Global Variable    ${conn_id_2}
    Login With Public Key    ${TOOLS_SYSTEM_USER}    ${USER_HOME}/.ssh/${SSH_KEY}    any
    Log    ${conn_id_2}
    Execute Command    sudo ovs-vsctl add-br BR2
    Execute Command    sudo ovs-vsctl set bridge BR2 protocols=OpenFlow13
    Execute Command    sudo ovs-vsctl set-controller BR2 tcp:${ODL_SYSTEM_IP}:6633
    Execute Command    sudo ifconfig BR2 up
    Execute Command    sudo ovs-vsctl set-manager tcp:${ODL_SYSTEM_IP}:6640
    ${output_2}    Execute Command    sudo ovs-vsctl show
    Log    ${output_2}

Stop Suite
    Log    Stop the tests
    Switch Connection    ${conn_id_1}
    Log    ${conn_id_1}
    Execute Command    sudo ovs-vsctl del-br BR1
    Execute Command    sudo ovs-vsctl del-manager
    Write    exit
    close connection
    Switch Connection    ${conn_id_2}
    Log    ${conn_id_2}
    Execute Command    sudo ovs-vsctl del-br BR2
    Execute Command    sudo ovs-vsctl del-manager
    Write    exit
    close connection

check establishment
    [Arguments]    ${conn_id}    ${port}
    Switch Connection    ${conn_id}
    ${check_establishment}    Execute Command    netstat -anp | grep ${port}
    Should contain    ${check_establishment}    ESTABLISHED
    [Return]    ${check_establishment}

Create Vteps
    [Arguments]    ${Dpn_id_1}    ${Dpn_id_2}    ${TOOLS_SYSTEM_IP}    ${TOOLS_SYSTEM_2_IP}    ${vlan}    ${gateway-ip}
    [Documentation]    This keyword creates VTEPs between ${TOOLS_SYSTEM_IP} and ${TOOLS_SYSTEM_2_IP}
    ${body}    OperatingSystem.Get File    ${genius_config_dir}/Itm_creation_no_vlan.json
    ${substr}    Should Match Regexp    ${TOOLS_SYSTEM_IP}    [0-9]\{1,3}\.[0-9]\{1,3}\.[0-9]\{1,3}\.
    ${subnet}    Catenate    ${substr}0
    Log    ${subnet}
    Set Global Variable    ${subnet}
    ${vlan}=    Set Variable    ${vlan}
    ${gateway-ip}=    Set Variable    ${gateway-ip}
    ${body}    Genius.Set Json    ${Dpn_id_1}    ${Dpn_id_2}    ${TOOLS_SYSTEM_IP}    ${TOOLS_SYSTEM_2_IP}    ${vlan}
    ...    ${gateway-ip}    ${subnet}
    ${vtep_body}    Set Variable    ${body}
    Set Global Variable    ${vtep_body}
    ${resp}    RequestsLibrary.Post Request    session    ${CONFIG_API}/itm:transport-zones/    data=${body}
    Log    ${resp.status_code}
    should be equal as strings    ${resp.status_code}    204

Set Json
    [Arguments]    ${Dpn_id_1}    ${Dpn_id_2}    ${TOOLS_SYSTEM_IP}    ${TOOLS_SYSTEM_2_IP}    ${vlan}    ${gateway-ip}
    ...    ${subnet}
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
    # "echo \$\(\(16\#${output1}\)\) command below converts ovs dpnid (i.e., output1) from hexadecimal to decimal."
    ${Dpn_id}    Execute command    echo \$\(\(16\#${output1}\)\)
    log    ${Dpn_id}
    [Return]    ${Dpn_id}

BFD Suite Stop
    [Documentation]    Run at end of BFD suite
    Delete All Vteps
    Stop Suite

Delete All Vteps
    [Documentation]    This will delete vtep.
    ${resp}    RequestsLibrary.Delete Request    session    ${CONFIG_API}/itm:transport-zones/    data=${vtep_body}
    Should Be Equal As Strings    ${resp.status_code}    200
    Log    "Before disconnecting CSS with controller"
    ${output} =    Issue Command On Karaf Console    ${TEP_SHOW}
    BuiltIn.Wait Until Keyword Succeeds    30    5    Verify All Tunnel Delete on DS

Genius Test Setup
    [Documentation]    Genius test case setup
    BuiltIn.Run Keyword And Ignore Error    KarafKeywords.Log_Testcase_Start_To_Controller_Karaf

Genius Test Teardown
    [Arguments]    ${data_models}    ${test_name}=${SUITE_NAME}.${TEST_NAME}    ${fail}=${FAIL_ON_EXCEPTIONS}
    OVSDB.Get DumpFlows And Ovsconfig    ${conn_id_1}    BR1
    OVSDB.Get DumpFlows And Ovsconfig    ${conn_id_2}    BR2
    BuiltIn.Run Keyword And Ignore Error    DataModels.Get Model Dump    ${ODL_SYSTEM_IP}    ${data_models}
    KarafKeywords.Fail If Exceptions Found During Test    ${test_name}    fail=${fail}
    ODLTools.Get All

Genius Suite Debugs
    [Arguments]    ${data_models}
    Genius Test Teardown    ${data_models}    test_name=${SUITE_NAME}    fail=False

ITM Direct Tunnels Start Suite
    [Documentation]    start suite for itm scalability
    ClusterManagement.ClusterManagement_Setup
    ClusterManagement.Stop_Members_From_List_Or_All
    : FOR    ${i}    IN RANGE    ${NUM_ODL_SYSTEM}
    \    Run Command On Remote System And Log    ${ODL_SYSTEM_${i+1}_IP}    sed -i -- 's/<itm-direct-tunnels>false/<itm-direct-tunnels>true/g' ${GENIUS_IFM_CONFIG_FLAG}
    ClusterManagement.Start_Members_From_List_Or_All
    Genius Suite Setup

ITM Direct Tunnels Stop Suite
    : FOR    ${i}    IN RANGE    ${NUM_ODL_SYSTEM}
    \    Run Command On Remote System And Log    ${ODL_SYSTEM_${i+1}_IP}    sed -i -- 's/<itm-direct-tunnels>true/<itm-direct-tunnels>false/g' ${GENIUS_IFM_CONFIG_FLAG}
    Genius Suite Teardown

Verify Tunnel Monitoring is on
    [Documentation]    This keyword will get tep:show output and verify tunnel monitoring status
    ${output}=    Issue Command On Karaf Console    ${TEP_SHOW}
    Should Contain    ${output}    ${TUNNEL_MONITOR_ON}

Ovs Verification For 2 Dpn
    [Arguments]    ${connection_id}    ${local}    ${remote-1}    ${tunnel}    ${tunnel-type}
    [Documentation]    Checks whether the created Interface is seen on OVS or not.
    Switch Connection    ${connection_id}
    ${check}    Execute Command    sudo ovs-vsctl show
    Log    ${check}
    Should Contain    ${check}    local_ip="${local}"    remote_ip="${remote-1}"    ${tunnel}    ${tunnel-type}
    [Return]    ${check}

Get ITM
    [Arguments]    ${itm_created[0]}    ${subnet}    ${vlan}    ${Dpn_id_1}    ${TOOLS_SYSTEM_IP}    ${Dpn_id_2}
    ...    ${TOOLS_SYSTEM_2_IP}
    [Documentation]    It returns the created ITM Transport zone with the passed values during the creation is done.
    Log    ${itm_created[0]},${subnet}, ${vlan}, ${Dpn_id_1},${TOOLS_SYSTEM_IP}, ${Dpn_id_2}, ${TOOLS_SYSTEM_2_IP}
    @{Itm-no-vlan}    Create List    ${itm_created[0]}    ${subnet}    ${vlan}    ${Dpn_id_1}    ${Bridge-1}-eth1
    ...    ${TOOLS_SYSTEM_IP}    ${Dpn_id_2}    ${Bridge-2}-eth1    ${TOOLS_SYSTEM_2_IP}
    Check For Elements At URI    ${TUNNEL_TRANSPORTZONE}/transport-zone/${itm_created[0]}    ${Itm-no-vlan}

Check Tunnel Delete On OVS
    [Arguments]    ${connection-id}    ${tunnel}
    [Documentation]    Verifies the Tunnel is deleted from OVS.
    Switch Connection    ${connection-id}
    ${return} =    Execute Command    sudo ovs-vsctl show
    log    ${return}
    Should Not Contain    ${return}    ${tunnel}
    [Return]    ${return}

Check Table0 Entry For 2 Dpn
    [Arguments]    ${connection_id}    ${Bridgename}    ${port-num1}
    [Documentation]    Checks the Table 0 entry in the OVS when flows are dumped.
    Switch Connection    ${connection_id}
    Log    ${connection_id}
    ${check}    Execute Command    sudo ovs-ofctl -O OpenFlow13 dump-flows ${Bridgename}
    Log    ${check}
    Should Contain    ${check}    in_port=${port-num1}
    [Return]    ${check}

Check ITM Tunnel State
    [Arguments]    ${tunnel1}    ${tunnel2}
    [Documentation]    Verifies the Tunnel is deleted from datastore
    ${resp}    RequestsLibrary.Get Request    session    ${OPERATIONAL_API}/itm-state:tunnels_state/
    Should Not Contain    ${resp.content}    ${tunnel1}    ${tunnel2}

Verify Tunnel Status as UP
    [Arguments]    ${Transport_zone}
    [Documentation]    Verify that the number of tunnels are UP
    ${No_of_Teps}    Issue_Command_On_Karaf_Console    ${TEP_SHOW}
    ${Lines_of_TZA}    Get Lines Containing String    ${No_of_Teps}    ${Transport_zone}
    ${Expected_Node_Count}    Get Line Count    ${Lines_of_TZA}
    ${no_of_tunnels}    Issue_Command_On_Karaf_Console    ${TEP_SHOW_STATE}
    ${lines_of_VXLAN}    Get Lines Containing String    ${no_of_tunnels}    VXLAN
    Should Contain    ${no_of_tunnels}    ${STATE_UP}
    Should Not Contain    ${no_of_tunnels}    ${STATE_DOWN}
    Should Not Contain    ${no_of_tunnels}    ${STATE_UNKNOWN}
    ${Actual_Tunnel_Count}    Get Line Count    ${lines_of_VXLAN}
    ${Expected_Tunnel_Count}    Set Variable    ${Expected_Node_Count*${Expected_Node_Count - 1}}
    Should Be Equal As Strings    ${Actual_Tunnel_Count}    ${Expected_Tunnel_Count}

Verify Tunnel Status
    [Arguments]    ${tunnel_names}    ${tunnel_status}
    [Documentation]    Verifies if all tunnels in the input, has the expected status(UP/DOWN/UNKNOWN)
    ${tep_result} =    KarafKeywords.Issue_Command_On_Karaf_Console    ${TEP_SHOW_STATE}
    : FOR    ${tunnel}    IN    @{tunnel_names}
    \    ${tep_output} =    String.Get Lines Containing String    ${tep_result}    ${tunnel}
    \    BuiltIn.Should Contain    ${tep_output}    ${tunnel_status}

Get Tunnels On OVS
    [Arguments]    ${connection_id}
    [Documentation]    Retrieves the list of tunnel ports present on OVS
    SSHLibrary.Switch Connection    ${connection_id}
    ${ovs_result} =    Utils.Write Commands Until Expected Prompt    sudo ovs-vsctl show    ${DEFAULT_LINUX_PROMPT_STRICT}
    ${tunnel_names}    BuiltIn.Create List
    ${tunnels} =    String.Get Lines Matching Regexp    ${ovs_result}    Interface "tun.*"    True
    @{tunnels_list} =    String.Split To Lines    ${tunnels}
    : FOR    ${tun}    IN    @{tunnels_list}
    \    ${tun_list}    BuiltIn.Should Match Regexp    @{tunnels_list}    tun.*\\w
    \    Collections.Append To List    ${tunnel_names}    ${tun_list}
    ${items_in_list} =    BuiltIn.Get Length    ${tunnel_names}
    [Return]    ${Tunnel_Names}

Get Tunnel
    [Arguments]    ${src}    ${dst}    ${type}
    [Documentation]    This keyword returns tunnel interface name between source DPN and destination DPN.
    ${resp} =    RequestsLibrary.Get Request    session    ${CONFIG_API}/itm-state:tunnel-list/internal-tunnel/${src}/${dst}/${type}/
    BuiltIn.Should Be Equal As Strings    ${resp.status_code}    ${RESP_CODE}
    BuiltIn.Should Contain    ${resp.content}    ${src}
    BuiltIn.Should Contain    ${resp.content}    ${dst}
    ${json} =    Utils.Json Parse From String    ${resp.content}
    ${tunnel} =    BuiltIn.Run Keyword If    "tunnel-interface-names" in "${json}"    Get Tunnel Interface Name    ${json["internal-tunnel"][0]}    tunnel-interface-names
    [Return]    ${tunnel}

Get Tunnel Interface Name
    [Arguments]    ${json}    ${expected_tunnel_interface_name}
    [Documentation]    This keyword extracts tunnel interface name from json given as input.
    ${tunnels} =    Collections.Get From Dictionary    ${json}    ${expected_tunnel_interface_name}
    [Return]    ${tunnels[0]}

Verify All Tunnel Delete on DS
    [Documentation]    This keyword confirms that tunnels are not present by giving command from karaf console.
    Verify Tunnel Delete on DS    tun

Verify Tunnel Delete on DS
    [Arguments]    ${tunnel}
    [Documentation]    This keyword confirms that specified tunnel is not present by giving command from karaf console.
    ${output} =    KarafKeywords.Issue Command On Karaf Console    ${TEP_SHOW_STATE}
    BuiltIn.Should Not Contain    ${output}    ${tunnel}

SRM Start Suite
    [Documentation]    Start suite for service recovery.
    Genius Suite Setup
    ${dpn_Id_1} =    Genius.Get Dpn Ids    ${conn_id_1}
    ${dpn_Id_2} =    Genius.Get Dpn Ids    ${conn_id_2}
    Genius.Create Vteps    ${dpn_Id_1}    ${dpn_Id_2}    ${TOOLS_SYSTEM_IP}    ${TOOLS_SYSTEM_2_IP}    ${vlan}    ${gateway-ip}
    ${tunnel} =    BuiltIn.Wait Until Keyword Succeeds    40    20    Genius.Get Tunnel    ${dpn_Id_1}    ${dpn_Id_2}
    ...    odl-interface:tunnel-type-vxlan
    BuiltIn.Wait Until Keyword Succeeds    60s    5s    Genius.Verify Tunnel Status as UP    TZA
    Genius Suite Debugs    ${data_models}

SRM Stop Suite
    [Documentation]    Stop suite for service recovery.
    Delete All Vteps
    Genius Suite Debugs    ${data_models}
    Genius Suite Teardown
