*** Variables ***
${TOR_USER}       mininet
${TOR_PASSWORD}    mininet
${OVS_USER}       mininet
${OVS_PASSWORD}    mininet
${DEFAULT_TOR_PROMPT}    \#
${DEFAULT_OVS_PROMPT}    \#
${ODL_SYSTEM_IP}    192.168.122.86    #Move to variable.robot
${OVS_SWITCH_IP}    192.168.122.104
${TOR_IP}         192.168.122.104
${RESTCONFPORT}    8181
${AUTH}           [u'admin', u'admin']
${HEADERS}        {'Content-Type': 'application/json'}
${OPERATIONS_API}    /restconf/operations
${PHYSICAL_SWITCH_NAME}    br0
${PHYSICAL_SWITCH_IP}    12.0.0.11
${GREP_OVSDB_DUMP_PHYSICAL_SWITCH}    sudo ovsdb-client dump hardware_vtep -f csv | grep -A2 "Physical_Switch table"
${GREP_OVSDB_DUMP_MANAGER_TABLE}    sudo ovsdb-client dump hardware_vtep -f csv | grep -A2 "Manager table"
