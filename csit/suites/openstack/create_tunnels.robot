*** Settings ***
Documentation     Initial test case to setup vxlan tunnels as required for netvirt-vpnservice.  It is assumed
...    that the test environment is already deployed and ready.
Library           SSHLibrary
Library           RequestsLibrary
Resource          ../../libraries/KarafKeywords.robot
Resource          ../../libraries/Utils.robot
Variables         ../../variables/Variables.py

*** Variables ***
${bridge_ref_info_api}    /restconf/operational/odl-interface-meta:bridge-ref-info

*** Test Cases ***
Create Vxlan Tunnels
    # TODO: in case of multiple control nodes, we can put that in a loop, but for now the only
    # job we have uses two nodes.
    ${control_node_dpid}=    Get DPID For Compute Node    ${OS_CONTROL_NODE_IP}
    ${node_1_dpid}=    Get DPID For Compute Node    ${OS_COMPUTE_1_IP}
    ${node_2_dpid}=    Get DPID For Compute Node    ${OS_COMPUTE_2_IP}
    ${control_node_adapter}=    Get Ethernet Adapter From Compute Node    ${OS_CONTROL_NODE_IP}
    ${node_1_adapter}=    Get Ethernet Adapter From Compute Node    ${OS_COMPUTE_1_IP}
    ${node_2_adapter}=    Get Ethernet Adapter From Compute Node    ${OS_COMPUTE_2_IP}
    ${first_three_octets}    ${last_octet}=    Split String From Right    ${OS_COMPUTE_1_IP}    .    1
    ${subnet}=    Set Variable    ${first_three_octets}.0/24
    ${gateway}=    Get Default Gateway    ${OS_COMPUTE_1_IP}
    Create TEP For Compute Node    ${OS_CONTROL_NODE_IP}    ${control_node_dpid}    ${control_node_adapter}    ${subnet}    ${gateway}
    Create TEP For Compute Node    ${OS_COMPUTE_1_IP}    ${node_1_dpid}    ${node_1_adapter}    ${subnet}    ${gateway}
    Create TEP For Compute Node    ${OS_COMPUTE_2_IP}    ${node_2_dpid}    ${node_2_adapter}    ${subnet}    ${gateway}

*** Keywords ***
Get DPID For Compute Node
    [Arguments]    ${ip}
    [Documentation]    Returns the decimal form of the dpid of br-int as found in bridge-ref-info API
    ...    that matches the ovs UUID for the given ${ip}
    ${found_dpid}=    Set Variable    ${EMPTY}
    Create Session    odl_session    http://${ODL_SYSTEM_IP}:${RESTCONFPORT}    auth=${AUTH}    headers=${HEADERS}
    ${uuid}=    Run Command On Remote System    ${ip}    sudo ovs-vsctl show | head -1
    ${resp}=    RequestsLibrary.Get Request    odl_session    ${bridge_ref_info_api}
    Log    ${resp.content}
    ${resp_json}=    To Json    ${resp.content}
    ${bride_ref_info}=    Get From Dictionary    ${resp_json}    bridge-ref-info
    ${bridge_list}=    Get From Dictionary    ${bride_ref_info}    bridge-ref-entry
    : FOR    ${bridge}    IN    @{bridge_list}
    \    ${ref}=    Get From Dictionary    ${bridge}    bridge-reference
    \    ${dpid}=    Get From Dictionary    ${bridge}    dpid
    \    ${found_dpid}=    Set Variable If    """${uuid}""" in """${ref}"""    ${dpid}    ${found_dpid}
    [Return]    ${found_dpid}

Get Ethernet Adapter From Compute Node
    [Arguments]    ${ip}
    [Documentation]    Returns the adapter name on the system for the provided ${ip}
    ${adapter}=    Run Command On Remote System    ${ip}    ip addr show | grep ${ip} | cut -d " " -f 11
    [Return]    ${adapter}

Get Default Gateway
    [Arguments]    ${ip}
    [Documentation]    Returns the default gateway used by ${ip}
    ${gateway}=    Run Command On Remote System    ${ip}    route -n | grep '^0.0.0.0' | cut -d " " -f 10
    [Return]    ${gateway}

Create TEP For Compute Node
    [Arguments]    ${ip}    ${dpid}    ${adapter}    ${subnet}    ${gateway}
    [Documentation]    Uses tep:add karaf console command to create tep for given values
    Issue Command On Karaf Console    tep:add ${dpid} ${adapter} 0 ${ip} ${subnet} ${gateway} TZA
