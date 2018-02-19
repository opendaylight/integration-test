*** Settings ***
Documentation     Subnet Routing And Multicast
Suite Setup       Start Suite
Suite Teardown    Stop Suite
Library           RequestsLibrary
Library           SSHLibrary
Library           Collections
Library           String
Resource          ../../libraries/Utils.robot
Resource          ../../libraries/OpenStackOperations.robot
Resource          ../../libraries/DevstackUtils.robot
Resource          ../../libraries/OVSDB.robot
Resource          ../../libraries/SetupUtils.robot
Resource          ../../libraries/L2GatewayOperations.robot
Resource          ../../libraries/Tcpdump.robot
Resource          ../../libraries/KarafKeywords.robot
Resource          ../../libraries/VpnOperations.robot
Resource          ../../libraries/BgpOperations.robot
Resource          ../../variables/Variables.robot
Resource          ../../variables/netvirt/Variables.robot


*** Variables ***
${Req_no_of_net}    6
${Req_no_of_subNet}    6
${Req_no_of_ports}    12
${Req_no_of_vms_per_dpn}    6
${Req_no_of_ports_per_dpn}    4
${Req_no_of_vms_dpn}    1
${Req_no_of_routers}    2
@{vm_delete}    VM11    VM13    VM12   VM14
@{VM_INSTANCES_REBOOT}    VM11
@{port_delete}    PORT11    PORT13    PORT12    PORT14
${req_no_cidr}   10.1.0.0/16
@{REQ_NETWORKS}       NET1    NET2    NET3    NET4    NET5    NET6
@{VM_INSTANCES_DPN1}    VM11    VM12    VM21    VM22    VM31    VM32
@{VM_INSTANCES_DPN2}    VM13    VM14    VM23    VM24    VM33    VM34
@{VM_INSTANCES_DPN1_PORTS}    PORT11    PORT12    PORT21    PORT22    PORT31    PORT32
@{VM_INSTANCES_DPN2_PORTS}    PORT13    PORT14    PORT23    PORT24    PORT33    PORT34
@{VM_INSTANCES}    VM11    VM12    VM21    VM22    VM31    VM32
...               VM13    VM14    VM23    VM24    VM33    VM34
@{REQ_PORT_LIST}      PORT11    PORT12    PORT13    PORT14    PORT21    PORT22
...               PORT23    PORT24    PORT31    PORT32    PORT33    PORT34
@{REQ_SUBNETS}        SUBNET1    SUBNET2    SUBNET3    SUBNET4    SUBNET5    SUBNET6
@{ROUTER1_INTERFACE}    SUBNET1    SUBNET2    SUBNET3
@{REQ_SUBNET_CIDR}    10.1.0.0/24    10.2.0.0/24    10.3.0.0/24    10.4.0.0/24    10.5.0.0/24    10.6.0.0/24    10.7.0.0/24
@{REQ_SUBNET_CIDR_FIB}    10.1.0.0/24    10.2.0.0/24    10.3.0.0/24
@{VPN_INSTANCE_ID}    4ae8cd92-48ca-49b5-94e1-b2921a261111    4ae8cd92-48ca-49b5-94e1-b2921a262222    4ae8cd92-48ca-49b5-94e1-b2921a263333
@{VPN_NAME}       vpn1    vpn2    vpn3
@{REQ_ROUTERS}        RTR1    RTR2
@{L3VPN_RD}       2200:2
@{CREATE_RD}      ["2200:2"]    ["100:3"]    ["100:4"]
@{CREATE_EXPORT_RT}    ["2200:2"]    ["100:3"]    ["100:4"]
@{CREATE_IMPORT_RT}    ["2200:2"]    ["100:3"]    ["100:4"]
${LOGIN_PSWD}     admin123
${REQ_PING_REGEXP}    , 0% packet loss
${REQ_PING_REGEXP_FAIL}    , 100% packet loss
@{CREATE_l3VNI}    200    300    400
${DEF_LINUX_PROMPT}    \    #
${DCGW_PROMPT}    \    #
${CONFIG_API}     /restconf/config
${OS_COMPUTE_1_IP}    192.168.56.100
${OS_COMPUTE_2_IP}    192.168.56.101
@{TunnelSourceIp}    192.168.56.100    192.168.56.101
${TunnelNetwork}    192.168.56.0/24
${OS_CONTROL_NODE_IP}    192.168.56.100
${OS_USER}        openstack
${ODL_SYSTEM_IP}    192.168.56.105
${TOOLS_SYSTEM_IP}    192.168.56.103
${ODL_SYSTEM_USER}    openstack
${ODL_SYSTEM_PASSWORD}    openstack
${DCGW_SYSTEM_IP}  192.168.56.103
${net_del}    NET1
${sub_add}    SUBNET1
${zone}    TZA
${OVSDB_STATE}    state=ACTIVE
${VM_IP_NET5}    10.1.0.200
${VM_IP_NET6}    224.1.0.200
@{ALLOWED_IP}     10.1.0.100    10.2.0.100    10.3.0.100    10.1.0.110
@{ALLOWED_IP_PORT}     10.1.0.100    10.2.0.100
@{ALLOWED_IP_PORT1}     10.2.0.100    10.3.0.100
@{ALLOWED_IP_PORT2}     10.3.0.100    10.1.0.100
@{MASK}           32    255.255.255.0
${RPING_MIP_IP}    sudo arping -I eth0:1 -c 5 -b -s 10.1.0.100 10.1.0.100
${RPING_MIP_IP1}    sudo arping -I eth0:1 -c 5 -b -s 10.2.0.100 10.2.0.100
${RPING_MIP_IP2}    sudo arping -I eth0:1 -c 5 -b -s 10.3.0.100 10.3.0.100
${RPING_MIP_IP3}    sudo arping -I eth0:1 -c 5 -b -s 10.1.0.110 10.1.0.110
@{VM_LIST}        VM11    VM12    VM21    VM22    VM31    VM32    VM13    VM14    VM23    VM24    VM33    VM34
@{PORT_LIST}        PORT11    PORT12    PORT21    PORT22    PORT31    PORT32    PORT13    PORT14    PORT23    PORT24    PORT33    PORT34

*** Test Cases ***
TC01 Verify Scale in of a Compute Node which is Primary Subnet Route switch with single VPN per Network
    [Documentation]    Verify Scale in of a Compute Node which is Primary Subnet Route switch with single VPN per Network

    Log    Verify Subnet Route Programming On CSS And EP’s Host Routes In Different VPNs Reachable From DC-GW & VMs On Remote DPNs
    VERIFY_FIBFLOWTABLE_AFTER_DCGW_TO_EPHOST_PING

    Log Verify The Primary DPN for subnet route for a specified network and get the dpn id of primary DPN
    [Documentation]    Verify The Primary DPN for subnet route for a specified network and tombstone that DPN
    ${Primary_DPN_IP}=    Verify_Primary_Compute_Node_For_Subnet_Route    ${Subnet1}
    Log    ${Primary_DPN_IP}

    Log    Verify the DPN to be tombstoned for a given subnet route
    ${TS_IP}    Run Keyword If    "${Primary_DPN_IP}" != "${OS_COMPUTE_1_IP}"    Set variable    ${OS_COMPUTE_1_IP}
    ...    ELSE    Set variable    ${OS_COMPUTE_2_IP}
    ${DPNId_tobe_Tombstoned}    Get DPID    ${TS_IP}
    Tombstone_DPN    ${DPNId_tobe_Tombstoned}

    Log    Migrate the VMs from Primary DPN
    @{VM_INSTANCES_MIGRATE}    Run Keyword If    "${Primary_DPN_IP}" != "${OS_COMPUTE_1_IP}"    Set variable    @{VM_LIST1}
    ...    ELSE    Set variable    @{VM_LIST2}
    @{PORT_LIST}    Run Keyword If    "${Primary_DPN_IP}" != "${OS_COMPUTE_1_IP}"    Set variable    @{PORT_LIST1}
    ...    ELSE    Set variable    @{PORT_LIST2}

    Log    Migrate the VMs from Primary DPN
    @{DPN1_NET1_VM_LIST}    Create List    ${VM_LIST[0]}    ${VM_LIST[1]}
    @{DPN2_NET1_VM_LIST}    Create List    ${VM_LIST[2]}    ${VM_LIST[3]}
    @{DPN3_NET1_VM_LIST}    Create List    ${VM_LIST[4]}    ${VM_LIST[5]}
    @{VM_INSTANCES_MIGRATE}    Run Keyword If    "${Primary_DPN_IP}" != "${OS_COMPUTE_1_IP}"    Set variable    @{DPN1_NET1_VM_LIST}
    ...    ELSE    Set variable    @{DPN1_NET1_VM_LIST}
    : FOR    ${VM_Name}    IN    @{VM_INSTANCES_MIGRATE}
    \    Migrate VM Instance    ${VM_Name}

    Log    Verify the Migrated VMs are not present in Primary DPN or Tombstoned DPN
    @{DPN1_NET1_PORT_LIST}    Create List    ${PORT_LIST[0]}    ${PORT_LIST[1]}
    @{DPN2_NET1_PORT_LIST}    Create List    ${PORT_LIST[2]}    ${PORT_LIST[3]}
    @{DPN3_NET1_PORT_LIST}    Create List    ${PORT_LIST[4]}    ${PORT_LIST[5]}
    @{PORT_LIST_MIGRATED}    Run Keyword If    "${Primary_DPN_IP}" != "${OS_COMPUTE_1_IP}"    Set variable    @{DPN1_NET1_PORT_LIST}
    ...    ELSE    Set variable    @{DPN2_NET1_PORT_LIST}

    : FOR    ${PORT_LIST}    IN    @{PORT_LIST_MIGRATED}
    \    ${PortShow}    OpenStackOperations.Neutron Port Show     ${PORT_LIST}
    \    Log    ${PortShow}
    \    Should Not Match Regexp    ${PortShow}     ${COMPUTE_NODE1}
    \    Should Not Match Regexp    ${PortShow}     ${COMPUTE_NODE2}

    Log    Verify the new primary DPN is not one of the tombstoned DPNS
    ${New_Primary_DPN_IP}=    Verify_Primary_Compute_Node_For_Subnet_Route    ${Subnet1}
    ${New_Primary_DPN_ID}=    Get DPID    ${New_Primary_DPN_IP}
    Should Not Be Equal    ${New_Primary_DPN_ID}     ${DPNId_tobe_Tombstoned}

    Log    Scale in the tombstoned DPN by making the br-int down and tep delete and check that its entry is removed from fib-show
    Run Command On Remote System    ${DPNIP_tobe_Tombstoned}    sudo ifconfig br-int down
    ${TepShow}    Issue Command On Karaf Console    tep:show
    Log    ${TepShow}

    Log    Delete the Compute Node 3 Tep port
    ${output}    Issue Command On Karaf Console    tep:${OPERATION[1]} ${DPNId_tobe_Tombstoned} dpdk0 0 ${TunnelSourceIp[2]} ${TunnelNetwork} null TZA
    ${output}    Issue Command On Karaf Console    tep:commit
    ${TepShow}    Issue Command On Karaf Console    tep:show
    ${TunnelCount}    Get Regexp Matches    ${TepShow}    TZA\\s+VXLAN
    Length Should Be    ${TunnelCount}    ${2}
    Wait Until Keyword Succeeds    200s    20s    Verify Tunnel Status as UP

    Log    Verify the Routes in controller
    ${CTRL_FIB}    Issue Command On Karaf Console    ${FIB_SHOW}
    Log    ${CTRL_FIB}
    Should Not Match Regexp    ${CTRL_FIB}     ${DPNIP_tobe_Tombstoned}

    Log    Undo the tombstone and re-add the tep
    ${output}    Issue Command On Karaf Console    tep:${OPERATION[0]} ${DPNId_tobe_Tombstoned} dpdk0 0 ${TunnelSourceIp[2]} ${TunnelNetwork} null TZA
    ${output}    Issue Command On Karaf Console    tep:commit
    ${TepShow}    Issue Command On Karaf Console    tep:show
    ${TunnelCount}    Get Regexp Matches    ${TepShow}    TZA\\s+VXLAN
    Length Should Be    ${TunnelCount}    ${3}
    Wait Until Keyword Succeeds    200s    20s    Verify Tunnel Status as UP

*** Keywords ***
Start Suite
    [Documentation]    Test Suite for Subnet_Routing_and_Multicast_Deployments with CSS.
    SetupUtils.Setup_Utils_For_Setup_And_Teardown
    DevstackUtils.Devstack Suite Setup
    BgpOperations.Start Quagga Processes On ODL    ${ODL_SYSTEM_IP}
    BgpOperations.Start Quagga Processes On DCGW    ${DCGW_SYSTEM_IP}
    Create Setup

Stop Suite
    [Documentation]    Run after the tests execution
    Delete Setup
    Close All Connections

Get Ovsdb State
    [Arguments]    ${dpn_ip}
    [Documentation]    Get Ovsdb State for the DPNs
    ${output_dpn1}    Utils.Run Command On Remote System    ${dpn_ip}    sudo ovsdb-client dump -f list Open_vSwitch Controller | grep state
    BuiltIn.Log    ${output_dpn1}
    BuiltIn.Should Contain    ${output_dpn1}    ${OVSDB_STATE}

Create Neutron Networks
    [Arguments]    ${NUM_OF_NETWORK}
    [Documentation]    Create required number of networks
    : FOR    ${NET}    IN    @{REQ_NETWORKS}
    \    OpenStackOperations.Create Network    ${NET}
    ${NET_LIST}    OpenStackOperations.List Networks
    BuiltIn.Log    ${NET_LIST}
    : FOR    ${index}    IN RANGE    0    ${NUM_OF_NETWORK}
    \     BuiltIn.Should Contain    ${NET_LIST}    ${REQ_NETWORKS[${index}]}

Create Neutron Subnets
    [Arguments]    ${NUM_OF_NETWORK}    ${additional_args}=${EMPTY}    ${verbose}=TRUE
    [Documentation]    Create required number of subnets for previously created networks
    : FOR    ${index}    IN RANGE    0    ${NUM_OF_NETWORK}
    \    OpenStackOperations.Create SubNet    ${REQ_NETWORKS[${index}]}    ${REQ_SUBNETS[${index}]}    ${REQ_SUBNET_CIDR[${index}]}
    ${SUB_LIST}    OpenStackOperations.List Subnets
    BuiltIn.Log    ${SUB_LIST}
    BuiltIn.Log    REQUIRED SUBNET IS
    BuiltIn.Log    ${SUB_LIST}
    : FOR    ${index}    IN RANGE    0    ${NUM_OF_NETWORK}
    \    BuiltIn.Should Contain    ${SUB_LIST}    ${REQ_SUBNETS[${index}]}

Security Group Rule with Remote IP Prefix
    [Documentation]    Allow all TCP/UDP/ICMP packets for this suite
    OpenStackOperations.Neutron Security Group Create    ${SECURITY_GROUP}
    OpenStackOperations.Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=ingress    port_range_max=65535    port_range_min=1    protocol=tcp    remote_ip_prefix=0.0.0.0/0
    OpenStackOperations.Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=egress    port_range_max=65535    port_range_min=1    protocol=tcp    remote_ip_prefix=0.0.0.0/0
    OpenStackOperations.Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=ingress    protocol=icmp    remote_ip_prefix=0.0.0.0/0
    OpenStackOperations.Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=egress    protocol=icmp    remote_ip_prefix=0.0.0.0/0
    OpenStackOperations.Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=ingress    port_range_max=65535    port_range_min=1    protocol=udp    remote_ip_prefix=0.0.0.0/0
    OpenStackOperations.Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=egress    port_range_max=65535    port_range_min=1    protocol=udp    remote_ip_prefix=0.0.0.0/0

Create Neutron Ports
    [Arguments]    ${NUM_OF_PORTS}    ${additional_args}==${EMPTY}    ${verbose}=TRUE
    [Documentation]    Create required number of ports under previously created subnets
    : FOR    ${index}    IN RANGE    0    ${Req_no_of_ports_per_dpn}
    \    ${port_name}    Get From List    ${REQ_PORT_LIST}    ${index}
    \    ${match}    Get Regexp Matches    ${port_name}    [A-Z]*(.).*    1
    \    ${net}    Get From List    ${match}    0
    \    ${net}    Convert To Integer    ${net}
    \    ${network}    Get From List    ${REQ_NETWORKS}    ${net-1}
    \    Create Port    ${network}    ${port_name}    sg=${SECURITY_GROUP}    allowed_address_pairs=@{ALLOWED_IP_PORT}
    #\    Create Port    ${network}    ${port_name}    allowed_address_pairs=@{ALLOWED_IP_PORT}
    ${start} =    Evaluate    ${index}+1
    ${Req_no_of_ports_per_dpn_net2} =    Evaluate    ${start}+${Req_no_of_ports_per_dpn}
    : FOR    ${index}    IN RANGE    ${start}    ${Req_no_of_ports_per_dpn_net2}
    \    ${port_name}    Get From List    ${REQ_PORT_LIST}    ${index}
    \    ${match}    Get Regexp Matches    ${port_name}    [A-Z]*(.).*    1
    \    ${net}    Get From List    ${match}    0
    \    ${net}    Convert To Integer    ${net}
    \    ${network}    Get From List    ${REQ_NETWORKS}    ${net-1}
    \    Create Port    ${network}    ${port_name}    sg=${SECURITY_GROUP}    allowed_address_pairs=@{ALLOWED_IP_PORT1}
    #\    Create Port    ${network}    ${port_name}    allowed_address_pairs=@{ALLOWED_IP_PORT1}
    ${start} =    Evaluate    ${index}+1
    ${Req_no_of_ports_per_dpn_net3} =    Evaluate    ${start}+${Req_no_of_ports_per_dpn}
    : FOR    ${index}    IN RANGE    ${start}    ${Req_no_of_ports_per_dpn_net3}
    \    ${port_name}    Get From List    ${REQ_PORT_LIST}    ${index}
    \    ${match}    Get Regexp Matches    ${port_name}    [A-Z]*(.).*    1
    \    ${net}    Get From List    ${match}    0
    \    ${net}    Convert To Integer    ${net}
    \    ${network}    Get From List    ${REQ_NETWORKS}    ${net-1}
    \    Create Port    ${network}    ${port_name}    sg=${SECURITY_GROUP}    allowed_address_pairs=@{ALLOWED_IP_PORT2}
    #\    Create Port    ${network}    ${port_name}    allowed_address_pairs=@{ALLOWED_IP_PORT2}

Check Vm Instances Have Ip Address
    @{VM_IP_NET1}    ${NET1_DHCP_IP} =    Get VM IPs    @{REQ_VM_INSTANCES_NET1}
    @{VM_IP_NET2}    ${NET2_DHCP_IP} =    Get VM IPs    @{REQ_VM_INSTANCES_NET2}
    @{VM_IP_NET3}    ${NET3_DHCP_IP} =    Get VM IPs    @{REQ_VM_INSTANCES_NET3}
    @{VM_IP_NET4}    ${NET4_DHCP_IP} =    Get VM IPs    @{REQ_VM_INSTANCES_NET4}
    Set Suite Variable    @{VM_IP_NET1}
    Set Suite Variable    @{VM_IP_NET2}
    Set Suite Variable    @{VM_IP_NET3}
    Set Suite Variable    @{VM_IP_NET4}
    BuiltIn.Should Not Contain    ${VM_IP_NET1}    None
    BuiltIn.Should Not Contain    ${VM_IP_NET2}    None
    BuiltIn.Should Not Contain    ${VM_IP_NET3}    None
    BuiltIn.Should Not Contain    ${VM_IP_NET4}    None
    [Teardown]    Run Keywords    Show Debugs    @{REQ_VM_INSTANCES_NET1}    @{REQ_VM_INSTANCES_NET2}    @{REQ_VM_INSTANCES_NET3}    @{REQ_VM_INSTANCES_NET4}
    ...    AND    Get Test Teardown Debugs

Create Nova VMs
    [Arguments]    ${NUM_OF_VMS_PER_DPN}    ${additional_args}=${EMPTY}    ${verbose}=TRUE
    [Documentation]    Create Vm instances on compute nodes
    : FOR    ${index}    IN RANGE    0    ${NUM_OF_VMS_PER_DPN}
    \    Create Vm Instance With Port On Compute Node    ${VM_INSTANCES_DPN1_PORTS[${index}]}    ${VM_INSTANCES_DPN1[${index}]}    ${OS_COMPUTE_1_IP}    sg=${SECURITY_GROUP}
    : FOR    ${index}    IN RANGE    0    ${NUM_OF_VMS_PER_DPN}
    \    Create Vm Instance With Port On Compute Node    ${VM_INSTANCES_DPN2_PORTS[${index}]}    ${VM_INSTANCES_DPN2[${index}]}    ${OS_COMPUTE_2_IP}    sg=${SECURITY_GROUP}
    List Nova VMs
    : FOR    ${VM}    IN    @{VM_INSTANCES_DPN1}    @{VM_INSTANCES_DPN2}
    \    Wait Until Keyword Succeeds    60s    10s    Verify VM Is ACTIVE    ${VM}

Tombstone_DPN
    [Arguments]    ${node_id}
    [Documentation]    Tombstone a DPN using Restconfig Api
    ${resp}=    RequestsLibrary.Post Request    session    restconf/operations/scalein-rpc:scalein-computes-start    data={"input":{"scalein-node-ids :${node_id}}}
    Should Be Equal As Strings    ${resp.status_code}    200

Migrate VM Instance
    [Arguments]    ${vm_name}
    [Documentation]    Show information of a given VM and grep for instance id. VM name should be sent as arguments.
    ${devstack_conn_id} =    Get ControlNode Connection
    SSHLibrary.Switch Connection    ${devstack_conn_id}
    ${output} =    Write Commands Until Prompt    openstack server migrate ${vm_name}    60s
    ${output} =    Write Commands Until Prompt    openstack server resize --confirm ${vm_name}    30s
    SSHLibrary.Close Connection
    Wait Until Keyword Succeeds    25s    5s    Verify VM Is ACTIVE    ${vm_name}

Verify_Primary_Compute_Node_For_Subnet_Route
    [Arguments]    ${NET-ID}
    [Documentation]    Verify primary compute node for the subnet route w.r.t the specified network
    ${fib-show}    Set Variable    fib-show
    ${output} =    Issue_Command_On_Karaf_Console    ${fib-show}
    BuiltIn.Log    ${output}
    @{vm_ip_list}    Get Regexp Matches    ${output}    .*${NET-ID}\/32.*[0-9]{1,3}\\.[0-9]{1,3}\\.[0-9]{1,3}\\.[0-9]{1,3}
    ${match}=    Should Match Regexp    @{vm_ip_list}    .*${NET-ID}\/32.*[0-9]{1,3}\\.[0-9]{1,3}\\.[0-9]{1,3}\\.[0-9]{1,3}.*
    @{splitted_output}=    Split String    ${match}    ${EMPTY}
    ${vm_ip}=    Get from List    ${splitted_output}    2
    [Return]    ${vm_ip}

Create Setup
    [Documentation]    Create Two Networks, Two Subnets, Four Ports And Four VMs on each DPN
    Log    Create tunnels between the 2 compute nodes
#    Create ITM Tunnel And Verify
    ${devstack_conn_id}=    Get ControlNode Connection
    Switch Connection    ${devstack_conn_id}
    Create Neutron Networks    ${Req_no_of_net}
    Create Neutron Subnets    ${Req_no_of_subNet}
    Security Group Rule with Remote IP Prefix
    Create Neutron Ports    ${Req_no_of_ports}   
    Create Nova VMs    ${Req_no_of_vms_per_dpn}
    ${VM_IP_NET1}    ${VM_IP_NET2}    ${VM_IP_NET3}    ${VM_IP_NET4}    BuiltIn.Wait Until Keyword Succeeds    180s    10s
    ...    Verify VMs received IP
    Set Global Variable    ${VM_IP_NET1}
    Set Global Variable    ${VM_IP_NET2}
    Set Global Variable    ${VM_IP_NET3}
    Set Global Variable    ${VM_IP_NET4}
    @{vm_ip_list} =     Create List    ${VM_IP_NET1}    ${VM_IP_NET2}    ${VM_IP_NET3}    ${VM_IP_NET4}
    BuiltIn.Log    STARTING ENTERPRISE NETWORK HOST CONFIGURATION
    Create Sub Interfaces And Verify
    ${devstack_conn_id}=    Get ControlNode Connection
    Switch Connection    ${devstack_conn_id}
    Create Routers    ${Req_no_of_routers}
    BuiltIn.Log    CREATE EVPN FROM THE REST API WITH PROPER L3VNI ID
    ${Req_no_of_L3VPN} =    Evaluate    1
    Create L3VPN    ${Req_no_of_L3VPN}
    BuiltIn.Log    ASSOCIATE net1 AND net2 TO EVPN FROM CSC
    ${Req_no_of_net} =    Evaluate    3
    Associate L3VPN To Networks    ${Req_no_of_net}
    Create BGP Config On ODL
    Create BGP Config On DCGW
    ${devstack_conn_id}=    Get ControlNode Connection
    Switch Connection    ${devstack_conn_id}
    BuiltIn.Log    VERIFY TUNNELS BETWEEN DPNS IS UP
    BuiltIn.Wait Until Keyword Succeeds    60s    10s    Verify Tunnel Status as UP
    BuiltIn.Log    CREATE EXTERNAL TUNNEL ENDPOINT BTW ODL AND DCGW
    Create External Tunnel Endpoint
    BuiltIn.Log    LIST ROUTES ON QUAGGA
    ${output} =    Execute Show Command On quagga    ${DCGW_SYSTEM_IP}    show ip bgp vrf ${DCGW_RD}
    BuiltIn.Log    ${output}
    ${cmd1}    Set Variable    fib-show
    ${output2} =    Issue_Command_On_Karaf_Console    ${cmd1}
    Log    ${output2}
    ${output} =    OpenStackOperations.Execute Command on VM Instance    @{REQ_NETWORKS}[0]    @{VM_IP_NET1}[0]    ${RPING_MIP_IP}
    BuiltIn.Should Contain    ${output}    broadcast
    BuiltIn.Should Contain    ${output}    Received 0 reply
    ${output} =    OpenStackOperations.Execute Command on VM Instance    @{REQ_NETWORKS}[1]    @{VM_IP_NET2}[0]    ${RPING_MIP_IP1}
    BuiltIn.Should Contain    ${output}    broadcast
    BuiltIn.Should Contain    ${output}    Received 0 reply
    ${output} =    OpenStackOperations.Execute Command on VM Instance    @{REQ_NETWORKS}[2]    @{VM_IP_NET3}[0]    ${RPING_MIP_IP2}
    BuiltIn.Should Contain    ${output}    broadcast
    BuiltIn.Should Contain    ${output}    Received 0 reply

Create ITM Tunnel And Verify
    [Documentation]    Create ITM Tunnel And Verify
    ${node_1_dpid}=    Get DPID    ${OS_COMPUTE_1_IP}
    ${node_2_dpid}=    Get DPID    ${OS_COMPUTE_2_IP}
    ${node_3_dpid}=    Get DPID    ${OS_CONTROL_NODE_IP}
    ${node_1_adapter}=    Get Ethernet Adapter    ${OS_COMPUTE_1_IP}
    ${node_2_adapter}=    Get Ethernet Adapter    ${OS_COMPUTE_2_IP}
    ${node_3_adapter}=    Get Ethernet Adapter    ${OS_CONTROL_NODE_IP}
    Set Global Variable    ${node_1_adapter}
    Set Global Variable    ${node_2_adapter}
    Set Global Variable    ${node_3_adapter}
    ${first_two_octets}    ${third_octet}    ${last_octet}=    Split String From Right    ${OS_COMPUTE_1_IP}    .    2
    ${subnet}=    Set Variable    ${first_two_octets}.56.0/24
    ${gateway}=    Get Default Gateway    ${OS_COMPUTE_1_IP}
    ${gateway1}=    Get Default Gateway    ${OS_CONTROL_NODE_IP}
    ${gateway2}=    Get Default Gateway    ${OS_COMPUTE_2_IP}
    Issue Command On Karaf Console    tep:add ${node_1_dpid} ${node_1_adapter} 0 ${OS_COMPUTE_1_IP} ${subnet} null TZA
    Issue Command On Karaf Console    tep:add ${node_2_dpid} ${node_2_adapter} 0 ${OS_COMPUTE_2_IP} ${subnet} null TZA
    Issue Command On Karaf Console    tep:add ${node_3_dpid} ${node_3_adapter} 0 ${OS_CONTROL_NODE_IP} ${subnet} null TZA
    Issue Command On Karaf Console    tep:commit
    ${output}=    Issue Command On Karaf Console    ${TEP_SHOW}
    BuiltIn.Log    ${output}
    BuiltIn.Wait Until Keyword Succeeds    120s    20s    VpnOperations.Verify Tunnel Status as UP

Create Sub Interfaces And Verify
    BuiltIn.Log    Create Sub Interface and verify for all VMs
    : FOR    ${vm_ip}    IN    ${VM_IP_NET1[0]}
    \    BuiltIn.Wait Until Keyword Succeeds    30s    5s    Configure_IP_On_Sub_Interface    ${REQ_NETWORKS[0]}    ${ALLOWED_IP[0]}
    \    ...    ${vm_ip}    ${MASK[1]}
    \    BuiltIn.Wait Until Keyword Succeeds    30s    5s    Verify_IP_Configured_On_Sub_Interface    ${REQ_NETWORKS[0]}    ${ALLOWED_IP[0]}
    \    ...    ${vm_ip}
    : FOR    ${vm_ip}    IN    ${VM_IP_NET2[0]}
    \    BuiltIn.Wait Until Keyword Succeeds    30s    5s    Configure_IP_On_Sub_Interface    ${REQ_NETWORKS[1]}    ${ALLOWED_IP[1]}
    \    ...    ${vm_ip}    ${MASK[1]}
    \    BuiltIn.Wait Until Keyword Succeeds    30s    5s    Verify_IP_Configured_On_Sub_Interface    ${REQ_NETWORKS[1]}    ${ALLOWED_IP[1]}
    \    ...    ${vm_ip}
    : FOR    ${vm_ip}    IN    ${VM_IP_NET3[0]}
    \    BuiltIn.Wait Until Keyword Succeeds    30s    5s    Configure_IP_On_Sub_Interface    ${REQ_NETWORKS[2]}    ${ALLOWED_IP[2]}
    \    ...    ${vm_ip}    ${MASK[1]}
    \    BuiltIn.Wait Until Keyword Succeeds    30s    5s    Verify_IP_Configured_On_Sub_Interface    ${REQ_NETWORKS[2]}    ${ALLOWED_IP[2]}
    \    ...    ${vm_ip}

Create Routers
    [Arguments]    ${NUM_OF_ROUTERS}
    [Documentation]    Create Router
    : FOR    ${index}    IN RANGE    0    ${NUM_OF_ROUTERS}
    \    OpenStackOperations.Create Router    ${REQ_ROUTERS[${index}]}
    ${router_output} =    OpenStackOperations.List Router
    BuiltIn.Log    ${router_output}
    : FOR    ${index}    IN RANGE    0    ${NUM_OF_ROUTERS}
    \    BuiltIn.Should Contain    ${router_output}    ${REQ_ROUTERS[${index}]}
    BuiltIn.Wait Until Keyword Succeeds    3s    1s    Check For Elements At URI    ${CONFIG_API}/neutron:neutron/routers/    ${REQ_ROUTERS}

Verify VMs received IP
    [Documentation]    Verify VM received IP
    ${VM_IP_NET1}    BuiltIn.Wait Until Keyword Succeeds    50 sec    10 sec    Get VM Ip Addresses    @{REQ_NETWORKS}[0]    @{REQ_VM_INSTANCES_NET1}
    ${VM_IP_NET2}    BuiltIn.Wait Until Keyword Succeeds    50 sec    10 sec    Get VM Ip Addresses    @{REQ_NETWORKS}[1]    @{REQ_VM_INSTANCES_NET2}
    ${VM_IP_NET3}    BuiltIn.Wait Until Keyword Succeeds    50 sec    10 sec    Get VM Ip Addresses    @{REQ_NETWORKS}[2]    @{REQ_VM_INSTANCES_NET3}
    ${VM_IP_NET4}    BuiltIn.Wait Until Keyword Succeeds    50 sec    10 sec    Get VM Ip Addresses    @{REQ_NETWORKS}[3]    @{REQ_VM_INSTANCES_NET4}
    BuiltIn.Log    ${VM_IP_NET1}
    BuiltIn.Log    ${VM_IP_NET2}
    BuiltIn.Log    ${VM_IP_NET3}
    BuiltIn.Log    ${VM_IP_NET4}
    [Return]    ${VM_IP_NET1}    ${VM_IP_NET2}    ${VM_IP_NET3}    ${VM_IP_NET4}

Get VM Ip Addresses
    [Arguments]    ${network_name}    @{vm_list}
    [Documentation]    Getting the ip address from VM
    ${ip_list}    Create List    @{EMPTY}
    : FOR    ${vm_name}    IN    @{vm_list}
    \    ${vm_ip_line}    Write Commands Until Expected Prompt    nova list | grep ${vm_name}    >    30
    \    BuiltIn.log    ${vm_ip_line}
    \    BuiltIn.log    ${network_name}
    \    @{vm_ip}    Get Regexp Matches    ${vm_ip_line}    [0-9]{1,3}\\.[0-9]{1,3}\\.[0-9]{1,3}\\.[0-9]{1,3}
    \    ${vm_ip_length}    Get Length    ${vm_ip}
    \    Run Keyword If    ${vm_ip_length}>0    Append To List    ${ip_list}    @{vm_ip}[0]
    \    ...    ELSE    Append To List    ${ip_list}    None
    BuiltIn.log    ${ip_list}
    [Return]    ${ip_list}

Delete L3VPN
    [Arguments]    ${NUM_OF_L3VPN}    ${additional_args}=${EMPTY}    ${verbose}=TRUE
    [Documentation]    Delete L3VPN
    : FOR    ${index}    IN RANGE    0    ${NUM_OF_L3VPN}
    \    VpnOperations.VPN Delete L3VPN    vpnid=${VPN_INSTANCE_ID[${index}]}
#    VpnOperations.VPN Delete L3VPN    vpnid=d5f3a2b9-2268-4faf-b552-ceddabe57bf4
#    VpnOperations.VPN Delete L3VPN    vpnid=cd0a3beb-10c8-40fe-8978-0250a11c0899

Create L3VPN
    [Arguments]    ${NUM_OF_L3VPN}    ${additional_args}=${EMPTY}    ${verbose}=TRUE
    [Documentation]    Creates L3VPN and verify the same
    ${net_id} =    Get Net Id    @{REQ_NETWORKS}[0]    ${devstack_conn_id}
    ${tenant_id} =    Get Tenant ID From Network    ${net_id}
    : FOR    ${index}    IN RANGE    0    ${NUM_OF_L3VPN}
    \    VpnOperations.VPN Create L3VPN    vpnid=${VPN_INSTANCE_ID[${index}]}    name=${VPN_NAME[${index}]}    rd=${CREATE_RD[${index}]}    exportrt=${CREATE_EXPORT_RT[${index}]}    importrt=${CREATE_IMPORT_RT[${index}]}    tenantid=${tenant_id}
    #\    ...    l3vni=${CREATE_L3VNI[${index}]}    tenantid=${tenant_id}
#    \    ...    tenantid=${tenant_id}
    \    ${resp}=    VpnOperations.VPN Get L3VPN    vpnid=${VPN_INSTANCE_ID[${index}]}
    \    BuiltIn.Should Contain    ${resp}    ${VPN_INSTANCE_ID[${index}]}
    \    BuiltIn.Should Match Regexp    ${resp}    .*export-RT.*\\n.*${CREATE_EXPORT_RT[${index}]}.*
    \    BuiltIn.Should Match Regexp    ${resp}    .*import-RT.*\\n.*${CREATE_IMPORT_RT[${index}]}.*
    \    BuiltIn.Should Match Regexp    ${resp}    .*route-distinguisher.*\\n.*${CREATE_RD[${index}]}.*
#    \    BuiltIn.Should Match Regexp    ${resp}    .*l3vni.*${CREATE_l3VNI[${index}]}.*

Create BGP Config On ODL
    [Documentation]    Configure BGP Config on ODL
    BgpOperations.Create BGP Configuration On ODL    localas=${AS_ID}    routerid=${ODL_SYSTEM_IP}
    BgpOperations.AddNeighbor To BGP Configuration On ODL    remoteas=${AS_ID}    neighborAddr=${DCGW_SYSTEM_IP}
    ${output} =    BgpOperations.Get BGP Configuration On ODL    session
    BuiltIn.Log    ${output}
    BuiltIn.Should Contain    ${output}    ${DCGW_SYSTEM_IP}

Create BGP Config On DCGW
    [Documentation]    Configure BGP on DCGW
    BgpOperations.Configure BGP And Add Neighbor On DCGW    ${DCGW_SYSTEM_IP}    ${AS_ID}    ${DCGW_SYSTEM_IP}    ${ODL_SYSTEM_IP}    ${VPN_NAME[0]}    ${DCGW_RD}
    ...    ${LOOPBACK_IP}
    BgpOperations.Add Loopback Interface On DCGW    ${DCGW_SYSTEM_IP}    lo    ${LOOPBACK_IP}
    ${output} =    Execute Show Command On Quagga    ${DCGW_SYSTEM_IP}    show running-config
    BuiltIn.Log    ${output}
    ${output} =    BuiltIn.Wait Until Keyword Succeeds    180s    10s    Verify BGP Neighbor Status On Quagga    ${DCGW_SYSTEM_IP}    ${ODL_SYSTEM_IP}
    BuiltIn.Log    ${output}
    ${output1} =    Execute Show Command On Quagga    ${DCGW_SYSTEM_IP}    show ip bgp vrf ${DCGW_RD}
    BuiltIn.Log    ${output1}

Delete BGP Config On ODL
    [Documentation]    Delete BGP Configuration on ODL
    BgpOperations.Delete BGP Configuration On ODL    session
    ${output} =    BgpOperations.Get BGP Configuration On ODL    session
    BuiltIn.Log    ${output}
    ${output}=    Run Command On Remote System    ${ODL_SYSTEM_IP}    sudo cp /opt/quagga/var/log/quagga/zrpcd.init.log /tmp/
    BuiltIn.Log    ${output}
    ${output}=    Run Command On Remote System    ${ODL_SYSTEM_IP}    sudo ls -la /tmp/
    BuiltIn.Log    ${output}

Create External Vxlan Tunnel Endpoint
    [Documentation]    Create and verify external tunnel endpoint between ODL and GWIP
    BgpOperations.Create External Vxlan Tunnel Endpoint Configuration    destIp=${OS_COMPUTE_1_IP}
    ${output} =    BgpOperations.Get External Tunnel Endpoint Configuration    ${OS_COMPUTE_1_IP}
    BuiltIn.Should Contain    ${output}    ${OS_COMPUTE_1_IP}

Create External Tunnel Endpoint
    [Documentation]    Create and verify external tunnel endpoint between ODL and GWIP
    BgpOperations.Create External Tunnel Endpoint Configuration    destIp=${DCGW_SYSTEM_IP}
    ${output} =    BgpOperations.Get External Tunnel Endpoint Configuration    ${DCGW_SYSTEM_IP}
    BuiltIn.Should Contain    ${output}    ${DCGW_SYSTEM_IP}

Associate L3VPN To Networks
    [Arguments]    ${NUM_OF_NET}    ${additional_args}=${EMPTY}    ${verbose}=TRUE
    [Documentation]    Associates L3VPN to networks and verify
    : FOR    ${index}    IN RANGE    0    ${NUM_OF_NET}
    \    ${network_id} =    Get Net Id    ${REQ_NETWORKS[${index}]}    ${devstack_conn_id}
    \    VpnOperations.Associate L3VPN To Network    networkid=${network_id}    vpnid=${VPN_INSTANCE_ID[0]}
    \    ${resp}=    VPN Get L3VPN    vpnid=${VPN_INSTANCE_ID[0]}
    \    BuiltIn.Should Contain    ${resp}    ${network_id}

Dissociate L3VPN To Networks
    [Arguments]    ${NUM_OF_NET}    ${additional_args}=${EMPTY}    ${verbose}=TRUE
    [Documentation]    Dissociates L3VPN to networks and verify
    : FOR    ${index}    IN RANGE    0    ${NUM_OF_NET}
    \    ${network_id} =    Get Net Id    ${REQ_NETWORKS[${index}]}    ${devstack_conn_id}
    \    VpnOperations.Dissociate L3VPN From Networks    networkid=${network_id}    vpnid=${VPN_INSTANCE_ID[0]}
    \    ${resp}=    VPN Get L3VPN    vpnid=${VPN_INSTANCE_ID[0]}
    \    BuiltIn.Should Not Contain    ${resp}    ${network_id}

Configure_IP_On_Sub_Interface
    [Arguments]    ${network_name}    ${ip}    ${vm_ip}    ${mask}    ${interface}=eth0    ${sub_interface_number}=1
    [Documentation]    Keyword for configuring specified IP on specified interface and the corresponding specified sub interface
    OpenStackOperations.Execute Command on VM Instance    ${network_name}    ${vm_ip}    sudo ifconfig ${interface}:${sub_interface_number} ${ip} netmask ${mask} up

Configure_IP_On_Sub_Interface_down
    [Arguments]    ${network_name}    ${ip}    ${vm_ip}    ${mask}    ${interface}=eth0    ${sub_interface_number}=1
    [Documentation]    Keyword for configuring specified IP on specified interface and the corresponding specified sub interface
    OpenStackOperations.Execute Command on VM Instance    ${network_name}    ${vm_ip}    sudo ifconfig ${interface}:${sub_interface_number} ${ip} netmask ${mask} down

Verify_IP_Configured_On_Sub_Interface
    [Arguments]    ${network_name}    ${ip}    ${vm_ip}    ${interface}=eth0    ${sub_interface_number}=1
    [Documentation]    Keyword for verifying specified IP on specified interface and the corresponding specified sub interface
    ${resp}    OpenStackOperations.Execute Command on VM Instance    ${network_name}    ${vm_ip}    sudo ifconfig ${interface}:${sub_interface_number}
    BuiltIn.Should Contain    ${resp}    ${ip}

VERIFY_FIBFLOWTABLE_AFTER_DCGW_TO_EPHOST_PING
    [Documentation]    PING EPHOST AND CHECK FIB, TABLE21 FOR ENTERPRISE HOST ROUTES 
    ${exp_result}    ConvertToInteger    0
    BuiltIn.Log    "Verification of intra_network_intra_openvswitch network connectivity"
    BuiltIn.Wait Until Keyword Succeeds    40s    10s    OpenStackOperations.Verify VM to VM Ping Status    @{REQ_NETWORKS}[0]    ${VM_IP_NET1[0]}    ${VM_IP_NET1[1]}
    ...    ${REQ_PING_REGEXP}
    BuiltIn.Wait Until Keyword Succeeds    40s    10s    OpenStackOperations.Verify VM to VM Ping Status    @{REQ_NETWORKS}[0]    ${VM_IP_NET1[0]}    @{ALLOWED_IP}[0]
    ...    ${REQ_PING_REGEXP}
    BuiltIn.Wait Until Keyword Succeeds    40s    10s    OpenStackOperations.Verify VM to VM Ping Status    @{REQ_NETWORKS}[0]    ${VM_IP_NET1[3]}    ${VM_IP_NET1[2]}
    ...    ${REQ_PING_REGEXP}
    BuiltIn.Log    "Verification of intra_network_inter_openvswitch network connectivity"
    BuiltIn.Wait Until Keyword Succeeds    60s    10s    OpenStackOperations.Verify VM to VM Ping Status    @{REQ_NETWORKS}[0]    ${VM_IP_NET1[0]}    ${VM_IP_NET1[2]}
    ...    ${REQ_PING_REGEXP}
    BuiltIn.Wait Until Keyword Succeeds    60s    10s    OpenStackOperations.Verify VM to VM Ping Status    @{REQ_NETWORKS}[1]    ${VM_IP_NET2[0]}    ${VM_IP_NET2[2]}
    ...    ${REQ_PING_REGEXP}
    BuiltIn.Wait Until Keyword Succeeds    60s    10s    OpenStackOperations.Verify VM to VM Ping Status    @{REQ_NETWORKS}[1]    ${VM_IP_NET2[0]}    @{ALLOWED_IP}[2]
    ...    ${REQ_PING_REGEXP}
    BuiltIn.Log    "Verification of inter_network_intra_openvswitch network connectivity"
    BuiltIn.Wait Until Keyword Succeeds    60s    10s    OpenStackOperations.Verify VM to VM Ping Status    @{REQ_NETWORKS}[0]    ${VM_IP_NET1[0]}    ${VM_IP_NET2[0]}
    ...    ${REQ_PING_REGEXP}
    BuiltIn.Wait Until Keyword Succeeds    60s    10s    OpenStackOperations.Verify VM to VM Ping Status    @{REQ_NETWORKS}[0]    ${VM_IP_NET1[1]}    ${VM_IP_NET2[1]}
    ...    ${REQ_PING_REGEXP}
    BuiltIn.Log    "Verification of inter_network_intra_openvswitch network connectivity between EP Hosts"
    BuiltIn.Wait Until Keyword Succeeds    40s    10s    OpenStackOperations.Verify VM to VM Ping Status    @{REQ_NETWORKS}[0]    ${VM_IP_NET1[0]}    @{ALLOWED_IP}[1]    ${REQ_PING_REGEXP}
    BuiltIn.Wait Until Keyword Succeeds    40s    10s    OpenStackOperations.Verify VM to VM Ping Status    @{REQ_NETWORKS}[0]    ${VM_IP_NET1[1]}    @{ALLOWED_IP}[1]    ${REQ_PING_REGEXP}
    BuiltIn.Wait Until Keyword Succeeds    40s    10s    OpenStackOperations.Verify VM to VM Ping Status    @{REQ_NETWORKS}[0]    ${VM_IP_NET1[0]}    @{ALLOWED_IP}[2]    ${REQ_PING_REGEXP}
    BuiltIn.Wait Until Keyword Succeeds    40s    10s    OpenStackOperations.Verify VM to VM Ping Status    @{REQ_NETWORKS}[0]    ${VM_IP_NET1[2]}    @{ALLOWED_IP}[2]    ${REQ_PING_REGEXP}

    BuiltIn.Wait Until Keyword Succeeds    40s    10s    OpenStackOperations.Verify VM to VM Ping Status    @{REQ_NETWORKS}[1]    ${VM_IP_NET2[0]}    @{ALLOWED_IP}[0]    ${REQ_PING_REGEXP}
    BuiltIn.Wait Until Keyword Succeeds    40s    10s    OpenStackOperations.Verify VM to VM Ping Status    @{REQ_NETWORKS}[1]    ${VM_IP_NET2[1]}    @{ALLOWED_IP}[0]    ${REQ_PING_REGEXP}
    BuiltIn.Wait Until Keyword Succeeds    40s    10s    OpenStackOperations.Verify VM to VM Ping Status    @{REQ_NETWORKS}[1]    ${VM_IP_NET2[0]}    @{ALLOWED_IP}[2]    ${REQ_PING_REGEXP}
    BuiltIn.Wait Until Keyword Succeeds    40s    10s    OpenStackOperations.Verify VM to VM Ping Status    @{REQ_NETWORKS}[1]    ${VM_IP_NET2[2]}    @{ALLOWED_IP}[2]    ${REQ_PING_REGEXP}

    BuiltIn.Wait Until Keyword Succeeds    40s    10s    OpenStackOperations.Verify VM to VM Ping Status    @{REQ_NETWORKS}[2]    ${VM_IP_NET3[0]}    @{ALLOWED_IP}[0]    ${REQ_PING_REGEXP}
    BuiltIn.Wait Until Keyword Succeeds    40s    10s    OpenStackOperations.Verify VM to VM Ping Status    @{REQ_NETWORKS}[2]    ${VM_IP_NET3[1]}    @{ALLOWED_IP}[0]    ${REQ_PING_REGEXP}
    BuiltIn.Wait Until Keyword Succeeds    40s    10s    OpenStackOperations.Verify VM to VM Ping Status    @{REQ_NETWORKS}[2]    ${VM_IP_NET3[0]}    @{ALLOWED_IP}[1]    ${REQ_PING_REGEXP}
    BuiltIn.Wait Until Keyword Succeeds    40s    10s    OpenStackOperations.Verify VM to VM Ping Status    @{REQ_NETWORKS}[2]    ${VM_IP_NET3[2]}    @{ALLOWED_IP}[1]    ${REQ_PING_REGEXP}
    ${output}=    Get Fib Entries    session
    : FOR    ${IP}    IN    @{VM_IP_NET1}    @{REQ_SUBNET_CIDR_FIB}
    \    BuiltIn.Should Contain    ${output}    ${IP}
    BuiltIn.Log    LIST ROUTES ON QUAGGA
    ${output} =    Execute Show Command On quagga    ${DCGW_SYSTEM_IP}    show ip bgp vrf ${DCGW_RD}
    BuiltIn.Log    ${output}
    ${cmd1}    Set Variable    fib-show
    ${output2} =    Issue_Command_On_Karaf_Console    ${cmd1}
    BuiltIn.Log    ${output2}
    BuiltIn.Log    LIST ROUTES ON QUAGGA
    ${output} =    Execute Show Command On quagga    ${DCGW_SYSTEM_IP}    show ip bgp vrf ${DCGW_RD}
    BuiltIn.Log    ${output}

Add Interfaces To Routers
    [Documentation]    Add Interfaces
    ${devstack_conn_id} =    Get ControlNode Connection
    : FOR    ${INTERFACE}    IN    @{ROUTER1_INTERFACE}
    \    OpenStackOperations.Add Router Interface    @{REQ_ROUTERS}[0]    ${INTERFACE}
    ${interface_output} =    OpenStackOperations.Show Router Interface    @{REQ_ROUTERS}[0]
    : FOR    ${INTERFACE}    IN    @{ROUTER1_INTERFACE}
    \    ${subnet_id} =    OpenStackOperations.Get Subnet Id    ${INTERFACE}    ${devstack_conn_id}
    \    BuiltIn.Should Contain    ${interface_output}    ${subnet_id}

Dissociate L3VPN
    [Arguments]    ${NUM_OF_NET}    ${additional_args}=${EMPTY}    ${verbose}=TRUE
    [Documentation]    Dissociate L3VPN from networks
    ${devstack_conn_id} =    Get ControlNode Connection
    Log Many    "Number of network"    ${NUM_OF_NET}
    ${NUM_OF_NETS}    Convert To Integer    ${NUM_OF_NET}
    :FOR   ${index}   IN RANGE   0   ${NUM_OF_NETS}
    \    ${network_id} =    Get Net Id    ${REQ_NETWORKS[${index}]}    ${devstack_conn_id}
    \    VpnOperations.Dissociate L3VPN From Networks    networkid=${network_id}    vpnid=${VPN_INSTANCE_ID[0]}
    \    ${resp}=    VpnOperations.VPN Get L3VPN    vpnid=${VPN_INSTANCE_ID[0]}
    \    BuiltIn.Should Not Contain    ${resp}    ${network_id}


Delete Setup
    [Documentation]    Delete the created VMs, ports, subnet and networks
    ${devstack_conn_id}=    Get ControlNode Connection
    Switch Connection    ${devstack_conn_id}
#    Log    Delete Interface From Router
#    : FOR    ${INTERFACE}    IN    @{ROUTER1_INTERFACE}
#    \    Remove Interface    ${REQ_ROUTERS[0]}    ${INTERFACE}
#    Log    Delete Routers
#    : FOR    ${index}    IN    @{REQ_ROUTERS}
#    \    Delete Router    ${index}
#    Log    Delete the VM instances
#    : FOR    ${VmInstance}    IN    @{VM_INSTANCES}
#    \    Delete Vm Instance    ${VmInstance}
#    Log    Delete neutron ports
#    : FOR    ${Port}    IN    @{REQ_PORT_LIST}
#    \    Delete Port    ${Port}
#    Log    Delete subnets
#    : FOR    ${Subnet}    IN    @{REQ_SUBNETS}
#    \    Delete SubNet    ${Subnet}
#    Log    Delete networks
#    : FOR    ${Network}    IN    @{REQ_NETWORKS}
#    \    Delete Network    ${Network}
#    Delete SecurityGroup    ${SECURITY_GROUP}
#    Log    DELETE L3VPN
    ${Req_no_of_L3VPN} =    Evaluate    1
    Delete L3VPN    ${Req_no_of_L3VPN}
    Log    DELETE BGP CONFIG ON ODL
#    Delete BGP Config On ODL
