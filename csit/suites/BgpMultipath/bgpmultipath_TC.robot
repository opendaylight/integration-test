*** Settings ***
Documentation     Test suite to validate multipath functionality in openstack integrated environment.
...               The assumption of this suite is that the environment is already configured with the proper
...               integration bridges and vxlan tunnels.
Library           OperatingSystem    #Suite Setup    Suite Setup    #Suite Teardown    Suite Teardown    #Test Setup    Pretest Setup
...               #Test Teardown    Pretest Cleanup
Library           RequestsLibrary
Resource          ../../../../libraries/Utils.robot
Resource          ../../../../libraries/OpenStackOperations.robot
Resource          ../../../../libraries/DevstackUtils.robot
Resource          ../../../../libraries/VpnOperations.robot
Resource          ../../../../libraries/OVSDB.robot
Resource          ../../../../libraries/Tcpdump.robot
Resource          ../../../../libraries/SetupUtils.robot
Resource          ../../../../libraries/BgpOperations.robot
Resource          ../../../../libraries/SSHKeywords.robot    

*** Variables ***
${NUM_ODL_SYSTEM}    1
@{ODL_SYSTEM}     ${ODL_SYSTEM_1_IP}    ${ODL_SYSTEM_2_IP}    ${ODL_SYSTEM_3_IP}
${Req_no_of_L3VPN}    8
${dcgw_ip}        172.168.1.151
@{NETWORKS}       NET1    NET2    NET3    NET4    NET5    NET6    NET7
...               NET8
@{SUBNETS}        SUBNET1    SUBNET2    SUBNET3    SUBNET4    SUBNET5    SUBNET6    SUBNET7
...               SUBNET8
@{SUBNET_CIDR}    10.1.1.0/24    20.1.1.0/24    30.1.1.0/24    40.1.1.0/24    50.1.1.0/24    60.1.1.0/24    70.1.1.0/24
...               80.1.1.0/24
@{VM_INSTANCES}    VM11    VM12    VM21    VM22
@{DCGW_SYSTEM_IP}    ${DCGW_1_IP}    ${DCGW_2_IP}    ${DCGW_3_IP}    ${DCGW_4_IP}    ${DCGW_5_IP}    ${DCGW_6_IP}    ${DCGW_7_IP}
...               ${DCGW_8_IP}
${DCGW_SYSTEM_IP}    ${TOOLS_SYSTEM_1_IP}
@{PORT_LIST_NEW}    PORT15
@{VM_NAME_NEW_LIST}    VM15
#${OS_CONTROL_NODE_IP}    10.183.255.11
${NETWORK_URL}    ${CONFIG_API}/neutron:neutron/networks/
${SUBNETWORK_URL}    ${CONFIG_API}/neutron:neutron/subnets/
${PORT_URL}       ${CONFIG_API}/neutron:neutron/ports/
${CONFIG_API}     /restconf/config
${SECURITY_GROUP}    sg-vpnservice
${Req_no_of_net}    8
${Req_no_of_subNet}    8
${Req_no_of_ports}    8
${Req_no_of_vms_per_dpn}    4
${Req_no_of_routers}    2
${No_of_dc_gw}    8
${multipath_fun}    odl:multipath    -f lu enable
${multipath_fun}    odl:multipath -f lu disable
${ERROR}          Command not found
${maxpath_fun}    multipath -r 200:1 -f lu -n 8 setmaxpath
${no_of_max_path}   8 
${max_path_zero}    0
${max_path_negative}    -1
${max_path_eight}    8
${max_path_64}    64
${max_path_65}    65
${max_path_10}    10
${bgp-cache}      bgp-cache
${vpn-session}    vpnservice:l3vpn-config-show
${fib-session}    fib-show
${Enable}         ENABLE
${Disable}        DISABLE
${OS_USER}        root
$(DCGW_USER)      dcgateway
${DCGW_PASS}      dcgateway
${DEVSTACK_SYSTEM_PASSWORD}    admin123
${DEVSTACK_DEPLOY_PATH}    /opt/stack/devstack/
${multipath_fun_enable}    odl:multipath    -f lu enable
${multipath_fun_disable}    odl:multipath    -f lu disable
${Address-Families}    vpnv4
${Multipath}      Multipath
${AS_NUM}         200
${No_of_path}    8 
${BGP_REC}        "bgp-neighbor-packets-received"\:\\d+
${BGP_SENT}       "bgp-neighbor-packets-sent"\:\\d+
${BGP_PREFIX}     "bgp-total-prefixes"\:\\d+
${REG_1}          :\\d+
${Value0}         0
#${user}          root
${multipath_config}    bgp bestpath as-path multipath-relax
${NUM_OF_DC_GW}    8
@{VPN_INSTANCE_ID}    ${VPN_INSTANCE_ID1}    ${VPN_INSTANCE_ID2}    ${VPN_INSTANCE_ID3}    ${VPN_INSTANCE_ID4}    ${VPN_INSTANCE_ID5}    ${VPN_INSTANCE_ID6}    ${VPN_INSTANCE_ID7}
...               ${VPN_INSTANCE_ID8}
${VPN_INSTANCE_ID1}    4ae8cd92-48ca-49b5-94e1-b2921a261111
${VPN_INSTANCE_ID2}    4ae8cd92-48ca-49b5-94e1-b2921a261112
${VPN_INSTANCE_ID3}    4ae8cd92-48ca-49b5-94e1-b2921a261113
${VPN_INSTANCE_ID4}    4ae8cd92-48ca-49b5-94e1-b2921a261114
${VPN_INSTANCE_ID5}    4ae8cd92-48ca-49b5-94e1-b2921a261115
${VPN_INSTANCE_ID6}    4ae8cd92-48ca-49b5-94e1-b2921a261116
${VPN_INSTANCE_ID7}    4ae8cd92-48ca-49b5-94e1-b2921a261117
${VPN_INSTANCE_ID8}    4ae8cd92-48ca-49b5-94e1-b2921a261118
@{VPN_NAME}       vpn1    vpn2    vpn3    vpn4    vpn5    vpn6    vpn7
...               vpn8
@{L3VPN_RD}       1:1
@{CREATE_RD}      ["1:1"]    ["1:2"]    ["1:3"]    ["1:4"]    ["1:5"]    ["1:6"]    ["1:7"]
...               ["1:8"]
@{CREATE_EXPORT_RT}    ["1:1"]    ["1:2"]    ["1:3"]    ["1:4"]    ["1:5"]    ["1:6"]    ["1:7"]
...               ["1:8"]
@{CREATE_IMPORT_RT}    ["1:1"]    ["1:2"]    ["1:3"]    ["1:4"]    ["1:5"]    ["1:6"]    ["1:7"]
...               ["1:8"]
@{DCGW_RD}        1:1    1:2    1:3    1:4    1:5    1:6    1:7
...               1:8
${TEP_SHOW_STATE}    tep:show-state
${EIGHT_VPN_SESSION}    8
@{NO_FIB_ENTRIES_1}    8    8    8    8    8    8    8
...               8
@{NO_FIB_ENTRIES_2}    0    0    0    0    16    16    16
...               16
${max_path_80}    80
${routes_disabling_multipath}    ??
${local_pre_100}    100
${local_pre_150}    150
${local_pre_200}    200
${local_pre_250}    250
${local_pre_300}    300
${local_pre_350}    350
${local_pre_400}    400
${local_pre_450}    450

*** Test Cases ***
TC1 Verify CSC supports REST API/CLI for multipath configuration (enable/disable multipath)
    [Documentation]    Verify CSC supports REST API/CLI for multipath configuration (enable/disable multipath)
    Log    "Verify BGP and VPN sessions are up"
    # Check BGP Session On ODL
    # Check BGP Session On DC_GW    ${No_of_dc_gw}
    #Check VPN Session    ${EIGHT_VPN_SESSION}
    Log    "Enable multipath"
    Multipath Functionality    ${Enable}
    Log    "Verify Multipath configuration"
    Verify Multipath

TC2 Verify CSC supports REST API/CLI for max path configuration
    [Documentation]    Verify CSC supports REST API/CLI for max path configuration
    Log    "Verify BGP and VPN sessions are up"
    #    Check BGP Session On ODL
    #    Check BGP Session On DC_GW    ${No_of_dc_gw}
    #    Check VPN Session    ${EIGHT_VPN_SESSION}
    Log    "Enable multipath"
    Multipath Functionality    ${Enable}
    Log    "Verify Multipath configuration"
    Verify Multipath
    Log    "Enable Maxpath"
    Configure Maxpath    ${no_of_max_path}
    Log    "Verify Maxpath configuration"
    Verify Maxpath    ${no_of_max_path}



**** keywords ****


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

Verify Multipath
    [Documentation]    Verify Multipath is Set properly
    ${PASSED}    ConvertToInteger    0
    ${output}=    Issue Command On Karaf Console    ${bgp-cache}
    Log    ${output}
    Should Contain    ${output}    ${Multipath}
    ${output}=    Issue Command On Karaf Console    ${bgp-cache}
    Should Contain    ${output}    ${Address-Families}

Configure Maxpath
    [Arguments]    ${Maxpath}    ${additional_args}=${EMPTY}    ${verbose}=TRUE
    [Documentation]    Set Maxpath
    ${PASSED}    ConvertToInteger    0
    ${maxpath_command}    Catenate    multipath -r    ${AS_NUM}:1 -f lu -n    ${No_of_path}    setmaxpath
    ${output}=    Issue Command On Karaf Console    ${maxpath_command}
    Log    ${output}
    Should Not Contain    ${output}    ${ERROR}


Verify Maxpath
    [Arguments]    ${Maxpath}    ${additional_args}=${EMPTY}    ${verbose}=TRUE
    [Documentation]    Verify Maxpath is Set Properly
    ${PASSED}    ConvertToInteger    0
    ${output}=    Issue Command On Karaf Console    ${bgp-cache}
    Log    ${output}
    Should Contain    ${output}    Maxpath
    ${output}=    Issue Command On Karaf Console    ${bgp-cache}
    Should Contain    ${output}    ${Maxpath}
