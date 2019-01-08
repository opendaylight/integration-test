*** Settings ***
Documentation     This test suite is to verify working of OF based Tunnels
Suite Setup       OF Tunnels Start Suite
Suite Teardown    OF Tunnels Stop Suite
Test Setup        Genius Test Setup
Test Teardown     Genius Test Teardown    ${data_models}
Library           OperatingSystem
Library           SSHLibrary
Library           String
Library           RequestsLibrary
Library           Collections
Library           re
Resource          ../../libraries/ClusterManagement.robot
Resource          ../../libraries/DataModels.robot
Resource          ../../libraries/Genius.robot
Resource          ../../libraries/KarafKeywords.robot
Resource          ../../libraries/ODLTools.robot
Resource          ../../libraries/OVSDB.robot
Resource          ../../libraries/Utils.robot
Resource          ../../libraries/VpnOperations.robot
Resource          ../../variables/Variables.robot
Resource          ../../variables/netvirt/Variables.robot
Variables         ../../variables/genius/Modules.py

*** Variables ***
${ovs_oftif_regex}    SEPARATOR=    Interface\\s\\"(tun\\w+)\\"\\r?\\n    \\s+type\\:\\s(\\w+)\\r?\\n    \\s+options\\:\\s\\{key\\=flow\\,\\slocal_ip\\=\\"(${REGEX_IPV4})\\"\\,\\sremote_ip\\=flow\\}

*** Test Cases ***
Create TZ with OFT TEPs
    [Documentation]    Creates a TZ with TEPs set to use OF based Tunnels and verify
    Genius.Create Vteps    ${NO_VLAN}    ${gateway_ip}
    OFT Verify Vteps Created

Delete TZ with OFT TEPs
    [Documentation]    Deletes a TZ with TEPs set to use OF based Tunnels and verify
    ${ovs_tunnel_list} =    OFT Ovs Interface Verification
    : FOR    ${dpn_id}    IN    @{DPN_ID_LIST}
    \    Utils.Remove All Elements At URI And Verify    ${CONFIG_API}/itm:transport-zones/transport-zone/${itm_created[0]}/subnets/${SUBNET}%2F16/vteps/${dpn_id}/${port_name}
    Remove All Elements At URI And Verify    ${CONFIG_API}/itm:transport-zones/transport-zone/${itm_created[0]}/
    ${output} =    KarafKeywords.Issue Command On Karaf Console    ${TEP_SHOW}
    BuiltIn.Should Not Contain    ${output}    ${itm_created[0]}
    Wait Until Keyword Succeeds    40    10    OFT Ovs Verify Tunnel Deleted
    Wait Until Keyword Succeeds    40    10    OFT Ovs Verify Ingress Flows Deleted
    Comment    TODO: Add Check for Table 95

Create TZ with single OFT TEPs
    [Documentation]    Creates a TZ with single TEPs set to use OF based Tunnels and verify
    ${dpn_ids} =    BuiltIn.CreateList    @{DPN_ID_LIST}
    Collections.Set List Value    ${dpn_ids}    -1    ${EMPTY}
    ${tools_ips} =    BuiltIn.Create List    @{TOOLS_SYSTEM_ALL_IPS}
    Collections.Set List Value    ${tools_ips}    -1    ${EMPTY}
    Genius.Create Vteps    ${NO_VLAN}    ${gateway_ip}    ${tools_ips}
    OFT Verify Vteps Created    ${dpn_ids}    ${tools_ips}
    Genius.Create Vteps    ${NO_VLAN}    ${gateway_ip}
    OFT Verify Vteps Created

Delete TZ with single OFT TEPs
    [Documentation]    Delete a TZ with single TEPs set to use OF based Tunnels and verify
    ${ovs_tunnel_list} =    OFT Ovs Interface Verification
    ${tunnel} =    Set Variable    @{tunnel_list}[0]
    ${dpn_id} =    Set Variable    @{DPN_ID_LIST}[0]
    ${tools_ip} =    Set Variable    @{TOOLS_SYSTEM_ALL_IPS}[0]
    Utils.Remove All Elements At URI And Verify    ${CONFIG_API}/itm:transport-zones/transport-zone/${itm_created[0]}/subnets/${SUBNET}%2F16/vteps/${dpn_id}/${port_name}
    ${output} =    KarafKeywords.Issue Command On Karaf Console    ${TEP_SHOW}
    BuiltIn.Should Not Contain    ${output}    ${tools_ip}
    Wait Until Keyword Succeeds    40    10    OFT Ovs Verify Tunnel Deleted In Switch    ${tools_ip}    ${tunnel}
    ${other_tools_ips} =    BuiltIn.CreateList    @{TOOLS_SYSTEM_ALL_IPS}
    Collections.Remove Values From List    ${other_tools_ips}    ${tools_ip}
    Wait Until Keyword Succeeds    40    10    OFT Ovs Verify Ingress Flows Deleted In Switch    ${tools_ip}    ${other_tools_ips}
    Comment    TODO: Add Check for Table 95

*** Keywords ***
OFT Verify Vteps Created
    [Arguments]    ${dpn_ids}=${DPN_ID_LIST}    ${tools_ips}=${TOOLS_SYSTEM_ALL_IPS}
    [Documentation]    Verifies if OFT Vteps are created successfully or not. Takes sparse lists as arguments.
    ${num_switches} =    Set Variable    ${0}
    : FOR    ${tools_ip}    IN    @{tools_ips}
    \    Continue For Loop If    '${tools_ip}'=='${EMPTY}'
    \    ${num_switches} =    Set Variable    ${num_switches+1}
    Should Be True    ${num_switches} > 1
    ${extra_data} =    Collections.Combine Lists    ${dpn_ids}    ${tools_ips}
    Wait Until Keyword Succeeds    40    10    Genius.Get ITM    ${itm_created[0]}    ${SUBNET}    ${NO_VLAN}
    ...    ${extra_data}
    ${type} =    BuiltIn.Set Variable    odl-interface:tunnel-type-vxlan
    Genius.Update Dpn id list and get tunnels    ${type}    dpn-teps-state    ${dpn_ids}
    Genius.Verify Response Code Of Dpn End Point Config API    ${dpn_ids}
    Wait Until Keyword Succeeds    40    10    OFT Ovs Interface Verification    ${tools_ips}
    ${resp} =    RequestsLibrary.Get Request    session    ${OPERATIONAL_API}/itm-state:tunnels_state/
    Should Be Equal As Strings    ${resp.status_code}    200
    Wait Until Keyword Succeeds    60    5    Verify Tunnel Status As Up    ${num_switches}
    Wait Until Keyword Succeeds    40    10    Genius.Verify Table0 Entry After fetching Port Number    oft_enabled=true    ${tools_ips}
    Comment    TODO: Add Check for Table 95

OFT Ovs Verify Ingress Flows Deleted In Switch
    [Arguments]    ${tools_ip}    ${other_tools_ips}
    ${output} =    Utils.Run Command On Remote System And Log    ${tools_ip}    sudo ovs-ofctl -OOpenFlow13 dump-flows ${Bridge} table=0
    : FOR    ${other_tools_ip}    IN    @{other_tools_ips}
    \    BuiltIn.Should Not Contain    ${output}    tun_src=${other_tools_ip}
    \    ${output2} =    Utils.Run Command On Remote System And Log    ${other_tools_ip}    sudo ovs-ofctl -OOpenFlow13 dump-flows ${Bridge} table=0
    \    BuiltIn.Should Not Contain    ${output2}    tun_src=${tools_ip}

OFT Ovs Verify Ingress Flows Deleted
    [Arguments]    ${tools_ips}=${TOOLS_SYSTEM_ALL_IPS}
    : FOR    ${tools_ip}    IN    @{tools_ips}
    \    ${other_tools_ips} =    BuiltIn.CreateList    @{tools_ips}
    \    Collections.Remove Values From List    ${other_tools_ips}    ${tools_ip}
    \    OFT Ovs Verify Flow Deleted Per Tools IP    ${tools_ip}    ${other_tools_ips}

OFT Ovs Verify Tunnel Deleted In Switch
    [Arguments]    ${tools_ip}    ${tunnel}
    ${output} =    Utils.Run Command On Remote System    ${tools_ip}    sudo ovs-vsctl show
    BuiltIn.Should Not Contain    ${output}    ${tunnel}

OFT Ovs Verify Tunnel Deleted
    [Arguments]    ${tools_ips}=${TOOLS_SYSTEM_ALL_IPS}    ${ovs_tunnel_list}
    ${len} =    BuiltIn.Get Length    ${tools_ips}
    : FOR    ${tool_system_index}    IN RANGE    ${len}
    \    Continue For Loop If    '@{tools_ips}[${tool_system_index}]'=='${EMPTY}'
    \    OFT Ovs Verify Tunnel Deleted In Switch    @{tools_ips}[${tool_system_index}]    @{ovs_tunnel_list}[${tool_system_index}]

OFT Ovs Interface Verification
    [Arguments]    ${tools_ips}=${TOOLS_SYSTEM_ALL_IPS}
    [Documentation]    Checks whether the created OF based tunnel Interface is seen on OVS and verifies vxlan.
    ${tunnel_list} =    BuiltIn.Create List
    : FOR    ${tools_ip}    IN    @{tools_ips}
    \    BuiltIn.Run Command If    '${tools_ip}'=='${EMPTY}'    Collections.Append To List    ${ovs_tunnels}    ${EMPTY}
    \    Continue For Loop If    '${tools_ip}'=='${EMPTY}'
    \    ${ovs_output} =    Utils.Run Command On Remote System And Log    ${tools_ip}    sudo ovs-vsctl show
    \    ${result} =    BuiltIn.Should Match Regexp    ${ovs_output}    ${ovs_oftif_regex}
    \    BuiltIn.Log    ${result}
    \    BuiltIn.Length Should Be    ${result}    4
    \    Collections.Append To List    ${ovs_tunnels}    @{result}[1]
    \    BuiltIn.Should Be Equal    @{result}[2]    vxlan
    \    BuiltIn.Should Be Equal    @{result}[3]    ${tools_ip}
    [Return]    ${tunnel_list}
