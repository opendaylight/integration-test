*** Settings ***
Documentation       Resource file containing OVSDB variables.


*** Variables ***
${OVSDB_NODE_PORT}                          6634
${RFC8040_RESTCONF_ROOT}                    /rests
${RFC8040_DATA_RESOURCE}                    ${RFC8040_RESTCONF_ROOT}/data
${RFC8040_CONFIG_CONTENT}                   content=config
${RFC8040_OPERATIONAL_CONTENT}              content=nonconfig
${RFC8040_TOPO_API}                         ${RFC8040_DATA_RESOURCE}/network-topology:network-topology
${RFC8040_CONFIG_TOPO_API}                  ${RFC8040_TOPO_API}?${RFC8040_CONFIG_CONTENT}
${RFC8040_OPERATIONAL_TOPO_API}             ${RFC8040_TOPO_API}?${RFC8040_OPERATIONAL_CONTENT}
${RFC8040_TOPO_OVSDB1_API}                  ${RFC8040_TOPO_API}/topology=ovsdb%3A1
${RFC8040_CONFIG_TOPO_OVSDB1_API}           ${RFC8040_TOPO_OVSDB1_API}?${RFC8040_CONFIG_CONTENT}
${RFC8040_OPERATIONAL_TOPO_OVSDB1_API}      ${RFC8040_TOPO_OVSDB1_API}?${RFC8040_OPERATIONAL_CONTENT}
${RFC8040_SOUTHBOUND_NODE_API}              ${RFC8040_TOPO_OVSDB1_API}/node=ovsdb%3A%2F%2F
${RFC8040_SOUTHBOUND_NODE_TOOLS_API}        ${RFC8040_SOUTHBOUND_NODE_API}${TOOLS_SYSTEM_IP}%3A${OVSDB_NODE_PORT}
${RFC8040_SOUTHBOUND_NODE_HOST1_API}        ${RFC8040_TOPO_OVSDB1_API}/node=ovsdb%3AHOST1
