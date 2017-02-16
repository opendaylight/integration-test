*** Settings ***
Library           SSHLibrary    120 seconds
Resource          ../../../../libraries/ClusterManagement.robot

*** Test Cases ***
Stop ODL
    [Documentation]    Stop ODL wit currently running GBP instances
    Kill_Single_Member    ${GBP_MASTER_INDEX}
