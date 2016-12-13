*** Settings ***
Library           SSHLibrary
Library           Collections
Library           OperatingSystem
Library           RequestsLibrary
Variables         ../../../variables/Variables.py
Resource          ../../../libraries/Utils.robot
Resource          ../../../libraries/TemplatedRequests.robot

*** Keywords ***
Init
    [Arguments]    ${FILENAME}
    [Documentation]    Initialize session and ODL version specific variables
    # Common initializations
    log    ${ODL_STREAM}
    Set Suite Variable    ${VERSION_DIR}    master
    BuiltIn.Run Keyword    Init ${FILENAME}

Init Create Session
    Create Session    session    http://${ODL_SYSTEM_IP}:${RESTCONFPORT}    auth=${AUTH}    headers=${HEADERS}

Init 010__sfc_service_functions
    BuiltIn.Run Keyword    Init Create Session
    Set Suite Variable    ${SERVICE_FUNCTIONS_URI}    /restconf/config/service-function:service-functions/
    Set Suite Variable    ${SERVICE_FUNCTIONS_FILE}    ${CURDIR}/../../../variables/sfc/${VERSION_DIR}/service-functions.json
    Set Suite Variable    ${SF_DPI102100_URI}    /restconf/config/service-function:service-functions/service-function/dpi-102-100/
    Set Suite Variable    ${SF_DPI102100_FILE}    ${CURDIR}/../../../variables/sfc/${VERSION_DIR}/sf_dpi_102_100.json
    Set Suite Variable    ${SF_DPL101_FILE}    ${CURDIR}/../../../variables/sfc/${VERSION_DIR}/sf_dpl_101.json

Init 020__sfc_service_forwarders
    BuiltIn.Run Keyword    Init Create Session
    Set Suite Variable    ${SERVICE_FORWARDERS_URI}    /restconf/config/service-function-forwarder:service-function-forwarders/
    Set Suite Variable    ${SERVICE_FORWARDERS_FILE}    ${CURDIR}/../../../variables/sfc/${VERSION_DIR}/service-function-forwarders.json
    Set Suite Variable    ${SFF_OVS100_URI}    /restconf/config/service-function-forwarder:service-function-forwarders/service-function-forwarder/ovs-100/
    Set Suite Variable    ${SFF_OVS100_FILE}    ${CURDIR}/../../../variables/sfc/${VERSION_DIR}/sff_ovs_100.json
    Set Suite Variable    ${SFF_DPL101_FILE}    ${CURDIR}/../../../variables/sfc/${VERSION_DIR}/sff_dpl_101.json
    Set Suite Variable    ${SFF_DPL_LOCATOR_FILE}    ${CURDIR}/../../../variables/sfc/${VERSION_DIR}/sff_dpl_locator.json
    Set Suite Variable    ${SFF_SFD_SF100_FILE}    ${CURDIR}/../../../variables/sfc/${VERSION_DIR}/sff_sfd_sf100.json
    Set Suite Variable    ${SFF_SFD_LOCATOR_FILE}    ${CURDIR}/../../../variables/sfc/${VERSION_DIR}/sff_sfd_locator.json
    Set Suite Variable    ${SFF_CSD_SFF100_FILE}    ${CURDIR}/../../../variables/sfc/${VERSION_DIR}/sff_csd_sff100.json
    Set Suite Variable    ${SFF_CSD_LOCATOR_FILE}    ${CURDIR}/../../../variables/sfc/${VERSION_DIR}/sff_csd_locator.json

Init 030__sfc_service_nodes
    BuiltIn.Run Keyword    Init Create Session
    Set Suite Variable    ${SERVICE_NODES_URI}    /restconf/config/service-node:service-nodes/
    Set Suite Variable    ${SERVICE_NODES_FILE}    ${CURDIR}/../../../variables/sfc/${VERSION_DIR}/service-nodes.json
    Set Suite Variable    ${SN_NODE100_URI}    /restconf/config/service-node:service-nodes/service-node/node-100
    Set Suite Variable    ${SN_NODE100_FILE}    ${CURDIR}/../../../variables/sfc/${VERSION_DIR}/sn_node_100.json

Init 040__sfc_service_chains
    BuiltIn.Run Keyword    Init Create Session
    Set Suite Variable    ${SERVICE_CHAINS_URI}    /restconf/config/service-function-chain:service-function-chains/
    Set Suite Variable    ${SERVICE_CHAINS_FILE}    ${CURDIR}/../../../variables/sfc/${VERSION_DIR}/service-function-chains.json
    Set Suite Variable    ${SERVICE_CHAIN100_URI}    /restconf/config/service-function-chain:service-function-chains/service-function-chain/SFC100
    Set Suite Variable    ${SERVICE_CHAIN100_FILE}    ${CURDIR}/../../../variables/sfc/${VERSION_DIR}/sfc_chain_100.json
    Set Suite Variable    ${SERVICE_CHAIN100_SFIDS_URI}    /restconf/config/service-function-chain:service-function-chains/service-function-chain/SFC100/sfc-service-function/ids-abstract100
    Set Suite Variable    ${SERVICE_CHAIN100_SFIDS_FILE}    ${CURDIR}/../../../variables/sfc/${VERSION_DIR}/sfc_chain_100_sfids.json

Init 050__sfc_service_schedule_types
    BuiltIn.Run Keyword    Init Create Session
    Set Suite Variable    ${SERVICE_SCHED_TYPES_URI}    /restconf/config/service-function-scheduler-type:service-function-scheduler-types/
    Set Suite Variable    ${SERVICE_SCHED_TYPES_FILE}    ${CURDIR}/../../../variables/sfc/${VERSION_DIR}/service-schedule-types.json
    Set Suite Variable    ${SERVICE_WSP_SCHED_TYPE_URI}    /restconf/config/service-function-scheduler-type:service-function-scheduler-types/service-function-scheduler-type/service-function-scheduler-type:weighted-shortest-path
    Set Suite Variable    ${SERVICE_WSP_SCHED_TYPE_FILE}    ${CURDIR}/../../../variables/sfc/${VERSION_DIR}/service-wsp-schedule-type.json

Init 060__sfc_service_paths
    BuiltIn.Run Keyword    Init Create Session
    Set Suite Variable    ${SERVICE_FUNCTION_PATHS_URI}    /restconf/config/service-function-path:service-function-paths/
    Set Suite Variable    ${SERVICE_FUNCTION_PATHS_FILE}    ${CURDIR}/../../../variables/sfc/${VERSION_DIR}/service-function-paths.json
    Set Suite Variable    ${SERVICE_FUNCTION_PATH400_URI}    /restconf/config/service-function-path:service-function-paths/service-function-path/SFC1-400
    Set Suite Variable    ${SERVICE_FUNCTION_PATH400_FILE}    ${CURDIR}/../../../variables/sfc/${VERSION_DIR}/sfp_sfc1_path400.json

Init 070__sfc_rendered_service_paths
    BuiltIn.Run Keyword    Init Create Session
    Set Suite Variable    ${SERVICE_FUNCTIONS_URI}    /restconf/config/service-function:service-functions/
    Set Suite Variable    ${SERVICE_FUNCTIONS_FILE}    ${CURDIR}/../../../variables/sfc/${VERSION_DIR}/service-functions.json
    Set Suite Variable    ${SERVICE_FORWARDERS_URI}    /restconf/config/service-function-forwarder:service-function-forwarders/
    Set Suite Variable    ${SERVICE_FORWARDERS_FILE}    ${CURDIR}/../../../variables/sfc/${VERSION_DIR}/service-function-forwarders.json
    Set Suite Variable    ${SERVICE_NODES_URI}    /restconf/config/service-node:service-nodes/
    Set Suite Variable    ${SERVICE_NODES_FILE}    ${CURDIR}/../../../variables/sfc/${VERSION_DIR}/service-nodes.json
    Set Suite Variable    ${SERVICE_CHAINS_URI}    /restconf/config/service-function-chain:service-function-chains/
    Set Suite Variable    ${SERVICE_CHAINS_FILE}    ${CURDIR}/../../../variables/sfc/${VERSION_DIR}/service-function-chains.json
    Set Suite Variable    ${SERVICE_FUNCTION_PATHS_URI}    /restconf/config/service-function-path:service-function-paths/
    Set Suite Variable    ${SERVICE_FUNCTION_PATHS_FILE}    ${CURDIR}/../../../variables/sfc/${VERSION_DIR}/service-function-paths.json
    Set Suite Variable    ${SERVICE_SCHED_TYPES_URI}    /restconf/config/service-function-scheduler-type:service-function-scheduler-types/
    Set Suite Variable    ${SERVICE_SCHED_TYPE_URI_BASE}    ${SERVICE_SCHED_TYPES_URI}service-function-scheduler-type/service-function-scheduler-type:
    Set Suite Variable    ${SERVICE_RANDOM_SCHED_TYPE_URI}    ${SERVICE_SCHED_TYPE_URI_BASE}random
    Set Suite Variable    ${SERVICE_RANDOM_SCHED_TYPE_FILE}    ${CURDIR}/../../../variables/sfc/${VERSION_DIR}/service-random-schedule-type.json
    Set Suite Variable    ${SERVICE_ROUNDROBIN_SCHED_TYPE_URI}    ${SERVICE_SCHED_TYPE_URI_BASE}round-robin
    Set Suite Variable    ${SERVICE_ROUNDROBIN_SCHED_TYPE_FILE}    ${CURDIR}/../../../variables/sfc/${VERSION_DIR}/service-roundrobin-schedule-type.json
    Set Suite Variable    ${SERVICE_LOADBALANCE_SCHED_TYPE_URI}    ${SERVICE_SCHED_TYPE_URI_BASE}load-balance
    Set Suite Variable    ${SERVICE_LOADBALANCE_SCHED_TYPE_FILE}    ${CURDIR}/../../../variables/sfc/${VERSION_DIR}/service-loadbalance-schedule-type.json
    Set Suite Variable    ${SERVICE_SHORTESTPATH_SCHED_TYPE_URI}    ${SERVICE_SCHED_TYPE_URI_BASE}shortest-path
    Set Suite Variable    ${SERVICE_SHORTESTPATH_SCHED_TYPE_FILE}    ${CURDIR}/../../../variables/sfc/${VERSION_DIR}/service-shortestpath-schedule-type.json
    Set Suite Variable    ${RENDERED_SERVICE_PATHS_URI}    /restconf/config/rendered-service-path:rendered-service-paths/
    Set Suite Variable    ${OPERATIONAL_RSPS_URI}    /restconf/operational/rendered-service-path:rendered-service-paths/
    Set Suite Variable    ${OPERATIONS_CREATE_RSP_URI}    /restconf/operations/rendered-service-path:create-rendered-path/
    Set Suite Variable    ${OPERATIONS_DELETE_RSP_URI}    /restconf/operations/rendered-service-path:delete-rendered-path
    Set Suite Variable    ${CREATE_RSP1_INPUT}    {"input":{"parent-service-function-path":"SFC1-100","name":"SFC1-100-Path-1"}}
    Set Suite Variable    ${CREATE_RSP2_INPUT}    {"input":{"parent-service-function-path":"SFC1-100","name":"SFC1-100-Path-2"}}
    Set Suite Variable    ${CREATE_RSP3_INPUT}    {"input":{"parent-service-function-path":"SFC1-100","name":"SFC1-100-Path-3"}}
    Set Suite Variable    ${CREATE_RSP4_INPUT}    {"input":{"parent-service-function-path":"SFC1-100","name":"SFC1-100-Path-4"}}
    Set Suite Variable    ${CREATE_RSP5_INPUT}    {"input":{"parent-service-function-path":"SFC1-100","name":"SFC1-100-Path-5"}}
    Set Suite Variable    ${CREATE_RSP6_INPUT}    {"input":{"parent-service-function-path":"SFC1-100","name":"SFC1-100-Path-6"}}
    Set Suite Variable    ${CREATE_RSP_FAILURE_INPUT}    {"input":{"parent-service-function-path":"SFC1-empty","name":"SFC1-empty-Path-1"}}
    Set Suite Variable    ${DELETE_RSP1_INPUT}    {"input":{"name":"SFC1-100-Path-1"}}
    Set Suite Variable    ${DELETE_RSP2_INPUT}    {"input":{"name":"SFC1-100-Path-2"}}
    Set Suite Variable    ${DELETE_RSP3_INPUT}    {"input":{"name":"SFC1-100-Path-3"}}
    Set Suite Variable    ${DELETE_RSP4_INPUT}    {"input":{"name":"SFC1-100-Path-4"}}
    Set Suite Variable    ${DELETE_RSP5_INPUT}    {"input":{"name":"SFC1-100-Path-5"}}
    Set Suite Variable    ${DELETE_RSP6_INPUT}    {"input":{"name":"SFC1-100-Path-6"}}

Init 080__sfc_simple_clustering
    Set Suite Variable    ${SFC_FUNCTIONS_FILE}    ${CURDIR}/../../../variables/sfc/${VERSION_DIR}/service-functions.json

Init 090__sfc_service_function_metadata
    BuiltIn.Run Keyword    Init Create Session
    Set Suite Variable    ${SERVICE_FUNCTION_METADATA_URI}    /restconf/config/service-function-path-metadata:service-function-metadata/
    Set Suite Variable    ${SERVICE_FUNCTION_METADATA_FILE}    ${CURDIR}/../../../variables/sfc/${VERSION_DIR}/service-function-metadata.json
    Set Suite Variable    ${SERVICE_FUNCTION_METADATA_CONTEXT_METADATA_URI}    /restconf/config/service-function-path-metadata:service-function-metadata/context-metadata
    Set Suite Variable    ${SERVICE_FUNCTION_METADATA_CONTEXT_METADATA_FILE}    ${CURDIR}/../../../variables/sfc/${VERSION_DIR}/service-function-metadata-context-metadata.json
    Set Suite Variable    ${SERVICE_FUNCTION_METADATA_VARIABLE_METADATA_URI}    /restconf/config/service-function-path-metadata:service-function-metadata/variable-metadata
    Set Suite Variable    ${SERVICE_FUNCTION_METADATA_VARIABLE_METADATA_FILE}    ${CURDIR}/../../../variables/sfc/${VERSION_DIR}/service-function-metadata-variable-metadata.json
