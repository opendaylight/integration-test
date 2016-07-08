*** Settings ***
Documentation     This suite verifies availability of ODL features needed for further testing
Suite Teardown    Delete All Sessions
Library           SSHLibrary
Library           OperatingSystem
Library           RequestsLibrary
Resource          Variables.robot
Resource          ../../../../libraries/Utils.robot
Resource          ../../../../libraries/DevstackUtils.robot
Variables         ../../../../variables/Variables.py

*** Variables ***

*** Test Cases ***
Wait for Renderers and NeutronMapper
    Create Session    session     http://${ODL_SYSTEM_IP}:8181    auth=${AUTH}    headers=${headers}
    Wait Until Keyword Succeeds   60x    5s    Renderers And NeutronMapper Initialized    session
    Delete All Sessions

*** Keywords ***
Renderers And NeutronMapper Initialized
    [Documentation]  Ofoverlay and Neutronmapper features start check via datastore.
    [Arguments]      ${session}
    Get Data From URI    ${session}    ${OF_OVERLAY_BOOT_URL}    headers=${headers}
    ${response}    RequestsLibrary.Get Request    ${session}    ${NEURONMAPPER_BOOT_URL}    ${headers}
    Should Be Equal As Strings    404    ${response.status_code}
