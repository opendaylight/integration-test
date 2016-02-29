*** Settings ***
Documentation     Project specific constants.

*** Variables ***

${NETWORK_CLIENT_GROUP}  ccc5e444-573c-11e5-885d-feff819cdc9f
${UUID_NO_DASHES}        [0-9a-f]{8}[0-9a-f]{4}[0-9a-f]{4}[0-9a-f]{4}[0-9a-f]{12}
${UUID_PATTERN}          [0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}
${NAME_PATTERN}          [a-zA-Z]([a-zA-Z0-9\-_.])*
${MAC_ADDRESS_PATTERN}   [0-9A-Fa-f]{2}[:-][0-9A-Fa-f]{2}[:-][0-9A-Fa-f]{2}[:-][0-9A-Fa-f]{2}[:-][0-9A-Fa-f]{2}[:-][0-9A-Fa-f]{2}