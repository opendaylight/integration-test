*** Settings ***
Documentation     Resource consisting purely of variable definitions useful for multiple project suites.

*** Variables ***
${JSONRPCCONFIG_MODULE_JSON}    ${CURDIR}/jsonrpcconfig_module.json
${JSONRPCCONFIG_DATA_JSON}    ${CURDIR}/jsonrpcconfig_data.json
${READ_SERVICE_PEER_PUT_URL}    /restconf/config/jsonrpc:config/configured-endpoints/
${READ_SERVICE_PEER_PAYLOAD}    ${CURDIR}/readservice_peer_payload.json
${READ_SERVICE_PEER_GET_1}    /restconf/config/jsonrpc:config/configured-endpoints/
${READ_SERVICE_PEER_GET_2}    /yang-ext:mount/jsonrpc:config/
${DEFAULT_ENDPOINT}    foo
${DEFAULT_PORT}    4444
${FIRST_CONTROLLER_INDEX}    1
${CENTOS_PIP}     sudo yum -y install python-pip
${UB_PIP}         sudo apt-get install -y python-pip
${READ_SERVICE_SCRIPT}    ${CURDIR}/odl-jsonrpc-test-read
${JSONRPCCONFIG_MODULE_DEFAULT_DATA}    jsonrpc:config
${READSERVICE_NAME}    foo
${TESTTOOL_GOV_ENDPOINT}    zmq://0.0.0.0:24320
${REMOTE_CONTROL_ENDPOINT}    zmq://0.0.0.0:24330
${TESTTOOL_DATA_ENDPOINT}    zmq://0.0.0.0:24340
${TESTTOOL_RPC_ENDPOINT}    zmq://0.0.0.0:24350
${TESTTOOL_JAVA_OPTIONS}    -Xmx512M -DLOG_LEVEL=TRACE
${JSONRPC_CFG_DS_URI}    restconf/config/jsonrpc:config
${JSONRPC_RPC_URI}    restconf/operations/jsonrpc:config
${JSONRPC_OP_DS_URI}    restconf/operational/jsonrpc:config
${JSONRPC_MP_URI}    ${JSONRPC_CFG_DS_URI}/configured-endpoints
