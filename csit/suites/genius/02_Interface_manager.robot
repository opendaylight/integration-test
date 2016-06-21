*** Settings ***
Documentation     Test Suite for Interface manager
Suite Setup       Create Session    session    http://${CONTROLLER}:${RESTCONFPORT}    auth=${AUTH}    headers=${HEADERS}
Suite Teardown    Delete All Sessions
Library           OperatingSystem
Library           String
Library           RequestsLibrary
Library           Collections
Library           re
Variables         ../../variables/Variables.py
Resource          ../../libraries/Utils.robot

*** Variables ***
${genius_config_dir}    ${CURDIR}/../../variables/genius

*** Test Cases ***
Create l2vlan trunk interface
    [Documentation]    This testcase creates a l2vlan trunk interface between 2 DPNs.
    Log    >>>> Getting file for posting json <<<<<<<
    ${body}    OperatingSystem.Get File    ${genius_config_dir}/l2vlan.json
    ${body}    replace string    ${body}    "l2vlan-mode":"trunk"    "l2vlan-mode":"trunk"
    ${post_resp}    RequestsLibrary.Post    session    ${CONFIG_API}/ietf-interfaces:interfaces/    data=${body}
    Log    ${post_resp.content}
    Log    ${post_resp.status_code}
    Should Be Equal As Strings    ${post_resp.status_code}    204
    Log    >>>> Get interface config <<<<<
    ${get_resp}    RequestsLibrary.Get    session    ${CONFIG_API}/ietf-interfaces:interfaces/    headers=${ACCEPT_XML}
    Log    ${get_resp.content}
    Log    ${get_resp.status_code}
    Should Be Equal As Strings    ${get_resp.status_code}    200
    @{l2vlan}    create list    l2vlan-trunk    l2vlan    trunk    tapab123    true
    : FOR    ${value}    IN    @{l2vlan}
    \    Should Contain    ${get_resp.content}    ${value}
    ${interface_name}    set variable    l2vlan-trunk
    Set Global Variable    ${interface_name}
    Log    >>>>> Get interface operational state<<<<
    ${get_oper_resp}    Wait Until Keyword Succeeds    10    5    get operational interface    ${interface_name}
    log    ${get_oper_resp}
    ${bridgename}    set variable    BR1
    Set Global Variable    ${bridgename}
    sleep    5
    switch connection    ${mininet1_conn_id_1}
    ${ovs-check}    execute command    sudo ovs-ofctl -O OpenFlow13 dump-flows ${bridgename}
    log    ${ovs-check}
    should contain    ${ovs-check}    table=0

Create l2vlan Trunk member interface
    [Documentation]    This testcase creates a l2vlan Trunk member interface for the l2vlan trunk interface created in 1st testcase.
    Log    >>>> Creating L2vlan member interface <<<<<
    Log    >>>> Getting file for posting json <<<<<<<
    ${body}    OperatingSystem.Get File    ${genius_config_dir}/l2vlan_member.json
    ${body}    replace string    ${body}    "l2vlan-mode":"trunk"    "l2vlan-mode":"trunk"
    ${post_resp}    RequestsLibrary.Post    session    ${CONFIG_API}/ietf-interfaces:interfaces/    data=${body}
    Log    ${post_resp.content}
    Log    ${post_resp.status_code}
    Should Be Equal As Strings    ${post_resp.status_code}    204
    Log    >>>> Get interface config <<<<<
    ${get_resp}    RequestsLibrary.Get    session    ${CONFIG_API}/ietf-interfaces:interfaces/    headers=${ACCEPT_XML}
    Log    ${get_resp.content}
    Log    ${get_resp.status_code}
    Should Be Equal As Strings    ${get_resp.status_code}    200
    @{l2vlan}    create list    l2vlan-trunk1    l2vlan    trunk-member    1000    l2vlan-trunk
    ...    true
    : FOR    ${value}    IN    @{l2vlan}
    \    Should Contain    ${get_resp.content}    ${value}
    Log    >>>>> Get interface operational state<<<<
    ${get_oper_resp}    Wait Until Keyword Succeeds    10    5    get operational interface    ${l2vlan[0]}
    log    ${get_oper_resp}
    sleep    5
    switch connection    ${mininet1_conn_id_1}
    ${ovs-check}    execute command    sudo ovs-ofctl -O OpenFlow13 dump-flows ${bridgename}
    log    ${ovs-check}
    should contain    ${ovs-check}    table=0
    should contain    ${ovs-check}    dl_vlan=1000
    should contain    ${ovs-check}    actions=pop_vlan

Bind service on Interface
    [Documentation]    This testcase binds service to the interface created .
    Log    >>>> Getting file for posting json <<<<<<<
    ${body}    OperatingSystem.Get File    ${genius_config_dir}/bind_service.json
    ${body}    replace string    ${body}    service1    VPN
    ${body}    replace string    ${body}    service2    elan
    log    ${body}
    ${post_resp}    RequestsLibrary.Post    session    ${CONFIG_API}/interface-service-bindings:service-bindings/services-info/${interface_name}/    data=${body}
    log    ${post_resp.content}
    log    ${post_resp.status_code}
    Should Be Equal As Strings    ${post_resp.status_code}    204
    Log    >>>>> Verifying Binded interface <<<<<
    ${get_resp}    RequestsLibrary.Get    session    ${CONFIG_API}/interface-service-bindings:service-bindings/services-info/${interface_name}/    headers=${ACCEPT_XML}
    log    ${get_resp.content}
    log    ${get_resp.status_code}
    should be equal as strings    ${get_resp.status_code}    200
    @{bind_array}    create list    2    3    VPN    elan    50
    ...    21
    : FOR    ${value}    IN    @{bind_array}
    \    should contain    ${get_resp.content}    ${value}
    sleep    5
    Log    >>>>> OVS check for table enteries <<<<
    ${command}    set variable    sudo ovs-ofctl -O OpenFlow13 dump-flows ${bridgename}
    ${Ovs-resp}    table entry    ${command}
    log    ${Ovs-resp}

unbind service on interface
    [Documentation]    This testcase Unbinds the service which is binded by the 3rd testcase.
    Log    >>>>>>Unbinding the service on interface <<<<
    ${interface_name}    set variable    l2vlan-trunk
    ${service-priority-1}    set variable    2
    ${service-priority-2}    set variable    3
    ${del_response_1}    RequestsLibrary.Delete    session    ${CONFIG_API}/interface-service-bindings:service-bindings/services-info/${interface_name}/bound-services/${service-priority-1}/
    log    ${del_response_1.content}
    log    ${del_response_1.status_code}
    should be equal as strings    ${del_response_1.status_code}    200
    ${get_resp1}    RequestsLibrary.Get    session    ${CONFIG_API}/interface-service-bindings:service-bindings/services-info/${interface_name}/bound-services/${service-priority-1}/    headers=${ACCEPT_XML}
    log    ${get_resp1}
    should be equal as strings    ${get_resp1.status_code}    404
    log    >>>> Ovs check for table 21 absence <<<
    ${table-id}    set variable    21
    ${no-table-21}    Wait Until Keyword Succeeds    6    2    no goto_table entry    ${table-id}
    log    ${no-table-21}
    ${del_response_2}    RequestsLibrary.Delete    session    ${CONFIG_API}/interface-service-bindings:service-bindings/services-info/${interface_name}/bound-services/${service-priority-2}/
    log    ${del_response_2.content}
    log    ${del_response_2.status_code}
    should be equal as strings    ${del_response_2.status_code}    200
    ${get_resp2}    RequestsLibrary.Get    session    ${CONFIG_API}/interface-service-bindings:service-bindings/services-info/${interface_name}/bound-services/${service-priority-2}/    headers=${ACCEPT_XML}
    log    ${get_resp2}
    should be equal as strings    ${get_resp2.status_code}    404
    log    >>>> Ovs check for table 50 absence <<<
    ${table-id}    set variable    50
    ${no-table-50}    Wait Until Keyword Succeeds    6    2    no goto_table entry    ${table-id}
    log    ${no-table-50}

Delete l2vlan trunk interface
    [Documentation]    Deletion of l2vlan trunk interface is done.
    ${del_resp}    RequestsLibrary.Delete    session    ${CONFIG_API}/ietf-interfaces:interfaces/
    Should Be Equal As Strings    ${del_resp.status_code}    200
    ${get_del_resp}    RequestsLibrary.Get    session    ${CONFIG_API}/ietf-interfaces:interfaces/    headers=${ACCEPT_XML}
    Log    ${get_del_resp.content}
    log    ${get_del_resp.status_code}
    Should Be Equal As Strings    ${get_del_resp.status_code}    404
    ${get_del_operresp}    RequestsLibrary.Get    session    ${OPERATIONAL_API}/ietf-interfaces:interfaces/    headers=${ACCEPT_XML}
    Log    ${get_del_operresp.content}
    log    ${get_del_operresp.status_code}
    Should Be Equal As Strings    ${get_del_operresp.status_code}    404
    ${resp}    Wait Until Keyword Succeeds    5    2    no table0 entry
    log    ${resp}

Create l2vlan transparent interface
    [Documentation]    This testcase creates a l2vlan transparent interface between 2 dpns.
    Log    >>>> Creating L2vlan interface <<<<<
    Log    >>>> Getting file for posting json <<<<<<<
    ${body}    OperatingSystem.Get File    ${genius_config_dir}/l2vlan.json
    ${body}    replace string    ${body}    "l2vlan-mode":"trunk"    "l2vlan-mode":"transparent"
    log    ${body}
    ${post_resp}    RequestsLibrary.Post    session    ${CONFIG_API}/ietf-interfaces:interfaces/    data=${body}
    Log    ${post_resp.content}
    Log    ${post_resp.status_code}
    Should Be Equal As Strings    ${post_resp.status_code}    204
    Log    >>>> Get interface config <<<<<
    ${get_resp}    RequestsLibrary.Get    session    ${CONFIG_API}/ietf-interfaces:interfaces/    headers=${ACCEPT_XML}
    Log    ${get_resp.content}
    Log    ${get_resp.status_code}
    Should Be Equal As Strings    ${get_resp.status_code}    200
    @{l2vlan}    create list    l2vlan-trunk    l2vlan    transparent    l2vlan    true
    : FOR    ${value}    IN    @{l2vlan}
    \    Should Contain    ${get_resp.content}    ${value}
    Log    >>>>> Get interface operational state<<<<
    ${get_oper_resp}    Wait Until Keyword Succeeds    10    5    get operational interface    ${interface_name}
    log    ${get_oper_resp}
    sleep    5
    switch connection    ${mininet1_conn_id_1}
    ${ovs-check}    execute command    sudo ovs-ofctl -O OpenFlow13 dump-flows ${bridgename}
    log    ${ovs-check}
    should contain    ${ovs-check}    table=0

Delete l2vlan transparent interface
    [Documentation]    This testcase deletes the l2vlan transparent interface created between 2 dpns.
    ${del_resp}    RequestsLibrary.Delete    session    ${CONFIG_API}/ietf-interfaces:interfaces/
    Should Be Equal As Strings    ${del_resp.status_code}    200
    ${get_del_resp}    RequestsLibrary.Get    session    ${CONFIG_API}/ietf-interfaces:interfaces/    headers=${ACCEPT_XML}
    Log    ${get_del_resp.content}
    log    ${get_del_resp.status_code}
    Should Be Equal As Strings    ${get_del_resp.status_code}    404
    ${get_del_operresp}    RequestsLibrary.Get    session    ${OPERATIONAL_API}/ietf-interfaces:interfaces/    headers=${ACCEPT_XML}
    Log    ${get_del_operresp.content}
    log    ${get_del_operresp.status_code}
    Should Be Equal As Strings    ${get_del_operresp.status_code}    404
    ${resp}    Wait Until Keyword Succeeds    5    2    no table0 entry
    log    ${resp}

*** Keywords ***
get operational interface
    [Arguments]    ${interface_name}
    [Documentation]    checks operational status of the interface.
    ${get_oper_resp}    RequestsLibrary.Get    session    ${OPERATIONAL_API}/ietf-interfaces:interfaces-state/interface/${interface_name}/    headers=${ACCEPT_XML}
    log    ${get_oper_resp.content}
    log    ${get_oper_resp.status_code}
    Should Be Equal As Strings    ${get_oper_resp.status_code}    200
    Should not contain    ${get_oper_resp.content}    down
    Should Contain    ${get_oper_resp.content}    up    up
    [Return]    ${get_oper_resp.content}

table entry
    [Arguments]    ${command}
    [Documentation]    Checks for tables entry wrt the service the Interface is binded.
    switch connection    ${mininet1_conn_id_1}
    ${result}    execute command    ${command}
    log    ${result}
    should contain    ${result}    table=17
    should contain    ${result}    goto_table:21
    should contain    ${result}    goto_table:50
    [Return]    ${result}

no table0 entry
    [Documentation]    after Deleting trunk interface , checking for absence of table 0 in the flow dumps
    switch connection    ${mininet1_conn_id_1}
    ${bridgename}    set variable    BR1
    ${ovs-check}    execute command    sudo ovs-ofctl -O OpenFlow13 dump-flows ${bridgename}
    log    ${ovs-check}
    should not contain    ${ovs-check}    table=0
    [Return]    ${ovs-check}

no goto_table entry
    [Arguments]    ${table-id}
    [Documentation]    cchecks for absence of no goto_table afetr unbinding the service on the interface.
    switch connection    ${mininet1_conn_id_1}
    ${ovs-check1}    execute command    sudo ovs-ofctl -O OpenFlow13 dump-flows ${bridgename}
    should not contain    ${ovs-check1}    goto_table:${table-id}
