*** Settings ***
Documentation     MyTest
Library           String
Library           Collections
Resource           ../../variables/Intra-DC_Deployments_TestPlan_Var/EVPN_In_Intra_DC_Deployments_vars.robot

*** Test Cases ***
TC1
    [Documentation]    Testcase 1
    Log To Console     ${PORT_LIST}
    ${REQUIRED_PORT_LIST}=    Get Slice From List    ${PORT_LIST}    0    8
    Log To Console     ${REQUIRED_PORT_LIST}
    ${port_name}    Get From List    ${PORT_LIST}     2
    Log To Console     ${port_name}
