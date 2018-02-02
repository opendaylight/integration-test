*** Settings ***
Documentation     Test Suite for Interface manager
Suite Setup       Create Session    session    http://${ODL_SYSTEM_IP}:${RESTCONFPORT}    auth=${AUTH}    headers=${HEADERS}
Suite Teardown    Delete All Sessions
Test Teardown     Get Model Dump    ${ODL_SYSTEM_IP}    ${data_models}
Library           OperatingSystem
Library           String
Library           RequestsLibrary
Library           Collections
Library           re
Variables         ../../../variables/Variables.py
Variables         ../../../variables/genius/Modules.py
Resource          ../../../libraries/DataModels.robot
Resource          ../../../libraries/Utils.robot

*** Variables ***
${genius_config_dir}    ${CURDIR}/../../../variables/genius
${bridgename}     BR1
${interface_name}    l2vlan-trunk
${trunk_json}     l2vlan.json
${trunk_member_json}    l2vlan_member.json

*** Test Cases ***
Create l2vlan transparent interface
    [Documentation]    This testcase creates a l2vlan transparent interface between 2 dpns.
    Log    >>>> Creating L2vlan interface <<<<<
    Create Interface    ${trunk_json}    transparent
    Log    >>>> Get interface config <<<<<
    @{l2vlan}    create list    l2vlan-trunk    l2vlan    transparent    l2vlan    true
    Check For Elements At URI    ${CONFIG_API}/ietf-interfaces:interfaces/    ${l2vlan}
    Log    >>>>> Get interface operational state<<<<
    Wait Until Keyword Succeeds    50    5    get operational interface    ${interface_name}
    ${ovs-check}    Wait Until Keyword Succeeds    40    10    table0 entry    ${conn_id_1}    ${bridgename}

Delete l2vlan transparent interface
    [Documentation]    This testcase deletes the l2vlan transparent interface created between 2 dpns.
    Remove All Elements At URI And Verify    ${CONFIG_API}/ietf-interfaces:interfaces/
    No Content From URI    session    ${OPERATIONAL_API}/ietf-interfaces:interfaces/
    Wait Until Keyword Succeeds    30    10    no table0 entry

Create l2vlan trunk interface
    [Documentation]    This testcase creates a l2vlan trunk interface between 2 DPNs.
    Log    >>>> Getting file for posting json <<<<<<<
    Create Interface    ${trunk_json}    trunk
    Log    >>>> Get interface config <<<<<
    @{l2vlan}    create list    l2vlan-trunk    l2vlan    trunk    tap8ed70586-6c    true
    Check For Elements At URI    ${CONFIG_API}/ietf-interfaces:interfaces/    ${l2vlan}
    Log    >>>>> Get interface operational state<<<<
    Wait Until Keyword Succeeds    50    5    get operational interface    ${interface_name}
    Wait Until Keyword Succeeds    30    10    table0 entry    ${conn_id_1}    ${bridgename}

Create l2vlan Trunk member interface
    [Documentation]    This testcase creates a l2vlan Trunk member interface for the l2vlan trunk interface created in 1st testcase.
    Log    >>>> Creating L2vlan member interface <<<<<
    Log    >>>> Getting file for posting json <<<<<<<
    ${body}    OperatingSystem.Get File    ${genius_config_dir}/l2vlan_member.json
    ${post_resp}    RequestsLibrary.Post Request    session    ${CONFIG_API}/ietf-interfaces:interfaces/    data=${body}
    Log    ${post_resp.content}
    Log    ${post_resp.status_code}
    Should Be Equal As Strings    ${post_resp.status_code}    204
    Log    >>>> Get interface config <<<<<
    @{l2vlan}    create list    l2vlan-trunk1    l2vlan    trunk-member    1000    l2vlan-trunk
    ...    true
    Check For Elements At URI    ${CONFIG_API}/ietf-interfaces:interfaces/    ${l2vlan}
    Log    >>>>> Get interface operational state<<<<
    Wait Until Keyword Succeeds    10    5    get operational interface    ${l2vlan[0]}
    Wait Until Keyword Succeeds    40    10    ovs check for member interface creation    ${conn_id_1}    ${bridgename}

Bind service on Interface
    [Documentation]    This testcase binds service to the interface created .
    Log    >>>> Getting file for posting json <<<<<<<
    ${body}    OperatingSystem.Get File    ${genius_config_dir}/bind_service.json
    ${body}    replace string    ${body}    service1    VPN
    ${body}    replace string    ${body}    service2    elan
    log    ${body}
    ${service_mode}    Set Variable    interface-service-bindings:service-mode-ingress
    ${post_resp}    RequestsLibrary.Post Request    session    ${CONFIG_API}/interface-service-bindings:service-bindings/services-info/${interface_name}/${service_mode}/    data=${body}
    log    ${post_resp.content}
    log    ${post_resp.status_code}
    Should Be Equal As Strings    ${post_resp.status_code}    204
    Log    >>>>> Verifying Binded interface <<<<<
    @{bind_array}    create list    2    3    VPN    elan    50
    ...    21
    Check For Elements At URI    ${CONFIG_API}/interface-service-bindings:service-bindings/services-info/${interface_name}/${service_mode}/    ${bind_array}
    Log    >>>>> OVS check for table enteries <<<<
    ${command}    set variable    sudo ovs-ofctl -O OpenFlow13 dump-flows ${bridgename}
    Wait Until Keyword Succeeds    40    10    table entry    ${command}

unbind service on interface
    [Documentation]    This testcase Unbinds the service which is binded by the 3rd testcase.
    Log    >>>>>>Unbinding the service on interface <<<<
    ${service-priority-1}    set variable    3
    ${service-priority-2}    set variable    4
    ${service_mode}    Set Variable    interface-service-bindings:service-mode-ingress
    Remove All Elements At URI And Verify    ${CONFIG_API}/interface-service-bindings:service-bindings/services-info/${interface_name}/${service_mode}/bound-services/${service-priority-1}/
    log    >>>> Ovs check for table 21 absence <<<
    ${table-id}    set variable    21
    Wait Until Keyword Succeeds    10    2    no goto_table entry    ${table-id}
    Remove All Elements At URI And Verify    ${CONFIG_API}/interface-service-bindings:service-bindings/services-info/${interface_name}/${service_mode}/bound-services/${service-priority-2}/
    No Content From URI    session    ${CONFIG_API}/interface-service-bindings:service-bindings/services-info/${interface_name}/${service_mode}/bound-services/${service-priority-2}/
    log    >>>> Ovs check for table 50 absence <<<
    ${table-id}    set variable    50
    Wait Until Keyword Succeeds    10    2    no goto_table entry    ${table-id}

Delete l2vlan trunk interface
    [Documentation]    Deletion of l2vlan trunk interface is done.
    Remove All Elements At URI And Verify    ${CONFIG_API}/ietf-interfaces:interfaces/
    No Content From URI    session    ${OPERATIONAL_API}/ietf-interfaces:interfaces/
    ${resp}    Wait Until Keyword Succeeds    30    10    no table0 entry

*** Keywords ***
get operational interface
    [Arguments]    ${interface_name}
    [Documentation]    checks operational status of the interface.
    ${get_oper_resp}    RequestsLibrary.Get Request    session    ${OPERATIONAL_API}/ietf-interfaces:interfaces-state/interface/${interface_name}/
    ${respjson}    RequestsLibrary.To Json    ${get_oper_resp.content}    pretty_print=True
    log    ${respjson}
    log    ${get_oper_resp.status_code}
    Should Be Equal As Strings    ${get_oper_resp.status_code}    200
    Should not contain    ${get_oper_resp.content}    down
    Should Contain    ${get_oper_resp.content}    up    up

table entry
    [Arguments]    ${command}
    [Documentation]    Checks for tables entry wrt the service the Interface is binded.
    switch connection    ${conn_id_1}
    ${result}    execute command    ${command}
    log    ${result}
    should contain    ${result}    table=17
    should contain    ${result}    goto_table:21
    should contain    ${result}    goto_table:50

no table0 entry
    [Documentation]    After Deleting trunk interface, checking for absence of table 0 in the flow dumps
    switch connection    ${conn_id_1}
    ${bridgename}    set variable    BR1
    ${ovs-check}    execute command    sudo ovs-ofctl -O OpenFlow13 dump-flows ${bridgename}
    log    ${ovs-check}
    should not contain    ${ovs-check}    table=0
    should not contain    ${ovs-check}    goto_table:17

no goto_table entry
    [Arguments]    ${table-id}
    [Documentation]    Checks for absence of no goto_table after unbinding the service on the interface.
    switch connection    ${conn_id_1}
    ${ovs-check1}    execute command    sudo ovs-ofctl -O OpenFlow13 dump-flows ${bridgename}
    Log    ${ovs-check1}
    should not contain    ${ovs-check1}    goto_table:${table-id}

table0 entry
    [Arguments]    ${connection-id}    ${bridgename}
    [Documentation]    After Creating the trunk interface , checking for table 0 entry exist in the flow dumps
    switch connection    ${connection-id}
    log    switch connection
    ${ovs-check}    execute command    sudo ovs-ofctl -O OpenFlow13 dump-flows ${bridgename}
    log    sudo ovs-ofctl -O OpenFlow13 dump-flows ${bridgename}
    log    ${ovs-check}
    should contain    ${ovs-check}    table=0

ovs check for member interface creation
    [Arguments]    ${connection-id}    ${bridgename}
    [Documentation]    This keyword verifies the member interface created on OVS by checking the table0 ,vlan and action=pop_vlan entries
    switch connection    ${connection-id}
    ${ovs-check}    execute command    sudo ovs-ofctl -O OpenFlow13 dump-flows ${bridgename}
    log    ${ovs-check}
    should contain    ${ovs-check}    table=0
    should contain    ${ovs-check}    dl_vlan=1000
    should contain    ${ovs-check}    actions=pop_vlan

Create Interface
    [Arguments]    ${json_file}    ${interface_mode}
    [Documentation]    Creates an trunk/transparent interface based on input provided to the json body
    ${body}    OperatingSystem.Get File    ${genius_config_dir}/${json_file}
    log    ${genius_config_dir}/${json_file}
    ${body}    replace string    ${body}    "l2vlan-mode":"trunk"    "l2vlan-mode":"${interface_mode}"
    log    "l2vlan-mode":"${interface_mode}"
    log    ${body}
    ${post_resp}    RequestsLibrary.Post Request    session    ${CONFIG_API}/ietf-interfaces:interfaces/    data=${body}
    Log    ${post_resp.content}
    Log    ${post_resp.status_code}
    Should Be Equal As Strings    ${post_resp.status_code}    204
