*** Settings ***
Documentation     Test suite for OpenFlow punt path protection for subnet route, SNAT, ARP and GARP
Suite Setup       Start Suite
Suite Teardown    Stop Suite
Test Setup        SetupUtils.Setup_Test_With_Logging_And_Without_Fast_Failing
Test Teardown     OpenStackOperations.Get Test Teardown Debugs
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
@{FILES_PATH}     /tmp/${BUNDLEFOLDER}/etc/opendaylight/datastore/initial/config/netvirt-vpnmanager-config.xml    /tmp/${BUNDLEFOLDER}/etc/opendaylight/datastore/initial/config/netvirt-natservice-config.xml    /tmp/${BUNDLEFOLDER}/etc/opendaylight/datastore/initial/config/netvirt-elanmanager-config.xml
${SNAT_DEFAULT_HARD_TIMEOUT}    5
${L3_DEFAULT_HARD_TIMEOUT}    10
${ARP_DEFAULT_HARD_TIMEOUT}    5
@{DEFAULT_HARD_TIMEOUT}    ${L3_DEFAULT_HARD_TIMEOUT}    ${SNAT_DEFAULT_HARD_TIMEOUT}    ${ARP_DEFAULT_HARD_TIMEOUT}
@{OF_PUNT_TABLES}    ${L3_PUNT_TABLE}    ${SNAT_PUNT_TABLE}    ${ARP_PUNT_TABLE}    ${ARP_LEARN_TABLE}
@{HARD_TIMEOUT_VALUES}    20    30    100    1000    10000

*** Test Cases ***
Verify default hard timeout in XML file in ODL Controller and default flow in OVS for subnet route, SNAT and ARP
    [Documentation]    Verify default time out for subnet route, SNAT and ARP in respective defualt openflow tables
    ${snat_napt_switch_ip} =    Get NAPT Switch IP From DPID    @{ROUTERS}[1]
    : FOR    ${index}    IN RANGE    0    3
    \    BuiltIn.Wait Until Keyword Succeeds    120s    20s    OVSDB.Verify Dump Flows For Specific Table    ${snat_napt_switch_ip}    @{OF_PUNT_TABLES}[${index}]
    \    ...    True    ${EMPTY}    learn(table=@{OF_PUNT_TABLES}[${index}],hard_timeout=@{DEFAULT_HARD_TIMEOUT}[${index}]

Verify No default flow for subnet route, SNAT and ARP after hard timeout is set to zero in XML file in ODL Controller
    [Documentation]    Verify default flows in OVS for subnet route, SNAT and ARP after the changing the default punt timeout value to zero.
    ...    Default subnet route, SNAT and ARP should get deleted after changing default timeout value to zero
    : FOR    ${index}    IN RANGE    0    3
    \    Change Hard Timeout Value In XML File    @{FILES_PATH}[${index}]    @{DEFAULT_HARD_TIMEOUT}[${index}]    ${0}
    \    Verify Punt Values In XML File    @{FILES_PATH}[${index}]    ${0}
    Restart Karaf Using Karaf Shell File
    ${snat_napt_switch_ip} =    Get NAPT Switch IP From DPID    @{ROUTERS}[1]
    BuiltIn.Wait Until Keyword Succeeds    120s    20s    OVSDB.Check OVS OpenFlow Connections    ${OS_CMP1_IP}    2
    : FOR    ${index}    IN RANGE    0    3
    \    OVSDB.Verify Dump Flows For Specific Table    ${snat_napt_switch_ip}    @{OF_PUNT_TABLES}[${index}]    False    ${EMPTY}    learn(table=@{OF_PUNT_TABLES}[${index}],hard_timeout=@{DEFAULT_HARD_TIMEOUT}[${index}]
    [Teardown]    Set Default TimeOut In Xml    ${0}

Verify default flow for subnet route and ARP after changing hard timeout to different values in XML file in ODL Controller
    [Documentation]    Verify the default flow in OVS for subnet route, SNAT and ARP after the changing the default value to different set of values.
    ...    Default subnet route, SNAT and ARP flows should get changed after changing default timeout value to different set of values
    : FOR    ${index}    IN RANGE    0    3
    \    Change Hard Timeout Value In XML File    @{FILES_PATH}[${index}]    @{DEFAULT_HARD_TIMEOUT}[${index}]    @{HARD_TIMEOUT_VALUES}[0]
    \    Verify Punt Values In XML File    @{FILES_PATH}[${index}]    @{HARD_TIMEOUT_VALUES}[0]
    ${count} =    BuiltIn.Get length    ${HARD_TIMEOUT_VALUES}
    : FOR    ${index}    IN RANGE    1    ${count}
    \    Change Hard Timeout Value In XML File    @{FILES_PATH}[0]    @{HARD_TIMEOUT_VALUES}[${index - 1}]    @{HARD_TIMEOUT_VALUES}[${index}]
    \    Verify Punt Values In XML File    @{FILES_PATH}[0]    @{HARD_TIMEOUT_VALUES}[${index}]
    \    Change Hard Timeout Value In XML File    @{FILES_PATH}[1]    @{HARD_TIMEOUT_VALUES}[${index - 1}]    @{HARD_TIMEOUT_VALUES}[${index}]
    \    Verify Punt Values In XML File    @{FILES_PATH}[1]    @{HARD_TIMEOUT_VALUES}[${index}]
    \    Change Hard Timeout Value In XML File    @{FILES_PATH}[2]    @{HARD_TIMEOUT_VALUES}[${index - 1}]    @{HARD_TIMEOUT_VALUES}[${index}]
    \    Verify Punt Values In XML File    @{FILES_PATH}[2]    @{HARD_TIMEOUT_VALUES}[${index}]
    \    Restart Karaf Using Karaf Shell File
    \    BuiltIn.Wait Until Keyword Succeeds    120s    20s    OVSDB.Check OVS OpenFlow Connections    ${OS_CMP1_IP}    2
    \    ${snat_napt_switch_ip} =    Get NAPT Switch IP From DPID    @{ROUTERS}[1]
    \    BuiltIn.Wait Until Keyword Succeeds    120s    5s    OVSDB.Verify Dump Flows For Specific Table    ${OS_COMPUTE_1_IP}    ${L3_PUNT_TABLE}
    \    ...    True    ${EMPTY}    learn(table=${L3_PUNT_TABLE},hard_timeout=@{HARD_TIMEOUT_VALUES}[${index}]
    \    BuiltIn.Wait Until Keyword Succeeds    120s    5s    OVSDB.Verify Dump Flows For Specific Table    ${OS_COMPUTE_1_IP}    ${ARP_PUNT_TABLE}
    \    ...    True    ${EMPTY}    learn(table=${ARP_PUNT_TABLE},hard_timeout=@{HARD_TIMEOUT_VALUES}[${index}]
    \    BuiltIn.Wait Until Keyword Succeeds    180s    5s    OVSDB.Verify Dump Flows For Specific Table    ${snat_napt_switch_ip}    ${SNAT_PUNT_TABLE}
    \    ...    True    ${EMPTY}    learn(table=${SNAT_PUNT_TABLE},hard_timeout=@{HARD_TIMEOUT_VALUES}[${index}]
    [Teardown]    Set Default TimeOut In Xml    @{HARD_TIMEOUT_VALUES}[4]

*** Keywords ***
Start Suite
    [Documentation]    Start suite to create common setup related SF441 openflow punt path
    VpnOperations.Basic Suite Setup
    Create Prerequisite Setup
    OpenStackOperations.Get Suite Debugs

Create Prerequisite Setup
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

Set Default TimeOut In Xml
    [Arguments]    ${hard_timeout}
    [Documentation]    Set default timeout in XML for all the punt files
    : FOR    ${index}    IN RANGE    0    3
    \    Change Hard Timeout Value In XML File    @{FILES_PATH}[${index}]    ${hard_timeout}    @{DEFAULT_HARD_TIMEOUT}[${index}]
    \    Verify Punt Values In XML File    @{FILES_PATH}[${index}]    @{DEFAULT_HARD_TIMEOUT}[${index}]
    Restart Karaf Using Karaf Shell File
    BuiltIn.Wait Until Keyword Succeeds    120s    20s    OVSDB.Check OVS OpenFlow Connections    ${OS_CMP1_IP}    2

Create Neutron Networks
    [Documentation]    Create Network with openstack request.
    : FOR    ${network}    IN    @{NETWORKS}
    \    OpenStackOperations.Create Network    ${network}
    BuiltIn.Wait Until Keyword Succeeds    3s    1s    Utils.Check For Elements At URI    ${NETWORK_URL}    ${NETWORKS}

Create Neutron External Networks
    [Documentation]    Create External Network with openstack request.
    OpenStackOperations.Create Network    ${EXT_NETWORKS}    additional_args=--external --provider-network-type gre
    ${elements} =    BuiltIn.Create List    ${EXT_NETWORKS}
    BuiltIn.Wait Until Keyword Succeeds    3s    1s    Utils.Check For Elements At URI    ${NETWORK_URL}    ${elements}

Create Neutron Subnets
    [Documentation]    Create Subnet with openstack request.
    ${count} =    BuiltIn.Get length    ${SUBNETS}
    : FOR    ${index}    IN RANGE    0    ${count}
    \    OpenStackOperations.Create SubNet    @{NETWORKS}[${index}]    @{SUBNETS}[${index}]    @{SUBNETS_CIDR}[${index}]
    BuiltIn.Wait Until Keyword Succeeds    3s    1s    Utils.Check For Elements At URI    ${SUBNETWORK_URL}    ${SUBNETS}

Create Neutron External Subnets
    [Documentation]    Create Subnet with openstack request.
    OpenStackOperations.Create SubNet    ${EXT_NETWORKS}    ${EXT_SUBNETS}    ${EXT_SUBNETS_CIDR}    additional_args=--no-dhcp
    ${elements} =    BuiltIn.Create List    ${EXT_SUBNETS}
    BuiltIn.Wait Until Keyword Succeeds    3s    1s    Utils.Check For Elements At URI    ${SUBNETWORK_URL}    ${elements}

Create Neutron Routers
    [Documentation]    Create Router with openstack request.
    : FOR    ${router}    IN    @{ROUTERS}
    \    OpenStackOperations.Create Router    ${router}
    \    ${router_id} =    OpenStackOperations.Get Router Id    ${router}
    \    Collections.Append To List    ${ROUTERS_ID}    ${router_id}
    BuiltIn.Set Suite Variable    @{ROUTERS_ID}

Add Router Interfaces
    [Documentation]    Add subnet interface to the routers.
    : FOR    ${index}    IN RANGE    0    2
    \    OpenStackOperations.Add Router Interface    @{ROUTERS}[0]    @{SUBNETS}[${index}]
    OpenStackOperations.Add Router Interface    @{ROUTERS}[1]    @{SUBNETS}[2]

Add Router Gateways
    [Documentation]    Add external gateway to the routers.
    ${additional_args} =    BuiltIn.Set Variable    --fixed-ip subnet=${EXT_SUBNETS},ip-address=${EXT_SUBNETS_FIXED_IP} --enable-snat
    OpenStackOperations.Add Router Gateway    @{ROUTERS}[1]    ${EXT_NETWORKS}    additional_args=${additional_args}

VPN Create L3VPNs
    [Documentation]    Create an L3VPN using the Json using the list of optional arguments received.
    : FOR    ${index}    IN RANGE    0    2
    \    VpnOperations.VPN Create L3VPN    name=@{VPN_NAME}[${index}]    vpnid=@{VPN_ID}[${index}]    rd=@{L3VPN_RD_IRT_ERT}[${index}]    exportrt=@{L3VPN_RD_IRT_ERT}[${index}]    importrt=@{L3VPN_RD_IRT_ERT}[${index}]
    VpnOperations.Associate VPN to Router    routerid=@{ROUTERS_ID}[0]    vpnid=@{VPN_ID}[0]
    ${network_id} =    OpenStackOperations.Get Net Id    ${EXT_NETWORKS}
    VpnOperations.Associate L3VPN To Network    networkid=${network_id}    vpnid=@{VPN_ID}[1]
    ${resp} =    VpnOperations.VPN Get L3VPN    vpnid=@{VPN_ID}[1]
    BuiltIn.Should Contain    ${resp}    ${network_id}

Create Neutron Ports
    [Documentation]    Create Port with openstack request.
    ${port1} =    BuiltIn.Set Variable    --allowed-address ip-address=0.0.0.0 --fixed-ip subnet=@{SUBNETS}[0],ip-address=@{EXTRA_NW_IP}[0]
    ${port2} =    BuiltIn.Set Variable    --allowed-address ip-address=0.0.0.0 --fixed-ip subnet=@{SUBNETS}[1],ip-address=@{EXTRA_NW_IP}[1]
    ${ext_net} =    BuiltIn.Create List    ${EXT_NETWORKS}
    ${NETWORKS_ALL} =    Collections.Combine Lists    ${NETWORKS}    ${ext_net}
    : FOR    ${index}    IN RANGE    0    3
    \    OpenStackOperations.Create Port    @{NETWORKS_ALL}[${index}]    @{PORT_LIST}[${index + ${index}}]    sg=${SECURITY_GROUP}
    \    OpenStackOperations.Create Port    @{NETWORKS_ALL}[${index}]    @{PORT_LIST}[${index + ${index + 1}}]    sg=${SECURITY_GROUP}
    OpenStackOperations.Create Port    @{NETWORKS}[0]    @{EXTRA_PORTS}[0]    sg=${SECURITY_GROUP}    additional_args=${port1}
    OpenStackOperations.Create Port    @{NETWORKS}[1]    @{EXTRA_PORTS}[1]    sg=${SECURITY_GROUP}    additional_args=${port2}

Create Nova VMs
    [Documentation]    Create Port with neutron request
    OpenStackOperations.Create Vm Instance With Port On Compute Node    @{PORT_LIST}[0]    @{VM_LIST}[0]    ${OS_CMP1_HOSTNAME}    sg=${SECURITY_GROUP}
    OpenStackOperations.Create Vm Instance With Port On Compute Node    @{PORT_LIST}[1]    @{VM_LIST}[1]    ${OS_CMP2_HOSTNAME}    sg=${SECURITY_GROUP}
    OpenStackOperations.Create Vm Instance With Port On Compute Node    @{PORT_LIST}[2]    @{VM_LIST}[2]    ${OS_CMP1_HOSTNAME}    sg=${SECURITY_GROUP}
    OpenStackOperations.Create Vm Instance With Port On Compute Node    @{PORT_LIST}[3]    @{VM_LIST}[3]    ${OS_CMP2_HOSTNAME}    sg=${SECURITY_GROUP}
    OpenStackOperations.Create Vm Instance With Port On Compute Node    @{PORT_LIST}[4]    @{VM_LIST}[4]    ${OS_CMP1_HOSTNAME}    sg=${SECURITY_GROUP}
    OpenStackOperations.Create Vm Instance With Port On Compute Node    @{PORT_LIST}[5]    @{VM_LIST}[5]    ${OS_CMP2_HOSTNAME}    sg=${SECURITY_GROUP}
    @{VM_IPS}    ${dhcp_ip} =    OpenStackOperations.Get VM IPs    @{VM_LIST}
    BuiltIn.Set Suite Variable    ${VM_IPS}
    BuiltIn.Should Not Contain    ${VM_IPS}    None
    BuiltIn.Should Not Contain    ${dhcp_ip}    None
    OpenStackOperations.Show Debugs    @{VM_LIST}

Restart Karaf Using Karaf Shell File
    [Documentation]    Restart Karaf and polls log to detect when Karaf is up and running again
    Utils.Run Command On Remote System And Log    ${ODL_SYSTEM_IP}    /tmp/${BUNDLEFOLDER}/bin/stop
    BuiltIn.Sleep    90s    reason = Karaf takes few seconds to stop or kill all karaf related processes
    BuiltIn.Wait Until Keyword Succeeds    60s    15s    Check Karaf Status    Not Running
    Utils.Run Command On Remote System And Log    ${ODL_SYSTEM_IP}    /tmp/${BUNDLEFOLDER}/bin/start
    BuiltIn.Wait Until Keyword Succeeds    60s    15s    Check Karaf Status    Running

Check Karaf Status
    [Arguments]    ${str}
    [Documentation]    Check karaf status whether its running or not
    ${status} =    Utils.Run Command On Remote System And Log    ${ODL_SYSTEM_IP}    /tmp/${BUNDLEFOLDER}/bin/status
    BuiltIn.Should Start With    ${status}    ${str}

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
