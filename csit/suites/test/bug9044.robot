*** Settings ***
Documentation     FIXME: Add.
Suite Setup       KarafKeywords.Setup_Karaf_Keywords
Resource          ${CURDIR}/../../libraries/KarafKeywords.robot

*** Test Cases ***
Bug9044
    [Documentation]    Access karaf ssh to log a message.
    KarafKeywords.Log_Message_To_Controller_Karaf    message=Bug 9044 check passed.    tolerate_failure=False
