*** Settings ***
Documentation     Test suite to validate multipath functionality in openstack integrated environment.
...               The assumption of this suite is that the environment is already configured with the proper
...               integration bridges and vxlan tunnels.

#Test Setup        Pretest Check
Suite Setup        Start Suite    
#Suite Teardown    Suite Teardown    
#Test Setup        Pretest Setup
#Test Setup        Pretest Check
Test Teardown      Pretest Cleanup
Library           OperatingSystem
Library           RequestsLibrary
Resource          ../../../variables/Variables.robot
Resource          ../../../libraries/BgpOperations.robot
Resource          ../../../libraries/Utils.robot
Resource          ../../../libraries/OpenStackOperations.robot
Resource          ../../../libraries/DevstackUtils.robot
Resource          ../../../libraries/VpnOperations.robot
Resource          ../../../libraries/OVSDB.robot
Resource          ../../../libraries/KarafKeywords.robot
Resource          ../../../libraries/SSHKeywords.robot
Resource          ../../../libraries/SetupUtils.robot

*** Variables ***
${AS_ID}          100
@{NETWORK_IP}     10.1.1.1/32    20.1.1.1/32    30.1.1.1/32    40.1.1.1/32    50.1.1.1/32    60.1.1.1/32    70.1.1.1/32   80.1.1.1/32    
${NUM_OF_DCGW}    3
${NUM_OF_L3VPN}    3
${START_VALUE}    0
${multipath_fun}    odl:multipath -f lu
${ERROR}          error: --maxpath range[1 - 64]
${INVALID_INPUT}    error: --maxpath range[1 - 64]
${maxpath_command}    multipath -r 10:1 -f lu -n 8 setmaxpath
${max_path_zero}    0
${max_path_min}    1
${max_path_two}    2
${max_path_six}    6
${max_path_negative}    -1
${max_path_eight}    8
${max_path_five}    5
${max_path_8}     8
${max_path_64}    64
${max_path_65}    65
${BGP_CACHE}      bgp-cache
${bgp-restart}    ./stop
${bgp-cmd}        show-bgp --cmd "ip bgp vpnv4 all"
${DISPLAY_VPN4_ALL}    show-bgp --cmd "ip bgp vpnv4 all"
${DISPLAY_NBR}    show-bgp --cmd "bgp neighbors"
${DISPLAY_NBR_SUMMARY}    show-bgp --cmd "bgp summary"
${DISPLAY_VPN}    vpnservice:l3vpn-config-show
${DIPSLAY_FIB}    fib-show
${Enable}         ENABLE
${Disable}        DISABLE
${OS_USER}        root
${ODL_MIP_IP}    ${ODL_SYSTEM_IP}
${ODL_ROUTER_ID}    ${ODL_SYSTEM_IP}
${CONFIG_START}    configure-bgp --as-num ${AS_ID} --router-id ${ODL_ROUTER_ID} -op start-bgp-server
${CONFIG_STOP}    configure-bgp --as-num ${AS_ID} --router-id ${ODL_ROUTER_ID} -op stop-bgp-server
${multipath_fun_enable}    odl:multipath -f lu enable
${multipath_fun_disable}    odl:multipath -f lu disable
${Address-Families}    vpnv4
${Multipath}      Multipath
@{VPN_NAME}       vpn1    vpn2    vpn3
@{DCGW_RD}        1:1    2:2    3:3    4:4
@{DCGW_IMPORT_RT}    22:1    22:2    22:3
@{DCGW_EXPORT_RT}    11:1    11:2    11:3
@{LABEL}          51    52    53
@{PREF_LIST}      101    102    103
@{PREF_LIST_110}    110    110    110    110    101    102    103  104
@{PREF_LIST_120}    120    120    120    120    120    120    120   120
@{PREF_LIST_90}    =    90    90    90    90    101    102  103    104
@{VPN_NAME_VAL}    vpn11    vpn22    vpn33
@{VPN_INSTANCE_ID_VAL}    12345678-1234-1234-1234-123456789301    12345678-1234-1234-1234-123456789302
...    12345678-1234-1234-1234-123456789303
@{RD}         11:1    22:2    33:3
@{MULTIPATH_RD}     11:1    22:2    33:3
@{L3VPN_RD}         ["11:1"]    ["22:2"]    ["33:3"]
@{L3VPN_IMPORT_RT}    ["11:1"]    ["11:2"]    ["11:3"]
@{L3VPN_EXPORT_RT}    ["22:1"]    ["22:2"]    ["22:3"]
${L3VPN_IMPORT_RT_12}    ["11:1","11:2"]
${L3VPN_IMPORT_RT_123}    ["11:1","11:2","11:3"]
${L3VPN_IMPORT_RT_23}    ["11:2","11:3"]
@{DCGW_IP_LIST}    ${TOOLS_SYSTEM_1_IP}    ${TOOLS_SYSTEM_2_IP}    ${TOOLS_SYSTEM_3_IP}


*** Test Cases ***

TC1 Verify CSC supports REST API/CLI for multipath configuration (enable/disable multipath)
    [Documentation]    Verify CSC supports REST API/CLI for multipath configuration (enable/disable multipath)
    Log    "Enable multipath"
    Multipath Functionality    ${Enable}
    Log    "Verify Multipath configuration"
    Verify Multipath
    Log    "Disable multipath"
    Multipath Functionality    ${Disable}
    Log    "Verify Multipath configuration"
    Verify Multipath    False

TC2 Verify CSC supports REST API/CLI for max path configuration
    [Documentation]    Verify CSC supports REST API/CLI for max path configuration
    Configure BGP Neighbor On Odl    ${NUM_OF_DCGW}
    Wait Until Keyword Succeeds    10    2    Verify BGP Neighbor On ODL    ${NUM_OF_DCGW}
    Log    "Configure BGP CLIs on each DC Gateway"
    : FOR    ${idx}    IN RANGE    0    ${NUM_OF_DCGW}
    \    Configure BGP And Add Neighbor On DCGW    ${DCGW_IP_LIST[${idx}]}    ${ODL_MIP_IP}    ${AS_ID}
    Check BGP Session On DCGW    ${NUM_OF_DCGW}
    Check BGP Session On ODL    ${NUM_OF_DCGW}
    Log    "Create Eight L3vpn on ODL"
    : FOR    ${idx}    IN RANGE    0    ${NUM_OF_DCGW}
    \    VPN Create L3VPN    name=${VPN_NAME[${idx}]}    vpnid=${VPN_INSTANCE_ID_VAL[${idx}]}    rd=${L3VPN_RD[${idx}]}
    \    ...    exportrt=${L3VPN_EXPORT_RT[${idx}]}    importrt=${L3VPN_IMPORT_RT[${idx}]}
    Wait Until Keyword Succeeds    10    2    Verify L3VPN On ODL    @{VPN_INSTANCE_ID_VAL}
    Log    "Create Eight L3vpn on Dcgateway"
    : FOR    ${idx}    IN RANGE    0    ${NUM_OF_DCGW}
    \    Create L3VPN on Dcgateway    ${DCGW_IP_LIST[${idx}]}    ${VPN_NAME[${idx}]}    ${DCGW_RD[${idx}]}    ${DCGW_IMPORT_RT[${idx}]}    ${DCGW_EXPORT_RT[${idx}]}
    #Verify L3VPN On DCGW    ${NUM_OF_DCGW}    ${VPN_NAME[${idx}]}    ${DCGW_RD[${idx}]}    ${DCGW_IMPORT_RT[${idx}]}    ${DCGW_EXPORT_RT[${idx}]}
    Check BGP Session On DCGW    ${NUM_OF_DCGW}
    Check BGP Session On ODL    ${NUM_OF_DCGW}
    Check BGP Nbr On ODL   ${NUM_OF_DCGW}
    Log    "Enable multipath"
    Multipath Functionality    ${Enable}
    Log    "Verify Multipath configuration"
    Wait Until Keyword Succeeds    10    2    Verify Multipath
    Log    "Configuring maxpath=8"
    : FOR    ${idx}    IN RANGE    0    ${NUM_OF_DCGW}
    \    Configure Maxpath    ${max_path_eight}    ${MULTIPATH_RD[${idx}]}
    Sleep    5s
    Log    "Verifying maxpath configuration"
    : FOR    ${idx}    IN RANGE    0    ${NUM_OF_DCGW}
    \    Verify Maxpath    ${max_path_eight}    ${MULTIPATH_RD[${idx}]}
    Check BGP VPNv4 Nbr On ODL   ${NUM_OF_DCGW}    False


*** Keywords ***

Start Suite
    [Documentation]
    #Create Session    default    http://${ODL_SYSTEM_IP}:${RESTCONFPORT}    auth=${AUTH}    headers=${HEADERS}
    RequestsLibrary.Create_Session    alias=default    url=http://${ODL_SYSTEM_IP}:${RESTCONFPORT}    auth=${AUTH}
    #VPN Create L3VPN    vpnid=${VPN_INSTANCE_ID_VAL[0]}    name=${VPN_NAME[0]}    rd=["100:1"]
    #...    exportrt=["100:1"]    importrt=["100:1"]
    #Log    DELETE L3VPN
    #Run Keyword And Ignore Error    VPN Delete L3VPN    vpnid=${VPN_INSTANCE_ID_VAL[0]}
    #VPN Create L3VPN    name=${VPN_NAME[0]}    vpnid=${VPN_INSTANCE_ID_VAL[0]}    rd=${RD_VAL[0]}
    #...    exportrt=${EXPORT_RT_VAL[0]}    importrt=${IMPORT_RT_VAL[0]}
    #Log    DELETE L3VPN
    #Run Keyword And Ignore Error    VPN Delete L3VPN    vpnid=${VPN_INSTANCE_ID_VAL[0]}

Suite Setup
    [Documentation]
    Log    Test Topology ::
    Topology
    Replace the below 3lines for cleanup(Openstack and testbed cleanup) with ROBOT subs going forward.
    Openstack Cleanup    ${entity_list}    ${command_list}
    Testbed Bringup Two DPN Topology CSSBE    ${DPN1_tunintf}    ${DPN2_tunintf}    ${1}
    ${resp}    Sleep    25
    Log    "STARTUP 1.1:Bring up ODL and DC-GW"
    SetupUtils.Setup_Utils_For_Setup_And_Teardown
    DevstackUtils.Devstack Suite Setup
    Create Session    session    http://${ODL_SYSTEM_IP}:${RESTCONFPORT}    auth=${AUTH}    headers=${HEADERS}
    For Community the below code is required to start Quagga on 3node Cluster ODL.For NONCBA/CEE we assume the Quagga is already running on ODL.
    : FOR    ${idx}    IN RANGE    0    ${NUM_ODL_SYSTEM}
    \    Start Quagga Processes On ODL    ${ODL_SYSTEM_IP}
    :FOR    ${index}    IN RANGE    0    1
    \     Start Quagga Processes On DCGW    ${DCGW_IP_LIST[${index}]}
    Log    "STARTUP 1.2:Security Group configuartions"
    Add Ssh Allow Rule
    Log    "STARTUP 1.3:Create network"
    Create Neutron Networks    ${Req_no_of_net}
    Log    "STARTUP 1.4:Create Subnet"
    Create Neutron Subnets    ${Req_no_of_subNet}
    Log    "STARTUP 1.5:Create Ports"
    Create Neutron Ports    ${Req_no_of_ports}
    Log    "STARTUP 1.6:Bring up 2 VM on DPN1"
    Create Nova VMs    ${Req_no_of_vms_per_dpn}    ${VM_IP_NET1}    ${VM_IP_NET2}    ${VM_IP_NET3}    ${VM_IP_NET4}    
    Wait Until Keyword Succeeds    180s  10s    Verify VMs received IP
    Set Global Variable    ${VM_IP_NET2}
    Set Global Variable    ${VM_IP_NET1}
    Set Global Variable    ${VM_IP_NET3}
    Set Global Variable    ${VM_IP_NET4}
    Log    "STARTUP 1.7:Create L3VPN"
    Create L3VPN    ${Req_no_of_L3VPN}
    Log    "STARTUP 1.8:Associate L3VPN to Network"
    Associate L3VPN To Networks    ${Req_no_of_net}
    Log    "STARTUP 1.9:Configure BGP on Controller and Quagga"
    Create BGP Config On ODL    ${NUM_OF_DCGW}
    Create BGP Config On DCGW    ${NUM_OF_DCGW}
    Log    "STARTUP 1.10 VERIFY TUNNELS BETWEEN DPNS IS UP"
    Wait Until Keyword Succeeds    60s    10s    Verify Tunnel Status as UP
    Log    "STARTUP 1.11 VERIFY FLOWS ARE PRESENT ON THE DPNS"
    Wait Until Keyword Succeeds    60s    10s    Verify Flows Are Present    ${OS_COMPUTE_1_IP}
    Wait Until Keyword Succeeds    60s    10s    Verify Flows Are Present    ${OS_COMPUTE_2_IP}
    Log    "STARTUP 1.2 VERIFY THE VM IS ACTIVE"
    :FOR    ${VM}    IN    @{VM_INSTANCES}
    \    Wait Until Keyword Succeeds    25s    5s    Verify VM Is ACTIVE    ${VM}
     The below lines commented as the DC-GW VM's are in the same host
    Log    "STARTUP 1.3 CREATE EXTERNAL TUNNEL ENDPOINT BTW ODL AND DCGW"
    Create External Tunnel Endpoint    ${NUM_OF_DCGW}
    LOG    "STARTUP 1.4 CHECK ROUTES ON QUAGGA"
    Check Routes on Quagga    ${NUM_OF_DCGW}

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
    
Pretest Check
    [Documentation]    Pre running configuration checkup
    Log To Console    "Running Test case level Pretest Configuration check"
    

Pretest Cleanup
    [Documentation]    Test Case Cleanup
    Log    ***********************************Pretest Cleanup ********************************
    #Pre Cleanup Configuration Check on Odl Quagga    ${ODL_QUAGGA_IP}
    RequestsLibrary.Create_Session    alias=session    url=http://${ODL_SYSTEM_IP}:${RESTCONFPORT}    auth=${AUTH} 
    Log    "Pre Cleanup Check For Dcgateway"
    : FOR    ${idx}    IN RANGE    0    ${NUM_OF_DCGW}
    \    ${output}    Pre Cleanup Configuration Check on Dcgateway    ${DCGW_IP_LIST[${idx}]}
    Delete Bgp Neighbor On Odl    ${NUM_OF_DCGW}
        Log    "Configuring maxpath=1"
    : FOR    ${idx}    IN RANGE    0    ${NUM_OF_DCGW}
    \    Configure Maxpath    ${max_path_min}    ${MULTIPATH_RD[${idx}]}
    Delete L3VPN    ${NUM_OF_L3VPN}
    Log    "Disabling multipath"
    Multipath Functionality    ${Disable}
    : FOR    ${idx}    IN RANGE    0    ${NUM_OF_DCGW}
    \    ${output}    Delete Dcgateway Configuration    ${DCGW_IP_LIST[${idx}]}

Pre Cleanup Configuration Check on Dcgateway
    [Arguments]    ${dcgw_ip}
    [Documentation]    Execute set of command on Dcgateway
    Create Quagga Telnet Session    ${dcgw_ip}    bgpd    sdncbgpc
    ${output} =    Write Commands Until Expected Prompt    show running-config    ${DEFAULT_LINUX_PROMPT_STRICT}
    Log    ${output}
    SSHLibrary.Close Connection

Pre Cleanup Configuration Check on Odl Quagga
    [Arguments]    ${odl_ip}    ${ODL_UNAME}=root    ${ODL_PWD}=admin123
    [Documentation]    Execute set of command on Dcgateway
    Create ODL Quagga Telnet Session    ${odl_ip}
    ${output} =    Write Commands Until Expected Prompt    show running-config    ${DEFAULT_LINUX_PROMPT_STRICT}
    Log    ${output}    
    SSHLibrary.Close Connection
    Issue Command On Karaf Console    ${DISPLAY_VPN}

Execute Show Running Command On Quagga
    [Arguments]    ${odl_ip}
    Create ODL Quagga Telnet Session    ${odl_ip}
    ${output} =    Write Commands Until Expected Prompt    show running-config    ${DEFAULT_LINUX_PROMPT_STRICT}
    Log    ${output}    
    SSHLibrary.Close Connection
    [Return]    ${output}

#Verify Maxpath On Odl Quagga
#    [Arguments]    ${odl_ip}    ${vpn_name}    ${max_path}
#    [Documentation]    Execute set of command On Odl Quagga
#    ${output}=    Execute Show Running Command On Quagga    ${odl_ip}
#    Log    ${output}
#    Should Match Regexp    ${output}    (?m)\\S*vrf\\s*${vpn_name}\\s*rd\\s*\\d*:\\d*\\s*rt\\s*import\\s*\\d*:\\d*\\s*rt\\s*export\\s*\\d*:\\d*\\s*maximum-path\\s*${max_path}\\s*
#    [Return]    ${output}
#
#Configure Maxpath on Odl Quagga
#    [Arguments]    ${odl_ip}    ${vpn_name}    ${max_path}
#    [Documentation]    Execute set of command on Dcgateway
#    Create ODL Quagga Telnet Session    ${odl_ip}
#    ${output} =    SSHLibrary.Write    configure terminal
#    ${output} =    SSHLibrary.Read Until    \#
#    ${output} =    SSHLibrary.Write    router bgp ${AS_ID}
#    ${output} =    SSHLibrary.Read Until    \#
#    ${output} =    SSHLibrary.Write    vrf ${vpn_name}
#    ${output} =    SSHLibrary.Read Until    \#
#    ${output} =    SSHLibrary.Write    maximum-path ${max_path}
#    ${output} =    SSHLibrary.Read Until    \#
#    ${output} =    SSHLibrary.Write    exit
#    ${output} =    SSHLibrary.Read Until    \#
#    ${output} =    SSHLibrary.Write    exit
#    ${output} =    SSHLibrary.Read Until    \#
#    SSHLibrary.Close Connection
#
#Configure Global Maxpath on Odl Quagga
#    [Arguments]    ${odl_ip}    ${max_path}
#    [Documentation]    Execute set of command on Odl Quagga
#    Create ODL Quagga Telnet Session    ${odl_ip}
#    ${output} =    SSHLibrary.Write    configure terminal
#    ${output} =    SSHLibrary.Read Until    \#
#    ${output} =    SSHLibrary.Write    router bgp ${AS_ID}
#    ${output} =    SSHLibrary.Read Until    \#
#    ${output} =    SSHLibrary.Write    maximum-path ${max_path}
#    ${output} =    SSHLibrary.Read Until    \#
#    ${output} =    SSHLibrary.Write    maximum-path ibgp ${max_path}
#    ${output} =    SSHLibrary.Read Until    \#
#    ${output} =    SSHLibrary.Write    address-family vpnv4
#    ${output} =    SSHLibrary.Read Until    \#
#    ${output} =    SSHLibrary.Write    maximum-path ${max_path}
#    ${output} =    SSHLibrary.Read Until    \#
#    ${output} =    SSHLibrary.Write    maximum-path ibgp ${max_path}
#    ${output} =    SSHLibrary.Read Until    \#
#    ${output} =    SSHLibrary.Write    exit
#    ${output} =    SSHLibrary.Read Until    \#
#    ${output} =    SSHLibrary.Write    exit
#    ${output} =    SSHLibrary.Read Until    \#
#    SSHLibrary.Close Connection
#
#Disable Maxpath on Odl Quagga
#    [Arguments]    ${odl_ip}    ${vpn_name}
#    [Documentation]    Execute set of command on Dcgateway
#    Create ODL Quagga Telnet Session    ${odl_ip}
#    ${output} =    SSHLibrary.Write    configure terminal
#    ${output} =    SSHLibrary.Read Until    \#
#    ${output} =    SSHLibrary.Write    router bgp ${AS_ID}
#    ${output} =    SSHLibrary.Read Until    \#
#    ${output} =    SSHLibrary.Write    vrf ${vpn_name}
#    ${output} =    SSHLibrary.Read Until    \#
#    ${output} =    SSHLibrary.Write    no maximum-path
#    ${output} =    SSHLibrary.Read Until    \#
#    ${output} =    SSHLibrary.Write    exit
#    ${output} =    SSHLibrary.Read Until    \#
#    ${output} =    SSHLibrary.Write    exit
#    ${output} =    SSHLibrary.Read Until    \#
#    SSHLibrary.Close Connection
#
#Clear Configuration On Odl Quagga
#    [Arguments]    ${odl_ip}
#    [Documentation]    Execute set of command on Dcgateway
#    Create ODL Quagga Telnet Session    ${odl_ip}
#    ${output} =    SSHLibrary.Write    clear ip bgp *
#    ${output} =    SSHLibrary.Read Until    \#
#    SSHLibrary.Close Connection
#
#Clear Configuration On Dcgateway
#    [Arguments]    ${dcgw_ip}
#    [Documentation]    Execute set of command on Dcgateway
#    Create Dcgateway Telnet Session    ${dcgw_ip}
#    ${output} =    SSHLibrary.Write    clear ip bgp *
#    ${output} =    SSHLibrary.Read Until    \#
#    SSHLibrary.Write    exit
#    SSHLibrary.Read Until    \#
#    SSHLibrary.Close Connection
#    [Return]    ${output}
#
Create ODL Quagga Telnet Session
    [Arguments]    ${odl_quagga_ip}    ${ODL_UNAME}=root    ${ODL_PWD}=admin123
    [Documentation]    Create telnet session for ODL Quagga
    ${conn_id}=    SSHLibrary.Open Connection    ${odl_quagga_ip}
    Login    ${ODL_UNAME}    ${ODL_PWD}
    Switch Connection    ${conn_id}
    ${output} =    SSHLibrary.Write    sudo -i
    ${output} =    SSHLibrary.Read Until    root
    ${output} =    SSHLibrary.Write    ${ODL_UNAME}
    ${output} =    SSHLibrary.Write    telnet localhost 2605
    ${output} =    Builtin.Run Keyword and Ignore Error    Read Until    assword:
    ${output} =    SSHLibrary.Write    sdncbgpc
    ${output} =    SSHLibrary.Read Until    \#
    ${output} =    SSHLibrary.Write    terminal length 0
    ${output} =    SSHLibrary.Read Until    \#

Configure BGP And Add Neighbor On DCGW
    [Arguments]    ${dcgw_ip}    ${odl_ip}    ${as_number}
    [Documentation]    Configure BGP and add neighbor on the dcgw
    Create Quagga Telnet Session    ${dcgw_ip}    bgpd    sdncbgpc
    Write Commands Until Expected Prompt    configure terminal    ${DEFAULT_LINUX_PROMPT_STRICT}
    Write Commands Until Expected Prompt    router bgp ${AS_ID}    ${DEFAULT_LINUX_PROMPT_STRICT}
    Write Commands Until Expected Prompt    bgp router-id ${dcgw_ip}    ${DEFAULT_LINUX_PROMPT_STRICT}
    Write Commands Until Expected Prompt    no bgp log-neighbor-changes    ${DEFAULT_LINUX_PROMPT_STRICT}
    Write Commands Until Expected Prompt    bgp graceful-restart stalepath-time 90    ${DEFAULT_LINUX_PROMPT_STRICT}
    Write Commands Until Expected Prompt    bgp graceful-restart stalepath-time 90    ${DEFAULT_LINUX_PROMPT_STRICT}
    Write Commands Until Expected Prompt    bgp graceful-restart restart-time 900    ${DEFAULT_LINUX_PROMPT_STRICT}
    Write Commands Until Expected Prompt    bgp graceful-restart    ${DEFAULT_LINUX_PROMPT_STRICT}
    Write Commands Until Expected Prompt    bgp graceful-restart preserve-fw-state    ${DEFAULT_LINUX_PROMPT_STRICT}
    Write Commands Until Expected Prompt    bgp bestpath as-path multipath-relax    ${DEFAULT_LINUX_PROMPT_STRICT}
    Write Commands Until Expected Prompt    neighbor ${odl_ip} send-remote-as ${as_number}    ${DEFAULT_LINUX_PROMPT_STRICT}
    Write Commands Until Expected Prompt    terminal length 0    ${DEFAULT_LINUX_PROMPT_STRICT}
    Write Commands Until Expected Prompt    neighbor ${odl_ip} update-source ${dcgw_ip}    ${DEFAULT_LINUX_PROMPT_STRICT}
    Write Commands Until Expected Prompt    no neighbor ${odl_ip} activate    ${DEFAULT_LINUX_PROMPT_STRICT}
    Write Commands Until Expected Prompt    address-family vpnv4    ${DEFAULT_LINUX_PROMPT_STRICT}
    Write Commands Until Expected Prompt    neighbor ${odl_ip} activate    ${DEFAULT_LINUX_PROMPT_STRICT}
    Write Commands Until Expected Prompt    neighbor ${odl_ip} attribute-unchanged next-hop    ${DEFAULT_LINUX_PROMPT_STRICT}
    Write Commands Until Expected Prompt    address-family ipv6    ${DEFAULT_LINUX_PROMPT_STRICT}
    Write Commands Until Expected Prompt    exit-address-family    ${DEFAULT_LINUX_PROMPT_STRICT}
    Write Commands Until Expected Prompt    exit    ${DEFAULT_LINUX_PROMPT_STRICT}
    ${output} =    Write Commands Until Expected Prompt    show running-config    ${DEFAULT_LINUX_PROMPT_STRICT}
    Log    ${output}
    Write Commands Until Expected Prompt    exit    ${DEFAULT_LINUX_PROMPT_STRICT}
    SSHLibrary.Close Connection
    Sleep    5s
    [Return]    ${output}

Create L3VPN on Dcgateway
    [Arguments]    ${dcgw_ip}    ${vpn_name}    ${rd}    ${import_rt}    ${export_rt}
    [Documentation]    Create L3VPN on Dcgateway
    Create Quagga Telnet Session    ${dcgw_ip}    bgpd    sdncbgpc
    ${output} =    SSHLibrary.Write    config t
    ${output} =    SSHLibrary.Read Until    \#
    ${output} =    SSHLibrary.Write    router bgp ${AS_ID}
    ${output} =    SSHLibrary.Read Until    \#
    ${output} =    SSHLibrary.Write    vrf ${vpn_name}
    ${output} =    SSHLibrary.Read Until    \#
    ${output} =    SSHLibrary.Write    rd ${rd}
    ${output} =    SSHLibrary.Read Until    \#
    ${output} =    SSHLibrary.Write    rt export ${export_rt}
    ${output} =    SSHLibrary.Read Until    \#
    ${output} =    SSHLibrary.Write    rt import ${import_rt}
    ${output} =    SSHLibrary.Read Until    \#
    ${output} =    SSHLibrary.Write    exit
    ${output} =    SSHLibrary.Read Until    \#
    SSHLibrary.Write    exit
    SSHLibrary.Read Until    \#
    SSHLibrary.Close Connection
    [Return]    ${output}

Create Multi VPN on Dcgateway
    [Arguments]    ${dcgw_ip}    ${vpn_name}    ${rd}    ${import_rt}    ${export_rt}    ${dc_count}
    ...    ${start}=0
    [Documentation]    Create Multi VPN on Dcgateway
    : FOR    ${idx}    IN RANGE    ${start}    ${dc_count}
    \    ${output}    Create L3VPN on Dcgateway    ${DCGW_IP_LIST[${idx}]}    ${vpn_name}    ${rd}    ${DCGW_IMPORT_RT[0]}    ${DCGW_EXPORT_RT[0]}
    [Return]    ${output}

Configure BGP Preference
    [Arguments]    ${dcgw_ip}    ${preference}
    [Documentation]    Configure BGP Preference
    Create Quagga Telnet Session    ${dcgw_ip}    bgpd    sdncbgpc
    ${output} =    SSHLibrary.Write    config t
    ${output} =    SSHLibrary.Read Until    \#
    ${output} =    SSHLibrary.Write    router bgp ${AS_ID}
    ${output} =    SSHLibrary.Read Until    \#
    ${output} =    SSHLibrary.Write    bgp default local-preference ${preference}
    ${output} =    SSHLibrary.Read Until    \#
    ${outpur} =    SSHLibrary.Write    exit
    ${output} =    SSHLibrary.Read Until    \#
    ${output} =    SSHLibrary.Write    do clear ip bgp *
    ${output} =    SSHLibrary.Read Until    \#
    Sleep    10s
    SSHLibrary.Write    exit
    SSHLibrary.Read Until    \#
    SSHLibrary.Close Connection
    [Return]    ${output}

Add Routes
    [Arguments]    ${dcgw_ip}    ${rd}    ${network_ip}    ${label}
    [Documentation]    Add the Routes to DCGW
    Create Quagga Telnet Session    ${dcgw_ip}    bgpd    sdncbgpc
    ${output} =    SSHLibrary.Write    config t
    ${output} =    SSHLibrary.Read Until    \#
    ${output} =    SSHLibrary.Write    router bgp ${AS_ID}
    ${output} =    SSHLibrary.Read Until    \#
    ${output} =    SSHLibrary.Write    address-family vpnv4
    ${output} =    SSHLibrary.Read Until    \#
    ${output} =    SSHLibrary.Write    network ${network_ip} rd ${rd} tag ${label}
    ${output} =    SSHLibrary.Read Until    \#
    ${output} =    SSHLibrary.Write    exit
    ${output} =    SSHLibrary.Read Until    \#
    ${output} =    SSHLibrary.Write    exit
    ${output} =    SSHLibrary.Read Until    \#
    SSHLibrary.Close Connection
    [Return]    ${output}

Delete Routes
    [Arguments]    ${dcgw_ip}    ${rd}    ${network_ip}    ${label}
    [Documentation]    Delete the Routes from DCGW
    Create Quagga Telnet Session    ${dcgw_ip}    bgpd    sdncbgpc
    ${output} =    SSHLibrary.Write    config ter
    ${output} =    SSHLibrary.Read Until    \#
    ${output} =    SSHLibrary.Write    router bgp ${AS_ID}
    ${output} =    SSHLibrary.Read Until    \#
    ${output} =    SSHLibrary.Write    address-family vpnv4
    ${output} =    SSHLibrary.Read Until    \#
    ${output} =    SSHLibrary.Write    no network ${network_ip} rd ${rd} tag ${label}
    ${output} =    SSHLibrary.Read Until    \#
    SSHLibrary.Write    exit
    SSHLibrary.Read Until    \#
    SSHLibrary.Write    exit
    SSHLibrary.Read Until    \#
    SSHLibrary.Close Connection
    
Create BGP Config On DCGW    
    [Arguments]    ${NUM_OF_DC_GW}    
    [Documentation]    Configure BGP Config on DCGW    
    : FOR    ${index}    IN RANGE    0    ${NUM_OF_DC_GW}    ${LOOPBACK_IP}
    \    Add Loopback Interface On DCGW    ${DCGW_IP_LIST[${index}]}    lo    ${LOOPBACK_IP[${index}]}
    ${output} =    Execute Show Command On Quagga    ${DCGW_IP_LIST[${index}]}    show running-config    
    Log    ${output}    
    ${output} =    Wait Until Keyword Succeeds    60s    10s    Verify BGP Neighbor Status On Quagga    ${DCGW_IP_LIST[${index}]}    ${ODL_MIP_IP}
    Log    ${output}    
    ${output1} =    Execute Show Command On Quagga    ${DCGW_IP_LIST[${index}]}    sh ip bgp vpnv4 all ${DCGW_RD[${index}]}    
    Log    ${output1}    
    Should Contain    ${output1}    ${LOOPBACK_IP[${index}]}

Check Routes on Quagga
    [Arguments]    ${NUM_OF_DC_GW}    ${additional_args}=${EMPTY}    ${verbose}=TRUE
    [Documentation]    Check for Routes on Quagga
    : FOR    ${index}    IN RANGE    0    ${NUM_OF_DC_GW}
    \    ${output} =    Execute Show Command On quagga    ${DCGW_IP_LIST[${index}]}    show ip bgp vrf ${DCGW_RD[${index}]}
    \    Log    ${output}

Multipath Functionality
    [Arguments]    ${STATE}    ${additional_args}=${EMPTY}    ${verbose}=TRUE
    [Documentation]    Enabling/Disabling Multipath
    Run Keyword If    '${STATE}'=='ENABLE'    MULTION
    ...    ELSE    MULTIOFF

MULTION
    [Documentation]    Enabling Multipath
    ${PASSED}    ConvertToInteger    0
    ${output}=    Issue_Command_On_Karaf_Console    ${multipath_fun_enable}
    Log    ${output}
    Should Not Contain    ${output}    ${ERROR}

MULTIOFF
    [Documentation]    Disabling Multipath
    ${PASSED}    ConvertToInteger    0
    ${output}=    Issue_Command_On_Karaf_Console    ${multipath_fun_disable}
    Log    ${output}
    Should Not Contain    ${output}    ${ERROR}

Configure Maxpath
    [Arguments]    ${maxpath}    ${rd}    ${additional_args}=${EMPTY}    ${verbose}=TRUE
    [Documentation]    Set Maxpath
    ${PASSED}    ConvertToInteger    0
    ${maxpath_command}    Catenate    multipath -r    ${rd} -f lu -n ${maxpath} setmaxpath
    ${output}=    Issue_Command_On_Karaf_Console    ${maxpath_command}
    Log    ${output}
    Run Keyword If    0 < ${maxpath} < 65    Should Not Contain    ${output}    ${ERROR}
    ...    ELSE    Should Contain    ${output}    ${INVALID_INPUT}

Verify Multipath
    [Arguments]    ${Enable}=True
    [Documentation]    Verify Multipath is Set properly
    ${PASSED}    ConvertToInteger    0
    ${output}=    Issue_Command_On_Karaf_Console    ${BGP_CACHE}
    Run Keyword If    ${Enable}==True    Should Contain    ${output}    ${Address-Families}
    ...    ELSE    Should Not Contain    ${output}    ${Address-Families}
    [Return]    ${output}

Verify Maxpath
    [Arguments]    ${maxpath}    ${rd}    ${additional_args}=${EMPTY}    ${verbose}=TRUE
    [Documentation]    Verify Maxpath is Set Properly
    ${PASSED}    ConvertToInteger    0
    ${output}=    Issue_Command_On_Karaf_Console    ${BGP_CACHE}
    Log    ${output}
    Should Match Regexp    ${output}    ${rd}\\s*${maxpath}
    #Should Contain    ${output}    ${maxpath}
    #Should Contain    ${output}    ${rd}
    Should Not Contain    ${output}    ${ERROR}

Verify Maxpath For Invalid Input
    [Arguments]    ${rd}    ${maxpath}
    [Documentation]    Verify Maxpath is Set Properly
    ${PASSED}    ConvertToInteger    0
    ${output}=    Issue_Command_On_Karaf_Console    ${BGP_CACHE}
    Log    ${output}
    Should Not Match Regexp    ${output}    ${rd}\\s*${maxpath}

TC RESULT
    [Arguments]    ${RESULT1}    ${RESULT2}    ${additional_args}=${EMPTY}    ${verbose}=TRUE
    [Documentation]    Check whether all checkpoints are passed
    ${FINAL_RET}    =    Catenate    ${RESULT1}    ${RESULT2}
    Run Keyword If    '${FINAL_RET}' != '0'    Log To Console    "PASSED"
    ...    ELSE    Log To Console    "FAILED"

Create L3VPN
    [Arguments]    ${vpn_name}    ${vpn_instance_id}    ${rd}    ${import_rt}    ${export_rt}    ${verbose}=TRUE
    [Documentation]    Create L3vpn
    ${output} =    set variable    configure-l3vpn -op create-l3-vpn -n ${vpn_name} -vid ${vpn_instance_id} -rd ${rd} -irt ${import_rt} -ert ${export_rt}
    ${OP1} =    Issue_Command_On_Karaf_Console    ${output}
    Log    ${OP1}
    ${output1} =    Issue_Command_On_Karaf_Console    ${BGP_CACHE}
    Log    ${output1}

Delete Bgp Neighbor On Odl
    [Arguments]    ${additional_args}=${EMPTY}    ${verbose}=TRUE
    [Documentation]    Delete bgp config on odl
    : FOR    ${index}    IN RANGE    0    ${NUM_OF_DC_GW}
    \    ${output} =    set variable    configure-bgp -op delete-neighbor --ip ${DCGW_IP_LIST[${index}]} --as-num ${AS_ID} --use-source-ip ${ODL_MIP_IP}
    \    ${OP1} =    Issue_Command_On_Karaf_Console    ${output}
    \    Log    ${OP1}
    \    ${output1} =    Issue_Command_On_Karaf_Console    ${BGP_CACHE}
    \    Log    ${output1}

Configure BGP Neighbor On Odl
    [Arguments]    ${dcgw_count}    ${start}=${START_VALUE}
    [Documentation]    Create bgp neighbor config on odl
    : FOR    ${index}    IN RANGE    ${start}    ${dcgw_count}
    \    ${add_nbr} =    set variable    configure-bgp -op add-neighbor --ip ${DCGW_IP_LIST[${index}]} --as-num ${AS_ID} --use-source-ip ${ODL_MIP_IP}
    \    ${output}=    Issue_Command_On_Karaf_Console    ${add_nbr}
    \    Log    ${output}
    \    Sleep    5s

Delete L3VPN
    [Arguments]    ${l3vpn_count}    ${start}=${START_VALUE}
    [Documentation]    Delete bgp l3vpn config on odl
    : FOR    ${idx}    IN RANGE    ${start}    ${l3vpn_count}
    \    Run Keyword And Ignore Error    VPN Delete L3VPN     vpnid=${VPN_INSTANCE_ID_VAL[${idx}]}

Delete Dcgateway Configuration
    [Arguments]    ${dcgw_ip}
    [Documentation]    Execute set of command on Dcgateway
    Create Quagga Telnet Session    ${dcgw_ip}    bgpd    sdncbgpc
    ${output} =    SSHLibrary.Write    config t
    ${output} =    SSHLibrary.Read Until    \#
    ${output} =    SSHLibrary.Write    no router bgp ${AS_ID}
    ${output} =    SSHLibrary.Read Until    \#
    SSHLibrary.Write    exit
    SSHLibrary.Read Until    \#
    SSHLibrary.Close Connection
    [Return]    ${output}

Create bgp config on odl
    [Arguments]    ${NUM_OF_DCGW}    ${additional_args}=${EMPTY}
    [Documentation]    Create bgp config on odl
    : FOR    ${index}    IN RANGE    0    ${NUM_OF_DCGW}
    \    ${output} =    set variable    configure-bgp -op add-neighbor --ip ${DCGW_IP_LIST[${index}]} --as-num ${AS_ID} --use-source-ip ${ODL_MIP_IP}
    \    ${OP1} =    Issue_Command_On_Karaf_Console    ${output}
    \    Log    ${OP1}
    \    ${output1} =    Issue_Command_On_Karaf_Console    ${BGP_CACHE}
    \    Log    ${output1}
    \    Sleep    10s

Delete bgp nbr on odl
    [Arguments]    ${nbr_ip}    ${additional_args}=${EMPTY}
    [Documentation]    Delete bgp neighbors on odl
    ${output} =    set variable    configure-bgp -op delete-neighbor --ip ${nbr_ip} --as-num ${AS_ID} --use-source-ip ${ODL_MIP_IP}
    ${OP1} =    Issue_Command_On_Karaf_Console    ${output}
    Log    ${OP1}

Verify BGP Neighbor On ODL
    [Arguments]    ${dcgw_count}    ${start}=${START_VALUE}
    [Documentation]    Verify BGP Neighbor on ODL
    ${output}=    Issue Command On Karaf Console    ${BGP_CACHE}
    : FOR    ${index}    IN RANGE    ${start}    ${dcgw_count}
    \    Should Contain    ${output}    ${DCGW_IP_LIST[${index}]}

Verify L3VPN On ODL
    [Arguments]    @{vpn_instance_list}
    [Documentation]    Verify BGP Neighbor on ODL
    : FOR    ${vpn_instance}    IN     @{vpn_instance_list}
    \    ${resp}    VPN Get L3VPN     vpnid=${vpn_instance}
    \    Should Contain    ${resp}    ${vpn_instance}

Verify L3VPN On DCGW
    [Arguments]    ${dcgw_count}    ${vpn_name}    ${rd}    ${import_rt}    ${export_rt}    ${start}=${START_VALUE}
    [Documentation]    Execute set of command on Dcgateway
    : FOR    ${index}    IN RANGE    ${start}    ${dcgw_count}
    \    ${output} =    Execute Show Command On Quagga    ${DCGW_IP_LIST[${index}]}    show running-config
    \    Log    ${output
    \    Should Contain     ${output}     vrf ${vpn_name}
    \    Should Contain     ${output}     rd ${rd}
    \    Should Contain     ${output}     rt import ${import_rt}
    \    Should Contain     ${output}     rt export ${export_rt}

Check BGP Session On ODL
    [Arguments]    ${dcgw_count}    ${start}=${START_VALUE}
    [Documentation]    Check BGP Session On ODL
    : FOR    ${index}    IN RANGE    ${start}    ${dcgw_count}
    \    ${cmd}    Set Variable    show-bgp --cmd "bgp neighbors ${DCGW_IP_LIST[${index}]}"
    \    ${output}=    Issue Command On Karaf Console    ${cmd}
    \    Log    ${output}
    \    Should Contain    ${output}    BGP state = Established
    [Return]    ${output}
         
Check BGP Nbr On ODL
    [Arguments]    ${dcgw_count}    ${start}=${START_VALUE}
    [Documentation]    Check BGP Session On ODL
    ${output}=    Issue Command On Karaf Console    ${DISPLAY_NBR_SUMMARY}
    : FOR    ${index}    IN RANGE    ${start}    ${dcgw_count}
    \    Should Contain     ${output}     ${DCGW_IP_LIST[${index}]}
    [Return]    ${output}

Check BGP VPNv4 Nbr On ODL
    [Arguments]    ${dcgw_count}    ${flag}=True     ${start}=${START_VALUE}
    [Documentation]    Check BGP Session On ODL
    ${output}=    Issue Command On Karaf Console    ${DISPLAY_VPN4_ALL}
    : FOR    ${index}    IN RANGE    ${start}    ${dcgw_count}
    \    Run Keyword If    ${flag}==True    Should Contain     ${output}     ${DCGW_IP_LIST[${index}]}
    \    ...    ELSE    Should Not Contain     ${output}     ${DCGW_IP_LIST[${index}]}
    [Return]    ${output}


Check BGP Nbr On DCGW
    [Arguments]    ${dcgw_count}    ${start}=${START_VALUE}
    [Documentation]    Verify BGP Config on DCGW
    : FOR    ${index}    IN RANGE    ${start}    ${dcgw_count}
    \    ${output} =    Execute Show Command On Quagga    ${DCGW_IP_LIST[${index}]}    show ip bgp vpnv4 all
    \    Log    ${output}
    \    Should Contain    ${output}    ${ODL_MIP_IP}
    [Return]    ${output}

Check BGP Session On ODL for karaf restart
    [Arguments]    ${additional_args}=${EMPTY}    ${verbose}=TRUE
    [Documentation]    Check BGP Session are UP
    ${output3}=    Issue Command On Karaf Console    ${bgp-restart}
    Log    ${output3}

Check BGP Session On DCGW
    [Arguments]    ${dcgw_count}    ${start}=${START_VALUE}
    [Documentation]    Verify BGP Config on DCGW
    : FOR    ${index}    IN RANGE    ${start}    ${dcgw_count}
    \    ${output} =    Execute Show Command On Quagga    ${DCGW_IP_LIST[${index}]}    show bgp neighbors
    \    Log    ${output}
    \    Wait Until Keyword Succeeds    60s    10s    Verify BGP Neighbor Status On Quagga    ${DCGW_IP_LIST[${index}]}    ${ODL_MIP_IP}

Verify VPN Config
    [Arguments]    ${vpn_id}    ${rd}    ${no_of_vpn_config}    ${additional_args}=${EMPTY}    ${verbose}=TRUE
    [Documentation]    Check VPN Session are configured on ODL
    ${output}=    Issue Command On Karaf Console    ${vpn-session}
    Log    ${output}
    Should Contain    ${output}    ${vpn_id}
    Should Contain    ${output}    ${rd}

Check FIB EACH DC-GW
    [Arguments]    ${additional_args}=${EMPTY}    ${verbose}=TRUE
    ${output}=    Issue Command On Karaf Console    ${fib-session}
    Log    ${output}
    : FOR    ${index}    IN RANGE    0    ${NUM_OF_DC_GW}
    \    ${result}    Get Lines Containing String    ${output}    ${DCGW_IP_LIST[${index}]}
    \    ${DCGW_Fib_Routes[$index]}    Get Line Count    ${result}
    \    Log    ${DCGW_Fib_Routes[$index]}
    [Return]    @{DCGW_Fib_Routes}

Verify Routing Entry
    [Arguments]    ${rd}    ${prefix}    ${no_of_times}
    [Documentation]    Get the Route entry for specific RD
    ${output}=    Issue Command On Karaf Console    show-bgp --cmd "ip bgp vrf ${rd}"
    Should Contain X Times    ${output}    ${prefix}    ${no_of_times}    msg="Routing table does not contain ${prefix} prefix ${no_of_times} times"

Verify FIB Entry
    [Arguments]    ${prefix}    ${no_of_times}
    [Documentation]    Check FIB
    ${output}=    Issue Command On Karaf Console    ${DIPSLAY_FIB}
    Should Contain X Times    ${output}    ${prefix}    ${no_of_times}    msg="FIB table does not contain ${prefix} prefix ${no_of_times} times"

Verify Route Entry With Nexthop
    [Arguments]    ${rd}    ${prefix}    ${dcgw_count}    ${start}=${START_VALUE}
    [Documentation]    Verification of routes entry with correct nexthop
    ${output}=    Issue Command On Karaf Console    ${DIPSLAY_FIB}
    : FOR    ${index}    IN RANGE    ${start}    ${dcgw_count} 
    \    Log    Output String should contain \\s*${prefix}\\s*${DCGW_IP_LIST[${index}]} in FIB entry
    \    Should Match Regexp    ${output}    \\s*${prefix}\\s*${DCGW_IP_LIST[${index}]}
    \    ...    msg="FIB table does not contain ${DCGW_IP_LIST[${index}]} for ${prefix} prefix "

Verify Leaking Route Across VPNs
    [Arguments]    ${rd}    @{nexthop_list}
    [Documentation]    Verification of best routes in Routing table at ODL
    ${output}=    Issue Command On Karaf Console    show-bgp --cmd "ip bgp vrf ${rd}"
    : FOR    ${nexthop}    IN    @{nexthop_list}
    \    Should Not Contain    ${output}    ${nexthop}

Verify Best Route In RIB
    [Arguments]    ${output_str}    ${rd}    ${prefix}    ${nexthop}    ${best}=\\*>i
    [Documentation]    Verification of best routes in Routing table at ODL
    Log    Output string should match \\s*${best}${prefix}\\s*${nexthop} entry in RIB entry
    Should Match Regexp    ${output_str}    \\s*${best}${prefix}\\s*${nexthop}
    [Return]    ${output_str}

Verify Equal Route In RIB
    [Arguments]    ${output_str}    ${rd}    ${prefix}    ${nexthop}    ${equal}=\\*=i
    [Documentation]    Verification of best routes in Routing table at ODL
    Log    Output string should match \\s*${equal}${prefix}\\s*${nexthop} entry in RIB entry
    Should Match Regexp    ${output_str}    \\s*${equal}${prefix}\\s*${nexthop}
    [Return]    ${output_str}

Check Routes on DC_GW
    [Arguments]    ${NUM_OF_DC_GW}    ${additional_args}=${EMPTY}    ${verbose}=TRUE
    [Documentation]    Verify the routes on DC_GW
    : FOR    ${index}    IN RANGE    0    ${NUM_OF_DC_GW}
    \    ${output1} =    Execute Show Command On Quagga    ${DCGW_IP_LIST[${index}]}    show ip bgp vpnv4 all
    \    Log    ${output1}
    \    Should Contain    ${output1}    ${LOOPBACK_IP[${index}]}

Configure BGP parameters
    [Arguments]    ${dcgw_ip}    ${as_id}    ${local-preference}    ${additional_args}=${EMPTY}    ${verbose}=TRUE
    [Documentation]    Configure BGP Parameters
    Create Quagga Telnet Session    ${dcgw_ip}    2605    sdncbgpc
    Execute Command On Quagga Telnet Session    configure terminal
    Execute Command On Quagga Telnet Session    router bgp ${as_id}
    Execute Command On Quagga Telnet Session    bgp default local-preference ${local-preference}
    Execute Command On Quagga Telnet Session    end
    ${output} =    Execute Command On Quagga Telnet Session    show running-config
    Log    ${output}
    Execute Command On Quagga Telnet Session    exit

Trigger ODL Reboot
    [Arguments]    ${CtrlIp}    ${additional_args}=${EMPTY}    ${verbose}=TRUE
    [Documentation]    Trigger ODL Reboot
    SSHLibrary.Open Connection    ${CtrlIp}
    Set Client Configuration    prompt=#
    SHLibrary.Login    root    admin123
    Write Commands Until Prompt    reboot
    Sleep    5
    SSHLibrary.Close Connection

Reconfigure DC-GW after Reboot
    [Arguments]    ${dcgw_ip}    ${as_id}    ${router_id}    ${neighbor_ip}    ${vrf_name}    ${rd}
    ...    ${loopback_ip}
    [Documentation]    Reconfigure DC-GW after Reboot
    Create Quagga Telnet Session    ${dcgw_ip}    2605    sdncbgpc
    Execute Command On Quagga Telnet Session    configure terminal
    Execute Command On Quagga Telnet Session    router bgp ${as_id}
    Execute Command On Quagga Telnet Session    bgp router-id ${router_id}
    Execute Command On Quagga Telnet Session    bgp default local-preference 200
    Execute Command On Quagga Telnet Session    redistribute static
    Execute Command On Quagga Telnet Session    redistribute connected
    Execute Command On Quagga Telnet Session    neighbor ${neighbor_ip} send-remote-as ${as_id}
    Execute Command On Quagga Telnet Session    vrf ${vrf_name}
    Execute Command On Quagga Telnet Session    rd ${rd}
    Execute Command On Quagga Telnet Session    rt import ${rd}
    Execute Command On Quagga Telnet Session    rt export ${rd}
    Execute Command On Quagga Telnet Session    exit
    Execute Command On Quagga Telnet Session    address-family vpnv4 unicast
    Execute Command On Quagga Telnet Session    network ${loopback_ip}/32 rd ${rd} tag ${as_id}
    Execute Command On Quagga Telnet Session    neighbor ${neighbor_ip} activate
    Execute Command On Quagga Telnet Session    end
    ${output} =    Execute Command On Quagga Telnet Session    show running-config
    Log    ${output}
    Execute Command On Quagga Telnet Session    exit

Back-to-Back route flaps
    [Arguments]    ${DEVICE_IP}    ${additional_args}=${EMPTY}    ${verbose}=TRUE
    [Documentation]    Back to Back Route Flap
    : FOR    ${index}    IN RANGE    0    5
    /    Run Keyword If    "${OPTION}" == "clear_bgp_css"    Run Keyword And Ignore Error    Kill Quagga Processes On ODL    ${DEVICE_IP}
    /    ...
    ...    ELSE IF    "${OPTION}" == "clear_bgp_dc_gw"    Kill BGP process on DC_GW    ${DEVICE_IP}
    /    ...
    ...    ELSE IF    "${OPTION}" == "odl_unconfigure_reconfigure"    Unconfigure Reconfigure ODL    ${DEVICE_IP}
    /    ...
    ...    ELSE IF    "${OPTION}" == "Quagga_restart"    Quagga Restart    ${DEVICE_IP}

Unconfigure Reconfigure ODL
    [Arguments]    ${ODL_IP}
    [Documentation]    Unconfigure Reconfigure ODL

Quagga Restart
    [Arguments]    ${ODL_IP}
    [Documentation]    Quagga Restart
    Kill Quagga Processes On ODL    ${ODL_IP}

NON_CBA_ALARM_ODL_LOG
    [Arguments]    ${CtrlIp}    ${additional_args}=${EMPTY}    ${verbose}=TRUE
    [Documentation]    Check ALARM
    SSHLibrary.Open Connection    ${CtrlIp}
    Set Client Configuration    prompt=

    SSHLibrary.Login    root    admin123
    Write Commands Until Prompt    /opt/sdnc/opendaylight/wm_servr/py-impl
    Write Commands Until Prompt    python AlarmServer.py
    Write Commands Until Prompt    watchmen-client active-alarm-list
    Sleep    5
    SSHLibrary.Close Connection

Check Counter BGP
    [Documentation]    Check BGP counters
    Log To Console    "Duration of time that OF port has been installed on OF switch"
    ${RESP}    RequestsLibrary.Get    session    ${REST_CON}/pm-counter-service:performance-counters/bgp-counters/
    ${match_1}    Should Match Regexp    ${RESP.content}    ${BGP_REC}
    ${match_2}    Should Match Regexp    ${RESP.content}    ${BGP_SENT}
    ${match_3}    Should Match Regexp    ${RESP.content}    ${BGP_PREFIX}
    ${receive}    Should Match Regexp    ${match_1}    ${REG_1}
    ${receive_1} =    Strip String    ${receive}    characters=:
    Log To Console    "the total number of BGP packets received from neighbor    "
    Log To Console    ${receive_1}
    Should Not Contain    ${receive_1}    {Value0}
    ${sent}    Should Match Regexp    ${match_2}    ${REG_1}
    ${sent_1} =    Strip String    ${sent}    characters=:
    Log To Console    "total number of BGP packets sent to neighbor "
    Log To Console    ${sent_1}
    Should Not Contain    ${sent_1}    {Value0}
    ${prefixes}    Should Match Regexp    ${match_3}    ${REG_1}
    ${prefixes_1} =    Strip String    ${prefixes}    characters=:
    Log To Console    "total number of IPv4 BGP prefixes received    "
    Log To Console    ${prefixes_1}
    Should Not Contain    ${prefixes_1}    {Value0}
    
Topology
    setup.file_open    ${logger}    %{SDN}/integration/test/csit/suites/SF262/SF262_feature.topology
    [Return]    ${resp.content}

Restart_ODL_Cluster
    [Documentation]    Restarts ODL Cluster
    Log    <<< ------------- Restarting ODL cluster --------------->>>
    ${output} =    Run Command On Remote System    ${DIRECTOR_IP}    ${ODL_CLUSTER_RESTART}    ${DIRECTOR_USER}    ${DIRECTOR_PASSWORD}    ${DIRECTOR_PROMPT}
