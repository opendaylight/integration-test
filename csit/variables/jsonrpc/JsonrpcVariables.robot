*** Settings ***
Documentation     Resource consisting purely of variable definitions useful for multiple project suites.

*** Variables ***
${INTERFACES_MODULE_JSON}    ${CURDIR}/interfaces_module.json
${INTERFACES_DATA_JSON}    ${CURDIR}/interfaces_data.json
${READ_SERVICE_PEER_PUT_URL}    /restconf/config/jsonrpc:config/configured-endpoints/
${READ_SERVICE_PEER_PAYLOAD}    ${CURDIR}/readservice_peer_payload.json
${READ_SERVICE_PEER_GET_1}    /restconf/config/opendaylight-inventory:nodes/node/
${READ_SERVICE_PEER_GET_2}    /yang-ext:mount/ietf-interfaces:interfaces/
${DEFAULT_ENDPOINT}    foo
${DEFAULT_PORT}    4444
${DEFAULT_PUT_MODULE}    ietf-interfaces
${FIRST_CONTROLLER_INDEX}    1
${CENTOS_PIP}     sudo yum -y install python-pip
${UB_PIP}         sudo apt-get install -y python-pip
${READ_SERVICE_SCRIPT}    ${CURDIR}/odl-jsonrpc-test-read
