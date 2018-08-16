*** Settings ***
Documentation     Test suite for OpenFlow punt path protection for subnet route, SNAT, ARP and GARP
Suite Setup       Start Suite
Suite Teardown    Stop Suite
Resource          ../../../libraries/OpenStackOperations.robot
Resource          ../../../libraries/OVSDB.robot
Resource          ../../../libraries/OvsManager.robot
Resource          ../../../libraries/Utils.robot
Resource          ../../../libraries/VpnOperations.robot
Resource          ../../../variables/Variables.robot
Resource          ../../../variables/netvirt/Variables.robot

*** Variables ***
@{NETWORKS}       of_punt_net1    of_punt_net2    of_punt_net3
${EXT_NETWORKS}    of_punt_ext_net1
@{PORT_LIST}      of_punt_net1_port_1    of_punt_net1_port_2    of_punt_net2_port_1    of_punt_net2_port_2    of_punt_net3_port_1    of_punt_net3_port_2
@{EXTRA_PORTS}    of_punt_net_1_port_3    of_punt_net_2_port_3
@{EXTRA_VMS}      of_punt_net_1_vm_3    of_punt_net_2_vm_3
@{EXTRA_NW_IP}    11.1.1.100    22.1.1.100    12.1.1.12    13.1.1.13
@{VM_LIST}        of_punt_net1_vm_1    of_punt_net1_vm_2    of_punt_net2_vm_1    of_punt_net2_vm_2    of_punt_net3_vm_1    of_punt_net3_vm_2
@{SUBNETS}        of_punt_subnet1    of_punt_subnet2    of_punt_subnet3
${EXT_SUBNETS}    of_punt_ext_subnet1
@{SUBNETS_CIDR}    11.1.1.0/24    22.1.1.0/24    33.1.1.0/24
${EXT_SUBNETS_CIDR}    55.1.1.0/24
${EXT_SUBNETS_FIXED_IP}    55.1.1.100
@{VPN_ID}         4ae8cd92-48ca-49b5-94e1-b2921a261111    4ae8cd92-48ca-49b5-94e1-b2921a262222
@{VPN_NAME}       of_punt_vpn1    of_punt_vpn2
@{ROUTERS}        of_punt_router1    of_punt_router2
${SECURITY_GROUP}    of_punt_sg
${ALLOW_ALL_ADDRESS}    0.0.0.0
@{DCGW_RD_IRT_ERT}    11:1    22:1
@{L3VPN_RD_IRT_ERT}    ["@{DCGW_RD_IRT_ERT}[0]"]    ["@{DCGW_RD_IRT_ERT}[1]"]
@{FILES_PATH}     /tmp/${BUNDLEFOLDER}/etc/opendaylight/datastore/initial/config/netvirt-vpnmanager-config.xml    /tmp/${BUNDLEFOLDER}/etc/opendaylight/datastore/initial/config/netvirt-natservice-config.xml    /tmp/${BUNDLEFOLDER}/etc/opendaylight/datastore/initial/config/netvirt-elanmanager-config.xml
${SNAT_DEFAULT_HARD_TIMEOUT}    5
${L3_DEFAULT_HARD_TIMEOUT}    10
${ARP_DEFAULT_HARD_TIMEOUT}    5
@{DEFAULT_HARD_TIMEOUT}    ${L3_DEFAULT_HARD_TIMEOUT}    ${SNAT_DEFAULT_HARD_TIMEOUT}    ${ARP_DEFAULT_HARD_TIMEOUT}
${HARD_TIMEOUT_180}    20
${HARD_TIMEOUT_10}    10
${SNAT_PUNT_TABLE}    46
${L3_PUNT_TABLE}    22
${ARP_PUNT_TABLE_1}    195
${ARP_PUNT_TABLE_2}    196
@{OF_PUNT_TABLES}    ${L3_PUNT_TABLE}    ${SNAT_PUNT_TABLE}    ${ARP_PUNT_TABLE_1}    ${ARP_PUNT_TABLE_2}
${HARD_TIMEOUT_VALUE_ZERO}    0
@{HARD_TIMEOUT_VALUES}    20    30    100    1000    10000

*** Test Cases ***
Verify default hard timeout in XML file in ODL Controller and default flow in OVS for Subnet Route, SNAT and ARP
    [Documentation]    To verify the default value for punt path Subnet Route, SNAT and ARP in the xml file in ODL Controller and default
    ...    flow in OVS for subnet route, SNAT and ARP tables
    ${snat_napt_switch_ip} =    Get Compute IP From DPIN ID    @{ROUTERS}[1]
    : FOR    ${index}    IN RANGE    0    3
    \    BuiltIn.Wait Until Keyword Succeeds    120s    20s    OVSDB.Verify Dump Flows For Specific Table    ${snat_napt_switch_ip}    @{OF_PUNT_TABLES}[${index}]
    \    ...    True    ${EMPTY}    learn(table=@{OF_PUNT_TABLES}[${index}],hard_timeout=@{DEFAULT_HARD_TIMEOUT}[${index}]

Verify No default flow for Subnet Route, SNAT and ARP after hard timeout is set to zero in XML file in ODL Controller
    [Documentation]    To verify the default flow in ovs for Subnet Route, SNAT and ARP after the changing the default value to zero. by change the the value to zero, punt path default flow is deleted.
    : FOR    ${index}    IN RANGE    0    3
    \    Change Hard Timeout Value In XML File    @{FILES_PATH}[${index}]    @{DEFAULT_HARD_TIMEOUT}[${index}]    ${HARD_TIMEOUT_VALUE_ZERO}
    \    Verify Punt Values In XML File    @{FILES_PATH}[${index}]    ${HARD_TIMEOUT_VALUE_ZERO}
    Restart Karaf Using Karaf Shell File
    ${snat_napt_switch_ip} =    Get Compute IP From DPIN ID    @{ROUTERS}[1]
    BuiltIn.Wait Until Keyword Succeeds    120s    20s    OVSDB.Check OVS OpenFlow Connections    ${OS_CMP1_IP}    2
    : FOR    ${index}    IN RANGE    0    3
    \    OVSDB.Verify Dump Flows For Specific Table    ${snat_napt_switch_ip}    @{OF_PUNT_TABLES}[${index}]    False    ${EMPTY}    learn(table=@{OF_PUNT_TABLES}[${index}],hard_timeout=@{DEFAULT_HARD_TIMEOUT}[${index}]
    : FOR    ${index}    IN RANGE    0    3
    \    Change Hard Timeout Value In XML File    @{FILES_PATH}[${index}]    ${HARD_TIMEOUT_VALUE_ZERO}    @{DEFAULT_HARD_TIMEOUT}[${index}]
    \    Verify Punt Values In XML File    @{FILES_PATH}[${index}]    @{DEFAULT_HARD_TIMEOUT}[${index}]
    Restart Karaf Using Karaf Shell File
    BuiltIn.Wait Until Keyword Succeeds    120s    20s    OVSDB.Check OVS OpenFlow Connections    ${OS_CMP1_IP}    2
    ${snat_napt_switch_ip} =    Get Compute IP From DPIN ID    @{ROUTERS}[1]
    : FOR    ${index}    IN RANGE    0    3
    \    BuiltIn.Wait Until Keyword Succeeds    120s    20s    OVSDB.Verify Dump Flows For Specific Table    ${snat_napt_switch_ip}    @{OF_PUNT_TABLES}[${index}]
    \    ...    True    ${EMPTY}    learn(table=@{OF_PUNT_TABLES}[${index}],hard_timeout=@{DEFAULT_HARD_TIMEOUT}[${index}]

Verify default flow for Subnet Route and ARP after changing hard timeout to different values in XML file in ODL Controller
    [Documentation]    To verify the default flow in ovs for Subnet Route, SNAT and ARP after the changing the default value to zero. by change the the value to zero, punt path default flow is deleted.
    : FOR    ${index}    IN RANGE    0    3
    \    Change Hard Timeout Value In XML File    @{FILES_PATH}[${index}]    @{DEFAULT_HARD_TIMEOUT}[${index}]    @{HARD_TIMEOUT_VALUES}[0]
    \    Verify Punt Values In XML File    @{FILES_PATH}[${index}]    @{HARD_TIMEOUT_VALUES}[0]
    Restart Karaf Using Karaf Shell File
    BuiltIn.Wait Until Keyword Succeeds    120s    20s    OVSDB.Check OVS OpenFlow Connections    ${OS_CMP1_IP}    2
    ${snat_napt_switch_ip} =    Get Compute IP From DPIN ID    @{ROUTERS}[1]
    : FOR    ${index}    IN RANGE    0    3
    \    OVSDB.Verify Dump Flows For Specific Table    ${snat_napt_switch_ip}    @{OF_PUNT_TABLES}[${index}]    True    ${EMPTY}    learn(table=@{OF_PUNT_TABLES}[${index}],hard_timeout=@{HARD_TIMEOUT_VALUES}[0]
    ${cnt}=    Get length    ${HARD_TIMEOUT_VALUES}
    : FOR    ${index}    IN RANGE    1    ${cnt}
    \    Change Hard Timeout Value In XML File    @{FILES_PATH}[0]    @{HARD_TIMEOUT_VALUES}[${index - 1}]    @{HARD_TIMEOUT_VALUES}[${index}]
    \    Verify Punt Values In XML File    @{FILES_PATH}[0]    @{HARD_TIMEOUT_VALUES}[${index}]
    \    Change Hard Timeout Value In XML File    @{FILES_PATH}[2]    @{HARD_TIMEOUT_VALUES}[${index - 1}]    @{HARD_TIMEOUT_VALUES}[${index}]
    \    Verify Punt Values In XML File    @{FILES_PATH}[2]    @{HARD_TIMEOUT_VALUES}[${index}]
    \    Change Hard Timeout Value In XML File    @{FILES_PATH}[1]    @{HARD_TIMEOUT_VALUES}[${index - 1}]    @{HARD_TIMEOUT_VALUES}[${index}]
    \    Verify Punt Values In XML File    @{FILES_PATH}[1]    @{HARD_TIMEOUT_VALUES}[${index}]
    \    Restart Karaf Using Karaf Shell File
    \    BuiltIn.Wait Until Keyword Succeeds    120s    20s    OVSDB.Check OVS OpenFlow Connections    ${OS_CMP1_IP}    2
    \    ${snat_napt_switch_ip} =    Get Compute IP From DPIN ID    @{ROUTERS}[1]
    \    BuiltIn.Wait Until Keyword Succeeds    120s    5s    OVSDB.Verify Dump Flows For Specific Table    ${OS_COMPUTE_1_IP}    ${L3_PUNT_TABLE}
    \    ...    True    ${EMPTY}    learn(table=${L3_PUNT_TABLE},hard_timeout=@{HARD_TIMEOUT_VALUES}[${index}]
    \    BuiltIn.Wait Until Keyword Succeeds    120s    5s    OVSDB.Verify Dump Flows For Specific Table    ${OS_COMPUTE_1_IP}    ${ARP_PUNT_TABLE_1}
    \    ...    True    ${EMPTY}    learn(table=${ARP_PUNT_TABLE_1},hard_timeout=@{HARD_TIMEOUT_VALUES}[${index}]
    \    BuiltIn.Wait Until Keyword Succeeds    180s    5s    OVSDB.Verify Dump Flows For Specific Table    ${snat_napt_switch_ip}    ${SNAT_PUNT_TABLE}
    \    ...    True    ${EMPTY}    learn(table=${SNAT_PUNT_TABLE},hard_timeout=@{HARD_TIMEOUT_VALUES}[${index}]
    : FOR    ${index}    IN RANGE    0    3
    \    Change Hard Timeout Value In XML File    @{FILES_PATH}[${index}]    @{HARD_TIMEOUT_VALUES}[4]    @{DEFAULT_HARD_TIMEOUT}[${index}]
    \    Verify Punt Values In XML File    @{FILES_PATH}[${index}]    @{DEFAULT_HARD_TIMEOUT}[${index}]
    Restart Karaf Using Karaf Shell File
    BuiltIn.Wait Until Keyword Succeeds    120s    20s    OVSDB.Check OVS OpenFlow Connections    ${OS_CMP1_IP}    2
    ${snat_napt_switch_ip} =    Get Compute IP From DPIN ID    @{ROUTERS}[1]
    : FOR    ${index}    IN RANGE    0    3
    \    BuiltIn.Wait Until Keyword Succeeds    120s    20s    OVSDB.Verify Dump Flows For Specific Table    ${snat_napt_switch_ip}    @{OF_PUNT_TABLES}[${index}]
    \    ...    True    ${EMPTY}    learn(table=@{OF_PUNT_TABLES}[${index}],hard_timeout=@{DEFAULT_HARD_TIMEOUT}[${index}]

*** Keywords ***
Start Suite
    [Documentation]    Start suite to create common setup related SF441 openflow punt path
    VpnOperations.Basic Suite Setup
    Common Setup
    OpenStackOperations.Get Suite Debugs

Common Setup
    [Documentation]    Create prerequisite for OpenFlow punt path protection for subnet route, SNAT, ARP and GARP
    Create Neutron Networks
    Create Neutron External Networks
    Create Neutron Subnets
    Create Neutron External Subnets
    Create Neutron Routers
    Add Router Interfaces
    Create And Configure Security Group    ${SECURITY_GROUP}
    Create Neutron Ports
    Create Nova VMs
    VPN Create L3VPNs
    Add Router Gateways
    Create Dictionary For DPN ID And Compute IP Mapping For All DPNS

Stop Suite
    [Documentation]    Delete the setup
    OpenStackOperations.OpenStack Cleanup All

Create Neutron Networks
    [Documentation]    Create Network with openstack request.
    : FOR    ${network}    IN    @{NETWORKS}
    \    OpenStackOperations.Create Network    ${network}
    BuiltIn.Wait Until Keyword Succeeds    3s    1s    Utils.Check For Elements At URI    ${NETWORK_URL}    ${NETWORKS}

Create Neutron External Networks
    [Documentation]    Create External Network with openstack request.
    ${additional_args}    BuiltIn.Set Variable    --external --provider-network-type gre
    OpenStackOperations.Create Network    ${EXT_NETWORKS}    additional_args=${additional_args}
    ${elements} =    BuiltIn.Create List    ${EXT_NETWORKS}
    BuiltIn.Wait Until Keyword Succeeds    3s    1s    Utils.Check For Elements At URI    ${NETWORK_URL}    ${elements}

Create Neutron Subnets
    [Documentation]    Create Subnet with openstack request.
    ${count} =    Get length    ${SUBNETS}
    : FOR    ${index}    IN RANGE    0    ${count}
    \    OpenStackOperations.Create SubNet    @{NETWORKS}[${index}]    @{SUBNETS}[${index}]    @{SUBNETS_CIDR}[${index}]
    BuiltIn.Wait Until Keyword Succeeds    3s    1s    Utils.Check For Elements At URI    ${SUBNETWORK_URL}    ${SUBNETS}

Create Neutron External Subnets
    [Documentation]    Create Subnet with openstack request.
    ${additional_args}    BuiltIn.Set Variable    --no-dhcp
    OpenStackOperations.Create SubNet    ${EXT_NETWORKS}    ${EXT_SUBNETS}    ${EXT_SUBNETS_CIDR}    additional_args=${additional_args}
    ${elements} =    BuiltIn.Create List    ${EXT_SUBNETS}
    BuiltIn.Wait Until Keyword Succeeds    3s    1s    Utils.Check For Elements At URI    ${SUBNETWORK_URL}    ${elements}

Create Neutron Routers
    [Documentation]    Create Router with openstack request.
    ${router_id_list}    BuiltIn.Create List    @{EMPTY}
    : FOR    ${router}    IN    @{ROUTERS}
    \    OpenStackOperations.Create Router    ${router}
    \    ${router_id} =    OpenStackOperations.Get Router Id    ${router}
    \    Collections.Append To List    ${router_id_list}    ${router_id}
    BuiltIn.Set Suite Variable    ${router_id_list}

Add Router Interfaces
    [Documentation]    Add subnet interface to the routers.
    : FOR    ${index}    IN RANGE    0    2
    \    Add Router Interface    @{ROUTERS}[0]    @{SUBNETS}[${index}]
    Add Router Interface    @{ROUTERS}[1]    @{SUBNETS}[2]

Add Router Gateways
    [Documentation]    Add external gateway to the routers.
    ${cmd}    BuiltIn.Set Variable    openstack router set @{ROUTERS}[1] --external-gateway ${EXT_NETWORKS} --fixed-ip subnet=${EXT_SUBNETS},ip-address=${EXT_SUBNETS_FIXED_IP} --enable-snat
    OpenStack CLI    ${cmd}

VPN Create L3VPNs
    [Documentation]    Create an L3VPN using the Json using the list of optional arguments received.
    : FOR    ${index}    IN RANGE    0    2
    \    VpnOperations.VPN Create L3VPN    name=@{VPN_NAME}[${index}]    vpnid=@{VPN_ID}[${index}]    rd=@{L3VPN_RD_IRT_ERT}[${index}]    exportrt=@{L3VPN_RD_IRT_ERT}[${index}]    importrt=@{L3VPN_RD_IRT_ERT}[${index}]
    VpnOperations.Associate VPN to Router    routerid=@{router_id_list}[0]    vpnid=@{VPN_ID}[0]
    ${network_id} =    OpenStackOperations.Get Net Id    ${EXT_NETWORKS}
    VpnOperations.Associate L3VPN To Network    networkid=${network_id}    vpnid=@{VPN_ID}[1]
    ${resp} =    VpnOperations.VPN Get L3VPN    vpnid=@{VPN_ID}[1]
    BuiltIn.Should Contain    ${resp}    ${network_id}
    ${vpn_id_1} =    VPN Get L3VPN ID    @{VPN_ID}[0]    @{DCGW_RD_IRT_ERT}[0]
    ${vpn_id_2} =    VPN Get L3VPN ID    @{VPN_ID}[1]    @{DCGW_RD_IRT_ERT}[1]
    BuiltIn.Set Suite Variable    ${vpn_id_1}
    BuiltIn.Set Suite Variable    ${vpn_id_2}

Create Neutron Ports
    [Documentation]    Create Port with openstack request.
    ${address_pair}    BuiltIn.Set Variable    --allowed-address ip-address=${ALLOW_ALL_ADDRESS}
    ${port1}    BuiltIn.Set Variable    --allowed-address ip-address=${ALLOW_ALL_ADDRESS} --fixed-ip subnet=@{SUBNETS}[0],ip-address=@{EXTRA_NW_IP}[0]
    ${port2}    BuiltIn.Set Variable    --allowed-address ip-address=${ALLOW_ALL_ADDRESS} --fixed-ip subnet=@{SUBNETS}[1],ip-address=@{EXTRA_NW_IP}[1]
    ${ext_net} =    BuiltIn.Create List    ${EXT_NETWORKS}
    ${NETWORKS_ALL}    Combine Lists    ${NETWORKS}    ${ext_net}
    : FOR    ${index}    IN RANGE    0    3
    \    Create Port    @{NETWORKS_ALL}[${index}]    @{PORT_LIST}[${index + ${index}}]    sg=${SECURITY_GROUP}
    \    Create Port    @{NETWORKS_ALL}[${index}]    @{PORT_LIST}[${index + ${index + 1}}]    sg=${SECURITY_GROUP}
    OpenStackOperations.Create Port    @{NETWORKS}[0]    @{EXTRA_PORTS}[0]    sg=${SECURITY_GROUP}    additional_args=${port1}
    OpenStackOperations.Create Port    @{NETWORKS}[1]    @{EXTRA_PORTS}[1]    sg=${SECURITY_GROUP}    additional_args=${port2}

Create Nova VMs
    [Documentation]    Create Port with neutron request
    Create Vm Instance With Port On Compute Node    @{PORT_LIST}[0]    @{VM_LIST}[0]    ${OS_CMP1_HOSTNAME}    sg=${SECURITY_GROUP}
    Create Vm Instance With Port On Compute Node    @{PORT_LIST}[1]    @{VM_LIST}[1]    ${OS_CMP1_HOSTNAME}    sg=${SECURITY_GROUP}
    Create Vm Instance With Port On Compute Node    @{PORT_LIST}[2]    @{VM_LIST}[2]    ${OS_CMP1_HOSTNAME}    sg=${SECURITY_GROUP}
    Create Vm Instance With Port On Compute Node    @{PORT_LIST}[3]    @{VM_LIST}[3]    ${OS_CMP1_HOSTNAME}    sg=${SECURITY_GROUP}
    Create Vm Instance With Port On Compute Node    @{PORT_LIST}[4]    @{VM_LIST}[4]    ${OS_CMP1_HOSTNAME}    sg=${SECURITY_GROUP}
    Create Vm Instance With Port On Compute Node    @{PORT_LIST}[5]    @{VM_LIST}[5]    ${OS_CMP1_HOSTNAME}    sg=${SECURITY_GROUP}
    @{VM_IPS}    ${DHCP_IP} =    OpenStackOperations.Get VM IPs    @{VM_LIST}
    Set Suite Variable    ${VM_IPS}
    BuiltIn.Should Not Contain    ${VM_IPS}    None
    BuiltIn.Should Not Contain    ${DHCP_IP}    None

Restart Karaf Using Karaf Shell File
    [Documentation]    Restarts Karaf and polls log to detect when Karaf is up and running again
    Utils.Run Command On Remote System    ${ODL_SYSTEM_IP}    /tmp/${BUNDLEFOLDER}/bin/stop
    ${status} =    Utils.Run Command On Remote System    ${ODL_SYSTEM_IP}    /tmp/${BUNDLEFOLDER}/bin/status
    BuiltIn.Wait Until Keyword Succeeds    60s    15s    BuiltIn.Should Contain    ${status}    Not Running
    Utils.Run Command On Remote System    ${ODL_SYSTEM_IP}    /tmp/${BUNDLEFOLDER}/bin/start
    Sleep    5s
    ${status} =    Utils.Run Command On Remote System    ${ODL_SYSTEM_IP}    /tmp/${BUNDLEFOLDER}/bin/status
    BuiltIn.Wait Until Keyword Succeeds    90s    15s    BuiltIn.Should Not Contain    ${status}    Not Running

Verify Punt Values In XML File
    [Arguments]    ${file_path}    ${value}
    [Documentation]    To verify the default value for SNAT, ARP in ELAN, Subnet Routing in the xml file in ODL Controller
    SSHKeywords.Open_Connection_To_ODL_System
    ${output} =    Utils.Write Commands Until Expected Prompt    cat ${file_path} | grep punt-timeout    ${DEFAULT_LINUX_PROMPT_STRICT}
    @{matches}    BuiltIn.Should Match Regexp    ${output}    punt.timeout.*?([0-9]+)
    BuiltIn.Should be true    @{matches}[1] == ${value}
    SSHLibrary.Close_Connection

Change Hard Timeout Value In XML File
    [Arguments]    ${file_path}    ${value_1}    ${value_2}
    [Documentation]    To change the default value in xml in the ODL controller for subnet route, SNAT and ARP
    SSHKeywords.Open_Connection_To_ODL_System
    Utils.Write Commands Until Expected Prompt    sed -i -e 's/punt-timeout\>${value_1}/punt-timeout\>${value_2}/' ${file_path}    ${DEFAULT_LINUX_PROMPT_STRICT}
    SSHLibrary.Close_Connection

Create Dictionary For DPN ID And Compute IP Mapping For All DPNS
    [Documentation]    Creating dictionary for DPN ID and compute IP mapping
    ${COMPUTE_1_DPNID} =    OVSDB.Get DPID    ${OS_CMP1_IP}
    BuiltIn.Set Suite Variable    ${COMPUTE_1_DPNID}
    ${COMPUTE_2_DPNID} =    OVSDB.Get DPID    ${OS_CMP2_IP}
    BuiltIn.Set Suite Variable    ${COMPUTE_2_DPNID}
    ${CNTL_DPNID} =    OVSDB.Get DPID    ${OS_CNTL_IP}
    BuiltIn.Set Suite Variable    ${CNTL_DPNID}
    ${DPN_TO_COMPUTE_IP} =    BuiltIn.Create Dictionary
    Collections.Set To Dictionary    ${DPN_TO_COMPUTE_IP}    ${COMPUTE_1_DPNID}    ${OS_CMP1_IP}
    Collections.Set To Dictionary    ${DPN_TO_COMPUTE_IP}    ${COMPUTE_2_DPNID}    ${OS_CMP2_IP}
    Collections.Set To Dictionary    ${DPN_TO_COMPUTE_IP}    ${CNTL_DPNID}    ${OS_CNTL_IP}
    Collections.Dictionary Should Contain Key    ${DPN_TO_COMPUTE_IP}    ${COMPUTE_1_DPNID}
    Collections.Dictionary Should Contain Key    ${DPN_TO_COMPUTE_IP}    ${COMPUTE_2_DPNID}
    Collections.Dictionary Should Contain Key    ${DPN_TO_COMPUTE_IP}    ${CNTL_DPNID}
    BuiltIn.Set Suite Variable    ${DPN_TO_COMPUTE_IP}

Get SNAT NAPT Switch DPIN ID
    [Arguments]    ${router_name}
    [Documentation]    Returns the SNAT NAPT switch dpnid from odl rest call.
    ${router_id}    OpenStackOperations.Get Router Id    ${router_name}
    ${output} =    Utils.Run Command On Remote System    ${OS_CMP1_IP}    curl -v -u ${ODL_RESTCONF_USER}:${ODL_RESTCONF_PASSWORD} GET http://${ODL_SYSTEM_1_IP}:${RESTCONFPORT}${CONFIG_API}/odl-nat:napt-switches/router-to-napt-switch/${router_id}
    @{matches}    BuiltIn.Should Match Regexp    ${output}    switch.id.*?([0-9]+)
    ${dpnid} =    BuiltIn.Convert To Integer    @{matches}[1]
    [Return]    ${dpnid}

Get Compute IP From DPIN ID
    [Arguments]    ${router_name}
    [Documentation]    Return SNAT NAPT switch ip for the given router name
    ${dpnid} =    BuiltIn.Wait Until Keyword Succeeds    60s    15s    Get SNAT NAPT Switch DPIN ID    ${router_name}
    ${compute_ip}    Collections.Get From Dictionary    ${DPN_TO_COMPUTE_IP}    ${dpnid}
    [Return]    ${compute_ip}

VPN Get L3VPN ID
    [Arguments]    ${vpn_id}    ${vrf_id}
    [Documentation]    Get L3VPN id for the given vpn instanse id
    ${resp} =    RequestsLibrary.Get Request    session    ${CONFIG_API}/odl-l3vpn:vpn-instance-to-vpn-id/
    BuiltIn.Log    ${resp.content}
    @{list_any_matches} =    String.Get_Regexp_Matches    ${resp.content}    \"vpn-instance-name\":\"${vpn_id}\",.*"vrf-id":"${vrf_id}",\"vpn-id\":(\\d+)    1
    ${result} =    Evaluate    ${list_any_matches[0]} * 2
    ${vpn_id_hex} =    BuiltIn.Convert To Hex    ${result}
    [Return]    ${vpn_id_hex.lower()}
