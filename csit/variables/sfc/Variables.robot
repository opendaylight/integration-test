*** Variables ***
# Generic Service Function Chaining URIs
${RESTS_DATA}                              /rests/data
${OPERATIONAL_RSPS_URI}                     ${RESTS_DATA}/rendered-service-path:rendered-service-path?content=nonconfig
${OPERATIONAL_RSP_URI}
...                                         ${RESTS_DATA}/rendered-service-path:rendered-service-paths/rendered-service-path?content=nonconfig
${OVSDB_TOPOLOGY_URI}                       ${RESTS_DATA}/network-topology:network-topology/topology=ovsdb:1?content=nonconfig
${RENDERED_SERVICE_PATHS_URI}               ${RESTS_DATA}/rendered-service-path:rendered-service-paths?content=config
${SERVICE_CHAINS_URI}                       ${RESTS_DATA}/service-function-chain:service-function-chains
${SERVICE_CHAIN_URI}                        ${SERVICE_CHAINS_URI}/service-function-chain?content=config
${SERVICE_CLASSIFIERS_URI}                  ${RESTS_DATA}/service-function-classifier:service-function-classifiers?content=config
${SERVICE_FORWARDERS_URI}                   ${RESTS_DATA}/service-function-forwarder:service-function-forwarders
${SERVICE_FORWARDER_URI}                    ${SERVICE_FORWARDERS_URI}/service-function-forwarder?content=config
${SERVICE_FUNCTIONS_URI}                    ${RESTS_DATA}/service-function:service-functions
${SERVICE_FUNCTION_URI}                     ${SERVICE_FUNCTIONS_URI}/service-function?content=config
${SERVICE_FUNCTION_ACLS_URI}                ${RESTS_DATA}/ietf-access-control-list:access-lists?content=config
${SERVICE_FUNCTION_PATHS_STATE_URI}         ${RESTS_DATA}/service-function-path:service-function-paths-state
${SERVICE_FUNCTION_PATH_STATE_URI}          ${SERVICE_FUNCTION_PATHS_STATE_URI}/service-function-path-state?content=nonconfig
${SERVICE_FUNCTION_PATHS_URI}               ${RESTS_DATA}/service-function-path:service-function-paths
${SERVICE_FUNCTION_PATH_URI}                ${SERVICE_FUNCTION_PATHS_URI}/service-function-path?content=config
${SERVICE_FUNCTION_TYPES_URI}               ${RESTS_DATA}/service-function-type:service-function-types?content=config
${SERVICE_METADATA_URI}                     ${RESTS_DATA}/service-function-path-metadata:service-function-metadata?content=config
${SERVICE_NODES_URI}                        ${RESTS_DATA}/service-node:service-nodes
${SERVICE_NODE_URI}                         ${SERVICE_NODES_URI}/service-node?content=config
${SERVICE_SCHED_TYPES_URI}
...                                         ${RESTS_DATA}/service-function-scheduler-type:service-function-scheduler-types
${SERVICE_SCHED_TYPE_URI_BASE}
...                                         ${SERVICE_SCHED_TYPES_URI}/service-function-scheduler-type/service-function-scheduler-type:
${SERVICE_RANDOM_SCHED_TYPE_URI}            ${SERVICE_SCHED_TYPE_URI_BASE}random?content=config
${SERVICE_LOADBALANCE_SCHED_TYPE_URI}       ${SERVICE_SCHED_TYPE_URI_BASE}load-balance?content=config
${SERVICE_ROUNDROBIN_SCHED_TYPE_URI}        ${SERVICE_SCHED_TYPE_URI_BASE}round-robin?content=config
${SERVICE_SHORTESTPATH_SCHED_TYPE_URI}      ${SERVICE_SCHED_TYPE_URI_BASE}shortest-path?content=config
