*** Settings ***
Suite Setup       Setup_Everything
Suite Teardown    Teardown_Everything
Default Tags      functional    netconf-performance
Library           OperatingSystem
Library           ../../../libraries/RequestsLibrary.py
Library           DateTime
Library           RequestsLibrary
Library           SSHLibrary    timeout=120s
Library           Collections
Library           ${CURDIR}/../../../libraries/netconf_library.py
Variables         ${CURDIR}/../../../variables/Variables.py
Resource          ../../../variables/netconf_scale/NetScale_variables.robot
Resource          ../../../libraries/ClusterManagement.robot
Resource          ../../../libraries/NetconfKeywords.robot
Resource          ../../../libraries/NexusKeywords.robot

*** Variables ***

*** Test Cases ***
Connect to ODL System
    [Tags]    critical
    SSHLibrary.Open Connection    ${CONTROLLER}    odlsystem
    SSHLibrary.Login With Public Key    ${ODL_SYSTEM_USER}    ${USER_HOME}/.ssh/${SSH_KEY}    ${KEYFILE_PASS}

Generate netconf configuration files
    [Tags]    critical
# Deploy test tool
    ${filename}=    NexusKeywords.Deploy_Test_Tool    netconf    netconf-testtool
    Log    "Filename of test tool=" ${filename}
    Log    "Location of test tool=" ${ttlocation}
    ClusterManagement.Kill_Members_From_List_Or_All
# Generate files
    Start Command    java -jar ${ttlocation}/${filename} --distribution-folder ${WORKSPACE}/${BUNDLEFOLDER} --device-count 4 --debug true

Restart ODL system
    [Tags]    critical
    ClusterManagement.Start_Members_From_List_Or_All
    SSHLibrary.Close Connection

*** Keywords ***
Setup_Everything
    [Documentation]    Setup everything needed for the test cases.
# Setup resources used by the suite.
    SetupUtils.Setup_Utils_For_Setup_And_Teardown
    RequestsLibrary.Create_Session    operational    http://${ODL_SYSTEM_IP}:${RESTCONFPORT}${OPERATIONAL_API}    auth=${AUTH}
    NetconfKeywords.Setup_Netconf_Keywords

Teardown_Everything
    [Documentation]    Teardown the test infrastructure, perform cleanup and release all resources.
    RequestsLibrary.Delete_All_Sessions
    BuiltIn.Run_Keyword_And_Ignore_Error    NetconfKeywords.Stop_Testtool
