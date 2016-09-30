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
Resource          ../../../libraries/Utils.robot
Resource          ../../../libraries/OpenStackOperations.robot
Resource          ../../../libraries/DevstackUtils.robot
Resource          ../../../libraries/VpnOperations.robot
Variables         ../../../variables/Variables.py

*** Variables ***
@{NETWORKS}       NET10    NET20
@{SUBNETS}        SUBNET1    SUBNET2
@{SUBNET_CIDR}    10.1.1.0/24    20.1.1.0/24
@{PORT_LIST}      PORT11    PORT21    PORT12    PORT22
@{VM_INSTANCES}    VM11    VM21    VM12    VM22
@{ROUTERS}        ROUTER_1    ROUTER_2
# Values passed by the calling method to API
${CREATE_ID}      "4ae8cd92-48ca-49b5-94e1-b2921a261111"
${CREATE_NAME}    "vpn2"
${CREATE_ROUTER_DISTINGUISHER}    ["2200:2"]
${CREATE_EXPORT_RT}    ["3300:2","8800:2"]
${CREATE_IMPORT_RT}    ["3300:2","8800:2"]
${CREATE_TENANT_ID}    "6c53df3a-3456-11e5-a151-feff819c1111"
@{VPN_INSTANCE}    vpn_instance_template.json
@{VPN_INSTANCE_NAME}    4ae8cd92-48ca-49b5-94e1-b2921a2661c7    4ae8cd92-48ca-49b5-94e1-b2921a261111

${ITM_CREATE_JSON}              ${CURDIR}/../../../variables/genius/Itm_creation_no_vlan.json
#${bridge_ref_info_api}         /restconf/operational/odl-interface-meta:bridge-ref-info

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
#Verify Tunnel Creation
#    [Documentation]    Checks that vxlan tunnels have been created properly.
#    ${node_1_dpid}=    Get DPID For Compute Node2    ${OS_COMPUTE_1_IP}
#    ${node_2_dpid}=    Get DPID For Compute Node2    ${OS_COMPUTE_2_IP}
#    ${node_1_adapter}=    Get Ethernet Adapter From Compute Node    ${OS_COMPUTE_1_IP}
#    ${node_2_adapter}=    Get Ethernet Adapter From Compute Node    ${OS_COMPUTE_2_IP}
#    ${first_two_octets}    ${third_octet}    ${last_octet}=    Split String From Right    ${OS_COMPUTE_1_IP}    .    2
#    ${subnet}=    Set Variable    ${first_two_octets}.0.0/16
#    ${gateway}=    Get Default Gateway    ${OS_COMPUTE_1_IP}
#    ITM Create Tunnel    tunnel-type=vxlan                   vlan-id=0
#    ...                  ip-address1="${OS_COMPUTE_1_IP}"    dpn-id1=${node_1_dpid}    portname1="${node_1_adapter}"
#    ...                  ip-address2="${OS_COMPUTE_2_IP}"    dpn-id2=${node_2_dpid}    portname2="${node_2_adapter}"
#    ...                  prefix="${subnet}"                  gateway-ip="${gateway}"


Verify Tunnel Creation With OSC
    [Documentation]    Checks that vxlan tunnels have been created properly.
    ${node_1_dpid}=    Get DPID For Compute Node2    ${OS_COMPUTE_1_IP}
    ${node_2_dpid}=    Get DPID For Compute Node2    ${OS_CONTROL_NODE_IP}
    ${node_1_adapter}=    Get Ethernet Adapter From Compute Node    ${OS_COMPUTE_1_IP}
    ${node_2_adapter}=    Get Ethernet Adapter From Compute Node    ${OS_CONTROL_NODE_IP}
    ${first_two_octets}    ${third_octet}    ${last_octet}=    Split String From Right    ${OS_COMPUTE_1_IP}    .    2
    ${subnet}=    Set Variable    ${first_two_octets}.0.0/16
    ${gateway}=    Get Default Gateway    ${OS_COMPUTE_1_IP}
    ITM Create Tunnel    tunnel-type=vxlan                   vlan-id=0
    ...                  ip-address1="${OS_COMPUTE_1_IP}"    dpn-id1=${node_1_dpid}    portname1="${node_1_adapter}"
    ...                  ip-address2="${OS_CONTROL_NODE_IP}"    dpn-id2=${node_2_dpid}    portname2="${node_2_adapter}"
    ...                  prefix="${subnet}"                  gateway-ip="${gateway}"

Get All Tunnels
    [Documentation]     This will return all tunnels created
    ${output}=    Run Command On Remote System     ${OS_COMPUTE_1_IP}     sudo ovs-vsctl show
    Log      ${output}
    ${output}=    Run Command On Remote System     ${OS_CONTROL_NODE_IP}     sudo ovs-vsctl show
    Log      ${output}

    ${output}=     ITM Get Tunnels 
    Log     ${output}
    

Delete Existing Tunnel
    [Documentation]    To delete if there is any tunnel
    ITM Delete Tunnel     TZA

##Verify Tunnel Creation
#    [Documentation]    Checks that vxlan tunnels have been created properly.
#    [Tags]    exclude
#    Log    This test case is currently a noop, but work can be added here to validate if needed.    However, as the    suite Documentation notes, it's already assumed that the environment has been configured properly.    If    we do add work in this test case, we need to remove the "exclude" tag for it to run.    In fact, if this
#    ...    test case is critical to run, and if it fails we would be dead in the water for the rest of the suite,    we should move it to Suite Setup so that nothing else will run and waste time in a broken environment.
#
#Create Neutron Networks
#    [Documentation]    Create two networks
#    Create Network    ${NETWORKS[0]}    --provider:network_type local
#    Create Network    ${NETWORKS[1]}    --provider:network_type local
#    ${NET_LIST}    List Networks
#    Log    ${NET_LIST}
#    Should Contain    ${NET_LIST}    ${NETWORKS[0]}
#    Should Contain    ${NET_LIST}    ${NETWORKS[1]}
#
#Create Neutron Subnets
#    [Documentation]    Create two subnets for previously created networks
#    Create SubNet    ${NETWORKS[0]}    ${SUBNETS[0]}    ${SUBNET_CIDR[0]}
#    Create SubNet    ${NETWORKS[1]}    ${SUBNETS[1]}    ${SUBNET_CIDR[1]}
#    ${SUB_LIST}    List Subnets
#    Log    ${SUB_LIST}
#    Should Contain    ${SUB_LIST}    ${SUBNETS[0]}
#    Should Contain    ${SUB_LIST}    ${SUBNETS[1]}
#
#Create Neutron Ports
#    [Documentation]    Create four ports under previously created subnets
#    Create Port    ${NETWORKS[0]}    ${PORT_LIST[0]}
#    Create Port    ${NETWORKS[0]}    ${PORT_LIST[1]}
#    Create Port    ${NETWORKS[1]}    ${PORT_LIST[2]}
#    Create Port    ${NETWORKS[1]}    ${PORT_LIST[3]}
#
#Check OpenDaylight Neutron Ports
#    [Documentation]    Checking OpenDaylight Neutron API for known ports
#    ${resp}    RequestsLibrary.Get Request    session    ${NEUTRON_PORTS_API}
#    Log    ${resp.content}
#    Should be Equal As Strings    ${resp.status_code}    200
#
#Create Nova VMs
#    [Documentation]    Create Vm instances on compute node with port
#    Create Vm Instance With Port On Compute Node    ${PORT_LIST[0]}    ${VM_INSTANCES[0]}    ${OS_COMPUTE_1_IP}
#    Create Vm Instance With Port On Compute Node    ${PORT_LIST[1]}    ${VM_INSTANCES[1]}    ${OS_COMPUTE_2_IP}
#    Create Vm Instance With Port On Compute Node    ${PORT_LIST[2]}    ${VM_INSTANCES[2]}    ${OS_COMPUTE_1_IP}
#    Create Vm Instance With Port On Compute Node    ${PORT_LIST[3]}    ${VM_INSTANCES[3]}    ${OS_COMPUTE_2_IP}
#
#Check ELAN Datapath Traffic Within The Networks
#    [Documentation]    Checks datapath within the same network with different vlans.
#    [Tags]    exclude
#    Log    This test will be added in the next patch
#
#Create Routers
#    [Documentation]    Create Router
#    Create Router    ${ROUTERS[0]}
#
#Add Interfaces To Router
#    [Documentation]    Add Interfaces
#    : FOR    ${INTERFACE}    IN    @{SUBNETS}
#    \    Add Router Interface    ${ROUTERS[0]}    ${INTERFACE}
#
#Check L3_Datapath Traffic Across Networks With Router
#    [Documentation]    Datapath Test Across the networks using Router for L3.
#    [Tags]    exclude
#    Log    This test will be added in the next patch
#
#Create L3VPN
#    [Documentation]    Creates L3VPN and verify the same
#    VPN Create L3VPN    ${VPN_INSTANCE[0]}    CREATE_ID=${CREATE_ID}    CREATE_EXPORT_RT=${CREATE_EXPORT_RT}    CREATE_IMPORT_RT=${CREATE_IMPORT_RT}    CREATE_TENANT_ID=${CREATE_TENANT_ID}
#    VPN Get L3VPN    ${CREATE_ID}
#
#Associate L3VPN to Routers
#    [Documentation]    Associating router to L3VPN
#    [Tags]    Associate
#    ${devstack_conn_id}=    Get ControlNode Connection
#    ${router_id}=    Get Router Id    ${ROUTERS[0]}    ${devstack_conn_id}
#    Associate VPN to Router    ${router_id}    ${VPN_INSTANCE_NAME[1]}
#
#Dissociate L3VPN to Routers
#    [Documentation]    Dissociating router to L3VPN
#    [Tags]    Dissociate
#    ${devstack_conn_id}=    Get ControlNode Connection
#    ${router_id}=    Get Router Id    ${ROUTERS[0]}    ${devstack_conn_id}
#    Dissociate VPN to Router    ${router_id}    ${VPN_INSTANCE_NAME[1]}
#
#Delete Router Interfaces
#    [Documentation]    Remove Interface to the subnets.
#    : FOR    ${INTERFACE}    IN    @{SUBNETS}
#    \    Remove Interface    ${ROUTERS[0]}    ${INTERFACE}
#
#Delete Routers
#    [Documentation]    Delete Router and Interface to the subnets.
#    Delete Router    ${ROUTERS[0]}
#
#Delete L3VPN
#    [Documentation]    Delete L3VPN
#    VPN Delete L3VPN    ${CREATE_ID}
#
#Check Datapath Traffic Across Networks With L3VPN
#    [Documentation]    Datapath Test Across the networks with VPN.
#    [Tags]    exclude
#    Log    This test will be added in the next patch
#
#Delete Vm Instances
#    [Documentation]    Delete Vm instances in the given Instance List
#    : FOR    ${VmInstance}    IN    @{VM_INSTANCES}
#    \    Delete Vm Instance    ${VmInstance}
#
#Delete Neutron Ports
#    [Documentation]    Delete Neutron Ports in the given Port List.
#    : FOR    ${Port}    IN    @{PORT_LIST}
#    \    Delete Port    ${Port}
#
#Delete Sub Networks
#    [Documentation]    Delete Sub Nets in the given Subnet List.
#    : FOR    ${Subnet}    IN    @{SUBNETS}
#    \    Delete SubNet    ${Subnet}
#
#Delete Networks
#    [Documentation]    Delete Networks in the given Net List
#    : FOR    ${Network}    IN    @{NETWORKS}
#    \    Delete Network    ${Network}
#
*** Keywords ***
Basic Vpnservice Suite Setup
    Create Session    session    http://${ODL_SYSTEM_IP}:${RESTCONFPORT}    auth=${AUTH}    headers=${HEADERS}

Basic Vpnservice Suite Teardown
    Delete All Sessions

#Get DPID For Compute Node
#    [Arguments]    ${ip}
#    [Documentation]    Returns the decimal form of the dpid of br-int as found in bridge-ref-info API
#    ...    that matches the ovs UUID for the given ${ip}
#    ${found_dpid}=    Set Variable    ${EMPTY}
#    ${uuid}=    Run Command On Remote System    ${ip}    sudo ovs-vsctl show | head -1
#    ${resp}=    RequestsLibrary.Get Request    session    ${bridge_ref_info_api}
#    Log    ${resp.content}
#    ${resp_json}=    To Json    ${resp.content}
#    ${bride_ref_info}=    Get From Dictionary    ${resp_json}    bridge-ref-info
#    ${bridge_list}=    Get From Dictionary    ${bride_ref_info}    bridge-ref-entry
#
#    : FOR    ${bridge}    IN    @{bridge_list}
#    \    ${ref}=    Get From Dictionary    ${bridge}    bridge-reference
#    \    ${dpid}=    Get From Dictionary    ${bridge}    dpid
#    \    ${found_dpid}=    Set Variable If    """${uuid}""" in """${ref}"""    ${dpid}    ${found_dpid}
#    [Return]    ${found_dpid}


Get DPID For Compute Node2
    [Arguments]    ${ip}
    [Documentation]    Returns the dpnid for the given ${ip}
    ${output}=    Run Command On Remote System    ${ip}    sudo ovs-ofctl show -O Openflow13 br-int | head -1 | awk -F "dpid:" '{print $2}'
    Log    ${output}
    ${dpnid}=    Convert To Integer   ${output}    16
    Log    ${dpnid}
    [Return]    ${dpnid}

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

ITM Delete Tunnel
    [Arguments]    ${zone-name}
    [Documentation]    Delete Tunnel
    ${resp}    RequestsLibrary.Delete Request   session    ${REST_CON}/itm:transport-zones/transport-zone/${zone-name}/
    Log    ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200
    [Return]    ${resp.content}

ITM Create Tunnel
    [Arguments]    &{Kwargs}
    [Documentation]    Create Tunnel
    @{KeysList}     Create List    prefix    vlan-id    dpn-id1    portname1    ip-address1
    ...    dpn-id2    portname2    ip-address2    gateway-ip    tunnel-type     zone-name
    Log      Arguments Received:${Kwargs}
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
    ${json_body} =    Replace String    ${json_body}    \"zone-name\":\"${itm_zone-name_def}
    ...    \"zone-name\":\"${zone-name}

    Log    Final Json Body for ITM Create REST Call: ${json_body}
    ${resp}    RequestsLibrary.Post Request    session    ${REST_CON}/itm:transport-zones/    data=${json_body}
    Log    ${resp.content}
    Log    ${resp.status_code}
    Should Be Equal As Strings    ${resp.status_code}    204

ITM Get Tunnels
    [Arguments]
    [Documentation]    Get all Tunnels
    ${resp}=    RequestsLibrary.Get Request    session    ${REST_CON}itm:transport-zones/
    Log    ${resp.content}
    [Return]    ${resp.content}

############# END OF FILE#################
