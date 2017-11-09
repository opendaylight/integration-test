*** Settings ***
Documentation     Suite description
Suite Setup       Setup_Everything
Suite Teardown    Teardown_Everything
Test Setup        SetupUtils.Setup_Test_With_Logging_And_Without_Fast_Failing
Test Teardown     FailFast.Start_Failing_Fast_If_This_Failed
Library           RequestsLibrary
Library           SSHLibrary
Library           OperatingSystem
Library           DateTime
Library           String
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
${BGP_CLI}        odl-bgpcep-bgp-cli
${BGP_VARIABLES_FOLDER}    ${CURDIR}/../../../variables/bgpuser/
${HOLDTIME}       180
${BGP_PEER_LOG_LEVEL}    debug
${ODL_LOG_LEVEL}    INFO
${ODL_BGP_LOG_LEVEL}    DEFAULT
${DEVICE_NAME}    controller-config
${BGP_PEER1_IP}    127.0.0.1
${BGP_PEER2_IP}    127.0.0.2
${BGP_PEER1_FIRST_PREFIX_IP}    8.1.0.0
${BGP_PEER2_FIRST_PREFIX_IP}    8.2.0.0
${PREFIX_LEN}     28
${BGP_PEER1_PREFIX_LEN}    ${PREFIX_LEN}
${BGP_PEER2_PREFIX_LEN}    ${PREFIX_LEN}
${PREFIX_COUNT}    3
${BGP_PEER1_PREFIX_COUNT}    ${PREFIX_COUNT}
${BGP_PEER2_PREFIX_COUNT}    ${PREFIX_COUNT}
${BGP_PEER1_COMMAND}    python play.py --firstprefix ${BGP_PEER1_FIRST_PREFIX_IP} --prefixlen ${BGP_PEER1_PREFIX_LEN} --amount ${BGP_PEER1_PREFIX_COUNT} --myip=${BGP_PEER1_IP} --myport=${BGP_TOOL_PORT} --peerip=${ODL_SYSTEM_IP} --peerport=${ODL_BGP_PORT}
${BGP_PEER2_COMMAND}    python play.py --firstprefix ${BGP_PEER2_FIRST_PREFIX_IP} --prefixlen ${BGP_PEER2_PREFIX_LEN} --amount ${BGP_PEER2_PREFIX_COUNT} --myip=${BGP_PEER2_IP} --myport=${BGP_TOOL_PORT} --peerip=${ODL_SYSTEM_IP} --peerport=${ODL_BGP_PORT}
${DEFAULT_TOPOLOGY_CHECK_TIMEOUT}    15s
${DEFAULT_TOPOLOGY_CHECK_PERIOD}    1s
${CONFIG_SESSION}    session
${RIB_INSTANCE}    example-bgp-rib
${PROTOCOL_OPENCONFIG}    ${RIB_INSTANCE}

*** Test Cases ***
Install_Cli
    [Documentation]    Tests whether required features are installed
    BuiltIn.Run_Keyword_And_Ignore_Error    KarafKeywords.Verify_Feature_Is_Installed    ${BGP_DEFAULT}
    BuiltIn.Run_Keyword_And_Ignore_Error    KarafKeywords.Verify_Feature_Is_Installed    ${BGP_CLI}

Configure_Two_iBGP_Route_Reflector_Client_Peers
    [Documentation]    Configure two iBGP peers as routing reflector clients.
    [Tags]    critical
    &{mapping}    BuiltIn.Create_Dictionary    DEVICE_NAME=${DEVICE_NAME}    NAME=example-bgp-peer1    IP=${BGP_PEER1_IP}    HOLDTIME=${HOLDTIME}    PEER_PORT=${BGP_TOOL_PORT}
    ...    PEER_ROLE=rr-client    INITIATE=false    BGP_RIB=${RIB_INSTANCE}    PASSIVE_MODE=true    BGP_RIB_OPENCONFIG=${PROTOCOL_OPENCONFIG}    RIB_INSTANCE_NAME=${RIB_INSTANCE}
    ...    RR_CLIENT=true
    TemplatedRequests.Put_As_Xml_Templated    ${BGP_VARIABLES_FOLDER}${/}ibgp_peers    mapping=${mapping}    session=${CONFIG_SESSION}
    &{mapping}    BuiltIn.Create_Dictionary    DEVICE_NAME=${DEVICE_NAME}    NAME=example-bgp-peer2    IP=${BGP_PEER2_IP}    HOLDTIME=${HOLDTIME}    PEER_PORT=${BGP_TOOL_PORT}
    ...    PEER_ROLE=rr-client    INITIATE=false    BGP_RIB=${RIB_INSTANCE}    PASSIVE_MODE=true    BGP_RIB_OPENCONFIG=${PROTOCOL_OPENCONFIG}    RIB_INSTANCE_NAME=${RIB_INSTANCE}
    ...    RR_CLIENT=true
    TemplatedRequests.Put_As_Xml_Templated    ${BGP_VARIABLES_FOLDER}${/}ibgp_peers    mapping=${mapping}    session=${CONFIG_SESSION}

Connect_BGP_Peer1
    [Documentation]    Connect BGP peer
    [Tags]    critical
    SSHLibrary.Switch Connection    bgp_peer1_console
    BGPcliKeywords.Start_Console_Tool    ${BGP_PEER1_COMMAND}    &>bgp_peer1.log
    BuiltIn.Wait_Until_Keyword_Succeeds    ${DEFAULT_TOPOLOGY_CHECK_TIMEOUT}    ${DEFAULT_TOPOLOGY_CHECK_PERIOD}    BgpOperations.Check_Example_IPv4_Topology_Content    {"prefix":"${BGP_PEER1_FIRST_PREFIX_IP}/${PREFIX_LEN}"}

Connect_BGP_Peer2
    [Documentation]    Connect BGP peer
    [Tags]    critical
    SSHLibrary.Switch Connection    bgp_peer2_console
    BGPcliKeywords.Start_Console_Tool    ${BGP_PEER2_COMMAND}    &>bgp_peer2.log
    BuiltIn.Wait_Until_Keyword_Succeeds    ${DEFAULT_TOPOLOGY_CHECK_TIMEOUT}    ${DEFAULT_TOPOLOGY_CHECK_PERIOD}    BgpOperations.Check_Example_IPv4_Topology_Content    {"prefix":"${BGP_PEER2_FIRST_PREFIX_IP}/${PREFIX_LEN}"}

Disconnect_BGP_Peer1
    [Documentation]    Stop BGP peer & store logs
    [Tags]    critical
    SSHLibrary.Switch Connection    bgp_peer1_console
    BGPcliKeywords.Stop_Console_Tool

Check_Cli_Returns
    [Documentation]    Tests results of commands through odl-bgpcep-bgp-cli
    [Tags]    critical
    BuiltIn.Repeat_Keyword    3 times    Test_Cli    3     0     3

Disconnect_BGP_Peer2
    [Documentation]    Stop BGP peer & store logs
    [Tags]    critical
    SSHLibrary.Switch Connection    bgp_peer2_console
    BGPcliKeywords.Stop_Console_Tool

Check_for_Empty_IPv4_Topology
    BuiltIn.Wait_Until_Keyword_Succeeds    ${DEFAULT_TOPOLOGY_CHECK_TIMEOUT}    ${DEFAULT_TOPOLOGY_CHECK_PERIOD}    BgpOperations.Check_Example_IPv4_Topology_Does_Not_Contain    prefix

Delete_BGP_Peers_Configuration
    [Documentation]    Delete all previously configured BGP peers.
    [Tags]    critical
    &{mapping}    BuiltIn.Create_Dictionary    DEVICE_NAME=${DEVICE_NAME}    NAME=example-bgp-peer1    IP=${BGP_PEER1_IP}    BGP_RIB_OPENCONFIG=${PROTOCOL_OPENCONFIG}
    TemplatedRequests.Delete_Templated    ${BGP_VARIABLES_FOLDER}${/}ibgp_peers    mapping=${mapping}    session=${CONFIG_SESSION}
    &{mapping}    BuiltIn.Create_Dictionary    DEVICE_NAME=${DEVICE_NAME}    NAME=example-bgp-peer2    IP=${BGP_PEER2_IP}    BGP_RIB_OPENCONFIG=${PROTOCOL_OPENCONFIG}
    TemplatedRequests.Delete_Templated    ${BGP_VARIABLES_FOLDER}${/}ibgp_peers    mapping=${mapping}    session=${CONFIG_SESSION}

Second_Check_Cli_Returns
    [Documentation]    Tests results of commands through odl-bgpcep-bgp-cli
    [Tags]    critical
    BuiltIn.Repeat_Keyword    3 times    Test_Cli    0    0    0

TC2_Configure_One_iBGP_Route_Reflector_Client_And_One_iBGP_Non_Client
    [Documentation]    Configure iBGP peers: 1st one as RR client, 2nd one as RR non-client.
    [Tags]    critical
    &{mapping}    BuiltIn.Create_Dictionary    DEVICE_NAME=${DEVICE_NAME}    NAME=example-bgp-peer1    IP=${BGP_PEER1_IP}    HOLDTIME=${HOLDTIME}    PEER_PORT=${BGP_TOOL_PORT}
    ...    PEER_ROLE=rr-client    INITIATE=false    BGP_RIB=${RIB_INSTANCE}    PASSIVE_MODE=true    BGP_RIB_OPENCONFIG=${PROTOCOL_OPENCONFIG}    RIB_INSTANCE_NAME=${RIB_INSTANCE}
    ...    RR_CLIENT=true
    TemplatedRequests.Put_As_Xml_Templated    ${BGP_VARIABLES_FOLDER}${/}ibgp_peers    mapping=${mapping}    session=${CONFIG_SESSION}
    &{mapping}    BuiltIn.Create_Dictionary    DEVICE_NAME=${DEVICE_NAME}    NAME=example-bgp-peer2    IP=${BGP_PEER2_IP}    HOLDTIME=${HOLDTIME}    PEER_PORT=${BGP_TOOL_PORT}
    ...    PEER_ROLE=ibgp    INITIATE=false    BGP_RIB=${RIB_INSTANCE}    PASSIVE_MODE=true    BGP_RIB_OPENCONFIG=${PROTOCOL_OPENCONFIG}    RIB_INSTANCE_NAME=${RIB_INSTANCE}
    ...    RR_CLIENT=false
    TemplatedRequests.Put_As_Xml_Templated    ${BGP_VARIABLES_FOLDER}${/}ibgp_peers    mapping=${mapping}    session=${CONFIG_SESSION}

TC2_Connect_BGP_Peer1
    [Documentation]    Connect BGP peer
    [Tags]    critical
    SSHLibrary.Switch Connection    bgp_peer1_console
    Start_Console_Tool    ${BGP_PEER1_COMMAND}    &>bgp_peer1.log
    BuiltIn.Wait_Until_Keyword_Succeeds    ${DEFAULT_TOPOLOGY_CHECK_TIMEOUT}    ${DEFAULT_TOPOLOGY_CHECK_PERIOD}    BgpOperations.Check_Example_IPv4_Topology_Content    {"prefix":"${BGP_PEER1_FIRST_PREFIX_IP}/${PREFIX_LEN}"}

TC2_Connect_BGP_Peer2
    [Documentation]    Connect BGP peer
    [Tags]    critical
    SSHLibrary.Switch Connection    bgp_peer2_console
    Start_Console_Tool    ${BGP_PEER2_COMMAND}    &>bgp_peer2.log
    BuiltIn.Wait_Until_Keyword_Succeeds    ${DEFAULT_TOPOLOGY_CHECK_TIMEOUT}    ${DEFAULT_TOPOLOGY_CHECK_PERIOD}    BgpOperations.Check_Example_IPv4_Topology_Content    {"prefix":"${BGP_PEER2_FIRST_PREFIX_IP}/${PREFIX_LEN}"}

TC2_Check_Cli_Returns
    [Documentation]    Tests results of commands through odl-bgpcep-bgp-cli
    [Tags]    critical
    Test_Cli    6     3     3

TC2_Disconnect_BGP_Peer1
    [Documentation]    Stop BGP peer & store logs
    [Tags]    critical
    SSHLibrary.Switch Connection    bgp_peer1_console
    Stop_Console_Tool

TC2_Second_Check_Cli_Returns
    [Documentation]    Tests results of commands through odl-bgpcep-bgp-cli
    [Tags]    critical
    Test_Cli    3     0     3

TC2_Disconnect_BGP_Peer2
    [Documentation]    Stop BGP peer & store logs
    [Tags]    critical
    SSHLibrary.Switch Connection    bgp_peer2_console
    Stop_Console_Tool

TC2_Third_Check_Cli_Returns
    [Documentation]    Tests results of commands through odl-bgpcep-bgp-cli
    [Tags]    critical
    BuiltIn.Repeat_Keyword    3 times    Test_Cli    0    0    0

TC2_Check_for_Empty_IPv4_Topology
    BuiltIn.Wait_Until_Keyword_Succeeds    ${DEFAULT_TOPOLOGY_CHECK_TIMEOUT}    ${DEFAULT_TOPOLOGY_CHECK_PERIOD}    BgpOperations.Check_Example_IPv4_Topology_Does_Not_Contain    prefix

TC2_Delete_BGP_Peers_Configuration
    [Documentation]    Delete all previously configured BGP peers.
    [Tags]    critical
    &{mapping}    BuiltIn.Create_Dictionary    DEVICE_NAME=${DEVICE_NAME}    NAME=example-bgp-peer1    IP=${BGP_PEER1_IP}    BGP_RIB_OPENCONFIG=${PROTOCOL_OPENCONFIG}
    TemplatedRequests.Delete_Templated    ${BGP_VARIABLES_FOLDER}${/}ibgp_peers    mapping=${mapping}    session=${CONFIG_SESSION}
    &{mapping}    BuiltIn.Create_Dictionary    DEVICE_NAME=${DEVICE_NAME}    NAME=example-bgp-peer2    IP=${BGP_PEER2_IP}    BGP_RIB_OPENCONFIG=${PROTOCOL_OPENCONFIG}
    TemplatedRequests.Delete_Templated    ${BGP_VARIABLES_FOLDER}${/}ibgp_peers    mapping=${mapping}    session=${CONFIG_SESSION}

*** Keywords ***
Setup_Everything
    SetupUtils.Setup_Utils_For_Setup_And_Teardown
    SSHLibrary.Set_Default_Configuration    prompt=${ODL_SYSTEM_PROMPT}
    SSHLibrary.Open_Connection    ${ODL_SYSTEM_IP}    alias=bgp_peer1_console
    SSHKeywords.Flexible_Controller_Login
    SSHLibrary.Open_Connection    ${ODL_SYSTEM_IP}    alias=bgp_peer2_console
    SSHKeywords.Flexible_Controller_Login
    SSHKeywords.Require_Python
    SSHKeywords.Assure_Library_Ipaddr    target_dir=.
    SSHLibrary.Put_File    ${CURDIR}/../../../../tools/fastbgp/play.py
    RequestsLibrary.Create_Session    operational    http://${ODL_SYSTEM_IP}:${RESTCONFPORT}${OPERATIONAL_TOPO_API}    auth=${AUTH}
    RequestsLibrary.Create_Session    ${CONFIG_SESSION}    http://${ODL_SYSTEM_IP}:${RESTCONFPORT}    auth=${AUTH}

Teardown_Everything
    SSHLibrary.Close_All_Connections
    RequestsLibrary.Delete_All_Sessions

Test_Cli
    [Arguments]    ${bgp_rib_value}=0    ${ibgp_1}=0    ${ibgp_2}=0
    [Documentation]    Verifies values of bgp-cli returns
    [Tags]    critical
    BuiltIn.Wait_Until_Keyword_Succeeds    3x    2s    Test_Bgp_Rib    bgp_rib_value=${bgp_rib_value}
    BuiltIn.Wait_Until_Keyword_Succeeds    3x    2s    Test_Bgp_Rib_Neighbor1    ibgp_1=${ibgp_1}
    BuiltIn.Wait_Until_Keyword_Succeeds    3x    2s    Test_Bgp_Rib_Neighbor2    ibgp_2=${ibgp_2}
    ${output}=    BuiltIn.Wait_Until_Keyword_Succeeds    3x    1s    KarafKeywords.Safe_Issue_Command_On_Karaf_Console    bgp:operational-state -rib example-bgp-rib -peer-group application-peers
    BuiltIn.Log    ${output}
    ${ret}=    Normalize_String    ${output}
    BuiltIn.Log    ${ret}

Test_Bgp_Rib
    [Arguments]    ${bgp_rib_value}
    ${output}=    KarafKeywords.Safe_Issue_Command_On_Karaf_Console    bgp:operational-state -rib example-bgp-rib
    BuiltIn.Log    ${output}
    ${ret}=    Normalize_String    ${output}
    BuiltIn.Should_Contain    ${ret}    TotalPrefixes|${bgp_rib_value}

Test_Bgp_Rib_Neighbor1
    [Arguments]    ${ibgp_1}
    ${output}=    BuiltIn.Wait_Until_Keyword_Succeeds    3x    1s    KarafKeywords.Safe_Issue_Command_On_Karaf_Console    bgp:operational-state -rib example-bgp-rib -neighbor 127.0.0.1
    BuiltIn.Log    ${output}
    ${ret}=    Normalize_String    ${output}
    BuiltIn.Should_Contain    ${ret}    Installed|${ibgp_1}

Test_Bgp_Rib_Neighbor2
    [Arguments]    ${ibgp_2}
    ${output}=    BuiltIn.Wait_Until_Keyword_Succeeds    3x    1s    KarafKeywords.Safe_Issue_Command_On_Karaf_Console    bgp:operational-state -rib example-bgp-rib -neighbor 127.0.0.2
    BuiltIn.Log    ${output}
    ${ret}=    Normalize_String    ${output}
    BuiltIn.Should_Contain    ${ret}    Installed|${ibgp_2}

Normalize_String
    [Arguments]    ${string}
    ${string}=   String.Remove_String   ${string}    ${SPACE}   \n
    [Return]    ${string}
