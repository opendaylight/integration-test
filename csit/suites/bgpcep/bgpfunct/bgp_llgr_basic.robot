*** Settings ***
Documentation       Functional test for ipv6 connection with bgp.
...
...                 Copyright (c) 2020 Lumina Networks Intellectual Property. All rights reserved.
...
...                 This program and the accompanying materials are made available under the
...                 terms of the Eclipse Public License v1.0 which accompanies this distribution,
...                 and is available at http://www.eclipse.org/legal/epl-v10.html
...
...                 This suite tests simple connection between one ibgp peer (goabgp) and Odl.
...                 Peer is configured with ipv6, and gobgp connectes to odl via ipv6.

Library             RequestsLibrary
Library             SSHLibrary
Resource            ../../../variables/Variables.robot
Resource            ../../../libraries/BGPcliKeywords.robot
Resource            ../../../libraries/GoBgpLib.robot
Resource            ../../../libraries/SetupUtils.robot
Resource            ../../../libraries/SSHKeywords.robot
Resource            ../../../libraries/TemplatedRequests.robot

Suite Setup         Start_Suite
Suite Teardown      Stop_Suite
Test Setup          SetupUtils.Setup_Test_With_Logging_And_Without_Fast_Failing


*** Variables ***
${BGP_VAR_FOLDER}       ${CURDIR}/../../../variables/bgpfunctional/ipv6
${GOBGP_FOLDER}         ${CURDIR}/../../../variables/bgpfunctional/gobgp
${CONFIG_SESSION}       config-session
${GOBGP_CFG}            gobgp.cfg
${GOBGP_LOG}            gobgp.log
${HOLDTIME}             180
${RIB_INSTANCE}         example-bgp-rib
${GOBGP_BINARY_URL}     https://github.com/osrg/gobgp/releases/download/v2.18.0/gobgp_2.18.0_linux_386.tar.gz
${FILE_NAME}            gobgp_2.18.0_linux_386.tar.gz


*** Test Cases ***
Reconfigure_ODL_To_Accept_Connections
    [Documentation]    Configure BGP peer modules with initiate-connection set to false with short ipv6 address.
    &{mapping}    Create Dictionary
    ...    IP=${TOOLS_SYSTEM_IP}
    ...    HOLDTIME=${HOLDTIME}
    ...    PEER_PORT=${BGP_TOOL_PORT}
    ...    INITIATE=false
    ...    BGP_RIB=${RIB_INSTANCE}
    ...    PASSIVE_MODE=true
    ...    BGP_RIB_OPENCONFIG=${RIB_INSTANCE}
    ...    RIB_INSTANCE_NAME=${RIB_INSTANCE}
    TemplatedRequests.Put_As_Xml_Templated
    ...    ${BGP_VAR_FOLDER}/bgp_peer
    ...    mapping=${mapping}
    ...    session=${CONFIG_SESSION}

Start_Gobgp
    [Tags]    critical
    ${cmd}    BuiltIn.Set Variable    ${GOBGP_CFG} > ${GOBGP_LOG}
    GoBgpLib.Start_GoBgp_And_Verify_Connected    ${cmd}    ${CONFIG_SESSION}    ${TOOLS_SYSTEM_IP}

Delete_Bgp_Peer_Configuration
    [Documentation]    Revert the BGP configuration to the original state: without any configured peers.
    &{mapping}    Create Dictionary
    ...    IP=${TOOLS_SYSTEM_IP}
    ...    HOLDTIME=${HOLDTIME}
    ...    PEER_PORT=${BGP_TOOL_PORT}
    ...    INITIATE=false
    ...    BGP_RIB=${RIB_INSTANCE}
    ...    PASSIVE_MODE=true
    ...    BGP_RIB_OPENCONFIG=${RIB_INSTANCE}
    ...    RIB_INSTANCE_NAME=${RIB_INSTANCE}
    TemplatedRequests.Delete_Templated    ${BGP_VAR_FOLDER}/bgp_peer    mapping=${mapping}    session=${CONFIG_SESSION}

Stop_All_Gobgps
    [Documentation]    Save exabgp logs as exaipv6.log, and stop exabgp with ctrl-c bash signal
    BGPcliKeywords.Store_File_To_Workspace    ${GOBGP_LOG}    ${GOBGP_LOG}
    GoBgpLib.Stop_GoBgp


*** Keywords ***
Start_Suite
    [Documentation]    Suite setup keyword.
    SetupUtils.Setup_Utils_For_Setup_And_Teardown
    ${tools_system_conn_id}    SSHLibrary.Open_Connection
    ...    ${TOOLS_SYSTEM_IP}
    ...    prompt=${DEFAULT_LINUX_PROMPT}
    ...    timeout=6s
    Builtin.Set_Suite_Variable    ${tools_system_conn_id}
    SSHKeywords.Flexible_Mininet_Login    ${TOOLS_SYSTEM_USER}
    RequestsLibrary.Create_Session    ${CONFIG_SESSION}    http://${ODL_SYSTEM_IP}:${RESTCONFPORT}    auth=${AUTH}
    Upload_Config_Files
    Download_Gobgp_Binary

Stop_Suite
    [Documentation]    Suite teardown keyword
    SSHLibrary.Close_All_Connections
    RequestsLibrary.Delete_All_Sessions
    BuiltIn.Run Keyword And Ignore Error    GoBgpLib.Stop_GoBgp

Upload_Config_Files
    [Documentation]    Uploads gobgp config files
    SSHLibrary.Put_File    ${GOBGP_FOLDER}/${GOBGP_CFG}    .
    @{cfgfiles}    SSHLibrary.List_Files_In_Directory    .    *.cfg
    FOR    ${cfgfile}    IN    @{cfgfiles}
        SSHLibrary.Execute_Command    sed -i -e 's/GOBGPIP/${TOOLS_SYSTEM_IP}/g' ${cfgfile}
        SSHLibrary.Execute_Command    sed -i -e 's/ODLIP/${ODL_SYSTEM_IP}/g' ${cfgfile}
        SSHLibrary.Execute_Command    sed -i -e 's/ROUTERID/${TOOLS_SYSTEM_IP}/g' ${cfgfile}
        SSHLibrary.Execute_Command    sed -i -e 's/ROUTEREFRESH/disable/g' ${cfgfile}
        SSHLibrary.Execute_Command    sed -i -e 's/ADDPATH/disable/g' ${cfgfile}
        ${stdout}    SSHLibrary.Execute_Command    cat ${cfgfile}
        Log    ${stdout}
    END

Download_Gobgp_Binary
    [Documentation]    Downloads gobgp binary and untar the binary zip file
    SSHKeywords.Open_Connection_To_Tools_System    ${TOOLS_SYSTEM_IP}
    SSHLibrary.Execute Command    wget ${GOBGP_BINARY_URL}
    SSHLibrary.File Should Exist    ./${FILE_NAME}
    SSHLibrary.Execute Command    tar -xzf ${FILE_NAME}
