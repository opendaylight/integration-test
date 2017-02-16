*** Settings ***
Library           SSHLibrary    120 seconds
Resource          ../../../../libraries/ClusterManagement.robot

*** Test Cases ***
Stop ODL
    [Documentation]    Stop all ODLs
    Kill_Members_From_List_Or_All

Start ODL
    [Documentation]    Start all ODLs
    Start_Members_From_List_Or_All
