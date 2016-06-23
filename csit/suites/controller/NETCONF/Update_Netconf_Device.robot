*** Settings ***
Suite Setup       Setup_Everything
Suite Teardown    Teardown_Everything
Default Tags      functional    netconf-performance
Library           OperatingSystem
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
${PERF_DEVICE_COUNT}    4

*** Test Cases ***
Generate netconf configuration files
    [Documentation]    Kill's ODL, cleans karaf directories at member index,
    ...                generates configuration files with a re-deployed netconf-testtool
    ...                and captures any output produced into 2 log files.
    ...                Then, stop testtool.
    [Tags]    critical
    ${controller_connection}=    SSHLibrary.Open Connection    ${ODL_SYSTEM_IP}    prompt=${ODL_SYSTEM_PROMPT}    timeout=10s
    SSHLibrary.Login With Public Key    ${user}    ${USER_HOME}/.ssh/${SSH_KEY}    ${KEYFILE_PASS}    delay=${delay}
    ClusterManagement.Kill_Members_From_List_Or_All
    ${member_index_list}=    Builtin.Create List    ${1}
    ClusterManagement.Clean_Directories_On_List_Or_All    ${member_index_list}    ${WORKSPACE}/${BUNDLEFOLDER}
    SSHLibrary.Switch Connection    ${controller_connection}
    ${filename}=    NexusKeywords.Deploy_Test_Tool    netconf    netconf-testtool
    ${command}=    NexusKeywords.Compose_Full_Java_Command    ${TESTTOOL_DEFAULT_JAVA_OPTIONS} -jar ${filename} --device-count ${PERF_DEVICE_COUNT} --generate-config-address ${TOOLS_SYSTEM_IP} --distribution-folder ${WORKSPACE}/${BUNDLEFOLDER} --debug true
    Log    "Executing: " ${command}
    SSHLibrary.Write    ${command} | tee testtool-device-generation.log
    SSHLibrary.Read Until    started successfully
    Utils.Write_Bare_Ctrl_C
    SSHLibrary.Get File    testtool-device-generation.log
    SSHLibrary.Get Directory    ${WORKSPACE}/${BUNDLEFOLDER}/etc/opendaylight/karaf
    SSHLibrary.Close Connection

Start testtool
    [Tags]    critical
    SSHKeywords.Open_Connection_To_Tools_System
    NetconfKeywords.Install_And_Start_TestTool    device-count=${PERF_DEVICE_COUNT}    schemas=${CURDIR}/../../../variables/netconf/CRUD/schemas

Restart ODL system
    [Tags]    critical
    ClusterManagement.Start_Members_From_List_Or_All

Wait_For_Device_To_Become_Connected
    [Documentation]    Wait until the device becomes available through Netconf on every device
    NetconfKeywords.Perform_Operation_On_Each_Device    NetconfKeywords.Wait_Device_Connected    timeout=5m    new_name=True

Wait_For_Device_Data_To_Be_Seen
    [Documentation]    Wait until the device data show up at every device in range specified by ${PERF_DEVICE_COUNT}
    :FOR    ${index}    IN RANGE    ${PERF_DEVICE_COUNT}
    \    BuiltIn.Wait_Until_Keyword_Succeeds    2m    1s   NetconfKeywords.Check_If_Data_Present_On_Device    ${index}    new_name=True

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


