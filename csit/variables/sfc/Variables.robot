*** Variables ***
# Generic Service Chains and Function URIs
${REST_CONFIG}    /restconf/config
${REST_OPER}    /restconf/operational
${REST_RPC}    /restconf/operations
${SERVICE_FUNCTION_TYPES_URI}    ${REST_CONFIG}/service-function-type:service-function-types/
${SERVICE_FUNCTIONS_URI}    ${REST_CONFIG}/service-function:service-functions/
${SERVICE_FUNCTION_URI}    ${REST_CONFIG}/service-function:service-functions/service-function/
${SERVICE_FUNCTION_ACLS_URI}    ${REST_CONFIG}/ietf-access-control-list:access-lists/
${SERVICE_CLASSIFIERS_URI}    ${REST_CONFIG}/service-function-classifier:service-function-classifiers/
${SERVICE_FORWARDERS_URI}    ${REST_CONFIG}/service-function-forwarder:service-function-forwarders/
${SERVICE_FORWARDER_URI}    ${REST_CONFIG}/service-function-forwarder:service-function-forwarders/service-function-forwarder/
${SERVICE_NODES_URI}    ${REST_CONFIG}/service-node:service-nodes/
${SERVICE_CHAINS_URI}    ${REST_CONFIG}/service-function-chain:service-function-chains/
${SERVICE_FUNCTION_PATHS_URI}    ${REST_CONFIG}/service-function-path:service-function-paths/
${SERVICE_SCHED_TYPES_URI}    ${REST_CONFIG}/service-function-scheduler-type:service-function-scheduler-types/
${SERVICE_SCHED_TYPE_URI_BASE}    ${SERVICE_SCHED_TYPES_URI}service-function-scheduler-type/service-function-scheduler-type:
${SERVICE_RANDOM_SCHED_TYPE_URI}    ${SERVICE_SCHED_TYPE_URI_BASE}random
${SERVICE_ROUNDROBIN_SCHED_TYPE_URI}    ${SERVICE_SCHED_TYPE_URI_BASE}round-robin
${SERVICE_METADATA_URI}    ${REST_CONFIG}/service-function-path-metadata:service-function-metadata/
${OPERATIONAL_RSPS_URI}    ${REST_OPER}/rendered-service-path:rendered-service-paths/
${OPERATIONS_CREATE_RSP_URI}    ${REST_RPC}/rendered-service-path:create-rendered-path/
${OPERATIONS_DELETE_RSP_URI}    ${REST_RPC}/rendered-service-path:delete-rendered-path/
${RENDERED_SERVICE_PATHS_URI}    ${REST_CONFIG}/rendered-service-path:rendered-service-paths/
${OVSDB_TOPOLOGY_URI}    ${REST_OPER}/network-topology:network-topology/topology/ovsdb:2
