*** Settings ***
Documentation     Resource file containing OpenFlow Plugin variables.

*** Variables ***
${RFC8040_API}    /rests/data
${RFC8040_CONFIG_NODES_API}    ${RFC8040_NODES_API}?content=config
${RFC8040_NODES_API}    /rests/data/opendaylight-inventory:nodes
${RFC8040_OPERATIONAL_API}    ?content=nonconfig
${RFC8040_OPERATIONAL_NODES_API}    ${RFC8040_NODES_API}?content=nonconfig
${RFC8040_OPERATIONAL_TOPO_API}    ${RFC8040_API}/network-topology:network-topology${RFC8040_OPERATIONAL_API}
${RFC8040_SAL_ECHO_API}    /rests/operations/sal-echo:send-echo
${RFC8040_SAL_FLOW_API}    /rests/operations/sal-flow
${RFC8040_SAL_TABLE_API}    /rests/operations/sal-table:update-table
${RFC8040_TOPOLOGY_API}    ${RFC8040_API}/network-topology:network-topology/topology
