*** Variables ***
# Generic Service Chains and Function URIs
${SERVICE_FUNCTIONS_URI}    /restconf/config/service-function:service-functions/
${SERVICE_FUNCTION_ACLS_URI}    /restconf/config/ietf-access-control-list:access-lists/
${SERVICE_CLASSIFIERS_URI}    /restconf/config/service-function-classifier:service-function-classifiers/
${SERVICE_FORWARDERS_URI}    /restconf/config/service-function-forwarder:service-function-forwarders/
${SERVICE_NODES_URI}    /restconf/config/service-node:service-nodes/
${SERVICE_CHAINS_URI}    /restconf/config/service-function-chain:service-function-chains/
${SERVICE_FUNCTION_PATHS_URI}    /restconf/config/service-function-path:service-function-paths/
${SERVICE_SCHED_TYPES_URI}    /restconf/config/service-function-scheduler-type:service-function-scheduler-types/
${SERVICE_SCHED_TYPE_URI_BASE}    SERVICE_SCHED_TYPES_URI+'service-function-scheduler-type/service-function-scheduler-type:'
${SERVICE_RANDOM_SCHED_TYPE_URI}    SERVICE_SCHED_TYPE_URI_BASE+'random'
${SERVICE_ROUNDROBIN_SCHED_TYPE_URI}    SERVICE_SCHED_TYPE_URI_BASE+'round-robin'
${SERVICE_METADATA_URI}    /restconf/config/service-function-path-metadata:service-function-metadata/
${OPERATIONAL_RSPS_URI}    /restconf/operational/rendered-service-path:rendered-service-paths/
${OPERATIONS_CREATE_RSP_URI}    /restconf/operations/rendered-service-path:create-rendered-path/
${OPERATIONS_DELETE_RSP_URI}    /restconf/operations/rendered-service-path:delete-rendered-path/
