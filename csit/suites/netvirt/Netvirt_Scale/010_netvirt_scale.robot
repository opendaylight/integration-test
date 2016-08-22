*** Settings ***
Documentation     Basic OVS-based NetVirt scale test
Suite Setup       RequestsLibrary.Create_Session    session    http://${ODL_SYSTEM_IP}:${RESTCONFPORT}    auth=${AUTH}    headers=${HEADERS_XML}
Suite Teardown    RequestsLibrary.Delete_All_Sessions
Library           RequestsLibrary
Variables         ${CURDIR}/../../../variables/Variables.py
Resource          ../../../libraries/Utils.robot

*** Variables ***
@{node_list}      ovsdb://uuid/
@{netvirt}        1

*** Test Cases ***
Add variables to controller custom.properties
    [Documentation]    Add variables to custom.properties
    [Tags]    Enable l3 forwarding
    Run Command On Remote System    ${ODL_SYSTEM_IP}    echo 'ovsdb.l3.fwd.enabled=yes' >> ${WORKSPACE}/${BUNDLEFOLDER}/etc/custom.properties
    Run Command On Remote System    ${ODL_SYSTEM_IP}    echo 'ovsdb.l3gateway.mac=00:00:5E:00:02:01' >> ${WORKSPACE}/${BUNDLEFOLDER}/etc/custom.properties
    ${controller_pid_1}=    Get Process ID Based On Regex On Remote System    ${ODL_SYSTEM_IP}    java.*distribution.*karaf
    Run Command On Remote System    ${ODL_SYSTEM_IP}    kill -SIGTERM ${controller_pid_1}
    Run Command On Remote System    ${ODL_SYSTEM_IP}    ${WORKSPACE}/${BUNDLEFOLDER}/bin/start
    ${controller_pid_2}=    Get Process ID Based On Regex On Remote System    ${ODL_SYSTEM_IP}    java.*distribution.*karaf
    Should Not be Equal As Numbers    ${controller_pid_1}    ${controller_pid_2}

Ensure controller is running
    [Documentation]    Check if the controller is running before sending restconf requests
    [Tags]    Check controller reachability
    Wait Until Keyword Succeeds    300s    2s    Check For Elements At URI    ${OPERATIONAL_TOPO_API}    ${node_list}

Ensure netvirt is loaded
    [Documentation]    Check if the netvirt piece has been loaded into the karaf instance
    [Tags]    Ensure netvirt is loaded
    Wait Until Keyword Succeeds    300s    4s    Check For Elements At URI    ${OPERATIONAL_NODES_NETVIRT}    ${netvirt}

Create External Net for Tenant
    [Documentation]    Create External Net for Tenant
    [Tags]    OpenStack Call Flow
    ${Data}    OperatingSystem.Get File    ${OVSDB_CONFIG_DIR}/create_ext_net.json
    ${Data}    Replace String    ${Data}    {netId}    ${EXT_NET1_ID}
    ${Data}    Replace String    ${Data}    {tntId}    ${TNT1_ID}
    Log    ${Data}
    ${resp}    RequestsLibrary.Post Request    session    ${NEUTRON_NB_API}/networks    data=${Data}    headers=${HEADERS}
    Log    ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    201
