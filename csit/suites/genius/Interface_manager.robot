*** Settings ***
Documentation     Test Suite for Interface manager
Suite Setup       Genius Suite Setup
Suite Teardown    Genius Suite Teardown
Test Setup        Genius Test Setup
Test Teardown     Genius Test Teardown    ${data_models}
Library           Collections
Library           OperatingSystem
Library           RequestsLibrary
Library           String
Resource          ../../libraries/DataModels.robot
Resource          ../../libraries/Genius.robot
Resource          ../../libraries/Utils.robot
Resource          ../../variables/Variables.robot
Variables         ../../variables/genius/Modules.py

*** Variables ***
${interface_name}    l2vlan-trunk
${trunk_json}     l2vlan.json
${trunk_member_json}    l2vlan_member.json

*** Test Cases ***
Create l2vlan transparent interface
    [Documentation]    This testcase creates a l2vlan transparent interface between 2 dpns.
    Create Interface    ${trunk_json}    transparent
    @{l2vlan} =    BuiltIn.Create List    l2vlan-trunk    l2vlan    transparent    l2vlan    true
    Utils.Check For Elements At URI    ${CONFIG_API}/ietf-interfaces:interfaces/    ${l2vlan}
    BuiltIn.Wait Until Keyword Succeeds    50    5    get operational interface    ${interface_name}
    BuiltIn.Wait Until Keyword Succeeds    40    10    table0 entry    ${TOOLS_SYSTEM_1_IP}

Delete l2vlan transparent interface
    [Documentation]    This testcase deletes the l2vlan transparent interface created between 2 dpns.
    Utils.Remove All Elements At URI And Verify    ${CONFIG_API}/ietf-interfaces:interfaces/
    Utils.No Content From URI    session    ${OPERATIONAL_API}/ietf-interfaces:interfaces/
    BuiltIn.Wait Until Keyword Succeeds    30    10    no table0 entry

Create l2vlan trunk interface
    [Documentation]    This testcase creates a l2vlan trunk interface between 2 DPNs.
    Create Interface    ${trunk_json}    trunk
    @{l2vlan} =    BuiltIn.Create list    l2vlan-trunk    l2vlan    trunk    tap0ed70586-6c    true
    Utils.Check For Elements At URI    ${CONFIG_API}/ietf-interfaces:interfaces/    ${l2vlan}
    BuiltIn.Wait Until Keyword Succeeds    50    5    get operational interface    ${interface_name}
    BuiltIn.Wait Until Keyword Succeeds    30    10    table0 entry    ${TOOLS_SYSTEM_1_IP}

Create l2vlan Trunk member interface
    [Documentation]    This testcase creates a l2vlan Trunk member interface for the l2vlan trunk interface created in 1st testcase.
    ${body} =    OperatingSystem.Get File    ${genius_config_dir}/l2vlan_member.json
    ${post_resp} =    RequestsLibrary.Post Request    session    ${CONFIG_API}/ietf-interfaces:interfaces/    data=${body}
    BuiltIn.Should Be Equal As Strings    ${post_resp.status_code}    204
    @{l2vlan} =    create list    l2vlan-trunk1    l2vlan    trunk-member    1000    l2vlan-trunk
    ...    true
    Utils.Check For Elements At URI    ${CONFIG_API}/ietf-interfaces:interfaces/    ${l2vlan}
    BuiltIn.Wait Until Keyword Succeeds    10    5    get operational interface    ${l2vlan[0]}
    BuiltIn.Wait Until Keyword Succeeds    40    10    ovs check for member interface creation    ${TOOLS_SYSTEM_1_IP}

Bind service on Interface
    [Documentation]    This testcase binds service to the interface created .
    ${body} =    OperatingSystem.Get File    ${genius_config_dir}/bind_service.json
    ${body} =    String.Replace string    ${body}    service1    VPN
    ${body} =    String.Replace string    ${body}    service2    elan
    BuiltIn.Log    ${body}
    ${service_mode} =    BuiltIn.Set Variable    interface-service-bindings:service-mode-ingress
    ${post_resp} =    RequestsLibrary.Post Request    session    ${CONFIG_API}/interface-service-bindings:service-bindings/services-info/${interface_name}/${service_mode}/    data=${body}
    BuiltIn.Should Be Equal As Strings    ${post_resp.status_code}    204
    @{bind_array} =    BuiltIn.Create List    2    3    VPN    elan    50
    ...    21
    Utils.Check For Elements At URI    ${CONFIG_API}/interface-service-bindings:service-bindings/services-info/${interface_name}/${service_mode}/    ${bind_array}
    BuiltIn.Wait Until Keyword Succeeds    40    10    table entry

unbind service on interface
    [Documentation]    This testcase Unbinds the service which is binded by the 3rd testcase.
    ${service-priority-1} =    BuiltIn.Set Variable    3
    ${service-priority-2} =    BuiltIn.Set Variable    4
    ${service_mode} =    BuiltIn.Set Variable    interface-service-bindings:service-mode-ingress
    Utils.Remove All Elements At URI And Verify    ${CONFIG_API}/interface-service-bindings:service-bindings/services-info/${interface_name}/${service_mode}/bound-services/${service-priority-1}/
    ${table-id} =    BuiltIn.Set Variable    21
    BuiltIn.Wait Until Keyword Succeeds    10    2    no goto_table entry    ${table-id}
    Utils.Remove All Elements At URI And Verify    ${CONFIG_API}/interface-service-bindings:service-bindings/services-info/${interface_name}/${service_mode}/bound-services/${service-priority-2}/
    Utils.No Content From URI    session    ${CONFIG_API}/interface-service-bindings:service-bindings/services-info/${interface_name}/${service_mode}/bound-services/${service-priority-2}/
    ${table-id} =    BuiltIn.Set Variable    50
    BuiltIn.Wait Until Keyword Succeeds    10    2    no goto_table entry    ${table-id}

Delete l2vlan trunk interface
    [Documentation]    Deletion of l2vlan trunk interface is done.
    Utils.Remove All Elements At URI And Verify    ${CONFIG_API}/ietf-interfaces:interfaces/
    Utils.No Content From URI    session    ${OPERATIONAL_API}/ietf-interfaces:interfaces/
    BuiltIn.Wait Until Keyword Succeeds    30    10    no table0 entry

*** Keywords ***
get operational interface
    [Arguments]    ${interface_name}
    [Documentation]    checks operational status of the interface.
    ${get_oper_resp} =    RequestsLibrary.Get Request    session    ${OPERATIONAL_API}/ietf-interfaces:interfaces-state/interface/${interface_name}/
    ${respjson} =    RequestsLibrary.To Json    ${get_oper_resp.content}    pretty_print=True
    BuiltIn.Log    ${respjson}
    BuiltIn.Should Be Equal As Strings    ${get_oper_resp.status_code}    200
    BuiltIn.Should not contain    ${get_oper_resp.content}    down
    BuiltIn.Should Contain    ${get_oper_resp.content}    up    up

table entry
    [Documentation]    Checks for tables entry wrt the service the Interface is binded.
    ${result} =    Utils.Run Command On Remote System    ${TOOLS_SYSTEM_1_IP}    sudo ovs-ofctl -O OpenFlow13 dump-flows ${Bridge}
    BuiltIn.Should Contain    ${result}    table=17
    BuiltIn.Should Contain    ${result}    goto_table:21
    BuiltIn.Should Contain    ${result}    goto_table:50

no table0 entry
    [Documentation]    After Deleting trunk interface, checking for absence of table 0 in the flow dumps
    ${ovs-check} =    Utils.Run Command On Remote System    ${TOOLS_SYSTEM_1_IP}    sudo ovs-ofctl -O OpenFlow13 dump-flows ${Bridge}
    BuiltIn.Should Not Contain    ${ovs-check}    table=0
    BuiltIn.Should Not Contain    ${ovs-check}    goto_table:17

no goto_table entry
    [Arguments]    ${table-id}
    [Documentation]    Checks for absence of no goto_table after unbinding the service on the interface.
    ${ovs-check1} =    Utils.Run Command On Remote System    ${TOOLS_SYSTEM_1_IP}    sudo ovs-ofctl -O OpenFlow13 dump-flows ${Bridge}
    BuiltIn.Should Not Contain    ${ovs-check1}    goto_table:${table-id}

table0 entry
    [Arguments]    ${tools_ip}
    [Documentation]    After Creating the trunk interface , checking for table 0 entry exist in the flow dumps
    ${ovs-check} =    Utils.Run Command On Remote System    ${tools_ip}    sudo ovs-ofctl -O OpenFlow13 dump-flows ${Bridge}
    BuiltIn.Should Contain    ${ovs-check}    table=0

ovs check for member interface creation
    [Arguments]    ${tools_ip}
    [Documentation]    This keyword verifies the member interface created on OVS by checking the table0 ,vlan and action=pop_vlan entries
    ${ovs-check} =    Utils.Run Command On Remote System    ${tools_ip}    sudo ovs-ofctl -O OpenFlow13 dump-flows ${Bridge}
    BuiltIn.Should Contain    ${ovs-check}    table=0
    BuiltIn.Should Contain    ${ovs-check}    dl_vlan=1000
    BuiltIn.Should Contain    ${ovs-check}    actions=pop_vlan

Create Interface
    [Arguments]    ${json_file}    ${interface_mode}
    [Documentation]    Creates an trunk/transparent interface based on input provided to the json body
    ${body} =    OperatingSystem.Get File    ${genius_config_dir}/${json_file}
    ${body} =    String.Replace String    ${body}    "l2vlan-mode":"trunk"    "l2vlan-mode":"${interface_mode}"
    ${post_resp} =    RequestsLibrary.Post Request    session    ${CONFIG_API}/ietf-interfaces:interfaces/    data=${body}
    BuiltIn.Should Be Equal As Strings    ${post_resp.status_code}    204
