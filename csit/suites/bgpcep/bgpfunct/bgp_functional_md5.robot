*** Settings ***
Documentation     Functional test suite for bgp - n-path and all-path selection
...
...               Copyright (c) 2017 Cisco Systems, Inc. and others. All rights reserved.
...
...               This program and the accompanying materials are made available under the
...               terms of the Eclipse Public License v1.0 which accompanies this distribution,
...               and is available at http://www.eclipse.org/legal/epl-v10.html
...
...               This suite tests tcpmd5 connection of bgp peers. It uses odl and exabgp as bgp
...               peer. No routes are advertized, simple peer presence in the datastore is tested.
...               are configured via application peer.
Suite Setup       Start_Suite
Suite Teardown    Stop_Suite
Test Setup        SetupUtils.Setup_Test_With_Logging_And_Without_Fast_Failing
Test Teardown     Delete_Bgp_Peer_Configuration
Library           RequestsLibrary
Library           SSHLibrary
Resource          ${CURDIR}/../../../variables/Variables.robot
Resource          ${CURDIR}/../../../libraries/BGPcliKeywords.robot
Resource          ${CURDIR}/../../../libraries/CompareStream.robot
Resource          ${CURDIR}/../../../libraries/ExaBgpLib.robot
Resource          ${CURDIR}/../../../libraries/SetupUtils.robot
Resource          ${CURDIR}/../../../libraries/SSHKeywords.robot
Resource          ${CURDIR}/../../../libraries/TemplatedRequests.robot
Resource          ${CURDIR}/../../../libraries/WaitForFailure.robot

*** Variables ***
${HOLDTIME}       180
${BGP_VAR_FOLDER}    ${CURDIR}/../../../variables/bgpfunctional/bgp_md5
${BGP_PEER_FOLDER}    ${BGP_VAR_FOLDER}${/}bgp_peer
${BGP_EXAMD5_CFG}    exa-md5.cfg
${MD5_SAME_PASSWD}    topsecret
${MD5_DIFF_PASSWD}    different
${PROTOCOL_OPENCONFIG}    example-bgp-rib
${CONFIG_SESSION}    session

*** Test Cases ***
Verify Exabgp Connected
    [Documentation]    Verifies exabgp connected with md5 settings
    [Tags]    critical
    [Setup]    Reconfigure_ODL_To_Accept_Connection    ${MD5_SAME_PASSWD}
    ExaBgpLib.Start_ExaBgp_And_Verify_Connected    ${BGP_EXAMD5_CFG}    ${CONFIG_SESSION}    ${TOOLS_SYSTEM_IP}    connection_retries=${3}
    ExaBgpLib.Stop_ExaBgp

Verify Exabgp Not Connected
    [Documentation]    Verifies exabgp connected with md5 settings
    [Tags]    critical
    [Setup]    Reconfigure_ODL_To_Accept_Connection    ${MD5_DIFF_PASSWD}
    ExaBgpLib.Start_ExaBgp    ${BGP_EXAMD5_CFG}
    WaitForFailure.Verify_Keyword_Never_Passes_Within_Timeout    15s    2s    ExaBgpLib.Verify_ExaBgps_Connection    ${CONFIG_SESSION}    ${TOOLS_SYSTEM_IP}
    ExaBgpLib.Stop_ExaBgp

*** Keywords ***
Start_Suite
    [Documentation]    Suite setup keyword.
    SetupUtils.Setup_Utils_For_Setup_And_Teardown
    ${tools_system_conn_id}=    SSHLibrary.Open_Connection    ${TOOLS_SYSTEM_IP}    prompt=${DEFAULT_LINUX_PROMPT}    timeout=6s
    Builtin.Set_Suite_Variable    ${tools_system_conn_id}
    SSHKeywords.Flexible_Mininet_Login    ${TOOLS_SYSTEM_USER}
    SSHKeywords.Virtual_Env_Create
    SSHKeywords.Virtual_Env_Install_Package    exabgp==3.4.17
    RequestsLibrary.Create_Session    ${CONFIG_SESSION}    http://${ODL_SYSTEM_IP}:${RESTCONFPORT}    auth=${AUTH}
    Upload_Config_Files

Stop_Suite
    [Documentation]    Suite teardown keyword with old rib restoration
    SSHKeywords.Virtual_Env_Delete
    SSHLibrary.Close_All_Connections
    RequestsLibrary.Delete_All_Sessions

Reconfigure_ODL_To_Accept_Connection
    [Arguments]    ${password}
    [Documentation]    Configures BGP peer module with initiate-connection set to false.
    &{mapping}    BuiltIn.Create_Dictionary    BGP_RIB_OPENCONFIG=${PROTOCOL_OPENCONFIG}    IP=${TOOLS_SYSTEM_IP}    HOLDTIME=${HOLDTIME}    PEER_PORT=${BGP_TOOL_PORT}    PASSWORD=${password}
    ...    PASSIVE_MODE=true
    TemplatedRequests.Put_As_Xml_Templated    ${BGP_PEER_FOLDER}    mapping=${mapping}    session=${CONFIG_SESSION}

Delete_Bgp_Peer_Configuration
    [Documentation]    Revert the BGP configuration to the original state: without any configured peers.
    &{mapping}    BuiltIn.Create_Dictionary    BGP_RIB_OPENCONFIG=${PROTOCOL_OPENCONFIG}    IP=${TOOLS_SYSTEM_IP}
    TemplatedRequests.Delete_Templated    ${BGP_PEER_FOLDER}    mapping=${mapping}    session=${CONFIG_SESSION}

Upload_Config_Files
    [Arguments]    ${addpath}=disable
    [Documentation]    Uploads exabgp config files
    SSHLibrary.Put_File    ${BGP_VAR_FOLDER}${/}exa-md5.cfg    .
    @{cfgfiles}=    SSHLibrary.List_Files_In_Directory    .    *.cfg
    FOR    ${cfgfile}    IN    @{cfgfiles}
        SSHLibrary.Execute_Command    sed -i -e 's/EXABGPIP/${TOOLS_SYSTEM_IP}/g' ${cfgfile}
        SSHLibrary.Execute_Command    sed -i -e 's/ODLIP/${ODL_SYSTEM_IP}/g' ${cfgfile}
        SSHLibrary.Execute_Command    sed -i -e 's/ROUTEREFRESH/enable/g' ${cfgfile}
        SSHLibrary.Execute_Command    sed -i -e 's/ADDPATH/disable/g' ${cfgfile}
        SSHLibrary.Execute_Command    sed -i -e 's/PASSWORD/${MD5_SAME_PASSWD}/g' ${cfgfile}
        ${stdout}=    SSHLibrary.Execute_Command    cat ${cfgfile}
        Log    ${stdout}
    END
