*** Settings ***
Documentation     This setup variable for Packetcable based on ODL version using resource CompareStream.
Resource          ${CURDIR}/CompareStream.robot

*** Variables ***
${ODLREST_CCAPS}    /restconf/config/packetcable:ccaps
${CCAP_TOKEN}     ccap

*** Keywords ***
Init Variables
    ${packetcable}=    CompareStream.Set_Variable_If_At_Least_Beryllium    ${CURDIR}/../variables/packetcable/beryllium    ${CURDIR}/../variables/packetcable/lithium
    BuiltIn.Set Suite Variable    ${PACKETCABLE_RESOURCE_DIR}    ${packetcable}
    CompareStream.Run_Keyword_If_Less_Than_Beryllium    Init Variables Lithium    No Operation
    log    ${ODLREST_CCAPS}
    log    ${CCAP_TOKEN}

Init Variables Lithium
    Set Suite Variable    ${ODLREST_CCAPS}    /restconf/config/packetcable:ccap
    Set Suite Variable    ${CCAP_TOKEN}    ccaps

Create Session And Init Variables
    Init Variables
    Create Session    ODLSession    http://${ODL_SYSTEM_IP}:${RESTCONFPORT}    auth=${AUTH}    headers=${HEADERS}
