*** Settings ***
Documentation    Suite description
Suite Setup       Setup_Everything
Suite Teardown    Teardown_Everything
Test Setup        SetupUtils.Setup_Test_With_Logging_And_Without_Fast_Failing
Test Teardown     FailFast.Start_Failing_Fast_If_This_Failed
Library           RequestsLibrary
Library           SSHLibrary
Library           OperatingSystem
Library           DateTime
Variables         ${CURDIR}/../../../variables/Variables.py
Variables         ${CURDIR}/../../../variables/bgpuser/variables.py    ${TOOLS_SYSTEM_IP}    ${ODL_STREAM}
Resource          ${CURDIR}/../../../libraries/KarafKeywords.robot
Resource          ${CURDIR}/../../../libraries/SetupUtils.robot
Resource          ${CURDIR}/../../../libraries/TemplatedRequests.robot
Resource          ${CURDIR}/../../../libraries/BGPcliKeywords.robot
Resource          ${CURDIR}/../../../libraries/BgpOperations.robot
Resource          ${CURDIR}/../../../libraries/BGPSpeaker.robot
Resource          ${CURDIR}/../../../libraries/FailFast.robot
Resource          ${CURDIR}/../../../libraries/KillPythonTool.robot
Resource          ${CURDIR}/../../../libraries/SSHKeywords.robot
Resource          ${CURDIR}/../../../libraries/Utils.robot
Resource          ${CURDIR}/../../../libraries/WaitForFailure.robot


*** Variables ***
${BGP_DEFAULT}    odl-bgpcep-bgp-config-example
${BGP_CLI}    odl-bgpcep-bgp-cli
${BGP_VARIABLES_FOLDER}    ${CURDIR}/../../../variables/bgpuser/
${HOLDTIME}       180
${BGP_PEER_LOG_LEVEL}    debug
${ODL_LOG_LEVEL}    INFO
${ODL_BGP_LOG_LEVEL}    DEFAULT
${DEVICE_NAME}    controller-config
${BGP_PEER1_IP}    127.0.0.1
${BGP_PEER1_FIRST_PREFIX_IP}    8.1.0.0
${PREFIX_LEN}     28
${BGP_PEER1_PREFIX_LEN}    ${PREFIX_LEN}
${PREFIX_COUNT}    3
${BGP_PEER1_PREFIX_COUNT}    ${PREFIX_COUNT}
${BGP_PEER1_LOG_FILE}    bgp_peer1.log
${BGP_PEER1_COMMAND}    python play.py --firstprefix ${BGP_PEER1_FIRST_PREFIX_IP} --prefixlen ${BGP_PEER1_PREFIX_LEN} --amount ${BGP_PEER1_PREFIX_COUNT} --myip=${BGP_PEER1_IP} --myport=${BGP_TOOL_PORT} --peerip=${ODL_SYSTEM_IP} --peerport=${ODL_BGP_PORT} --${BGP_PEER_LOG_LEVEL} --logfile ${BGP_PEER1_LOG_FILE}
${BGP_PEER1_OPTIONS}    &>${BGP_PEER1_LOG_FILE}
${DEFAULT_LOG_CHECK_TIMEOUT}    20s
${DEFAULT_LOG_CHECK_PERIOD}    1s
${DEFAULT_TOPOLOGY_CHECK_TIMEOUT}    10s
${DEFAULT_TOPOLOGY_CHECK_PERIOD}    1s
${CONFIG_SESSION}    session
${RIB_INSTANCE}    example-bgp-rib
${PROTOCOL_OPENCONFIG}    ${RIB_INSTANCE}
${DEVICE_NAME}    controller-config

*** Test Cases ***
Install_Cli
    [Documentation]    Tests whethere required features are installed
    KarafKeywords.Verify_Feature_Is_Installed    ${BGP_DEFAULT}
    KarafKeywords.Verify_Feature_Is_Installed    ${BGP_CLI}

TC1_Configure_Two_iBGP_Route_Reflector_Client_Peers
    [Documentation]    Configure two iBGP peers as routing reflector clients.
    [Tags]    critical
    &{mapping}    BuiltIn.Create_Dictionary    DEVICE_NAME=${DEVICE_NAME}    NAME=example-bgp-peer1    IP=${BGP_PEER1_IP}    HOLDTIME=${HOLDTIME}    PEER_PORT=${BGP_TOOL_PORT}
    ...    PEER_ROLE=rr-client    INITIATE=false    BGP_RIB=${RIB_INSTANCE}    PASSIVE_MODE=true    BGP_RIB_OPENCONFIG=${PROTOCOL_OPENCONFIG}    RIB_INSTANCE_NAME=${RIB_INSTANCE}
    ...    RR_CLIENT=true
    TemplatedRequests.Put_As_Xml_Templated    ${BGP_VARIABLES_FOLDER}${/}ibgp_peers    mapping=${mapping}    session=${CONFIG_SESSION}

TC1_Connect_BGP_Peer1
    [Documentation]    Connect BGP peer
    [Tags]    critical
    BGPcliKeywords.Start_Console_Tool    ${BGP_PEER1_COMMAND}    ${BGP_PEER1_OPTIONS}
    BuiltIn.Wait_Until_Keyword_Succeeds    ${DEFAULT_TOPOLOGY_CHECK_TIMEOUT}    ${DEFAULT_TOPOLOGY_CHECK_PERIOD}    BgpOperations.Check_Example_IPv4_Topology_Content

Test_Cli
    [Documentation]
    ${output}=    KarafKeywords.Issue_Command_On_Karaf_Console    bgp:operational-state -rib example-bgp-rib
    BuiltIn.Log    ${output}
    ${output}=    KarafKeywords.Issue_Command_On_Karaf_Console    bgp:operational-state -rib example-bgp-rib -neighbor 192.0.2.1
    BuiltIn.Log    ${output}
    ${output}=    KarafKeywords.Issue_Command_On_Karaf_Console    bgp:operational-state -rib example-bgp-rib -neighbor 127.0.0.1
    BuiltIn.Log    ${output}
    ${output}=    KarafKeywords.Issue_Command_On_Karaf_Console    bgp:operational-state -rib example-bgp-rib -neighbor 127.0.0.2
    BuiltIn.Log    ${output}

TC1_Disconnect_BGP_Peer1
    [Documentation]    Stop BGP peer & store logs
    [Tags]    critical
    BGPcliKeywords.Stop_Console_Tool
    BGPcliKeywords.Store_File_To_Workspace    ${BGP_PEER1_LOG_FILE}    tc1_${BGP_PEER1_LOG_FILE}


*** Keywords ***
Setup_Everything
    SetupUtils.Setup_Utils_For_Setup_And_Teardown
    ${tools_system_conn_id}=    SSHLibrary.Open_Connection    ${TOOLS_SYSTEM_IP}    prompt=${DEFAULT_LINUX_PROMPT}    timeout=6s
    Builtin.Set_Suite_Variable    ${tools_system_conn_id}
    RequestsLibrary.Create_Session    session    http://${ODL_SYSTEM_IP}:${RESTCONFPORT}    auth=${AUTH}

Teardown_Everything
    SSHLibrary.Close_All_Connections
    RequestsLibrary.Delete_All_Sessions
