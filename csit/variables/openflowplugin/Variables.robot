*** Settings ***
Documentation     Resource file containing OpenFlow Plugin variables.

*** Variables ***
${RFC8040_NODES_API}    /rests/data/opendaylight-inventory:nodes
${RFC8040_CONFIG_NODES_API}    ${RFC8040_NODES_API}?content=config
${RFC8040_OPERATIONAL_NODES_API}    ${RFC8040_NODES_API}?content=nonconfig
