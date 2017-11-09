*** Settings ***
Documentation    Suite description
Suite Setup       Setup_Everything
Suite Teardown    Teardown_Everything
Test Setup        SetupUtils.Setup_Test_With_Logging_And_Without_Fast_Failing
Test Teardown     FailFast.Start_Failing_Fast_If_This_Failed
Library           RequestsLibrary
Library           SSHLibrary
Variables         ${CURDIR}/../../../variables/Variables.py
Variables         ${CURDIR}/../../../variables/bgpuser/variables.py    ${TOOLS_SYSTEM_IP}    ${ODL_STREAM}
Resource          ${CURDIR}/../../../libraries/KarafKeywords.robot
Resource          ${CURDIR}/../../../libraries/SetupUtils.robot

*** Test Cases ***
Install_Cli
    KarafKeywords.Install_A_Feature    odl-bgpcep-bgp-config-example
    KarafKeywords.Install_A_Feature    odl-bgpcep-bgp-cli

Test_Cli
    ${output}=    KarafKeywords.Issue_Command_On_Karaf_Console    bgp:operational-state -rib example-bgp-rib
    BuiltIn.Log    ${output}
    ${output}=    KarafKeywords.Issue_Command_On_Karaf_Console    bgp:operational-state -rib example-bgp-rib -neighbor 192.0.2.1
    BuiltIn.Log    ${output}
    ${output}=    KarafKeywords.Issue_Command_On_Karaf_Console    bgp:operational-state -rib -peer-group application-peers
    BuiltIn.Log    ${output}


*** Keywords ***
Setup_Everything
    SetupUtils.Setup_Utils_For_Setup_And_Teardown
    ${tools_system_conn_id}=    SSHLibrary.Open_Connection    ${TOOLS_SYSTEM_IP}    prompt=${DEFAULT_LINUX_PROMPT}    timeout=6s
    Builtin.Set_Suite_Variable    ${tools_system_conn_id}
    RequestsLibrary.Create_Session    session    http://${ODL_SYSTEM_IP}:${RESTCONFPORT}    auth=${AUTH}

Teardown_Everything
    SSHLibrary.Close_All_Connections
    RequestsLibrary.Delete_All_Sessions
