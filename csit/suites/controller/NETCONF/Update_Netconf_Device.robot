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
Resource          ../../../libraries/SetupUtils.robot
Resource          ../../../libraries/Utils.robot
Resource          ../../../libraries/SSHKeywords.robot

*** Variables ***

*** Test Cases ***
Generate netconf configuration files
    [Tags]    critical
    SSHKeywords.Open_Connection_To_ODL_System
# Deploy test tool
    ${filename}=    NexusKeywords.Deploy_Test_Tool    netconf    netconf-testtool
    Log    "Filename of test tool=" ${filename}
    Log    "Location of test tool=" ${ttlocation}
    ClusterManagement.Kill_Members_From_List_Or_All
# Generate files - generate ip address for TOOLS_SYSTEM --generate-config-address
# write - read until  Registration succeeded
    SSHLibrary.Write    java -jar ${WORKSPACE}/${filename} --distribution-folder ${WORKSPACE}/${BUNDLEFOLDER} --device-count 4 | tee testtool-generation.log
    SSHLibrary.Read Until    Registration succeeded
# stop test tool
    Utils.Write_Bare_Ctrl_C
    SSHLibrary.Close Connection

Start testtool
    SSHKeywords.Open_Connection_To_Tools_System
# start testtool again at TOOLS_SYSTEM
    NetconfKeywords.Install_And_Start_TestTool    device-count=4    schemas=${CURDIR}/../../../variables/netconf/CRUD/schemas

Restart ODL system
    [Tags]    critical
    ClusterManagement.Start_Members_From_List_Or_All

*** Keywords ***
Setup_Everything
    [Documentation]    Setup everything needed for the test cases.
# Setup resources used by the suite.
    SetupUtils.Setup_Utils_For_Setup_And_Teardown
    RequestsLibrary.Create_Session    operational    http://${ODL_SYSTEM_IP}:${RESTCONFPORT}${OPERATIONAL_API}    auth=${AUTH}
    NetconfKeywords.Setup_Netconf_Keywords
    ClusterManagement.ClusterManagement_Setup

Teardown_Everything
    [Documentation]    Teardown the test infrastructure, perform cleanup and release all resources.
    RequestsLibrary.Delete_All_Sessions
    BuiltIn.Run_Keyword_And_Ignore_Error    NetconfKeywords.Stop_Testtool

