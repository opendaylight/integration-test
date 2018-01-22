*** Settings ***
Documentation     This suite is a common keywordis file for genius project.
Library           Collections
Library           OperatingSystem
Library           RequestsLibrary
Library           SSHLibrary
Library           re
Library           string
Resource          KarafKeywords.robot
Resource          Utils.robot
Resource          ../variables/Variables.robot

*** Variables ***

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
    Run_Keyword_If_At_Least_Oxygen    Check Service Status    ACTIVE    OPERATIONAL
    Log    Start the tests
    ${conn_id_1}=    Open Connection    ${TOOLS_SYSTEM_IP}    prompt=${DEFAULT_LINUX_PROMPT}    timeout=30s
    Set Global Variable    ${conn_id_1}
    KarafKeywords.Setup_Karaf_Keywords
    ${karaf_debug_enabled}    BuiltIn.Get_Variable_Value    ${KARAF_DEBUG}    ${False}
    BuiltIn.run_keyword_if    ${karaf_debug_enabled}    KarafKeywords.Execute_Controller_Karaf_Command_On_Background    log:set DEBUG org.opendaylight.genius
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

Check Service Status
    [Arguments]    ${system_ready_state}    ${service_state}
    [Documentation]    Issues the karaf shell command showSvcStatus to verify the ready and service states are the same as the arguments passed
    ${service_status_output}    Issue_Command_On_Karaf_Console    showSvcStatus    ${ODL_SYSTEM_IP}    8101
    Should Contain    ${service_status_output}    ${system_ready_state}
    @{split}    Split To Lines    ${service_status_output}    3    7
    : FOR    ${var}    IN    @{split}
    \    Should Contain    ${var}    ${service_state}

Create Vteps
    [Arguments]    ${TOOLS_SYSTEM_IP}    ${TOOLS_SYSTEM_2_IP}    ${vlan}    ${gateway-ip}
    [Documentation]    This keyword creates VTEPs between ${TOOLS_SYSTEM_IP} and ${TOOLS_SYSTEM_2_IP}
    ${body}    OperatingSystem.Get File    ${genius_config_dir}/Itm_creation_no_vlan.json
    ${substr}    Should Match Regexp    ${TOOLS_SYSTEM_IP}    [0-9]\{1,3}\.[0-9]\{1,3}\.[0-9]\{1,3}\.
    ${subnet}    Catenate    ${substr}0
    Log    ${subnet}
    Set Global Variable    ${subnet}
    ${vlan}=    Set Variable    ${vlan}
    ${gateway-ip}=    Set Variable    ${gateway-ip}
    ${body}    Set Json    ${TOOLS_SYSTEM_IP}    ${TOOLS_SYSTEM_2_IP}    ${vlan}    ${gateway-ip}    ${subnet}
    ${vtep_body}    Set Variable    ${body}
    Set Global Variable    ${vtep_body}
    ${resp}    RequestsLibrary.Post Request    session    ${CONFIG_API}/itm:transport-zones/    data=${body}
    Log    ${resp.status_code}
    should be equal as strings    ${resp.status_code}    204

Set Json
    [Arguments]    ${TOOLS_SYSTEM_IP}    ${TOOLS_SYSTEM_2_IP}    ${vlan}    ${gateway-ip}    ${subnet}
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
    Log    ${resp.status_code}
    Should Be Equal As Strings    ${resp.status_code}    200
    Log    "Before disconnecting CSS with controller"
    ${output}=    Issue Command On Karaf Console    ${TEP_SHOW}
    Log    ${output}
    ${output}=    Issue Command On Karaf Console    ${TEP_SHOW_STATE}
    Log    ${output}
