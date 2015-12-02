*** Settings ***
Documentation     Global variables for GBPSFC 3-node topology
Variables         ../../../../variables/Variables.py

*** Variables ***
${VM_HOME_FOLDER}    ${WORKSPACE}
${VM_SCRIPTS_FOLDER}    scripts
${ODL}            ${ODL_SYSTEM_IP}
${GBP1}           ${TOOLS_SYSTEM_IP}
${GBP2}           ${TOOLS_SYSTEM_2_IP}
${GBP3}           ${TOOLS_SYSTEM_3_IP}
@{GBPs}           ${GBP1}    ${GBP2}    ${GBP3}
${GBP_TENANT1_ID}    tenant-dobre
${GBP_TENANT2_ID}    tenant-dobre2
${TENANT1_PATH}    ${GBP_TENANTS_API}/policy:tenant/${GBP_TENANT1_ID}
${TENANT2_PATH}    ${GBP_TENANTS_API}/policy:tenant/${GBP_TENANT2_ID}
${TUNNELS_PATH}    ${CONFIG_NODES_API}
${ENDPOINT_REG_PATH}    ${GBP_REGEP_API}
${ENDPOINT_UNREG_PATH}    ${GBP_UNREGEP_API}
${ENDPOINTS_OPER_PATH}    /restconf/operational/endpoint:endpoints
${OF_OVERLAY_CONFIG_PATH}    /restconf/config/ofoverlay:of-overlay-config
${TUNNELS_FILE}    ${CURDIR}/../../../../variables/gbp/3node/tunnels.json
${ENDPOINTS_GBP1_DIR}    ${CURDIR}/../../../../variables/gbp/3node/demo-gbp1
${ENDPOINTS_GBP2_DIR}    ${CURDIR}/../../../../variables/gbp/3node/demo-gbp2

*** Keywords ***
Set Test Variables
    [Arguments]    ${client_switch_ip}    ${client_docker}    ${client_ip}    ${client_mac}    ${same_webserver_docker}    ${same_webserver_ip}
    ...    ${same_webserver_mac}    ${diff_webserver_switch_ip}    ${diff_webserver_docker}    ${diff_webserver_ip}    ${diff_webserver_mac}
    [Documentation]    Sets variables used in 3node test cases.
    Set Global Variable    ${CLIENT_SWITCH_IP}    ${client_switch_ip}
    Set Global Variable    ${CLIENT_DOCKER}    ${client_docker}
    Set Global Variable    ${CLIENT_IP}    ${client_ip}
    Set Global Variable    ${CLIENT_MAC}    ${client_mac}
    Set Global Variable    ${SAME_WEBSERVER_DOCKER}    ${same_webserver_docker}
    Set Global Variable    ${SAME_WEBSERVER_IP}    ${same_webserver_ip}
    Set Global Variable    ${SAME_WEBSERVER_MAC}    ${same_webserver_mac}
    Set Global Variable    ${DIFF_WEBSERVER_SWITCH_IP}    ${diff_webserver_switch_ip}
    Set Global Variable    ${DIFF_WEBSERVER_DOCKER}    ${diff_webserver_docker}
    Set Global Variable    ${DIFF_WEBSERVER_IP}    ${diff_webserver_ip}
    Set Global Variable    ${DIFF_WEBSERVER_MAC}    ${diff_webserver_mac}

Init Variables
    [Documentation]    Initialize ODL version specific variables
    log    ${ODL_VERSION}
    Run Keyword If    ${ODL_VERSION} == 'stable-lithium'    Init Variables Lithium
    ...    ELSE    Init Variables Master

Init Variables Master
    [Documentation]    Sets variables specific to latest(master) version
    Set Global Variable    ${TENANT1_FILE}    ${CURDIR}/../../../../variables/gbp/3node/master/tenant1.json
    Set Global Variable    ${TENANT2_FILE}    ${CURDIR}/../../../../variables/gbp/3node/master/tenant2.json

Init Variables Lithium
    [Documentation]    Sets variables specific to Lithium version
    Set Global Variable    ${TENANT1_FILE}    ${CURDIR}/../../../../variables/gbp/3node/lithium/tenant1.json
    Set Global Variable    ${TENANT2_FILE}    ${CURDIR}/../../../../variables/gbp/3node/lithium/tenant2.json
