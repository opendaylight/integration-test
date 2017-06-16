#=============================================================================================================
*** Settings ***
Documentation     Test suite to validate multipath functionality in openstack integrated environment.
...               The assumption of this suite is that the environment is already configured with the proper
...               integration bridges and vxlan tunnels.
Suite Setup       Suite Setup
Suite Teardown    Suite Teardown
Test Setup        Pretest Setup 
Test Teardown     Pretest Cleanup
Library           OperatingSystem
Library           RequestsLibrary
Resource          ../../libraries/Utils.robot
Resource          ../../libraries/OpenStackOperations.robot
Resource          ../../libraries/DevstackUtils.robot
Resource          ../../libraries/VpnOperations.robot
Resource          ../../libraries/OVSDB.robot
Resource          ../../libraries/Tcpdump.robot
Resource          ../../libraries/SetupUtils.robot
Resource          ../../libraries/Bgp_Operations.robot
#Resource          ../../../variables/Variables.robot
#Resource          ../../../variables/netvirt/Variables.robot
Resource          ../../variables/SF262/Variables.robot
#Resource          ../../variables/Variables.py


#Resource          /home/xsanvel/SF262_Validation/sdnctest/integration/test/csit/variables/SF262/Variables.robot
*** Variables ***


#${USER_HOME}    /root/
${HA_PROXY_IP}       10.2.1.77
${NUM_ODL_SYSTEM}      3
${ODL_SYSTEM_IP}      10.183.255.11
${ODL_SYSTEM_1_IP}    172.168.1.101 
${ODL_SYSTEM_2_IP}    172.168.1.102
${ODL_SYSTEM_3_IP}    172.168.1.103
${DCGW_1_IP}          172.168.1.151
${DCGW_2_IP}          172.168.1.152
${DCGW_3_IP}          172.168.1.153
${DCGW_4_IP}          172.168.1.154
${DCGW_5_IP}          172.168.1.155
${DCGW_6_IP}          172.168.1.156
${DCGW_7_IP}          172.168.1.157
${DCGW_8_IP}          172.168.1.158



${Req_no_of_L3VPN}    8 
${dcgw_ip}   172.168.1.151
@{NETWORKS}       NET1    NET2    NET3    NET4    NET5    NET6    NET7    NET8
@{SUBNETS}        SUBNET1    SUBNET2     SUBNET3    SUBNET4    SUBNET5    SUBNET6    SUBNET7    SUBNET8
@{SUBNET_CIDR}    10.1.1.0/24    20.1.1.0/24    30.1.1.0/24    40.1.1.0/24    50.1.1.0/24    60.1.1.0/24    70.1.1.0/24    80.1.1.0/24
@{VM_INSTANCES}    VM11    VM12    VM21    VM22    
@{DCGW_SYSTEM_IP}    ${DCGW_1_IP}     ${DCGW_2_IP}     ${DCGW_3_IP}     ${DCGW_4_IP}     ${DCGW_5_IP}     ${DCGW_6_IP}     ${DCGW_7_IP}     ${DCGW_8_IP}
${DCGW_SYSTEM_IP}     ${TOOLS_SYSTEM_1_IP}
@{PORT_LIST_NEW}      PORT15
@{VM_NAME_NEW_LIST}        VM15
#${OS_CONTROL_NODE_IP}    10.183.255.11
${NETWORK_URL}    ${CONFIG_API}/neutron:neutron/networks/
${SUBNETWORK_URL}    ${CONFIG_API}/neutron:neutron/subnets/
${PORT_URL}    ${CONFIG_API}/neutron:neutron/ports/
${CONFIG_API}    /restconf/config
${SECURITY_GROUP}    sg-vpnservice
${Req_no_of_net}            8 
${Req_no_of_subNet}         8
${Req_no_of_ports}    8 
${Req_no_of_vms_per_dpn}    4 
${Req_no_of_routers}        2
${No_of_dc_gw}              8
${multipath_fun}       odl:multipath  -f lu 
${ERROR}               Command not found
${maxpath_fun}         multipath -r 200:1 -f lu -n 10 setmaxpath
${no_of_max_path}      9
${max_path_zero}       0
${max_path_negative}   -1
${max_path_eight}      8
${max_path_64}         64
${max_path_65}         65
${max_path_10}         10
${bgp-cache}           bgp-cache
${vpn-session}         vpnservice:l3vpn-config-show
${fib-session}         fib-show
${Enable}   ENABLE 
${Disable}    DISABLE
${OS_USER}    root
${DEVSTACK_SYSTEM_PASSWORD}    admin123
${DEVSTACK_DEPLOY_PATH}    /opt/stack/devstack/
${multipath_fun_enable}       odl:multipath  -f lu enable
${multipath_fun_disable}       odl:multipath  -f lu disable
${Address-Families}    vpnv4 
${Multipath}    Multipath
${AS_NUM}    200
${No_of_path}    9 
${BGP_REC}    "bgp-neighbor-packets-received"\:\\d+
${BGP_SENT}    "bgp-neighbor-packets-sent"\:\\d+
${BGP_PREFIX}    "bgp-total-prefixes"\:\\d+
${REG_1}     :\\d+
${Value0}     0
#${user}    root
#${password}    admin123
${multipath_config}    bgp bestpath as-path multipath-relax
${NUM_OF_DC_GW}     8

@{VPN_INSTANCE_ID}    ${VPN_INSTANCE_ID1}    ${VPN_INSTANCE_ID2}    ${VPN_INSTANCE_ID3}    ${VPN_INSTANCE_ID4}    ${VPN_INSTANCE_ID5}    ${VPN_INSTANCE_ID6}    ${VPN_INSTANCE_ID7}    ${VPN_INSTANCE_ID8}
${VPN_INSTANCE_ID1}   4ae8cd92-48ca-49b5-94e1-b2921a261111
${VPN_INSTANCE_ID2}   4ae8cd92-48ca-49b5-94e1-b2921a261112
${VPN_INSTANCE_ID3}   4ae8cd92-48ca-49b5-94e1-b2921a261113
${VPN_INSTANCE_ID4}   4ae8cd92-48ca-49b5-94e1-b2921a261114
${VPN_INSTANCE_ID5}   4ae8cd92-48ca-49b5-94e1-b2921a261115
${VPN_INSTANCE_ID6}   4ae8cd92-48ca-49b5-94e1-b2921a261116
${VPN_INSTANCE_ID7}   4ae8cd92-48ca-49b5-94e1-b2921a261117
${VPN_INSTANCE_ID8}   4ae8cd92-48ca-49b5-94e1-b2921a261118

@{VPN_NAME}       vpn1    vpn2    vpn3    vpn4    vpn5    vpn6    vpn7    vpn8
@{L3VPN_RD}        1:1
@{CREATE_RD}      ["1:1"]    ["1:2"]    ["1:3"]    ["1:4"]    ["1:5"]    ["1:6"]    ["1:7"]    ["1:8"]
@{CREATE_EXPORT_RT}    ["1:1"]    ["1:2"]    ["1:3"]    ["1:4"]    ["1:5"]    ["1:6"]    ["1:7"]    ["1:8"]
@{CREATE_IMPORT_RT}    ["1:1"]    ["1:2"]    ["1:3"]    ["1:4"]    ["1:5"]    ["1:6"]    ["1:7"]    ["1:8"]
@{DCGW_RD}        1:1    1:2    1:3    1:4    1:5    1:6    1:7    1:8

${TEP_SHOW_STATE}    tep:show-state

*** Test Cases ***
TC1 Verify CSC supports REST API/CLI for multipath configuration (enable/disable multipath)  
    [Documentation]    Verify CSC supports REST API/CLI for multipath configuration (enable/disable multipath) 
    Log    "Enable multipath"
    Multipath Functionality    ${Enable} 
    Log    "Verify Multipath configuration"
    Verify Multipath
 
TC2 Verify CSC supports REST API/CLI for max path configuration
    [Documentation]    Verify CSC supports REST API/CLI for max path configuration
    Log    "Enable multipath"
    Multipath Functionality    ${Enable}
    Log    "Verify Multipath configuration"
    Verify Multipath
    Log    "Enable Maxpath"
    Configure Maxpath    ${no_of_max_path}
    Log    "Verify Maxpath configuration"
    Verify Maxpath    ${no_of_max_path}    

TC3 Verify max-path configuration value should not be 0/-ve, because it’s not supported
    [Documentation]    Verify max-path configuration value should not be 0/-ve, because it’s not supported
    Log    "Enable multipath"
    Multipath Functionality    ${Enable}
    Log    "Verify Multipath configuration"
    Verify Multipath
    Log    "Enable Maxpath = 0 "
    Configure Maxpath    ${max_path_zero}
    Log    "Verify Maxpath configuration"
    Verify Maxpath_Negative    ${max_path_zero}  
    Log    "Enable Maxpath = 0 "
    Configure Maxpath    ${max_path_negative}
    Log    "Verify Maxpath configuration"
    Verify Maxpath_Negative    ${max_path_negative}

TC4 Verify that max path default is set to 8 and max path configurable is 64 on CSC
    [Documentation]   Verify that max path default is set to 8 and max path configurable is 64 on CSC
    Log    "Enable multipath"
    Multipath Functionality    ${Enable}
    Log    "Verify Multipath configuration"
    Verify Multipath
    Log    "Enable Maxpath =8 "
    Configure Maxpath    ${max_path_eight}
    Log    "Verify Maxpath configuration"
    Verify Maxpath
    Log    "Enable Maxpath =64 "
    Configure Maxpath    ${max_path_64}
    Log    "Verify Maxpath configuration"
    Verify Maxpath    ${max_path_64}
    Verify FIB ENTRIES    ${max_path_64}    
    Log    "Enable Maxpath =65 "
    Configure Maxpath    ${max_path_65}
    Log    "Verify Maxpath configuration"
    Verify Maxpath_Negative    ${max_path_65}
    Verify FIB ENTRIES NEGATIVE    ${max_path_65}



*** Keywords ***

Suite Setup
    [Documentation]
    Log    Test Topology ::
    Topology
    # Replace the below 3lines for cleanup(Openstack and testbed cleanup) with ROBOT subs going forward.
    #Openstack Cleanup    ${entity_list}    ${command_list}
    #Testbed Bringup Two DPN Topology CSSBE    ${DPN1_tunintf}    ${DPN2_tunintf}    ${1}
    #${resp}    Sleep    25
    Log    "STARTUP 1.1:Bring up ODL and DC-GW"
    SetupUtils.Setup_Utils_For_Setup_And_Teardown
    DevstackUtils.Devstack Suite Setup
    Create Session    session    http://${HA_PROXY_IP}:${RESTCONFPORT}    auth=${AUTH}    headers=${HEADERS}
    #For Community the below code is required to start Quagga on 3node Cluster ODL.For NONCBA/CEE we assume the Quagga is already running on ODL. 
    # : FOR    ${idx}    IN RANGE    0    ${NUM_ODL_SYSTEM}
    # \    Start Quagga Processes On ODL    ${ODL_SYSTEM_${idx}_IP}
    :FOR   ${index}   IN RANGE   0   ${NUM_OF_DC_GW}
    \    Start Quagga Processes On DCGW    ${DCGW_SYSTEM_IP[${index}]} 
    Log    "STARTUP 1.2:Security Group configuartions"
    Add Ssh Allow Rule 
    Log    "STARTUP 1.3:Create network" 
    Create Neutron Networks    ${Req_no_of_net} 
    Log    "STARTUP 1.4:Create Subnet"
    Create Neutron Subnets    ${Req_no_of_subNet}
    Log    "STARTUP 1.5:Create Ports"
    Create Neutron Ports    ${Req_no_of_ports} 
    Log    "STARTUP 1.6:Bring up 2 VM on DPN1"
    Create Nova VMs     ${Req_no_of_vms_per_dpn}
    #${VM_IP_NET1}    ${VM_IP_NET2}    ${VM_IP_NET3}    ${VM_IP_NET4}    Wait Until Keyword Succeeds    180s    10s    Verify VMs received IP
   # Set Global Variable    ${VM_IP_NET2}
   # Set Global Variable    ${VM_IP_NET1}
   # Set Global Variable    ${VM_IP_NET3}
   # Set Global Variable    ${VM_IP_NET4}
    Log    "STARTUP 1.7:Create L3VPN"
    Create L3VPN    ${Req_no_of_L3VPN}
    Log    "STARTUP 1.8:Associate L3VPN to Network"
    Associate L3VPN To Networks    ${Req_no_of_net}   
    Log    "STARTUP 1.9:Configure BGP on Controller and Quagga"
    Create BGP Config On ODL     ${No_of_dc_gw}
    Create BGP Config On DCGW    ${No_of_dc_gw}
    Log    "STARTUP 1.10 VERIFY TUNNELS BETWEEN DPNS IS UP"
    Wait Until Keyword Succeeds    60s    10s    Verify Tunnel Status as UP
    Log    "STARTUP 1.11 VERIFY FLOWS ARE PRESENT ON THE DPNS"
    Wait Until Keyword Succeeds    60s    10s    Verify Flows Are Present    ${OS_COMPUTE_1_IP}
    Wait Until Keyword Succeeds    60s    10s    Verify Flows Are Present    ${OS_COMPUTE_2_IP}
    Log    "STARTUP 1.2 VERIFY THE VM IS ACTIVE"
    :FOR    ${VM}    IN    @{VM_INSTANCES}
    \    Wait Until Keyword Succeeds    25s    5s    Verify VM Is ACTIVE    ${VM}
    Log    "STARTUP 1.3 CREATE EXTERNAL TUNNEL ENDPOINT BTW ODL AND DCGW"
    Create External Tunnel Endpoint    ${No_of_dc_gw}
    LOG    "STARTUP 1.4 CHECK ROUTES ON QUAGGA"
    Check Routes on Quagga    ${No_of_dc_gw}

Suite Teardown
    [Documentation]    Continue Execution
    Log To Console    "End of Setup"
    Log    "CLEANUP 1.0 Delete the VM instances"
    : FOR    ${VmInstance}    IN    @{VM_INSTANCES}
    \    Delete Vm Instance    ${VmInstance}
    Log    "CLEANUP 1.1 Delete neutron ports"
    : FOR    ${Port}    IN    @{PORT_LIST}
    \    Delete Port    ${Port}
    Log    "CLEANUP 1.2 Delete subnets"
    : FOR    ${Subnet}    IN    @{SUBNETS}
    \    Delete SubNet    ${Subnet}
    Log    "CLEANUP 1.3 Delete networks"
    : FOR    ${Network}    IN    @{NETWORKS}
    \    Delete Network    ${Network}
    Delete SecurityGroup    ${SECURITY_GROUP}
    Log    "CLEANUP 1.4 DELETE L3VPN"
    ${Req_no_of_L3VPN} =    Evaluate    1
    Delete L3VPN    ${Req_no_of_L3VPN}
    Log    "CLEANUP 1.5 DELETE BGP CONFIG ON ODL"
    Delete BGP Config On ODL

#    ${status1}    Run Keyword And Ignore Error    POSTTEST TC LOG
#    Run Keyword If Any Tests Failed    POSTTEST TC LOG ON FAILURE
#    ${status2}    Run Keyword And Ignore Error    POSTTEST SUITE CLEAR LOG
#    Pass Execution If    ${status1}=='FAIL'    Complete the test suite despite of stopping and transferring log collection failed
#    Pass Execution If    ${status2}=='FAIL'    Complete the test suite despite of clearing logs failed



Pretest Cleanup
    [Documentation]    Test Case Cleanup
    Log To Console    "Running Test case level Pretest Cleanup"
    ${resp}    Log    ***********************************Pretest Cleanup ********************************
    Configure Maxpath    0
    Multipath Functionality    ${Disable}

Pretest Setup
    [Documentation]    Test Case Pre Setup
    ${exp_result}    ConvertToInteger    0
    Log To Console    "Running Test case level Pretest Setup"
    ${resp}    Log    ***********************************Pretest Setup ********************************


Create Neutron Networks
    [Arguments]    ${NUM_OF_NETWORK}    ${additional_args}=${EMPTY}    ${verbose}=TRUE
    [Documentation]    Create required number of networks
    ${REQUIRED_NETWORKS}=    Get Slice From List    ${NETWORKS}    0    ${NUM_OF_NETWORK}
    Log To Console    "REQUIRED NETWORKS IS"
    Log To Console    ${REQUIRED_NETWORKS}
    : FOR    ${NET}    IN    @{REQUIRED_NETWORKS}
    \    Create Network    ${NET}
    ${NET_LIST}    List Networks
    Log    ${NET_LIST}
#    :FOR   ${index}   IN RANGE   0   ${NUM_OF_NETWORK}
#    \    Should Contain    ${NET_LIST}    ${NETWORKS[${index}]}
#    Wait Until Keyword Succeeds    3s    1s    Check For Elements At URI    ${NETWORK_URL}    ${NETWORKS}


Create Neutron Subnets
    [Arguments]    ${NUM_OF_NETWORK}    ${additional_args}=${EMPTY}    ${verbose}=TRUE
    [Documentation]    Create required number of subnets for previously created networks
    :FOR   ${index}   IN RANGE   0   ${NUM_OF_NETWORK}
    \    Create SubNet    ${NETWORKS[${index}]}    ${SUBNETS[${index}]}    ${SUBNET_CIDR[${index}]}
    ${SUB_LIST}    List Subnets
    Log    ${SUB_LIST}
    Log To Console    "REQUIRED SUBNET IS"
    Log To Console    ${SUB_LIST}
#    :FOR   ${index}   IN RANGE   0   ${NUM_OF_NETWORK}
#    \    Should Contain    ${SUB_LIST}    ${SUBNETS[${index}]}
#    Wait Until Keyword Succeeds    3s    1s    Check For Elements At URI    ${SUBNETWORK_URL}    ${SUBNETS}


Create Neutron Ports
    [Arguments]    ${NUM_OF_PORTS}    ${additional_args}=${EMPTY}    ${verbose}=TRUE
    [Documentation]    Create required number of ports under previously created subnets
    Log     ${PORT_LIST}
    ${REQUIRED_PORT_LIST}=    Get Slice From List    ${PORT_LIST}    0    ${NUM_OF_PORTS}
    Log     ${REQUIRED_PORT_LIST}
    Log To Console    "REQUIRED PORT LIST IS"
    Log To Console    ${REQUIRED_PORT_LIST}
    :FOR    ${item}    IN RANGE    0    ${NUM_OF_PORTS}
    \    ${port_name}    Get From List    ${PORT_LIST}     ${item}
    \    ${match}    Get Regexp Matches    ${port_name}    [A-Z]*(.).*    1
    \    ${net}    Get From List    ${match}    0
    \    ${net}    Convert To Integer     ${net}
    \    ${network}    Get From List       ${NETWORKS}    ${net-1}
    \    Create Port     ${network}    ${port_name}    sg=${SECURITY_GROUP}
#    Wait Until Keyword Succeeds    3s    1s    Check For Elements At URI    ${PORT_URL}    ${PORT_LIST}



Create Nova VMs
    [Arguments]    ${NUM_OF_VMS_PER_DPN}    ${additional_args}=${EMPTY}    ${verbose}=TRUE
    [Documentation]    Create Vm instances on compute nodes
    :FOR   ${index}   IN RANGE   0   ${NUM_OF_VMS_PER_DPN}
    \    Create Vm Instance With Port On Compute Node    ${PORT_LIST[${index}]}    ${VM_INSTANCES_DPN1[${index}]}    ${OS_COMPUTE_2_IP}    sg=${SECURITY_GROUP}
    ${start} =     Evaluate    ${index}+1
    ${NUM_OF_VMS_PER_DPN} =    Evaluate    ${start}+${NUM_OF_VMS_PER_DPN}
    :FOR    ${index}    IN RANGE    ${start}    ${NUM_OF_VMS_PER_DPN}
    \    Create Vm Instance With Port On Compute Node    ${PORT_LIST[${index}]}    ${VM_INSTANCES[${index}]}    ${OS_COMPUTE_2_IP}    sg=${SECURITY_GROUP}
#    :FOR    ${VM}    IN    @{VM_INSTANCES_DPN1}    @{VM_INSTANCES_DPN2}
#    \    Wait Until Keyword Succeeds    25s    5s    Verify VM Is ACTIVE    ${VM}

Verify Tunnel Status as UP
    [Documentation]    Verify that the tunnels are UP
    ${output}=    Issue Command On Karaf Console    ${TEP_SHOW_STATE}
    Log    ${output}
    Should Contain    ${output}    ${STATE_UP}
    Should Not Contain    ${output}    ${STATE_DOWN}



Verify VMs received IP
    [Documentation]    Verify VM received IP
    ${status}    ${message}    Run Keyword And Ignore Error    Wait Until Keyword Succeeds    60s    5s    Collect VM IP Addresses
    ...    true    @{VM_INSTANCES_NET1}
    ${status}    ${message}    Run Keyword And Ignore Error    Wait Until Keyword Succeeds    60s    5s    Collect VM IP Addresses
    ...    true    @{VM_INSTANCES_NET2}
    ${status}    ${message}    Run Keyword And Ignore Error    Wait Until Keyword Succeeds    60s    5s    Collect VM IP Addresses
    ...    true    @{VM_INSTANCES_NET3}
    ${status}    ${message}    Run Keyword And Ignore Error    Wait Until Keyword Succeeds    60s    5s    Collect VM IP Addresses
    ...    true    @{VM_INSTANCES_NET4}
    ${VM_IP_NET1}    ${DHCP_IP1}    Collect VM IP Addresses    false    @{VM_INSTANCES_NET1}
    ${VM_IP_NET2}    ${DHCP_IP2}    Collect VM IP Addresses    false    @{VM_INSTANCES_NET2}
    ${VM_IP_NET3}    ${DHCP_IP3}    Collect VM IP Addresses    false    @{VM_INSTANCES_NET3}
    ${VM_IP_NET4}    ${DHCP_IP4}    Collect VM IP Addresses    false    @{VM_INSTANCES_NET4}
    Log    ${VM_IP_NET1}
    Log    ${VM_IP_NET2}
    Log    ${VM_IP_NET3}
    Log    ${VM_IP_NET4}
    Should Not Contain    ${VM_IP_NET2}    None
    Should Not Contain    ${VM_IP_NET1}    None
    Should Not Contain    ${VM_IP_NET3}    None
    Should Not Contain    ${VM_IP_NET4}    None
    [Return]    ${VM_IP_NET1}    ${VM_IP_NET2}    ${VM_IP_NET3}    ${VM_IP_NET4}


Verify Flows Are Present
    [Arguments]    ${ip}
    [Documentation]    Verify Flows Are Present
    ${flow_output}=    Run Command On Remote System    ${ip}    sudo ovs-ofctl -O OpenFlow13 dump-flows br-int
    Log    ${flow_output}
    ${resp}=    Should Contain    ${flow_output}    table=50
    Log    ${resp}
    ${resp}=    Should Match regexp    ${flow_output}    table=0.*goto_table:36
    ${resp}=    Should Match regexp    ${flow_output}    table=0.*goto_table:17
    ${resp}=    Should Contain    ${flow_output}    table=51
    Log    ${resp}




Add Ssh Allow Rule
    [Documentation]    Allow all TCP/UDP/ICMP packets for this suite
    OpenStackOperations.Neutron Security Group Create    ${SECURITY_GROUP}
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=ingress    port_range_max=65535    port_range_min=1    protocol=tcp    remote_ip_prefix=0.0.0.0/0
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=egress    port_range_max=65535    port_range_min=1    protocol=tcp    remote_ip_prefix=0.0.0.0/0
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=ingress    protocol=icmp    remote_ip_prefix=0.0.0.0/0
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=egress    protocol=icmp    remote_ip_prefix=0.0.0.0/0
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=ingress    port_range_max=65535    port_range_min=1    protocol=udp    remote_ip_prefix=0.0.0.0/0
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=egress    port_range_max=65535    port_range_min=1    protocol=udp    remote_ip_prefix=0.0.0.0/0


Create L3VPN
    [Arguments]    ${NUM_OF_L3VPN}    ${additional_args}=${EMPTY}    ${verbose}=TRUE
    [Documentation]    Creates L3VPN and verify the same
    ${devstack_conn_id} =    Get ControlNode Connection
    Switch Connection    ${devstack_conn_id}
#    ${net_id} =    Get Net Id    @{NETWORKS}[0]    ${devstack_conn_id}
#    ${tenant_id} =    Get Tenant ID From Network    ${net_id}
    :FOR   ${index}   IN RANGE   0   ${NUM_OF_L3VPN}
    \    ${net_id} =    Get Net Id    @{NETWORKS}[${index}]    ${devstack_conn_id}
    \    ${tenant_id} =    Get Tenant ID From Network    ${net_id}
#    \    VPN Create L3VPN    vpnid=${VPN_INSTANCE_ID[${index}]}    name=${VPN_NAME[${index}]}    rd=${CREATE_RD[${index}]}    exportrt=${CREATE_EXPORT_RT[${index}]}    importrt=${CREATE_IMPORT_RT[${index}]}    l3vni=${CREATE_L3VNI}    tenantid=${tenant_id}
    \    VPN Create L3VPN    vpnid=${VPN_INSTANCE_ID[${index}]}    name=${VPN_NAME[${index}]}    rd=${CREATE_RD[${index}]}    exportrt=${CREATE_EXPORT_RT[${index}]}    importrt=${CREATE_IMPORT_RT[${index}]}    ${tenant_id}
    \    ${resp}=    VPN Get L3VPN    vpnid=${VPN_INSTANCE_ID[${index}]}
    \    Should Contain    ${resp}    ${VPN_INSTANCE_ID[${index}]}
    \    Should Match Regexp    ${resp}    .*export-RT.*\\n.*${CREATE_EXPORT_RT[${index}]}.*
    \    Should Match Regexp    ${resp}    .*import-RT.*\\n.*${CREATE_IMPORT_RT[${index}]}.*
    \    Should Match Regexp    ${resp}    .*route-distinguisher.*\\n.*${CREATE_RD[${index}]}.*

Create L3VPN MULTI RT
    [Arguments]    ${NUM_OF_L3VPN}    ${additional_args}=${EMPTY}    ${verbose}=TRUE
    [Documentation]    Creates L3VPN and verify the same
    ${devstack_conn_id} =    Get ControlNode Connection
    Switch Connection    ${devstack_conn_id}
    ${net_id} =    Get Net Id    @{NETWORKS}[0]    ${devstack_conn_id}
    ${tenant_id} =    Get Tenant ID From Network    ${net_id}
    :FOR   ${index}   IN RANGE   0   ${NUM_OF_L3VPN}
    \    VPN Create L3VPN    vpnid=${VPN_INSTANCE_ID[${index}]}    name=${VPN_NAME[${index}]}    rd=${CREATE_RD[${index}]}    exportrt=${CREATE_EXPORT_RT[${index}]}    importrt=${CREATE_IMPORT_RT[${index}]}    l3vni=${CREATE_L3VNI}    tenantid=${tenant_id}
    \    ${resp}=    VPN Get L3VPN    vpnid=${VPN_INSTANCE_ID[${index}]}
    \    Should Contain    ${resp}    ${VPN_INSTANCE_ID[${index}]}
    \    Should Match Regexp    ${resp}    .*export-RT.*\\n.*${CREATE_EXPORT_RT[${index}]}.*
    \    Should Match Regexp    ${resp}    .*import-RT.*\\n.*${CREATE_IMPORT_RT[${index}]}.*
    \    Should Match Regexp    ${resp}    .*route-distinguisher.*\\n.*${CREATE_RD[${index}]}.*
    \    Should Match Regexp    ${resp}    .*l3vni.*${CREATE_l3VNI}.*

Delete L3VPN
    [Arguments]    ${NUM_OF_L3VPN}    ${additional_args}=${EMPTY}    ${verbose}=TRUE
    [Documentation]    Delete L3VPN
    :FOR   ${index}   IN RANGE   0   ${NUM_OF_L3VPN}
    \    VPN Delete L3VPN    vpnid=${VPN_INSTANCE_ID[${index}]}


Associate L3VPN To Networks
    [Arguments]    ${NUM_OF_NET}    ${additional_args}=${EMPTY}    ${verbose}=TRUE
    [Documentation]    Associates L3VPN to networks and verify
    ${devstack_conn_id} =    Get ControlNode Connection
    :FOR   ${index}   IN RANGE   0   ${NUM_OF_NET}
    \    ${network_id} =    Get Net Id    ${NETWORKS[${index}]}    ${devstack_conn_id}
    \    Associate L3VPN To Network    networkid=${network_id}    vpnid=${VPN_INSTANCE_ID[${index}]}
    \    ${resp}=    VPN Get L3VPN    vpnid=${VPN_INSTANCE_ID[${index}]}
    \    Should Contain    ${resp}    ${network_id}



Create BGP Config On ODL
    [Arguments]    ${NUM_OF_DC_GW}    ${additional_args}=${EMPTY}    ${verbose}=TRUE
    [Documentation]    Create BGP Config on ODL
    Create BGP Configuration On ODL    localas=${AS_ID}    routerid=${ODL_SYSTEM_IP}
    :FOR   ${index}   IN RANGE   0   ${NUM_OF_DC_GW}
    \    AddNeighbor To BGP Configuration On ODL    remoteas=${AS_ID}    neighborAddr=${DCGW_SYSTEM_IP[${index}]}
    \    ${output} =    Get BGP Configuration On ODL    session
    \    Log    ${output}
    \    Should Contain    ${output}    ${DCGW_SYSTEM_IP}


Delete BGP Config On ODL
    [Documentation]    Delete BGP Configuration on ODL
    Delete BGP Configuration On ODL    session
    ${output} =    Get BGP Configuration On ODL    session
    Log    ${output}
    ${output}=    Run Command On Remote System    ${ODL_SYSTEM_IP}    sudo cp /opt/quagga/var/log/quagga/zrpcd.init.log /tmp/
    Log    ${output}
    ${output}=    Run Command On Remote System    ${ODL_SYSTEM_IP}    sudo ls -la /tmp/
    Log    ${output}

Create BGP Config On DCGW
    [Arguments]    ${NUM_OF_DC_GW}    ${additional_args}=${EMPTY}    ${verbose}=TRUE
    [Documentation]    Configure BGP Config on DCGW
    :FOR   ${index}   IN RANGE   0   ${NUM_OF_DC_GW}
    \    Configure BGP And Add Neighbor On DCGW    ${DCGW_SYSTEM_IP[${index}]}    ${AS_ID}    ${DCGW_SYSTEM_IP[${index}]}    ${ODL_SYSTEM_IP}    ${VPN_NAME[${index}]}    ${DCGW_RD[${index}]}
    \    ...    ${LOOPBACK_IP}
    \    Add Loopback Interface On DCGW    ${DCGW_SYSTEM_IP[${index}]}    lo    ${LOOPBACK_IP[${index}]}
    \    ${output} =    Execute Show Command On Quagga    ${DCGW_SYSTEM_IP[${index}]}    show running-config
    \    Log    ${output}
    \    ${output} =    Wait Until Keyword Succeeds    60s    10s    Verify BGP Neighbor Status On Quagga    ${DCGW_SYSTEM_IP[${index}]}    ${ODL_SYSTEM_IP}
    \    Log    ${output}
    \    ${output1} =    Execute Show Command On Quagga    ${DCGW_SYSTEM_IP}    show ip bgp vrf ${DCGW_RD[{index}]}
    \    Log    ${output1}
    \    Should Contain    ${output1}    ${LOOPBACK_IP[${index}]}


Create External Tunnel Endpoint
    [Arguments]    ${NUM_OF_DC_GW}    ${additional_args}=${EMPTY}    ${verbose}=TRUE
    [Documentation]    Create and verify external tunnel endpoint between ODL and GWIP
    :FOR   ${index}   IN RANGE   0   ${NUM_OF_DC_GW}
    \    Create External Tunnel Endpoint Configuration    destIp=${DCGW_SYSTEM_IP[${index}]}
    \    ${output} =    Get External Tunnel Endpoint Configuration    ${DCGW_SYSTEM_IP[${index}]}
    \    Should Contain    ${output}    ${DCGW_SYSTEM_IP[${index}]}


Check Routes on Quagga
    [Arguments]    ${NUM_OF_DC_GW}    ${additional_args}=${EMPTY}    ${verbose}=TRUE
    [Documentation]    Check for Routes on Quagga
    :FOR   ${index}   IN RANGE   0   ${NUM_OF_DC_GW}
    \    ${output} =    Execute Show Command On quagga    ${DCGW_SYSTEM_IP[${index}]}    show ip bgp vrf ${DCGW_RD[${index}]}
    \    Log    ${output}


Multipath Functionality
    [Arguments]    ${STATE}    ${additional_args}=${EMPTY}    ${verbose}=TRUE
    [Documentation]    Enabling/Disabling Multipath
    Run Keyword If    '${STATE}'=='ENABLE'   MULTION    ELSE    MULTIOFF

MULTION
    [Documentation]    Enabling Multipath
    ${PASSED}    ConvertToInteger    0
    ${output}=    Issue Command On Karaf Console    ${multipath_fun_enable}
    Log    ${output}
    Should Not Contain    ${output}    ${ERROR}

MULTIOFF
    [Documentation]    Disabling Multipath
    ${PASSED}    ConvertToInteger    0
    ${output}=    Issue Command On Karaf Console    ${multipath_fun_disable} 
    Log    ${output}
    Should Not Contain    ${output}    ${ERROR}


Configure Maxpath
    [Arguments]    ${Maxpath}    ${additional_args}=${EMPTY}    ${verbose}=TRUE
    [Documentation]    Set Maxpath
    ${PASSED}    ConvertToInteger    0
    ${maxpath_command}    Catenate    multipath -r    ${AS_NUM}:1 -f lu -n    ${No_of_path}    setmaxpath
    ${output}=    Issue Command On Karaf Console    ${maxpath_command}
    Log    ${output}
    Should Not Contain    ${output}    ${ERROR}

Verify Multipath
    [Documentation]    Verify Multipath is Set properly
    ${PASSED}    ConvertToInteger    0
    ${output}=    Issue Command On Karaf Console    ${bgp-cache}
    Log    ${output}
    Should Contain    ${output}    ${Multipath}
    ${output}=    Issue Command On Karaf Console    ${bgp-cache}
    Should Contain    ${output}    ${Address-Families} 
    Create Quagga Telnet Session    ${dcgw_ip}    bgpd    sdncbgpc
    ${output} =    Execute Command On Quagga Telnet Session    show running-config
    Log    ${output} 
    Should Contain    ${output}    ${multipath_config}
 

Verify Maxpath
    [Arguments]    ${Maxpath}    ${additional_args}=${EMPTY}    ${verbose}=TRUE
    [Documentation]    Verify Maxpath is Set Properly
    ${PASSED}    ConvertToInteger    0
    ${output}=    Issue Command On Karaf Console    ${bgp-cache}
    Log    ${output}
    Should Contain    ${output}    Maxpath
    ${output}=    Issue Command On Karaf Console    ${bgp-cache}
    Should Contain    ${output}    ${Maxpath}

Verify Maxpath_Negative
    [Arguments]    ${Maxpath}    ${additional_args}=${EMPTY}    ${verbose}=TRUE
    [Documentation]    Verify Maxpath 0/-ve or 65 or above NOT Set 
    ${PASSED}    ConvertToInteger    0
    ${output}=    Issue Command On Karaf Console    ${bgp-cache}
    Log    ${output}
    Should Contain    ${output}    Maxpath
    ${output}=    Issue Command On Karaf Console    ${bgp-cache}
    Should Not Contain    ${output}    ${Maxpath}

TC RESULT 
    [Arguments]    ${RESULT1}    ${RESULT2}    ${additional_args}=${EMPTY}    ${verbose}=TRUE
    [Documentation]    Check whether all checkpoints are passed
    ${FINAL_RET}    =    Catenate    ${RESULT1}    ${RESULT2}
    Run Keyword If    '${FINAL_RET}' != '0'   Log To Console    "PASSED"    ELSE    Log To Console    "FAILED"

Check BGP Session On ODL
    [Arguments]    ${RESULT1}    ${RESULT2}    ${additional_args}=${EMPTY}    ${verbose}=TRUE
    [Documentation]    Check BGP Session are UP
    ${output}=    Issue Command On Karaf Console    ${bgp-cache}
    Log    ${output}


Check BGP Session On DC_GW 
    [Arguments]    ${NUM_OF_DC_GW}    ${additional_args}=${EMPTY}    ${verbose}=TRUE
    [Documentation]    Verify BGP Config on DCGW
    :FOR   ${index}   IN RANGE   0   ${NUM_OF_DC_GW}
    \    ${output} =    Execute Show Command On Quagga    ${DCGW_SYSTEM_IP[${index}]}    do sh bg neighbors 
    \    Log    ${output}
    \    ${output} =    Wait Until Keyword Succeeds    60s    10s    Verify BGP Neighbor Status On Quagga    ${DCGW_SYSTEM_IP[${index}]}    ${ODL_SYSTEM_IP}
    \    Log    ${output}


Check VPN Session
    [Arguments]    ${RESULT1}    ${RESULT2}    ${additional_args}=${EMPTY}    ${verbose}=TRUE
    [Documentation]    Check VPN Session are UP
    ${output}=    Issue Command On Karaf Console   ${vpn-session} 
    Log    ${output}
    :FOR   ${index}   IN RANGE   0   ${NUM_OF_DC_GW}
    \     

Check FIB
    [Arguments]    ${RESULT1}    ${RESULT2}    ${additional_args}=${EMPTY}    ${verbose}=TRUE
    [Documentation]    Check FIB 
    ${output}=    Issue Command On Karaf Console  ${fib-session} 
    Log    ${output}


Check Routes on DC_GW
    [Arguments]    ${NUM_OF_DC_GW}    ${additional_args}=${EMPTY}    ${verbose}=TRUE
    [Documentation]    Verify the routes on DC_GW
    :FOR   ${index}   IN RANGE   0   ${NUM_OF_DC_GW}
    \    ${output1} =    Execute Show Command On Quagga    ${DCGW_SYSTEM_IP}    show ip bgp vrf ${DCGW_RD}
    \    Log    ${output1}
    \    Should Contain    ${output1}    ${LOOPBACK_IP[${index}]}


Configure BGP parameters
    [Arguments]    ${NUM_OF_DC_GW}    ${additional_args}=${EMPTY}    ${verbose}=TRUE
    [Documentation]    Configure BGP Parameters


Trigger DC-GW Reboot
    [Documentation]    Trigger DC-GW reboot


Cluster Reboot
    [Arguments]    ${NUM_OF_DC_GW}    ${additional_args}=${EMPTY}    ${verbose}=TRUE
    [Documentation]    Cluster Reboot


Trigger ODL Reboot
    [Arguments]    ${NUM_OF_DC_GW}    ${additional_args}=${EMPTY}    ${verbose}=TRUE
    [Documentation]    Trigger ODL Reboot

Reconfigure DC-GW after Reboot
    [Arguments]    ${NUM_OF_DC_GW}    ${additional_args}=${EMPTY}    ${verbose}=TRUE
    [Documentation]    Reconfigure DC-GW after Reboot


Back-to-Back route flaps
    [Arguments]    ${NUM_OF_DC_GW}    ${additional_args}=${EMPTY}    ${verbose}=TRUE
    [Documentation]    Back to Back Route Flap

Ping VM to VM
    [Arguments]    ${NETWORK}    ${VM_IP1}    ${VM_IP2}
    [Documentation]    Verify Ping among VMs
    ${output}=    Wait Until Keyword Succeeds    60s    10s    Execute Command on VM Instance    ${NETWORK}    ${VM_IP1}    ping -c 3 ${VM_IP2}
    Should Contain    ${output}    ${REQ_PING_REGEXP} 

NON_CBA_ALARM_ODL_LOG
    [Arguments]    ${NUM_OF_DC_GW}    ${additional_args}=${EMPTY}    ${verbose}=TRUE
    [Documentation]    Check ALARM


Check Counter BGP
    [Documentation]    Check BGP counters
    Log To Console    "Duration of time that OF port has been installed on OF switch"
    ${RESP}    RequestsLibrary.Get    session    ${REST_CON}/pm-counter-service:performance-counters/bgp-counters/
    ${match_1}    Should Match Regexp    ${RESP.content}    ${BGP_REC}
    ${match_2}    Should Match Regexp    ${RESP.content}    ${BGP_SENT}
    ${match_3}    Should Match Regexp    ${RESP.content}    ${BGP_PREFIX}

    ${receive}    Should Match Regexp    ${match_1}    ${REG_1}
    ${receive_1} =    Strip String    ${receive}    characters=:
    Log To Console    "the total number of BGP packets received from neighbor  "
    Log To Console    ${receive_1}
    Should Not Contain    ${receive_1}    {Value0}

    ${sent}    Should Match Regexp    ${match_2}    ${REG_1}
    ${sent_1} =    Strip String    ${sent}    characters=:
    Log To Console    "total number of BGP packets sent to neighbor "
    Log To Console    ${sent_1}
    Should Not Contain    ${sent_1}    {Value0}

    ${prefixes}    Should Match Regexp    ${match_3}    ${REG_1}
    ${prefixes_1} =    Strip String    ${prefixes}    characters=:
    Log To Console    "total number of IPv4 BGP prefixes received  "
    Log To Console    ${prefixes_1}
    Should Not Contain    ${prefixes_1}    {Value0}

Verify FIB ENTRIES
    [Arguments]    ${NUM_OF_ROUTE}    ${additional_args}=${EMPTY}    ${verbose}=TRUE
    [Documentation]    Check Fib Entries
    ${Fib_entries}    Check Fib
    Should Contain    ${Fib_entries}    ${NUM_OF_ROUTE}  

Verify FIB ENTRIES NEGATIVE
    [Arguments]    ${NUM_OF_ROUTE}    ${additional_args}=${EMPTY}    ${verbose}=TRUE
    [Documentation]    Check Fib Entries
    ${Fib_entries}    Check Fib
    Should Not Contain    ${Fib_entries}    ${NUM_OF_ROUTE}
  
Topology
    [Documentation]    1)Topology view
    setup.file_open    ${logger}    %{SDN}/integration/test/csit/suites/SF262/SF262_feature.topology

              
