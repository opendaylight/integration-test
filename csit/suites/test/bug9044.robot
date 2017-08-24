*** Settings ***
Documentation     FIXME: Add.
Suite Setup       KarafKeywords.Setup_Karaf_Keywords
Resource          ${CURDIR}/../../libraries/ClusterManagement.robot
Resource          ${CURDIR}/../../libraries/KarafKeywords.robot

*** Test Cases ***
Bug9044_Bash
    [Documentation]    Access karaf ssh from bash to log a message.
    ClusterManagement.Run_Bash_Command_On_List_Or_All    command=sshpass -p karaf ssh -p 8101 karaf@127.0.0.1 log:log Bug 9044 bash check passed.

Bug9044_Robot
    [Documentation]    Access karaf ssh from Robot to log a message.
    KarafKeywords.Log_Message_To_Controller_Karaf    message=Bug 9044 robot check passed.    tolerate_failure=False

