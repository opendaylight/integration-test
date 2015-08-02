*** Settings ***
Library           SSHLibrary
Resource          Utils.robot
Library           String
Library           Collections
Variables         ../variables/Variables.py
Library           RequestsLibrary

*** Variables ***
${OVSDB_CONFIG_DIR}    ../variables/ovsdb
${SOUTHBOUND_CONFIG_API}    ${CONFIG_TOPO_API}/topology/ovsdb:1/node/ovsdb:%2F%2F

*** Keywords ***
Connect To Ovsdb Node
    [Arguments]    ${mininet_ip}
    [Documentation]    This will Initiate the connection to OVSDB node from controller
    ${sample}    OperatingSystem.Get File    ${OVSDB_CONFIG_DIR}/connect.json
    ${sample1}    Replace String    ${sample}    127.0.0.1    ${mininet_ip}
    ${body}    Replace String    ${sample1}    61644    ${OVSDB_PORT}
    Log    URL is ${SOUTHBOUND_CONFIG_API}${mininet_ip}:${OVSDB_PORT}
    ${resp}    RequestsLibrary.Put    session    ${SOUTHBOUND_CONFIG_API}${mininet_ip}:${OVSDB_PORT}    data=${body}
    Log    ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200

Disconnect From Ovsdb Node
    [Arguments]    ${mininet_ip}
    [Documentation]    This request will disconnect the OVSDB node from the controller
    ${resp}    RequestsLibrary.Delete    session    ${SOUTHBOUND_CONFIG_API}${mininet_ip}:${OVSDB_PORT}
    Should Be Equal As Strings    ${resp.status_code}    200

Add Bridge To Ovsdb Node
    [Arguments]    ${mininet_ip}    ${bridge_num}    ${datapath_id}
    [Documentation]    This will create a bridge and add it to the OVSDB node.
    ${sample}    OperatingSystem.Get File    ${OVSDB_CONFIG_DIR}/create_bridge.json
    ${sample1}    Replace String    ${sample}    tcp:127.0.0.1:6633    tcp:${CONTROLLER}:6633
    ${sample2}    Replace String    ${sample1}    127.0.0.1    ${mininet_ip}
    ${sample3}    Replace String    ${sample2}    br01    ${bridge_num}
    ${sample4}    Replace String    ${sample3}    61644    ${OVSDB_PORT}
    ${body}    Replace String    ${sample4}    0000000000000001    ${datapath_id}
    Log    URL is ${SOUTHBOUND_CONFIG_API}${mininet_ip}:${OVSDB_PORT}%2Fbridge%2F${bridge_num}
    ${resp}    RequestsLibrary.Put    session    ${SOUTHBOUND_CONFIG_API}${mininet_ip}:${OVSDB_PORT}%2Fbridge%2F${bridge_num}    data=${body}
    Log    ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200

Delete Bridge From Ovsdb Node
    [Arguments]    ${mininet_ip}    ${bridge_num}
    [Documentation]    This request will delete the bridge node from the OVSDB
    ${resp}    RequestsLibrary.Delete    session    ${SOUTHBOUND_CONFIG_API}${mininet_ip}:${OVSDB_PORT}%2Fbridge%2F${bridge_num}
    Should Be Equal As Strings    ${resp.status_code}    200

Add Vxlan To Bridge
    [Arguments]    ${mininet_ip}    ${bridge_num}    ${vxlan_port}    ${remote_ip}    ${custom_port}=create_port.json
    [Documentation]    This request will create vxlan port for vxlan tunnel and attach it to the specific bridge
    ${sample}    OperatingSystem.Get File    ${OVSDB_CONFIG_DIR}/${custom_port}
    ${body}    Replace String    ${sample}    192.168.0.21    ${remote_ip}
    Log    URL is ${SOUTHBOUND_CONFIG_API}${mininet_ip}:${OVSDB_PORT}%2Fbridge%2F${bridge_num}/termination-point/${vxlan_port}/
    ${resp}    RequestsLibrary.Put    session    ${SOUTHBOUND_CONFIG_API}${mininet_ip}:${OVSDB_PORT}%2Fbridge%2F${bridge_num}/termination-point/${vxlan_port}/    data=${body}
    Log    ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200
