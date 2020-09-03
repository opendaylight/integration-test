*** Settings ***
Documentation     Functional test for bgp flowspec.
...
...               Copyright (c) 2016 Cisco Systems, Inc. and others. All rights reserved.
...
...               This program and the accompanying materials are made available under the
...               terms of the Eclipse Public License v1.0 which accompanies this distribution,
...               and is available at http://www.eclipse.org/legal/epl-v10.html
Suite Setup       Start_Suite
Suite Teardown    Stop_Suite
Library           RequestsLibrary
Library           SSHLibrary
Resource          ../../../libraries/CompareStream.robot
Resource          ../../../libraries/ExaBgpLib.robot
Resource          ../../../libraries/SSHKeywords.robot
Resource          ../../../libraries/TemplatedRequests.robot
Resource          ../../../variables/Variables.robot

*** Variables ***
${BGP_VARIABLES_FOLDER}    ${CURDIR}/../../../variables/bgpflowspec/
${CMD}            env exabgp.tcp.port=1790 exabgp --debug
${HOLDTIME}       180
${OLD_AS_PATH}    \n"as-path": {},
${NEW_AS_PATH}    ${EMPTY}
${EXP0}           {"bgp-flowspec:flowspec-routes": {}}
${CFG1}           bgp-flowspec.cfg
${EXP1}           bgp_flowspec
${CFG2}           bgp-flowspec-redirect.cfg
${EXP2}           bgp_flowspec_redirect
${FLOWSPEC_URL}    /restconf/operational/bgp-rib:bgp-rib/rib/example-bgp-rib/loc-rib/tables/bgp-types:ipv4-address-family/bgp-flowspec:flowspec-subsequent-address-family/bgp-flowspec:flowspec-routes
${CONFIG_SESSION}    session
${DEVICE_NAME}    controller-config
${RIB_INSTANCE}    example-bgp-rib
${PROTOCOL_OPENCONFIG}    ${RIB_INSTANCE}
@{EMPTY_LIST}

*** Test Cases ***
Check_For_Empty_Topology_Before_Talking
    [Documentation]    Sanity check bgp-flowspec:flowspec-routes is up but empty.
    [Tags]    critical
    BuiltIn.Wait_Until_Keyword_Succeeds    60s    3s    Verify_Empty_Flowspec_Data

Reconfigure_ODL_To_Accept_Connection
    [Documentation]    Configure BGP peer module with initiate-connection set to false.
    &{mapping}    BuiltIn.Create_Dictionary    IP=${TOOLS_SYSTEM_IP}    HOLDTIME=${HOLDTIME}    PEER_PORT=${BGP_TOOL_PORT}    INITIATE=false    BGP_RIB_OPENCONFIG=${PROTOCOL_OPENCONFIG}
    ...    PASSIVE_MODE=true
    TemplatedRequests.Put_As_Xml_Templated    ${BGP_VARIABLES_FOLDER}/bgp_peer    mapping=${mapping}    session=${CONFIG_SESSION}

FlowSpec_Test_1
    [Documentation]    Testing flowspec values for ${CFG1}
    [Setup]    Setup_Testcase    ${CFG1}
    BuiltIn.Wait_Until_Keyword_Succeeds    15s    1s    Verify_Flowspec_Data    ${EXP1}
    [Teardown]    ExaBgpLib.Stop_ExaBgp

FlowSpec_Test_2
    [Documentation]    Testing flowspec values for ${CFG2}
    [Setup]    Setup_Testcase    ${CFG2}
    BuiltIn.Wait_Until_Keyword_Succeeds    15s    1s    Verify_Flowspec_Data    ${EXP2}
    [Teardown]    ExaBgpLib.Stop_ExaBgp

Deconfigure_ODL_To_Accept_Connection
    [Documentation]    Deconfigure BGP peer.
    &{mapping}    BuiltIn.Create_Dictionary    IP=${TOOLS_SYSTEM_IP}    BGP_RIB_OPENCONFIG=${PROTOCOL_OPENCONFIG}
    TemplatedRequests.Delete_Templated    ${BGP_VARIABLES_FOLDER}/bgp_peer    mapping=${mapping}    session=${CONFIG_SESSION}

*** Keywords ***
Start_Suite
    [Documentation]    Suite setup keyword
    SSHLibrary.Open_Connection    ${TOOLS_SYSTEM_IP}    prompt=${DEFAULT_LINUX_PROMPT}    timeout=6s
    SSHKeywords.Flexible_Mininet_Login    ${TOOLS_SYSTEM_USER}
    SSHKeywords.Virtual_Env_Create
    SSHKeywords.Virtual_Env_Install_Package    setuptools==44.0.0
    SSHKeywords.Virtual_Env_Install_Package    exabgp==3.4.16
    RequestsLibrary.Create_Session    ${CONFIG_SESSION}    http://${ODL_SYSTEM_IP}:${RESTCONFPORT}    auth=${AUTH}
    Upload_Config_Files    ${BGP_VARIABLES_FOLDER}
    ${AS_PATH} =    CompareStream.Set_Variable_If_At_Least_Neon    ${NEW_AS_PATH}    ${OLD_AS_PATH}
    BuiltIn.Set_Suite_Variable    ${AS_PATH}

Stop_Suite
    [Documentation]    Suite teardown keyword
    SSHLibrary.Close_All_Connections
    RequestsLibrary.Delete_All_Sessions

Upload_Config_Files
    [Arguments]    ${dir_name}
    [Documentation]    Uploads exabgp config files
    SSHLibrary.Put_Directory    ${BGP_VARIABLES_FOLDER}    .
    @{cfgfiles} =    SSHLibrary.List_Files_In_Directory    .    *.cfg
    FOR    ${cfgfile}    IN    @{cfgfiles}
        SSHLibrary.Execute_Command    sed -i -e 's/EXABGPIP/${TOOLS_SYSTEM_IP}/g' ${cfgfile}
        SSHLibrary.Execute_Command    sed -i -e 's/ODLIP/${ODL_SYSTEM_IP}/g' ${cfgfile}
        ${stdout}=    SSHLibrary.Execute_Command    cat ${cfgfile}
        Log    ${stdout}
    END

Setup_Testcase
    [Arguments]    ${cfg_file}
    Verify_Empty_Flowspec_Data
    ExaBgpLib.Start_ExaBgp_And_Verify_Connected    ${cfg_file}    ${CONFIG_SESSION}    ${TOOLS_SYSTEM_IP}    connection_retries=${3}

Verify_Empty_Flowspec_Data
    [Documentation]    Verify expected response.
    CompareStream.Run_Keyword_If_At_Most_Fluorine    Normalize_And_Compare
    CompareStream.Run_Keyword_If_At_Least_Neon    Verify_Empty_Flowspec_Data_Neon

Verify_Flowspec_Data
    [Arguments]    ${exprspdir}
    [Documentation]    Verify expected response
    &{mapping}    BuiltIn.Create_Dictionary    AS_PATH=${AS_PATH}
    TemplatedRequests.Get_As_Json_Templated    ${BGP_VARIABLES_FOLDER}${/}${exprspdir}    session=${CONFIG_SESSION}    mapping=${mapping}    verify=True

Normalize_And_Compare
    [Documentation]    Verify empty flowspec data
    ${rsp} =    RequestsLibrary.Get_Request    ${CONFIG_SESSION}    ${FLOWSPEC_URL}
    TemplatedRequests.Normalize_Jsons_With_Bits_And_Compare    ${EXP0}    ${rsp.content}    keys_with_bits=${EMPTY_LIST}

Verify_Empty_Flowspec_Data_Neon
    [Documentation]    Verify empty flowspec data on neon
    TemplatedRequests.Get_As_Json_Templated    ${BGP_VARIABLES_FOLDER}${/}empty_route    session=${CONFIG_SESSION}    verify=True
