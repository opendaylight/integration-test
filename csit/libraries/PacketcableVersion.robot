*** Settings ***
Documentation     This setup variable for Packetcable based on ODL version

*** Variables ***
${ODL_VERSION}    master    # defaults to latest version in the master branch
${ODLREST_CCAPS}    /restconf/config/packetcable:ccaps
${CCAP_TOKEN}     ccap
${PACKETCABLE_RESOURCE_DIR}    ${CURDIR}/../variables/packetcable/${ODL_VERSION}

*** Keywords ***
Init Variables
    Run Keyword If    "${ODL_VERSION}" == "lithium"    Init Variables Lithium
    log    ${ODL_VERSION}
    log    ${ODLREST_CCAPS}
    log    ${CCAP_TOKEN}

Init Variables Lithium
    ${ODLREST_CAPPS}    Set Variable    /restconf/config/packetcable:ccap
    ${CCAP_TOKEN}    Set Variable    ccaps

Create Session And Init Variables
    Init Variables
    Create Session    ODLSession    http://${CONTROLLER}:${RESTCONFPORT}    auth=${AUTH}    headers=${HEADERS}
