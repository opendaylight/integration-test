*** Settings ***
Documentation     Resource consisting purely of variable definitions useful for multiple project suites.

*** Variables ***
${JSONRPCCONFIG_MODULE_JSON}    ${CURDIR}/jsonrpcconfig_module.json
${JSONRPCCONFIG_DATA_JSON}    ${CURDIR}/jsonrpcconfig_data.json
${READ_SERVICE_PEER_URL}    /rests/data/jsonrpc:config/configured-endpoints
${READ_SERVICE_PEER_PAYLOAD}    ${CURDIR}/readservice_peer_payload.json
${READ_SERVICE_PEER_MOUNT_PATH}    /yang-ext:mount/jsonrpc:config
${DEFAULT_ENDPOINT}    foo
${DEFAULT_PORT}    4444
${FIRST_CONTROLLER_INDEX}    1
${CENTOS_PIP}     sudo yum -y install python-pip
${UB_PIP}         sudo apt-get install -y python-pip
${READ_SERVICE_SCRIPT}    ${CURDIR}/odl-jsonrpc-test-read
${JSONRPCCONFIG_MODULE_DEFAULT_DATA}    jsonrpc:config
${READSERVICE_NAME}    foo
