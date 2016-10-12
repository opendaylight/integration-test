*** Settings ***
Documentation     This setup variable for Packetcable based on ODL version using resource CompareStream.
Resource          ${CURDIR}/CompareStream.robot

*** Keywords ***
Init Variables
    CompareStream.Run_Keyword_If_Less_Than_Beryllium    Init Variables Lithium
    BuiltIn.Set Suite Variable    ${PACKETCABLE_RESOURCE_DIR}    ${CURDIR}/../variables/packetcable/beryllium
    BuiltIn.Set Suite Variable    ${ODLREST_CCAPS}    /restconf/config/packetcable:ccaps
    BuiltIn.Set Suite Variable    ${CCAP_TOKEN}    ccap
    log    ${ODLREST_CCAPS}
    log    ${CCAP_TOKEN}

Init Variables Lithium
    BuiltIn.Set Suite Variable    ${PACKETCABLE_RESOURCE_DIR}    ${CURDIR}/../variables/packetcable/lithium
    BuildIn.Set Suite Variable    ${ODLREST_CCAPS}    /restconf/config/packetcable:ccap
    BuildIn.Set Suite Variable    ${CCAP_TOKEN}    ccaps

Create Session And Init Variables
    Init Variables
    Create Session    ODLSession    http://${ODL_SYSTEM_IP}:${RESTCONFPORT}    auth=${AUTH}    headers=${HEADERS}
