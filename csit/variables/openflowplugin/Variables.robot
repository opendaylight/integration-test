*** Settings ***
Documentation       Resource file containing OpenFlow Plugin variables.


*** Variables ***
${RFC8040_RESTCONF_ROOT}                    /rests
${RFC8040_DATA_RESOURCE}                    ${RFC8040_RESTCONF_ROOT}/data
${RFC8040_CONFIG_CONTENT}                   content=config
${RFC8040_OPERATIONAL_CONTENT}              content=nonconfig
${RFC8040_NODES_API}                        ${RFC8040_DATA_RESOURCE}/opendaylight-inventory:nodes
${RFC8040_CONFIG_NODES_API}                 ${RFC8040_NODES_API}?${RFC8040_CONFIG_CONTENT}
${RFC8040_OPERATIONAL_NODES_API}            ${RFC8040_NODES_API}?${RFC8040_OPERATIONAL_CONTENT}
${RFC8040_TOPO_API}                         ${RFC8040_DATA_RESOURCE}/network-topology:network-topology
${RFC8040_OPERATIONAL_TOPO_API}             ${RFC8040_TOPO_API}?${RFC8040_OPERATIONAL_CONTENT}
${RFC8040_OPERATIONAL_TOPO_FLOW1_API}       ${RFC8040_TOPO_API}/topology=flow%3A1?${RFC8040_OPERATIONAL_CONTENT}
