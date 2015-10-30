*** Settings ***
Documentation    Global variables for GBPSFC 6node topology
Variables         ../../../../variables/Variables.py

*** Variables ***
${VM_HOME_FOLDER} =  ${WORKSPACE}
${VM_SCRIPTS_FOLDER} =  scripts
${ODL} =    ${ODL_SYSTEM_IP}
${GBPSFC1} =    ${TOOLS_SYSTEM_IP}
${GBPSFC2} =    ${TOOLS_SYSTEM_2_IP}
${GBPSFC3} =    ${TOOLS_SYSTEM_3_IP}
${GBPSFC4} =    ${TOOLS_SYSTEM_4_IP}
${GBPSFC5} =    ${TOOLS_SYSTEM_5_IP}
${GBPSFC6} =    ${TOOLS_SYSTEM_6_IP}
@{GBPSFCs} =    ${GBPSFC1}    ${GBPSFC2}    ${GBPSFC3}
...             ${GBPSFC4}    ${GBPSFC5}    ${GBPSFC6}
${GBP_TENANT_ID}           f5c7d344-d1c7-4208-8531-2c2693657e12

${OF_OVERLAY_CONFIG_PATH}  /restconf/config/ofoverlay:of-overlay-config
${TOPOLOGY_PATH}           ${CONFIG_TOPO_API}/topology/ovsdb:1

${SF_PATH}                 /restconf/config/service-function:service-functions
${SF_FILE}                 ${CURDIR}/../../../../variables/gbp/6node/service_functions.json
${SFF_PATH}                /restconf/config/service-function-forwarder:service-function-forwarders
${SFF_FILE}                ${CURDIR}/../../../../variables/gbp/6node/service_function_forwarders.json
${SFC_PATH}                /restconf/config/service-function-chain:service-function-chains
${TUNNELS_PATH}            ${CONFIG_NODES_API}
${TUNNELS_FILE}            ${CURDIR}/../../../../variables/gbp/6node/tunnels.json

${SFC_ASYMM_FILE}          ${CURDIR}/../../../../variables/gbp/6node/demo-asymmetric-chain/service_function_chains.json
${SFC_SYMM_FILE}           ${CURDIR}/../../../../variables/gbp/6node/demo-symmetric-chain/service_function_chains.json
${SFP_PATH}                /restconf/config/service-function-path:service-function-paths
${SFP_ASYMM_FILE}          ${CURDIR}/../../../../variables/gbp/6node/demo-asymmetric-chain/service_function_paths.json
${SFP_SYMM_FILE}           ${CURDIR}/../../../../variables/gbp/6node/demo-symmetric-chain/service_function_paths.json
${TENANT_PATH}             ${GBP_TENANTS_API}/tenant/${GBP_TENANT_ID}
${TENANT_ASYMM_FILE}       ${CURDIR}/../../../../variables/gbp/6node/demo-asymmetric-chain/tenants.json
${TENANT_SYMM_FILE}        ${CURDIR}/../../../../variables/gbp/6node/demo-symmetric-chain/tenants.json
${ENDPOINTS_ASYMM_DIR}     ${CURDIR}/../../../../variables/gbp/6node/demo-asymmetric-chain/
${ENDPOINTS_SYMM_DIR}      ${CURDIR}/../../../../variables/gbp/6node/demo-symmetric-chain/
${ENDPOINT_REG_PATH}       ${GBP_REGEP_API}
${ENDPOINT_UNREG_PATH}     ${GBP_UNREGEP_API}
${ENDPOINTS_OPER_PATH}     /restconf/operational/endpoint:endpoints

*** Keywords ***
Set Test Variables
    [Documentation]  Sets variables used in 6node test cases.
    [Arguments]   ${client_ip}    ${client_name}    ${server_ip}    ${server_name}
    ...    ${ether_type}    ${proto}    ${service_port}=${EMPTY}    ${vxlan_port}=${EMPTY}    ${vxlan_gpe_port}=${EMPTY}
    Set Global Variable    ${CLIENT_IP}       ${client_ip}
    Set Global Variable    ${CLIENT_NAME}     ${client_name}
    Set Global Variable    ${SERVER_IP}       ${server_ip}
    Set Global Variable    ${SERVER_NAME}     ${server_name}
    Set Global Variable    ${SERVICE_PORT}    ${service_port}
    Set Global Variable    ${ETHER_TYPE}      ${ether_type}
    Set Global Variable    ${PROTO}           ${proto}
    Set Global Variable    ${VXLAN_PORT}      ${vxlan_port}
    Set Global Variable    ${VXLAN_GPE_PORT}  ${vxlan_gpe_port}

