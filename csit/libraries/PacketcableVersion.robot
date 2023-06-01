*** Settings ***
Documentation       This setup variable for Packetcable based on ODL version using resource CompareStream.

Resource            ${CURDIR}/CompareStream.robot


*** Keywords ***
Init Variables
    BuiltIn.Set Suite Variable    ${PACKETCABLE_RESOURCE_DIR}    ${CURDIR}/../variables/packetcable/beryllium
    BuiltIn.Set Suite Variable    ${ODLREST_CCAPS}    /rests/data/packetcable:ccaps?content=config
    BuiltIn.Set Suite Variable    ${CCAP_TOKEN}    ccap
    log    ${ODLREST_CCAPS}
    log    ${CCAP_TOKEN}

Create Session And Init Variables
    Init Variables
    Create Session    ODLSession    http://${ODL_SYSTEM_IP}:${RESTCONFPORT}    auth=${AUTH}    headers=${HEADERS}
