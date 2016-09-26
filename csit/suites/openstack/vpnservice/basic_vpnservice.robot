*** Settings ***
Documentation     Test suite to validate vpnservice functionality in an openstack integrated environment.
...               The assumption of this suite is that the environment is already configured with the proper
...               integration bridges and vxlan tunnels.
Suite Setup       Basic Vpnservice Suite Setup
Suite Teardown    Basic Vpnservice Suite Teardown
Test Setup        Log Testcase Start To Controller Karaf
Library           SSHLibrary
Library           OperatingSystem
Library           RequestsLibrary
Library           Collections
Library           String

Resource          ../../../libraries/Utils.robot
Resource          ../../../libraries/OpenStackOperations.robot
Resource          ../../../libraries/DevstackUtils.robot
Variables         ../../../variables/Variables.py

*** Variables ***
@{NETWORKS}       NET10    NET20
@{SUBNETS}        SUBNET1    SUBNET2
@{SUBNET_CIDR}    10.1.1.0/24    20.1.1.0/24
@{PORT_LIST}      PORT11    PORT21    PORT12    PORT22
@{VM_INSTANCES}    VM11    VM21    VM12    VM22
@{ROUTERS}        ROUTER_1    ROUTER_2

${VPN_CONFIG_DIR}              ${CURDIR}/../../variables/vpnservice
${REST_CON}                    /restconf/config/
${REST_CON_OP}                 /restconf/operations/
${ITM_CREATE_JSON}             ../../../variables/genius/Itm_creation_no_vlan.json
${ITM_CREATE_STATUS_CODE}      200
${ACCEPT_XML}                  {'Accept': 'application/xml'}
${HEADERS}                     {'Content-Type': 'application/json'}
${bridge_ref_info_api}         /restconf/operational/odl-interface-meta:bridge-ref-info

${itm_prefix_def}          "1.1.1.1/24"
${itm_vlan-id_def}         0
${itm_dpn-id1_def}         1
${itm_portname1_def}       "BR1-eth1"
${itm_ip-address1_def}     "2.2.2.2"
${itm_dpn-id2_def}         2
${itm_portname2_def}       "BR2-eth1"
${itm_ip-address2_def}     "3.3.3.3"
${itm_gateway-ip_def}      "0.0.0.0"
${itm_tunnel-type_def}     vxlan
${itm_zone-name_def}       TZA

*** Test Cases ***
Verify Tunnel Creation
    [Documentation]    Checks that vxlan tunnels have been created properly.

    ${node_1_dpid}=    Get DPID For Compute Node    ${OS_COMPUTE_1_IP}
    ${node_2_dpid}=    Get DPID For Compute Node    ${OS_COMPUTE_2_IP}
    ${node_1_adapter}=    Get Ethernet Adapter From Compute Node    ${OS_COMPUTE_1_IP}
    ${node_2_adapter}=    Get Ethernet Adapter From Compute Node    ${OS_COMPUTE_2_IP}
    ${first_two_octets}    ${third_octet}    ${last_octet}=    Split String From Right    ${OS_COMPUTE_1_IP}    .    2
    ${subnet}=    Set Variable    ${first_two_octets}.0.0/16
    ${gateway}=    Get Default Gateway    ${OS_COMPUTE_1_IP}
    # Create tunnel using ODL CLI commands
    #Create TEP For Compute Node    ${OS_COMPUTE_1_IP}    ${node_1_dpid}    ${node_1_adapter}    ${subnet}    ${gateway}
    #Create TEP For Compute Node    ${OS_COMPUTE_2_IP}    ${node_2_dpid}    ${node_2_adapter}    ${subnet}    ${gateway}

    # Create tunnel using REST CALL
    # Variable for tunnel creation-ip-address1 dpn-id1  portname1  prefix  vlan-id  ip-address2  dpn-id2  portname2  gateway-ip  tunnel-type
    ITM Create Tunnel    tunnel-type=VXLAN    vlan-id=0    ip-address1=${OS_COMPUTE_1_IP}    dpn-id1=${node_1_dpid}
    ...    portname1=${node_1_adapter}    prefix=${subnet}    gateway-ip=${gateway}    ip-address2=${OS_COMPUTE_2_IP}
    ...    dpn-id2=${node_2_dpid}    portname2=${node_2_adapter}
    ${output} =    ITM Get Tunnels
    Log    ${output}

Delete Tunnel
    [Documentation]    Delete tunnels with TZA zone.
    ITM Delete Tunnel    TZA

*** Keywords ***
Basic Vpnservice Suite Setup
    Create Session    session    http://${ODL_SYSTEM_IP}:${RESTCONFPORT}    auth=${AUTH}    headers=${HEADERS}

Basic Vpnservice Suite Teardown
    Delete All Sessions

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
    ${adapter}=    Run Command On Remote System    ${ip}    /usr/sbin/ip addr show
    Log    ${adapter}
    ${adapter}=    Run Command On Remote System    ${ip}    /usr/sbin/ip addr show | grep ${ip} | cut -d " " -f 11
    [Return]    ${adapter}

Get Default Gateway
    [Arguments]    ${ip}
    [Documentation]    Returns the default gateway used by ${ip}
    ${gateway}=    Run Command On Remote System    ${ip}    /usr/sbin/route -n
    Log    ${gateway}
    ${gateway}=    Run Command On Remote System    ${ip}    /usr/sbin/route -n | grep '^0.0.0.0' | cut -d " " -f 10
    [Return]    ${gateway}

ITM Create Tunnel
    [Arguments]    &{Kwargs}
    [Documentation]    Create Tunnel
    @{KeysList}     Create List    prefix    vlan-id    dpn-id1    portname1    ip-address1
    ...    dpn-id2    portname2    ip-address2    gateway-ip    tunnel-type     zone-name
    ${json_body}    OperatingSystem.Get File    ${ITM_CREATE_JSON}
    Run Keyword If    ${Kwargs}    Log    ${Kwargs}
    Log    json_body:${json_body}
    ${prefix}    Run Keyword If     ${Kwargs} != None
    ...    Pop From Dictionary    ${Kwargs}    ${KeysList[0]}    default=${itm_prefix_def}
    ${json_body} =    Replace String    ${json_body}      prefix\"\:${itm_prefix_def}    prefix\"\:${prefix}
    ${vlan-id}    Run Keyword If     ${Kwargs} != None
    ...    Pop From Dictionary    ${Kwargs}    ${KeysList[1]}    default=${itm_vlan-id_def}
    ${json_body} =    Replace String    ${json_body}    vlan-id\"\:${itm_vlan-id_def}    vlan-id\"\:${vlan-id}
    ${dpn-id1}    Run Keyword If    ${Kwargs} != None
    ...    Pop From Dictionary    ${Kwargs}    ${KeysList[2]}    default=${itm_dpn-id1_def}
    ${json_body} =    Replace String    ${json_body}    dpn-id\"\:${itm_dpn-id1_def}      dpn-id\"\:${dpn-id1}
    ${portname1}    Run Keyword If    ${Kwargs} != None
    ...    Pop From Dictionary    ${Kwargs}    ${KeysList[3]}    default=${itm_portname1_def}
    ${json_body} =    Replace String    ${json_body}    portname\"\:${itm_portname1_def}    portname\"\:${portname1}
    ${ip-address1}    Run Keyword If    ${Kwargs} != None
    ...    Pop From Dictionary    ${Kwargs}    ${KeysList[4]}    default=${itm_ip-address1_def}
    ${json_body} =    Replace String    ${json_body}    ip-address\"\:${itm_ip-address1_def}    ip-address\"\:${ip-address1}
    ${dpn-id2}    Run Keyword If    ${Kwargs} != None
    ...    Pop From Dictionary    ${Kwargs}    ${KeysList[5]}    default=${itm_dpn-id2_def}
    ${json_body} =    Replace String    ${json_body}    dpn-id\"\:${itm_dpn-id2_def}      dpn-id\"\:${dpn-id2}
    ${portname2}    Run Keyword If    ${Kwargs} != None
    ...    Pop From Dictionary    ${Kwargs}    ${KeysList[6]}    default=${itm_portname2_def}
    ${json_body} =    Replace String    ${json_body}    portname\"\:${itm_portname2_def}    portname\"\:${portname2}
    ${ip-address2}    Run Keyword If    ${Kwargs} != None
    ...    Pop From Dictionary    ${Kwargs}    ${KeysList[7]}    default=${itm_ip-address2_def}
    ${json_body} =    Replace String    ${json_body}    ip-address\"\:${itm_ip-address2_def}    ip-address\"\:${ip-address2}
    ${gateway-ip}    Run Keyword If    ${Kwargs} != None
    ...    Pop From Dictionary    ${Kwargs}    ${KeysList[8]}    default=${itm_gateway-ip_def}
    ${json_body} =    Replace String    ${json_body}    gateway-ip\"\:${itm_gateway-ip_def}    gateway-ip\"\:${gateway-ip}
    ${tunnel-type}    Run Keyword If    ${Kwargs} != None
    ...    Pop From Dictionary    ${Kwargs}    ${KeysList[9]}    default=${itm_tunnel-type_def}
    ${json_body} =    Replace String    ${json_body}    \:tunnel-type-${itm_tunnel-type_def}
    ...    \:tunnel-type-${tunnel-type}
    ${zone-name}    Run Keyword If    ${Kwargs} != None
    ...    Pop From Dictionary    ${Kwargs}    ${KeysList[10]}    default=${itm_zone-name_def}
    ${json_body} =    Replace String    ${json_body}    \"zone-name\": \"${itm_zone-name_def}
    ...    \"zone-name\": \"${zone-name}

    Log    Final Json Body for ITM Create REST Call: ${json_body}
    ${resp}    RequestsLibrary.Post    session    ${REST_CON}/itm:transport-zones/    data=${body}
    Log    ${resp.content}
    Log    ${resp.status_code}
    Should Be Equal As Strings    ${resp.status_code}    200

ITM Get Tunnels
    [Arguments]
    [Documentation]    Get all Tunnels
    Log     "REST Call for Get ITM Tunnels
    ${resp}    RequestsLibrary.Get    session    ${REST_CON}itm:transport-zones/
    Log    ${resp.content}
    [Return]    ${resp.content}

ITM Delete Tunnel
    [Arguments]    ${zone-name}
    [Documentation]    Delete Tunnel
    Log    "REST Call for Delete Tunnel"
    ${resp}    RequestsLibrary.Delete    session    ${REST_CON}/itm:transport-zones/transport-zone/${zone-name}/
    Log    ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200
    [Return]    ${resp.content}

