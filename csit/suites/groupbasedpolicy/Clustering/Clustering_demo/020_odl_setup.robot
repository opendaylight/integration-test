*** Settings ***
Suite Setup       Start Connections
Library           SSHLibrary    120 seconds
Library           RequestsLibrary
Resource          ../Variables.robot
Resource          ../Connections.robot
Resource          ../../../../libraries/KarafKeywords.robot
Resource          ../../../../libraries/Utils.robot
Resource          ../../../../libraries/GBP/ConnUtils.robot
Resource          ../GBPClusteringKeywords.robot

*** Test Cases ***
Setup ODL
    [Documentation]    Setup ODL with data to incialize netconf connections
    Set Suite Variable    ${ODL_SYSTEM_IP}    ${ODL_SYSTEM_${GBP_MASTER_INDEX}_IP}
    Issue Command On Karaf Console    log:clear
    Register Node    controller    ${VPP1}
    Wait For Karaf Log    controller is capable and ready    karaf_ip=${ODL_SYSTEM_IP}
    Issue Command On Karaf Console    log:clear
    Register Node    compute0    ${VPP2}
    Wait For Karaf Log    compute0 is capable and ready    karaf_ip=${ODL_SYSTEM_IP}
    Issue Command On Karaf Console    log:clear
    Register Node    compute1    ${VPP3}
    Wait For Karaf Log    compute1 is capable and ready    karaf_ip=${ODL_SYSTEM_IP}
    Issue Command On Karaf Console    log:clear
    RequestsLibrary.Create Session    session    http://${ODL_SYSTEM_IP}:${RESTCONFPORT}    auth=${AUTH}    headers=${HEADERS}
    Add Elements To URI From File And Verify    /restconf/config/neutron:neutron    ${NEUTRON_FILE}    ${HEADERS_YANG_JSON}
    Wait For Karaf Log    Renderer updated renderer policy to version    karaf_ip=${ODL_SYSTEM_IP}

*** Keywords ***
Register Node
    [Arguments]    ${VPP_NAME}    ${VPP_IP}
    [Documentation]    Write node to netconf topology in ODL datastore
    ConnUtils.Connect and Login    ${VPP_IP}    timeout=10s
    Register VPP Node In ODL    ${VPP_NAME} ${VPP_IP}
    SSHLibrary.Close Connection
