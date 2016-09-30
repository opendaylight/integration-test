*** Settings ***
Documentation     Project specific constants.
Resource          ${CURDIR}/../Variables.robot

*** Variables ***
${GBP_BASE_ENDPOINTS_API}    /restconf/operational/base-endpoint:endpoints
${GBP_ENDPOINTS_API}    /restconf/operational/endpoint:endpoints
${GBP_REGEP_API}    /restconf/operations/endpoint:register-endpoint
${GBP_TENANTS_API}    /restconf/config/policy:tenants
${GBP_TUNNELS_API}    /restconf/config/opendaylight-inventory:nodes
${GBP_UNREGEP_API}    /restconf/operations/endpoint:unregister-endpoint
${MAC_ADDRESS_PATTERN}    [0-9A-Fa-f]{2}[:-][0-9A-Fa-f]{2}[:-][0-9A-Fa-f]{2}[:-][0-9A-Fa-f]{2}[:-][0-9A-Fa-f]{2}[:-][0-9A-Fa-f]{2}
${NAME_PATTERN}    [a-zA-Z]([a-zA-Z0-9\-_.])*
${NETWORK_CLIENT_GROUP}    ccc5e444-573c-11e5-885d-feff819cdc9f
${UUID_NO_DASHES}    [0-9a-f]{8}[0-9a-f]{4}[0-9a-f]{4}[0-9a-f]{4}[0-9a-f]{12}
${UUID_PATTERN}    [0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}
