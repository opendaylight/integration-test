*** Settings ***
Documentation     Basic tests for odl-bgpcep-bgp-all feature.
...
...               Copyright (c) 2015 Cisco Systems, Inc. and others. All rights reserved.
...
...               This program and the accompanying materials are made available under the
...               terms of the Eclipse Public License v1.0 which accompanies this distribution,
...               and is available at http://www.eclipse.org/legal/epl-v10.html
...
...               TODO: Rename this file after Beryllium is out, for example to basic.robot
...
...               Test suite performs basic BGP functional test cases:
...               BGP peer initiated coonection
...               - introduce and check 3 prefixes in one update message
...               ODL controller initiated coonection:
...               - introduce and check 3 prefixes in one update message
...               - introduce 2 prefixes in first update message and then additional 2 prefixes
...               in another update while the very first prefix is withdrawn
...               - introduce 3 prefixes and try to withdraw the first one
...               (to be ignored by controller) in a single update message
...
...               Brief description how to perform BGP functional test:
...               https://wiki.opendaylight.org/view/BGP_LS_PCEP:Lithium_Feature_Tests#How_to_test_2
...
...               Reported bugs:
...               https://bugs.opendaylight.org/show_bug.cgi?id=4409
...               https://bugs.opendaylight.org/show_bug.cgi?id=4634
#Suite Setup       Setup_Everything
#Suite Teardown    Teardown_Everything
#Test Setup        SetupUtils.Setup_Test_With_Logging_And_Fast_Failing
#Test Teardown     FailFast.Start_Failing_Fast_If_This_Failed
Library           OperatingSystem
Library           SSHLibrary    timeout=10s
Library           RequestsLibrary
Library           ${CURDIR}/../../../libraries/HsfJson/hsf_json.py
Variables         ${CURDIR}/../../../variables/Variables.py
Variables         ${CURDIR}/../../../variables/bgpuser/variables.py    ${TOOLS_SYSTEM_IP}
Resource          ${CURDIR}/../../../libraries/BGPcliKeywords.robot
Resource          ${CURDIR}/../../../libraries/BGPSpeaker.robot
Resource          ${CURDIR}/../../../libraries/ConfigViaRestconf.robot
Resource          ${CURDIR}/../../../libraries/FailFast.robot
Resource          ${CURDIR}/../../../libraries/KarafKeywords.robot
Resource          ${CURDIR}/../../../libraries/KillPythonTool.robot
Resource          ${CURDIR}/../../../libraries/SetupUtils.robot
Resource          ${CURDIR}/../../../libraries/SSHKeywords.robot
Resource          ${CURDIR}/../../../libraries/Utils.robot
Resource          ${CURDIR}/../../../libraries/WaitForFailure.robot

*** Variables ***
${ACTUAL_RESPONSES_FOLDER}    ${TEMPDIR}/actual
${EXPECTED_RESPONSES_FOLDER}    ${TEMPDIR}/expected
${BGP_VARIABLES_FOLDER}    ${CURDIR}/../../../variables/bgpuser/
${TOOLS_SYSTEM_PROMPT}    ${DEFAULT_LINUX_PROMPT}
${HOLDTIME}       0
${BGP_TOOL_LOG_LEVEL}    info
${CONTROLLER_LOG_LEVEL}    INFO
${CONTROLLER_BGP_LOG_LEVEL}    DEFAULT

*** Test Cases ***

Deploy
    SSHLibrary.Open_Connection    ${TOOLS_SYSTEM_IP}
    Utils.Flexible_Mininet_Login
    SSHLibrary.Put_Directory    ${CURDIR}/../../../variables/bgpuser/exabgp    destination=./exabgpcfg
    # Cannot use SSHLibrary.Execute_Command due to mysterious error 127.
    ${stdout}    ${stderr}    ${rc}=    SSHLibrary.Execute Command    sudo apt-get install -y python-pip    return_stdout=True    return_stderr=True
    ...    return_rc=True
    ${stdout}    ${stderr}    ${rc}=    SSHLibrary.Execute Command    sudo pip install exabgp    return_stdout=True    return_stderr=True
    ...    return_rc=True

Configure_ExaBgp_Peers
    ConfigViaRestconf.Setup_Config_Via_Restconf
    ${template_as_string}=    BuiltIn.Set_Variable    {'NAME': 'example-bgp-peer-1', 'IP': '127.0.0.201', 'HOLDTIME': '${HOLDTIME}', 'PEER_PORT': '${BGP_TOOL_PORT}', 'AS_NUMBER':'64496', 'INITIATE': 'false', 'PEER_ROLE':'ebgp'}
    ConfigViaRestconf.Put_Xml_Template_Folder_Config_Via_Restconf    ${BGP_VARIABLES_FOLDER}${/}ebgp_peers    ${template_as_string}
    ${template_as_string}=    BuiltIn.Set_Variable    {'NAME': 'example-bgp-peer-2', 'IP': '127.0.0.202', 'HOLDTIME': '${HOLDTIME}', 'PEER_PORT': '${BGP_TOOL_PORT}', 'AS_NUMBER':'64497', 'INITIATE': 'false', 'PEER_ROLE':'ebgp'}
    ConfigViaRestconf.Put_Xml_Template_Folder_Config_Via_Restconf    ${BGP_VARIABLES_FOLDER}${/}ebgp_peers    ${template_as_string}
