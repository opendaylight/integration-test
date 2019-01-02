*** Settings ***
Documentation     Test suite for OpenFlow punt path protection for subnet route, SNAT, ARP and GARP
Suite Setup       Suite Setup
Suite Teardown    OpenStackOperations.OpenStack Suite Teardown
Test Setup        SetupUtils.Setup_Test_With_Logging_And_Without_Fast_Failing
Test Teardown     OpenStackOperations.Get Test Teardown Debugs
Resource          ../../../libraries/ClusterManagement.robot
Resource          ../../../libraries/OpenStackOperations.robot
Resource          ../../../libraries/OVSDB.robot
Resource          ../../../libraries/Utils.robot
Resource          ../../../libraries/VpnOperations.robot
Resource          ../../../variables/Variables.robot
Resource          ../../../variables/netvirt/Variables.robot

*** Variables ***
@{NETWORKS}       of_punt_net_1    of_punt_net_2    of_punt_net_3
${EXT_NETWORKS}    of_punt_ext_net_1
@{PORT_LIST}      of_punt_net1_port_1    of_punt_net1_port_2    of_punt_net2_port_1    of_punt_net2_port_2    of_punt_net3_port_1    of_punt_net3_port_2
@{EXTRA_PORTS}    of_punt_net_1_port_3    of_punt_net_2_port_3
@{EXTRA_VMS}      of_punt_net_1_vm_3    of_punt_net_2_vm_3
@{EXTRA_NW_IP}    11.1.1.100    22.1.1.100    12.1.1.12    13.1.1.13
@{VM_LIST}        of_punt_net1_vm_1    of_punt_net1_vm_2    of_punt_net2_vm_1    of_punt_net2_vm_2    of_punt_net3_vm_1    of_punt_net3_vm_2
@{SUBNETS}        of_punt_sub_1    of_punt_sub_2    of_punt_sub_3
${EXT_SUBNETS}    of_punt_ext_sub_1
@{SUBNETS_CIDR}    11.1.1.0/24    22.1.1.0/24    33.1.1.0/24
${EXT_SUBNETS_CIDR}    55.1.1.0/24
${EXT_SUBNETS_FIXED_IP}    55.1.1.100
@{VPN_ID}         4ae8cd92-48ca-49b5-94e1-b2921a261111    4ae8cd92-48ca-49b5-94e1-b2921a262222
@{VPN_NAME}       of_punt_vpn_1    of_punt_vpn_2
@{ROUTERS}        of_punt_router_1    of_punt_router_2
@{ROUTERS_ID}     @{EMPTY}
@{DPN_IDS}        @{EMPTY}
${SECURITY_GROUP}    of_punt_sg
@{DCGW_RD_IRT_ERT}    11:1    22:1
@{L3VPN_RD_IRT_ERT}    ["@{DCGW_RD_IRT_ERT}[0]"]    ["@{DCGW_RD_IRT_ERT}[1]"]
@{FILES_PATH}     ${KARAF_HOME}/etc/opendaylight/datastore/initial/config/netvirt-vpnmanager-config.xml    ${KARAF_HOME}/etc/opendaylight/datastore/initial/config/netvirt-natservice-config.xml    ${KARAF_HOME}/etc/opendaylight/datastore/initial/config/netvirt-elanmanager-config.xml
${SNAT_ORIGINAL_TIMEOUT}    5
${L3_ORIGINAL_TIMEOUT}    10
${ARP_ORIGINAL_TIMEOUT}    5
@{ORIGINAL_TIMEOUTS}    ${L3_ORIGINAL_TIMEOUT}    ${SNAT_ORIGINAL_TIMEOUT}    ${ARP_ORIGINAL_TIMEOUT}
@{OF_PUNT_TABLES}    ${L3_PUNT_TABLE}    ${SNAT_PUNT_TABLE}    ${ARP_PUNT_TABLE}    ${ARP_LEARN_TABLE}
@{VALID_TIMEOUTS}    20    30    100    1000    10000

*** Test Cases ***
Verify default punt timeout values and flows
    [Documentation]    Verify default time out for subnet route, SNAT and ARP in respective defualt openflow tables
    ${snat_napt_switch_ip} =    Get NAPT Switch IP From DPID    @{ROUTERS}[1]
    : FOR    ${index}    IN RANGE    0    3
    \    BuiltIn.Wait Until Keyword Succeeds    120s    20s    OVSDB.Verify Dump Flows For Specific Table    ${snat_napt_switch_ip}    @{OF_PUNT_TABLES}[${index}]
    \    ...    True    ${EMPTY}    learn(table=@{OF_PUNT_TABLES}[${index}],hard_timeout=@{ORIGINAL_TIMEOUTS}[${index}]

Set punt timeout to zero and verify flows
    [Documentation]    Verify default flows in OVS for subnet route, SNAT and ARP after the changing the default punt timeout value to zero.
    ...    Default subnet route, SNAT and ARP should get deleted after changing default timeout value to zero
    : FOR    ${index}    IN RANGE    0    3
    \    Change Hard Timeout Value In XML File    @{FILES_PATH}[${index}]    @{ORIGINAL_TIMEOUTS}[${index}]    ${0}
    \    Verify Punt Values In XML File    @{FILES_PATH}[${index}]    ${0}
    ClusterManagement.Stop_Members_From_List_Or_All
    ClusterManagement.Start_Members_From_List_Or_All
    ${snat_napt_switch_ip} =    Get NAPT Switch IP From DPID    @{ROUTERS}[1]
    BuiltIn.Wait Until Keyword Succeeds    120s    20s    OVSDB.Check OVS OpenFlow Connections    ${OS_CMP1_IP}    2
    : FOR    ${index}    IN RANGE    0    3
    \    OVSDB.Verify Dump Flows For Specific Table    ${snat_napt_switch_ip}    @{OF_PUNT_TABLES}[${index}]    False    ${EMPTY}    learn(table=@{OF_PUNT_TABLES}[${index}],hard_timeout=@{ORIGINAL_TIMEOUTS}[${index}]

Set punt timeout to combination of valid ranges and verfiy flows
    [Documentation]    Verify the default flow in OVS for subnet route, SNAT and ARP after the changing the default value to different set of values.
    ...    Default subnet route, SNAT and ARP flows should get changed after changing default timeout value to different set of values
    Set Original TimeOut In Xml    ${0}
    : FOR    ${index}    IN RANGE    0    3
    \    Change Hard Timeout Value In XML File    @{FILES_PATH}[${index}]    @{ORIGINAL_TIMEOUTS}[${index}]    @{VALID_TIMEOUTS}[0]
    \    Verify Punt Values In XML File    @{FILES_PATH}[${index}]    @{VALID_TIMEOUTS}[0]
    ${count} =    BuiltIn.Get length    ${VALID_TIMEOUTS}
    : FOR    ${index}    IN RANGE    1    ${count}
    \    Change Hard Timeout Value In XML File    @{FILES_PATH}[0]    @{VALID_TIMEOUTS}[${index - 1}]    @{VALID_TIMEOUTS}[${index}]
    \    Verify Punt Values In XML File    @{FILES_PATH}[0]    @{VALID_TIMEOUTS}[${index}]
    \    Change Hard Timeout Value In XML File    @{FILES_PATH}[1]    @{VALID_TIMEOUTS}[${index - 1}]    @{VALID_TIMEOUTS}[${index}]
    \    Verify Punt Values In XML File    @{FILES_PATH}[1]    @{VALID_TIMEOUTS}[${index}]
    \    Change Hard Timeout Value In XML File    @{FILES_PATH}[2]    @{VALID_TIMEOUTS}[${index - 1}]    @{VALID_TIMEOUTS}[${index}]
    \    Verify Punt Values In XML File    @{FILES_PATH}[2]    @{VALID_TIMEOUTS}[${index}]
    \    ClusterManagement.Stop_Members_From_List_Or_All
    \    ClusterManagement.Start_Members_From_List_Or_All
    \    BuiltIn.Wait Until Keyword Succeeds    120s    20s    OVSDB.Check OVS OpenFlow Connections    ${OS_CMP1_IP}    2
    \    ${snat_napt_switch_ip} =    Get NAPT Switch IP From DPID    @{ROUTERS}[1]
    \    BuiltIn.Wait Until Keyword Succeeds    120s    5s    OVSDB.Verify Dump Flows For Specific Table    ${OS_COMPUTE_1_IP}    ${L3_PUNT_TABLE}
    \    ...    True    ${EMPTY}    learn(table=${L3_PUNT_TABLE},hard_timeout=@{VALID_TIMEOUTS}[${index}]
    \    BuiltIn.Wait Until Keyword Succeeds    120s    5s    OVSDB.Verify Dump Flows For Specific Table    ${OS_COMPUTE_1_IP}    ${ARP_PUNT_TABLE}
    \    ...    True    ${EMPTY}    learn(table=${ARP_PUNT_TABLE},hard_timeout=@{VALID_TIMEOUTS}[${index}]
    \    BuiltIn.Wait Until Keyword Succeeds    180s    5s    OVSDB.Verify Dump Flows For Specific Table    ${snat_napt_switch_ip}    ${SNAT_PUNT_TABLE}
    \    ...    True    ${EMPTY}    learn(table=${SNAT_PUNT_TABLE},hard_timeout=@{VALID_TIMEOUTS}[${index}]
    Set Original TimeOut In Xml    @{VALID_TIMEOUTS}[4]

*** Keywords ***
Suite Setup
    [Documentation]    Create common setup related to openflow punt path protection
    VpnOperations.Basic Suite Setup
    : FOR    ${network}    IN    @{NETWORKS}
    \    OpenStackOperations.Create Network    ${network}
    OpenStackOperations.Create Network    ${EXT_NETWORKS}    additional_args=--external --provider-network-type gre
    ${elements} =    BuiltIn.Create List    ${EXT_NETWORKS}
    ${count} =    BuiltIn.Get length    ${SUBNETS}
    : FOR    ${index}    IN RANGE    0    ${count}
    \    OpenStackOperations.Create SubNet    @{NETWORKS}[${index}]    @{SUBNETS}[${index}]    @{SUBNETS_CIDR}[${index}]
    OpenStackOperations.Create SubNet    ${EXT_NETWORKS}    ${EXT_SUBNETS}    ${EXT_SUBNETS_CIDR}    additional_args=--no-dhcp
    : FOR    ${router}    IN    @{ROUTERS}
    \    OpenStackOperations.Create Router    ${router}
    \    ${router_id} =    OpenStackOperations.Get Router Id    ${router}
    \    Collections.Append To List    ${ROUTERS_ID}    ${router_id}
    BuiltIn.Set Suite Variable    @{ROUTERS_ID}
    : FOR    ${index}    IN RANGE    0    2
    \    OpenStackOperations.Add Router Interface    @{ROUTERS}[0]    @{SUBNETS}[${index}]
    OpenStackOperations.Add Router Interface    @{ROUTERS}[1]    @{SUBNETS}[2]
    OpenStackOperations.Create And Configure Security Group    ${SECURITY_GROUP}
    ${ext_net} =    BuiltIn.Create List    ${EXT_NETWORKS}
    ${NETWORKS_ALL} =    Collections.Combine Lists    ${NETWORKS}    ${ext_net}
    : FOR    ${index}    IN RANGE    0    3
    \    OpenStackOperations.Create Port    @{NETWORKS_ALL}[${index}]    @{PORT_LIST}[${index + ${index}}]    sg=${SECURITY_GROUP}
    \    OpenStackOperations.Create Port    @{NETWORKS_ALL}[${index}]    @{PORT_LIST}[${index + ${index + 1}}]    sg=${SECURITY_GROUP}
    OpenStackOperations.Create Port    @{NETWORKS}[0]    @{EXTRA_PORTS}[0]    sg=${SECURITY_GROUP}    additional_args=--allowed-address ip-address=0.0.0.0 --fixed-ip subnet=@{SUBNETS}[0],ip-address=@{EXTRA_NW_IP}[0]
    OpenStackOperations.Create Port    @{NETWORKS}[1]    @{EXTRA_PORTS}[1]    sg=${SECURITY_GROUP}    additional_args=--allowed-address ip-address=0.0.0.0 --fixed-ip subnet=@{SUBNETS}[1],ip-address=@{EXTRA_NW_IP}[1]
    : FOR    ${index}    IN RANGE    0    3
    \    OpenStackOperations.Create Vm Instance With Port On Compute Node    @{PORT_LIST}[${index + ${index}}]    @{VM_LIST}[${index + ${index}}]    ${OS_CMP1_HOSTNAME}    sg=${SECURITY_GROUP}
    \    OpenStackOperations.Create Vm Instance With Port On Compute Node    @{PORT_LIST}[${index + ${index + 1}}]    @{VM_LIST}[${index + ${index + 1}}]    ${OS_CMP2_HOSTNAME}    sg=${SECURITY_GROUP}
    @{VM_IPS}    ${dhcp_ip} =    OpenStackOperations.Get VM IPs    @{VM_LIST}
    BuiltIn.Set Suite Variable    ${VM_IPS}
    OpenStackOperations.Show Debugs    @{VM_LIST}
    BuiltIn.Should Not Contain    ${VM_IPS}    None
    BuiltIn.Should Not Contain    ${dhcp_ip}    None
    : FOR    ${index}    IN RANGE    0    2
    \    VpnOperations.VPN Create L3VPN    name=@{VPN_NAME}[${index}]    vpnid=@{VPN_ID}[${index}]    rd=@{L3VPN_RD_IRT_ERT}[${index}]    exportrt=@{L3VPN_RD_IRT_ERT}[${index}]    importrt=@{L3VPN_RD_IRT_ERT}[${index}]
    VpnOperations.Associate VPN to Router    routerid=@{ROUTERS_ID}[0]    vpnid=@{VPN_ID}[0]
    ${network_id} =    OpenStackOperations.Get Net Id    ${EXT_NETWORKS}
    VpnOperations.Associate L3VPN To Network    networkid=${network_id}    vpnid=@{VPN_ID}[1]
    OpenStackOperations.Add Router Gateway    @{ROUTERS}[1]    ${EXT_NETWORKS}    additional_args=--fixed-ip subnet=${EXT_SUBNETS},ip-address=${EXT_SUBNETS_FIXED_IP} --enable-snat
    Create Dictionary For DPN ID And Compute IP Mapping For All DPNS
    OpenStackOperations.Get Suite Debugs

Set Original TimeOut In Xml
    [Arguments]    ${hard_timeout}
    [Documentation]    Set default timeout in XML for all the punt files
    : FOR    ${index}    IN RANGE    0    3
    \    Change Hard Timeout Value In XML File    @{FILES_PATH}[${index}]    ${hard_timeout}    @{ORIGINAL_TIMEOUTS}[${index}]
    \    Verify Punt Values In XML File    @{FILES_PATH}[${index}]    @{ORIGINAL_TIMEOUTS}[${index}]
    ClusterManagement.Stop_Members_From_List_Or_All
    ClusterManagement.Start_Members_From_List_Or_All
    BuiltIn.Wait Until Keyword Succeeds    120s    20s    OVSDB.Check OVS OpenFlow Connections    ${OS_CMP1_IP}    2

Verify Punt Values In XML File
    [Arguments]    ${file_path}    ${value}
    [Documentation]    Verify the default value for SNAT, ARP in ELAN, Subnet Routing in the xml file in ODL Controller
    ${output} =    Utils.Run Command On Remote System And Log    ${ODL_SYSTEM_IP}    cat ${file_path} | grep punt-timeout
    @{matches} =    BuiltIn.Should Match Regexp    ${output}    punt.timeout.*?([0-9]+)
    BuiltIn.Should be true    @{matches}[1] == ${value}

Change Hard Timeout Value In XML File
    [Arguments]    ${file_path}    ${value_1}    ${value_2}
    [Documentation]    Change the default value in xml in the ODL controller for subnet route, SNAT and ARP
    Utils.Run Command On Remote System And Log    ${ODL_SYSTEM_IP}    sed -i -e 's/punt-timeout\>${value_1}/punt-timeout\>${value_2}/' ${file_path}

Create Dictionary For DPN ID And Compute IP Mapping For All DPNS
    [Documentation]    Creating dictionary for DPN ID and compute IP mapping
    : FOR    ${ip}    IN    @{OS_ALL_IPS}
    \    ${dpnid}    OVSDB.Get DPID    ${ip}
    \    Collections.Append To List    ${DPN_IDS}    ${dpnid}
    ${DPN_TO_COMPUTE_IP} =    BuiltIn.Create Dictionary
    ${count} =    BuiltIn.Get length    ${OS_ALL_IPS}
    : FOR    ${index}    IN RANGE    0    ${count}
    \    Collections.Set To Dictionary    ${DPN_TO_COMPUTE_IP}    @{DPN_IDS}[${index}]    @{OS_ALL_IPS}[${index}]
    : FOR    ${dp_id}    IN    @{DPN_IDS}
    \    Collections.Dictionary Should Contain Key    ${DPN_TO_COMPUTE_IP}    ${dp_id}
    BuiltIn.Set Suite Variable    ${DPN_TO_COMPUTE_IP}

Get SNAT NAPT Switch DPID
    [Arguments]    ${router_name}
    [Documentation]    Returns the SNAT NAPT switch dpnid from odl rest call.
    ${router_id} =    OpenStackOperations.Get Router Id    ${router_name}
    ${resp}    RequestsLibrary.Get Request    session    ${CONFIG_API}/odl-nat:napt-switches/router-to-napt-switch/${router_id}
    Log    ${resp.content}
    @{matches} =    BuiltIn.Should Match Regexp    ${resp.content}    switch.id.*?([0-9]+)
    ${dpnid} =    BuiltIn.Convert To Integer    @{matches}[1]
    [Return]    ${dpnid}

Get NAPT Switch IP From DPID
    [Arguments]    ${router_name}
    [Documentation]    Return SNAT NAPT switch ip for the given router name
    ${dpnid} =    BuiltIn.Wait Until Keyword Succeeds    60s    15s    Get SNAT NAPT Switch DPID    ${router_name}
    ${compute_ip} =    Collections.Get From Dictionary    ${DPN_TO_COMPUTE_IP}    ${dpnid}
    [Return]    ${compute_ip}
