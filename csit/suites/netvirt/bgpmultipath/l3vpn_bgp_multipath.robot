*** Settings ***
Documentation     Test suite to validate multipath functionality in openstack integrated environment.
...               The assumption of this suite is that the environment is already configured with the proper
...               integration bridges and vxlan tunnels.
Suite Setup       Start Suite
Suite Teardown    Stop Suite
Test Teardown     Pretest Cleanup
Library           OperatingSystem
Library           RequestsLibrary
Resource          ../../../libraries/BgpOperations.robot
Resource          ../../../libraries/Utils.robot
Resource          ../../../libraries/OpenStackOperations.robot
Resource          ../../../libraries/DevstackUtils.robot
Resource          ../../../libraries/VpnOperations.robot
Resource          ../../../libraries/OVSDB.robot
Resource          ../../../libraries/KarafKeywords.robot
Resource          ../../../libraries/SSHKeywords.robot
Resource          ../../../libraries/SetupUtils.robot
Resource          ../../../variables/Variables.robot

*** Variables ***
${AS_ID}          100
@{NETWORK_IP}     10.1.1.1/32    20.1.1.1/32    30.1.1.1/32    40.1.1.1/32    50.1.1.1/32    60.1.1.1/32    70.1.1.1/32
...               80.1.1.1/32
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
${max_path_three}    3
${max_path_six}    6
${max_path_negative}    -1
${max_path_eight}    8
${max_path_five}    5
${max_path_8}     8
${max_path_64}    64
${max_path_65}    65
${BGP_CACHE}      bgp-cache
${bgp-cmd}        show-bgp --cmd "ip bgp vpnv4 all"
${DISPLAY_VPN4_ALL}    show-bgp --cmd "ip bgp vpnv4 all"
${DISPLAY_NBR}    show-bgp --cmd "bgp neighbors"
${DISPLAY_NBR_SUMMARY}    show-bgp --cmd "bgp summary"
${DISPLAY_VPN}    vpnservice:l3vpn-config-show
${DIPSLAY_FIB}    fib-show
${ODL_MIP_IP}     ${ODL_SYSTEM_IP}
${ODL_ROUTER_ID}    ${ODL_SYSTEM_IP}
${BGP_CONNECT}    bgp-connect -h ${ODL_SYSTEM_IP} -p 7644 add
${multipath_fun_enable}    odl:multipath -f lu enable
${multipath_fun_disable}    odl:multipath -f lu disable
${Address-Families}    vpnv4
${Multipath}      Multipath
@{VPN_NAME}       vpn1    vpn2    vpn3
@{DCGW_RD}        1:1    2:2    3:3    4:4
@{DCGW_IMPORT_RT}    22:1    22:2    22:3
@{DCGW_EXPORT_RT}    11:1    11:2    11:3
@{DCGW_IP_LIST}    ${TOOLS_SYSTEM_1_IP}    ${TOOLS_SYSTEM_2_IP}    ${TOOLS_SYSTEM_3_IP}
@{LABEL}          51    52    53
@{PREF_LIST}      100    101    102
@{PREF_LIST_110}    110    110    101
@{PREF_LIST_120}    120    120    120
@{PREF_LIST_90}    90    90    101
@{VPN_NAME_VAL}    vpn11    vpn22    vpn33
@{VPN_INSTANCE_ID_VAL}    12345678-1234-1234-1234-123456789301    12345678-1234-1234-1234-123456789302    12345678-1234-1234-1234-123456789303
@{RD}             11:1    22:2    33:3
@{MULTIPATH_RD}    11:1    22:2    33:3
@{L3VPN_RD}       ["11:1"]    ["22:2"]    ["33:3"]
@{L3VPN_IMPORT_RT}    ["11:1"]    ["11:2"]    ["11:3"]
@{L3VPN_EXPORT_RT}    ["22:1"]    ["22:2"]    ["22:3"]
${L3VPN_IMPORT_RT_12}    ["11:1","11:2"]
${L3VPN_IMPORT_RT_123}    ["11:1","11:2","11:3"]
${L3VPN_IMPORT_RT_23}    ["11:2","11:3"]

*** Test Cases ***
TC1 Verify CSC supports REST API/CLI for multipath configuration (enable/disable multipath)
    [Documentation]    Verify CSC supports REST API/CLI for multipath configuration (enable/disable multipath)
    Enable Multipath On ODL
    Verify Multipath
    Disable Multipath On ODL
    Verify Multipath    False

TC2 Verify CSC supports REST API/CLI for max path configuration
    [Documentation]    Verify CSC supports REST API/CLI for max path configuration
    Log    "Create Eight L3vpn on ODL"
    : FOR    ${idx}    IN RANGE    0    ${NUM_OF_DCGW}
    \    VPN Create L3VPN    name=${VPN_NAME[${idx}]}    vpnid=${VPN_INSTANCE_ID_VAL[${idx}]}    rd=${L3VPN_RD[${idx}]}    exportrt=${L3VPN_EXPORT_RT[${idx}]}    importrt=${L3VPN_IMPORT_RT[${idx}]}
    Wait Until Keyword Succeeds    10    2    Verify L3VPN On ODL    @{VPN_INSTANCE_ID_VAL}
    Log    "Create Eight L3vpn on Dcgateway"
    : FOR    ${idx}    IN RANGE    0    ${NUM_OF_DCGW}
    \    Create L3VPN on Dcgateway    ${DCGW_IP_LIST[${idx}]}    ${VPN_NAME[${idx}]}    ${DCGW_RD[${idx}]}    ${DCGW_IMPORT_RT[${idx}]}    ${DCGW_EXPORT_RT[${idx}]}
    Check BGP Session On DCGW    ${NUM_OF_DCGW}
    Check BGP Session On ODL    ${NUM_OF_DCGW}
    Check BGP Nbr On ODL    ${NUM_OF_DCGW}
    Enable Multipath On ODL
    Wait Until Keyword Succeeds    10    2    Verify Multipath
    Log    "Configuring maxpath=8"
    : FOR    ${idx}    IN RANGE    0    ${NUM_OF_DCGW}
    \    Configure Maxpath    ${max_path_eight}    ${MULTIPATH_RD[${idx}]}
    Sleep    5s
    Log    "Verifying maxpath configuration"
    : FOR    ${idx}    IN RANGE    0    ${NUM_OF_DCGW}
    \    Verify Maxpath    ${max_path_eight}    ${MULTIPATH_RD[${idx}]}
    Check BGP VPNv4 Nbr On ODL    ${NUM_OF_DCGW}    False

TC3 Verify max-path configuration value should not be 0/-ve, because it’s not supported
    [Documentation]    Verify max-path configuration value should not be 0/-ve, because it’s not supported
    Log    "Creating L3vpn on ODL"
    VPN Create L3VPN    name=${VPN_NAME[0]}    vpnid=${VPN_INSTANCE_ID_VAL[0]}    rd=${L3VPN_RD[0]}    exportrt=${L3VPN_EXPORT_RT[0]}    importrt=${L3VPN_IMPORT_RT[0]}
    Wait Until Keyword Succeeds    10    2    Verify L3VPN On ODL    ${VPN_INSTANCE_ID_VAL[0]}
    Log    "Create L3vpn on Dcgateway"
    : FOR    ${idx}    IN RANGE    0    ${NUM_OF_DCGW}
    \    Create L3VPN on Dcgateway    ${DCGW_IP_LIST[${idx}]}    ${VPN_NAME[0]}    ${DCGW_RD[0]}    ${DCGW_IMPORT_RT[0]}    ${DCGW_EXPORT_RT[0]}
    Verify L3VPN On DCGW    ${NUM_OF_DCGW}    ${VPN_NAME[0]}    ${DCGW_RD[0]}    ${DCGW_IMPORT_RT[0]}    ${DCGW_EXPORT_RT[0]}
    Check BGP Session On DCGW    ${NUM_OF_DCGW}
    Check BGP Session On ODL    ${NUM_OF_DCGW}
    Check BGP Nbr On ODL    ${NUM_OF_DCGW}
    Enable Multipath On ODL
    Verify Multipath
    Configure Maxpath    ${max_path_zero}    ${MULTIPATH_RD[0]}
    Verify Maxpath For Invalid Input    ${MULTIPATH_RD[0]}    ${max_path_zero}
    Configure Maxpath    ${max_path_negative}    ${MULTIPATH_RD[0]}
    Verify Maxpath For Invalid Input    ${MULTIPATH_RD[0]}    ${max_path_negative}
    Configure Maxpath    ${max_path_65}    ${MULTIPATH_RD[0]}
    Verify Maxpath For Invalid Input    ${MULTIPATH_RD[0]}    ${max_path_65}
    Check BGP VPNv4 Nbr On ODL    ${NUM_OF_DCGW}    False

TC5 Verify CSC supports dynamic configuration changes for max path value
    [Documentation]    Verify CSC supports dynamic configuration changes for max path value
    Log    "Create L3vpn on ODL"
    VPN Create L3VPN    name=${VPN_NAME[0]}    vpnid=${VPN_INSTANCE_ID_VAL[0]}    rd=${L3VPN_RD[0]}    exportrt=${L3VPN_EXPORT_RT[0]}    importrt=${L3VPN_IMPORT_RT[0]}
    Wait Until Keyword Succeeds    10    2    Verify L3VPN On ODL    ${VPN_INSTANCE_ID_VAL[0]}
    Log    "Create L3vpn on Dcgateway"
    : FOR    ${idx}    IN RANGE    0    ${NUM_OF_DCGW}
    \    Create L3VPN on Dcgateway    ${DCGW_IP_LIST[${idx}]}    ${VPN_NAME[0]}    ${DCGW_RD[0]}    ${DCGW_IMPORT_RT[0]}    ${DCGW_EXPORT_RT[0]}
    Verify L3VPN On DCGW    ${NUM_OF_DCGW}    ${VPN_NAME[0]}    ${DCGW_RD[0]}    ${DCGW_IMPORT_RT[0]}    ${DCGW_EXPORT_RT[0]}
    Check BGP Session On DCGW    ${NUM_OF_DCGW}
    Check BGP Session On ODL    ${NUM_OF_DCGW}
    Check BGP Nbr On ODL    ${NUM_OF_DCGW}
    Enable Multipath On ODL
    Wait Until Keyword Succeeds    10    2    Verify Multipath
    Configure Maxpath    ${max_path_three}    ${MULTIPATH_RD[0]}
    Wait Until Keyword Succeeds    10    2    Verify Maxpath    ${max_path_three}    ${MULTIPATH_RD[0]}
    Log    "Adding Routes on Dcgateway"
    : FOR    ${idx}    IN RANGE    0    ${NUM_OF_DCGW}
    \    Add Routes    ${DCGW_IP_LIST[${idx}]}    ${DCGW_RD[0]}    ${NETWORK_IP[0]}    ${LABEL[${idx}]}
    Wait Until Keyword Succeeds    10    2    Check BGP VPNv4 Nbr On ODL    ${NUM_OF_DCGW}
    Wait Until Keyword Succeeds    10    2    Verify Routing Entry    ${RD[0]}    ${NETWORK_IP[0]}    3
    Wait Until Keyword Succeeds    10    2    Verify FIB Entry    ${NETWORK_IP[0]}    3
    Configure Maxpath    ${max_path_two}    ${MULTIPATH_RD[0]}
    Wait Until Keyword Succeeds    10    2    Verify Maxpath    ${max_path_two}    ${MULTIPATH_RD[0]}
    Wait Until Keyword Succeeds    10    2    Check BGP VPNv4 Nbr On ODL    ${NUM_OF_DCGW}
    Wait Until Keyword Succeeds    10    2    Verify Routing Entry    ${RD[0]}    ${NETWORK_IP[0]}    3
    Wait Until Keyword Succeeds    10    2    Verify FIB Entry    ${NETWORK_IP[0]}    2
    Configure Maxpath    ${max_path_min}    ${MULTIPATH_RD[0]}
    Wait Until Keyword Succeeds    10    2    Verify Maxpath    ${max_path_min}    ${MULTIPATH_RD[0]}
    Wait Until Keyword Succeeds    10    2    Check BGP VPNv4 Nbr On ODL    ${NUM_OF_DCGW}
    Wait Until Keyword Succeeds    10    2    Verify Routing Entry    ${RD[0]}    ${NETWORK_IP[0]}    3
    Wait Until Keyword Succeeds    10    2    Verify FIB Entry    ${NETWORK_IP[0]}    1
    Configure Maxpath    ${max_path_three}    ${MULTIPATH_RD[0]}
    Wait Until Keyword Succeeds    10    2    Verify Maxpath    ${max_path_three}    ${MULTIPATH_RD[0]}
    Wait Until Keyword Succeeds    10    2    Check BGP VPNv4 Nbr On ODL    ${NUM_OF_DCGW}
    Wait Until Keyword Succeeds    10    2    Verify Routing Entry    ${RD[0]}    ${NETWORK_IP[0]}    3
    Wait Until Keyword Succeeds    10    2    Verify FIB Entry    ${NETWORK_IP[0]}    3

TC6 Verify that ECMP path gets withdrawn by QBGP after disabling Multipath
    [Documentation]    Verify that ECMP path gets withdrawn by QBGP after disabling Multipath
    Log    "Create L3vpn on ODL"
    VPN Create L3VPN    name=${VPN_NAME[0]}    vpnid=${VPN_INSTANCE_ID_VAL[0]}    rd=${L3VPN_RD[0]}    exportrt=${L3VPN_EXPORT_RT[0]}    importrt=${L3VPN_IMPORT_RT[0]}
    Wait Until Keyword Succeeds    10    2    Verify L3VPN On ODL    ${VPN_INSTANCE_ID_VAL[0]}
    Log    "Create L3vpn on Dcgateway"
    : FOR    ${idx}    IN RANGE    0    ${NUM_OF_DCGW}
    \    Create L3VPN on Dcgateway    ${DCGW_IP_LIST[${idx}]}    ${VPN_NAME[0]}    ${DCGW_RD[0]}    ${DCGW_IMPORT_RT[0]}    ${DCGW_EXPORT_RT[0]}
    Verify L3VPN On DCGW    ${NUM_OF_DCGW}    ${VPN_NAME[0]}    ${DCGW_RD[0]}    ${DCGW_IMPORT_RT[0]}    ${DCGW_EXPORT_RT[0]}
    Check BGP Session On DCGW    ${NUM_OF_DCGW}
    Check BGP Session On ODL    ${NUM_OF_DCGW}
    Check BGP Nbr On ODL    ${NUM_OF_DCGW}
    Enable Multipath On ODL
    Wait Until Keyword Succeeds    10    2    Configure Maxpath    ${max_path_three}    ${MULTIPATH_RD[0]}
    Wait Until Keyword Succeeds    10    2    Verify Maxpath    ${max_path_three}    ${MULTIPATH_RD[0]}
    Log    "Adding Routes on Dcgateway"
    : FOR    ${idx}    IN RANGE    0    ${NUM_OF_DCGW}
    \    Add Routes    ${DCGW_IP_LIST[${idx}]}    ${DCGW_RD[0]}    ${NETWORK_IP[0]}    ${LABEL[${idx}]}
    Sleep    5
    Check BGP VPNv4 Nbr On ODL    ${NUM_OF_DCGW}
    Wait Until Keyword Succeeds    10    2    Verify Routing Entry    ${RD[0]}    ${NETWORK_IP[0]}    3
    Wait Until Keyword Succeeds    10    2    Verify FIB Entry    ${NETWORK_IP[0]}    3
    Configure Maxpath    ${max_path_min}    ${MULTIPATH_RD[0]}
    Wait Until Keyword Succeeds    10    2    Verify Routing Entry    ${RD[0]}    ${NETWORK_IP[0]}    3
    Wait Until Keyword Succeeds    10    2    Verify FIB Entry    ${NETWORK_IP[0]}    1
    Configure Maxpath    ${max_path_three}    ${MULTIPATH_RD[0]}
    Wait Until Keyword Succeeds    10    2    Verify Routing Entry    ${RD[0]}    ${NETWORK_IP[0]}    3
    Wait Until Keyword Succeeds    10    2    Verify FIB Entry    ${NETWORK_IP[0]}    3

TC7 Verify ECMP path advertised by QBGP to CSC in case of distinct VRF
    [Documentation]    Verify ECMP path advertised by QBGP to CSC in case of distinct VRF
    Log    "Create two L3vpn on ODL with different RTs"
    VPN Create L3VPN    name=${VPN_NAME[0]}    vpnid=${VPN_INSTANCE_ID_VAL[0]}    rd=${L3VPN_RD[0]}    exportrt=${L3VPN_EXPORT_RT[0]}    importrt=${L3VPN_IMPORT_RT[0]}
    VPN Create L3VPN    name=${VPN_NAME[1]}    vpnid=${VPN_INSTANCE_ID_VAL[1]}    rd=${L3VPN_RD[1]}    exportrt=${L3VPN_EXPORT_RT[1]}    importrt=${L3VPN_IMPORT_RT[1]}
    Wait Until Keyword Succeeds    10    2    Verify L3VPN On ODL    ${VPN_INSTANCE_ID_VAL[0]}    ${VPN_INSTANCE_ID_VAL[1]}
    Log    "Create L3vpn on Dcgateway, common set of RTs"
    : FOR    ${idx}    IN RANGE    0    1
    \    Create L3VPN on Dcgateway    ${DCGW_IP_LIST[${idx}]}    ${VPN_NAME[${idx}]}    ${DCGW_RD[0]}    ${DCGW_IMPORT_RT[0]}    ${DCGW_EXPORT_RT[0]}
    Log    "Create L3vpn on Dcgateway, common set of other RTs"
    : FOR    ${idx}    IN RANGE    1    3
    \    Create L3VPN on Dcgateway    ${DCGW_IP_LIST[${idx}]}    ${VPN_NAME[${idx}]}    ${DCGW_RD[1]}    ${DCGW_IMPORT_RT[1]}    ${DCGW_EXPORT_RT[1]}
    Check BGP Session On DCGW    ${NUM_OF_DCGW}
    Check BGP Session On ODL    ${NUM_OF_DCGW}
    Check BGP Nbr On ODL    ${NUM_OF_DCGW}
    Enable Multipath On ODL
    Wait Until Keyword Succeeds    10    2    Verify Multipath
    Wait Until Keyword Succeeds    10    2    Configure Maxpath    ${max_path_three}    ${MULTIPATH_RD[0]}
    Wait Until Keyword Succeeds    10    2    Configure Maxpath    ${max_path_three}    ${MULTIPATH_RD[1]}
    Wait Until Keyword Succeeds    10    2    Verify Maxpath    ${max_path_three}    ${MULTIPATH_RD[0]}
    Wait Until Keyword Succeeds    10    2    Verify Maxpath    ${max_path_three}    ${MULTIPATH_RD[1]}
    Log    "Adding set of Routes on Dcgateway"
    : FOR    ${idx}    IN RANGE    0    1
    \    Add Routes    ${DCGW_IP_LIST[${idx}]}    ${DCGW_RD[0]}    ${NETWORK_IP[0]}    ${LABEL[${idx}]}
    \    Add Routes    ${DCGW_IP_LIST[${idx}]}    ${DCGW_RD[0]}    ${NETWORK_IP[1]}    ${LABEL[${idx}]}
    Sleep    5
    Log    "Adding other set of Routes on Dcgateway"
    : FOR    ${idx}    IN RANGE    1    3
    \    Add Routes    ${DCGW_IP_LIST[${idx}]}    ${DCGW_RD[1]}    ${NETWORK_IP[0]}    ${LABEL[${idx}]}
    \    Add Routes    ${DCGW_IP_LIST[${idx}]}    ${DCGW_RD[1]}    ${NETWORK_IP[1]}    ${LABEL[${idx}]}
    Sleep    10
    Wait Until Keyword Succeeds    10    2    Check BGP VPNv4 Nbr On ODL    ${NUM_OF_DCGW}
    Wait Until Keyword Succeeds    10    2    Verify Routing Entry    ${RD[0]}    ${NETWORK_IP[0]}    1
    Wait Until Keyword Succeeds    10    2    Verify Routing Entry    ${RD[0]}    ${NETWORK_IP[1]}    1
    Wait Until Keyword Succeeds    10    2    Verify Routing Entry    ${RD[1]}    ${NETWORK_IP[0]}    2
    Wait Until Keyword Succeeds    10    2    Verify Routing Entry    ${RD[1]}    ${NETWORK_IP[1]}    2
    Wait Until Keyword Succeeds    10    2    Verify FIB Entry    ${NETWORK_IP[0]}    3
    Wait Until Keyword Succeeds    10    2    Verify FIB Entry    ${NETWORK_IP[1]}    3
    Verify Route Entry With Nexthop    ${RD[0]}    ${NETWORK_IP[0]}    1
    Verify Route Entry With Nexthop    ${RD[0]}    ${NETWORK_IP[1]}    1
    Verify Route Entry With Nexthop    ${RD[1]}    ${NETWORK_IP[0]}    ${NUM_OF_DCGW}    start=1
    Verify Route Entry With Nexthop    ${RD[1]}    ${NETWORK_IP[1]}    ${NUM_OF_DCGW}    start=1
    Delete Routes    ${DCGW_IP_LIST[2]}    ${DCGW_RD[1]}    ${NETWORK_IP[0]}    ${LABEL[2]}
    Delete Routes    ${DCGW_IP_LIST[2]}    ${DCGW_RD[1]}    ${NETWORK_IP[1]}    ${LABEL[2]}
    Wait Until Keyword Succeeds    10    2    Check BGP VPNv4 Nbr On ODL    ${NUM_OF_DCGW}    flag=False    start=2
    Wait Until Keyword Succeeds    10    2    Verify Routing Entry    ${RD[0]}    ${NETWORK_IP[0]}    1
    Wait Until Keyword Succeeds    10    2    Verify Routing Entry    ${RD[0]}    ${NETWORK_IP[1]}    1
    Wait Until Keyword Succeeds    10    2    Verify Routing Entry    ${RD[1]}    ${NETWORK_IP[0]}    1
    Wait Until Keyword Succeeds    10    2    Verify Routing Entry    ${RD[1]}    ${NETWORK_IP[1]}    1
    Wait Until Keyword Succeeds    10    2    Verify FIB Entry    ${NETWORK_IP[0]}    2
    Wait Until Keyword Succeeds    10    2    Verify FIB Entry    ${NETWORK_IP[1]}    2
    Log    "Verify that route is not licking from one VPN to other on CSC"
    Verify Leaking Route Across VPNs    ${RD[0]}    ${DCGW_IP_LIST[1]}    ${DCGW_IP_LIST[2]}
    Verify Leaking Route Across VPNs    ${RD[1]}    ${DCGW_IP_LIST[0]}

TC8 Verify ECMP path advertised by QBGP to CSC when routes shared across VPNs
    [Documentation]    Verify ECMP path advertised by QBGP to CSC when routes shared across VPNs
    Log    "Create three L3-VPN on CSC with common eRT and combination of iRT"
    VPN Create L3VPN    name=${VPN_NAME[0]}    vpnid=${VPN_INSTANCE_ID_VAL[0]}    rd=${L3VPN_RD[0]}    importrt=${L3VPN_IMPORT_RT_123}    exportrt=${L3VPN_EXPORT_RT[0]}
    VPN Create L3VPN    name=${VPN_NAME[1]}    vpnid=${VPN_INSTANCE_ID_VAL[1]}    rd=${L3VPN_RD[1]}    importrt=${L3VPN_IMPORT_RT[0]}    exportrt=${L3VPN_EXPORT_RT[0]}
    VPN Create L3VPN    name=${VPN_NAME[2]}    vpnid=${VPN_INSTANCE_ID_VAL[2]}    rd=${L3VPN_RD[2]}    importrt=${L3VPN_IMPORT_RT_23}    exportrt=${L3VPN_EXPORT_RT[0]}
    Wait Until Keyword Succeeds    10    2    Verify L3VPN On ODL    ${VPN_INSTANCE_ID_VAL[0]}    ${VPN_INSTANCE_ID_VAL[1]}    ${VPN_INSTANCE_ID_VAL[2]}
    Log    "Create L3 VPN on all DC-GW with common iRT and different eRT"
    Create L3VPN on Dcgateway    ${DCGW_IP_LIST[0]}    ${VPN_NAME[0]}    ${DCGW_RD[0]}    ${DCGW_IMPORT_RT[0]}    ${DCGW_EXPORT_RT[0]}
    Create L3VPN on Dcgateway    ${DCGW_IP_LIST[1]}    ${VPN_NAME[1]}    ${DCGW_RD[1]}    ${DCGW_IMPORT_RT[0]}    ${DCGW_EXPORT_RT[1]}
    Create L3VPN on Dcgateway    ${DCGW_IP_LIST[2]}    ${VPN_NAME[2]}    ${DCGW_RD[2]}    ${DCGW_IMPORT_RT[0]}    ${DCGW_EXPORT_RT[2]}
    Check BGP Session On DCGW    ${NUM_OF_DCGW}
    Check BGP Session On ODL    ${NUM_OF_DCGW}
    Check BGP Nbr On ODL    ${NUM_OF_DCGW}
    Enable Multipath On ODL
    Wait Until Keyword Succeeds    10    2    Verify Multipath
    Log    "Configuring maxpath=8"
    : FOR    ${idx}    IN RANGE    0    3
    \    Wait Until Keyword Succeeds    10    2    Configure Maxpath    ${max_path_three}    ${MULTIPATH_RD[${idx}]}
    Sleep    10s
    Log    "Verifying maxpath configuration"
    : FOR    ${idx}    IN RANGE    0    3
    \    Wait Until Keyword Succeeds    10    2    Verify Maxpath    ${max_path_three}    ${MULTIPATH_RD[${idx}]}
    Log    "Adding set of Routes on Dcgateway"
    Add Routes    ${DCGW_IP_LIST[0]}    ${DCGW_RD[0]}    ${NETWORK_IP[0]}    ${LABEL[0]}
    Add Routes    ${DCGW_IP_LIST[1]}    ${DCGW_RD[1]}    ${NETWORK_IP[0]}    ${LABEL[1]}
    Add Routes    ${DCGW_IP_LIST[2]}    ${DCGW_RD[2]}    ${NETWORK_IP[0]}    ${LABEL[2]}
    Sleep    10s
    Wait Until Keyword Succeeds    60    2    Check BGP VPNv4 Nbr On ODL    ${NUM_OF_DCGW}
    Wait Until Keyword Succeeds    10    2    Verify Routing Entry    ${RD[0]}    ${NETWORK_IP[0]}    3
    Wait Until Keyword Succeeds    10    2    Verify Routing Entry    ${RD[1]}    ${NETWORK_IP[0]}    1
    Wait Until Keyword Succeeds    10    2    Verify Routing Entry    ${RD[2]}    ${NETWORK_IP[0]}    2
    Wait Until Keyword Succeeds    10    2    Verify FIB Entry    ${NETWORK_IP[0]}    6
    Log    "Verify the routes with correct next hop"
    Verify Route Entry With Nexthop    ${RD[0]}    ${NETWORK_IP[0]}    ${NUM_OF_DCGW}
    Verify Route Entry With Nexthop    ${RD[1]}    ${NETWORK_IP[0]}    1
    Verify Route Entry With Nexthop    ${RD[2]}    ${NETWORK_IP[0]}    3    start=1
    Log    "Configuring maxpath=8"
    Wait Until Keyword Succeeds    10    2    Configure Maxpath    ${max_path_two}    ${MULTIPATH_RD[0]}
    Sleep    10s
    Log    "Verifying maxpath configuration"
    Wait Until Keyword Succeeds    10    2    Verify Maxpath    ${max_path_two}    ${MULTIPATH_RD[0]}
    Wait Until Keyword Succeeds    10    2    Check BGP VPNv4 Nbr On ODL    ${NUM_OF_DCGW}
    Wait Until Keyword Succeeds    10    2    Verify Routing Entry    ${RD[0]}    ${NETWORK_IP[0]}    3
    Wait Until Keyword Succeeds    10    2    Verify Routing Entry    ${RD[1]}    ${NETWORK_IP[0]}    1
    Wait Until Keyword Succeeds    10    2    Verify Routing Entry    ${RD[2]}    ${NETWORK_IP[0]}    2
    Wait Until Keyword Succeeds    10    2    Verify FIB Entry    ${NETWORK_IP[0]}    5
    Log    "Verify the routes with correct next hop"
    Verify Route Entry With Nexthop    ${RD[0]}    ${NETWORK_IP[0]}    ${NUM_OF_DCGW}
    Verify Route Entry With Nexthop    ${RD[1]}    ${NETWORK_IP[0]}    1
    Verify Route Entry With Nexthop    ${RD[2]}    ${NETWORK_IP[0]}    3    start=1

TC9 Verify BGP routes advertised to CSC when QBGP receives only unequal cost routes
    [Documentation]    Verify BGP routes advertised to CSC when QBGP receives only unequal cost routes
    Log    "Create L3vpn on ODL"
    VPN Create L3VPN    name=${VPN_NAME[0]}    vpnid=${VPN_INSTANCE_ID_VAL[0]}    rd=${L3VPN_RD[0]}    exportrt=${L3VPN_EXPORT_RT[0]}    importrt=${L3VPN_IMPORT_RT[0]}
    Wait Until Keyword Succeeds    10    2    Verify L3VPN On ODL    ${VPN_INSTANCE_ID_VAL[0]}
    Log    "Create L3vpn on Dcgateway"
    : FOR    ${idx}    IN RANGE    0    ${NUM_OF_DCGW}
    \    Create L3VPN on Dcgateway    ${DCGW_IP_LIST[${idx}]}    ${VPN_NAME[0]}    ${DCGW_RD[0]}    ${DCGW_IMPORT_RT[0]}    ${DCGW_EXPORT_RT[0]}
    Verify L3VPN On DCGW    ${NUM_OF_DCGW}    ${VPN_NAME[0]}    ${DCGW_RD[0]}    ${DCGW_IMPORT_RT[0]}    ${DCGW_EXPORT_RT[0]}
    Check BGP Session On DCGW    ${NUM_OF_DCGW}
    Check BGP Session On ODL    ${NUM_OF_DCGW}
    Check BGP Nbr On ODL    ${NUM_OF_DCGW}
    Enable Multipath On ODL
    Wait Until Keyword Succeeds    10    2    Verify Multipath
    Configure Maxpath    ${max_path_three}    ${MULTIPATH_RD[0]}
    Wait Until Keyword Succeeds    10    2    Verify Maxpath    ${max_path_three}    ${MULTIPATH_RD[0]}
    Log    "Adding Routes on Dcgateway"
    : FOR    ${idx}    IN RANGE    0    ${NUM_OF_DCGW}
    \    Add Routes    ${DCGW_IP_LIST[${idx}]}    ${DCGW_RD[0]}    ${NETWORK_IP[0]}    ${LABEL[${idx}]}
    Sleep    5
    Wait Until Keyword Succeeds    10    2    Check BGP VPNv4 Nbr On ODL    ${NUM_OF_DCGW}
    Wait Until Keyword Succeeds    10    2    Verify Routing Entry    ${RD[0]}    ${NETWORK_IP[0]}    3
    Wait Until Keyword Succeeds    10    2    Verify FIB Entry    ${NETWORK_IP[0]}    3
    Log    "Set the cost of all BGP route unequal from each DC-GW"
    : FOR    ${idx}    IN RANGE    0    ${NUM_OF_DCGW}
    \    Configure BGP Preference    ${DCGW_IP_LIST[${idx}]}    ${PREF_LIST[${idx}]}
    Wait Until Keyword Succeeds    10    2    Verify Routing Entry    ${RD[0]}    ${NETWORK_IP[0]}    3
    Wait Until Keyword Succeeds    10    2    Verify FIB Entry    ${NETWORK_IP[0]}    1
    Log    "Verify the routes with correct next hop"
    Verify Route Entry With Nexthop    ${RD[0]}    ${NETWORK_IP[0]}    ${NUM_OF_DCGW}    2
    Configure Maxpath    ${max_path_two}    ${MULTIPATH_RD[0]}
    Sleep    10
    Wait Until Keyword Succeeds    10    2    Verify Maxpath    ${max_path_two}    ${MULTIPATH_RD[0]}
    Log    "Set the cost of BGP route equal for last 2 DCGW"
    : FOR    ${idx}    IN RANGE    0    ${NUM_OF_DCGW}
    \    Configure BGP Preference    ${DCGW_IP_LIST[${idx}]}    ${PREF_LIST[0]}
    Check BGP Session On DCGW    ${NUM_OF_DCGW}
    Check BGP Session On ODL    ${NUM_OF_DCGW}
    Check BGP Nbr On ODL    ${NUM_OF_DCGW}
    Wait Until Keyword Succeeds    30    2    Verify Routing Entry    ${RD[0]}    ${NETWORK_IP[0]}    3
    Wait Until Keyword Succeeds    30    2    Verify FIB Entry    ${NETWORK_IP[0]}    2

TC10 Verify ECMP routes on CSC, when QBGP receives combination of equal and unequal cost routes
    [Documentation]    Verify ECMP routes on CSC, when QBGP receives combination of equal and unequal cost routes
    Log    "Create L3vpn on ODL"
    VPN Create L3VPN    name=${VPN_NAME[0]}    vpnid=${VPN_INSTANCE_ID_VAL[0]}    rd=${L3VPN_RD[0]}    exportrt=${L3VPN_EXPORT_RT[0]}    importrt=${L3VPN_IMPORT_RT[0]}
    Wait Until Keyword Succeeds    10    2    Verify L3VPN On ODL    ${VPN_INSTANCE_ID_VAL[0]}
    Log    "Create L3vpn on Dcgateway"
    : FOR    ${idx}    IN RANGE    0    ${NUM_OF_DCGW}
    \    Create L3VPN on Dcgateway    ${DCGW_IP_LIST[${idx}]}    ${VPN_NAME[0]}    ${DCGW_RD[0]}    ${DCGW_IMPORT_RT[0]}    ${DCGW_EXPORT_RT[0]}
    Verify L3VPN On DCGW    ${NUM_OF_DCGW}    ${VPN_NAME[0]}    ${DCGW_RD[0]}    ${DCGW_IMPORT_RT[0]}    ${DCGW_EXPORT_RT[0]}
    Check BGP Session On DCGW    ${NUM_OF_DCGW}
    Check BGP Session On ODL    ${NUM_OF_DCGW}
    Check BGP Nbr On ODL    ${NUM_OF_DCGW}
    Enable Multipath On ODL
    Wait Until Keyword Succeeds    10    2    Verify Multipath
    Wait Until Keyword Succeeds    10    2    Configure Maxpath    ${max_path_three}    ${MULTIPATH_RD[0]}
    Wait Until Keyword Succeeds    10    2    Verify Maxpath    ${max_path_three}    ${MULTIPATH_RD[0]}
    Log    "Adding Routes on Dcgateway"
    : FOR    ${idx}    IN RANGE    0    ${NUM_OF_DCGW}
    \    Add Routes    ${DCGW_IP_LIST[${idx}]}    ${DCGW_RD[0]}    ${NETWORK_IP[0]}    ${LABEL[${idx}]}
    Sleep    5
    Wait Until Keyword Succeeds    10    2    Check BGP VPNv4 Nbr On ODL    ${NUM_OF_DCGW}
    Wait Until Keyword Succeeds    10    2    Verify Routing Entry    ${RD[0]}    ${NETWORK_IP[0]}    3
    Wait Until Keyword Succeeds    10    2    Verify FIB Entry    ${NETWORK_IP[0]}    3
    Log    "Set the cost of all BGP route unequal from each DCGW"
    : FOR    ${idx}    IN RANGE    0    2
    \    Configure BGP Preference    ${DCGW_IP_LIST[${idx}]}    ${PREF_LIST_110[${idx}]}
    : FOR    ${idx}    IN RANGE    2    3
    \    Configure BGP Preference    ${DCGW_IP_LIST[${idx}]}    ${PREF_LIST_110[${idx}]}
    Wait Until Keyword Succeeds    10    2    Verify Routing Entry    ${RD[0]}    ${NETWORK_IP[0]}    3
    Wait Until Keyword Succeeds    10    2    Verify FIB Entry    ${NETWORK_IP[0]}    2
    Log    "Set the cost of all BGP route unequal from each DCGW"
    : FOR    ${idx}    IN RANGE    0    ${NUM_OF_DCGW}
    \    Configure BGP Preference    ${DCGW_IP_LIST[${idx}]}    ${PREF_LIST[${idx}]}
    Wait Until Keyword Succeeds    10    2    Verify Routing Entry    ${RD[0]}    ${NETWORK_IP[0]}    3
    Wait Until Keyword Succeeds    10    2    Verify FIB Entry    ${NETWORK_IP[0]}    1
    Log    "Verify the routes with correct next hop"
    Verify Route Entry With Nexthop    ${RD[0]}    ${NETWORK_IP[0]}    ${NUM_OF_DCGW}    2

*** Keywords ***
Start Suite
    [Documentation]    Setup Start Suite
    RequestsLibrary.Create_Session    alias=session    url=http://${ODL_SYSTEM_IP}:${RESTCONFPORT}    auth=${AUTH}
    TemplatedRequests.Create Default Session    timeout=${SESSION_TIMEOUT}
    Log Many    @{DCGW_IP_LIST}
    Log    Starting quagga process in all DCGW
    : FOR    ${dcgw}    IN    @{DCGW_IP_LIST}
    \    Start Quagga Processes On DCGW    ${dcgw}
    Start Quagga Processes On ODL    ${ODL_SYSTEM_IP}
    KarafKeywords.Issue Command On Karaf Console    ${BGP_CONNECT}
    BgpOperations.Create BGP Configuration On ODL    localas=${AS_ID}    routerid=${ODL_SYSTEM_IP}
    Configure BGP Neighbor On ODL    ${NUM_OF_DCGW}
    Wait Until Keyword Succeeds    10    2    Verify BGP Neighbor On ODL    ${NUM_OF_DCGW}
    Log    "Configure BGP CLIs on each DC Gateway"
    : FOR    ${idx}    IN RANGE    0    ${NUM_OF_DCGW}
    \    Configure BGP And Add Neighbor On DCGW    ${DCGW_IP_LIST[${idx}]}    ${ODL_MIP_IP}    ${AS_ID}

Stop Suite
    [Documentation]    Deleting all BGP neighbors and configurations
    RequestsLibrary.Create_Session    alias=session    url=http://${ODL_SYSTEM_IP}:${RESTCONFPORT}    auth=${AUTH}
    Log    "Pre Cleanup Check For Dcgateway"
    : FOR    ${idx}    IN RANGE    0    ${NUM_OF_DCGW}
    \    ${output}    Pre Cleanup Configuration Check on Dcgateway    ${DCGW_IP_LIST[${idx}]}
    Delete BGP Neighbor On ODL    ${NUM_OF_DCGW}
    Log    "Configuring maxpath=1"
    : FOR    ${idx}    IN RANGE    0    ${NUM_OF_DCGW}
    \    Configure Maxpath    ${max_path_min}    ${MULTIPATH_RD[${idx}]}
    Delete L3VPN    ${NUM_OF_L3VPN}
    Disable Multipath On ODL
    : FOR    ${idx}    IN RANGE    0    ${NUM_OF_DCGW}
    \    ${output}    Delete BGP Config On Quagga    ${DCGW_IP_LIST[${idx}]}    ${AS_ID}

Pretest Cleanup
    [Documentation]    Test Case Cleanup
    Log    ***********************************Pretest Cleanup ********************************
    RequestsLibrary.Create_Session    alias=session    url=http://${ODL_SYSTEM_IP}:${RESTCONFPORT}    auth=${AUTH}
    Log    "Pre Cleanup Check For Dcgateway"
    : FOR    ${idx}    IN RANGE    0    ${NUM_OF_DCGW}
    \    ${output}    Pre Cleanup Configuration Check on Dcgateway    ${DCGW_IP_LIST[${idx}]}
    Log    "Configuring maxpath=1"
    : FOR    ${idx}    IN RANGE    0    ${NUM_OF_DCGW}
    \    Configure Maxpath    ${max_path_min}    ${MULTIPATH_RD[${idx}]}
    Delete L3VPN    ${NUM_OF_L3VPN}
    Disable Multipath On ODL
    : FOR    ${idx}    IN RANGE    0    ${NUM_OF_DCGW}
    \    ${output}    Delete BGP Config On Quagga    ${DCGW_IP_LIST[${idx}]}    ${AS_ID}
    Log    "Configure BGP CLIs on each DC Gateway"
    : FOR    ${idx}    IN RANGE    0    ${NUM_OF_DCGW}
    \    Configure BGP And Add Neighbor On DCGW    ${DCGW_IP_LIST[${idx}]}    ${ODL_MIP_IP}    ${AS_ID}
    Sleep    10s

Pre Cleanup Configuration Check on Dcgateway
    [Arguments]    ${dcgw_ip}
    [Documentation]    Execute set of command on Dcgateway
    ${output} =    Execute Show Command On quagga    ${dcgw_ip}    show running-config
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
    Execute Command On Quagga Telnet Session    configure terminal
    Execute Command On Quagga Telnet Session    router bgp ${AS_ID}
    Execute Command On Quagga Telnet Session    bgp router-id ${dcgw_ip}
    Execute Command On Quagga Telnet Session    no bgp log-neighbor-changes
    Execute Command On Quagga Telnet Session    bgp graceful-restart stalepath-time 90
    Execute Command On Quagga Telnet Session    bgp graceful-restart stalepath-time 90
    Execute Command On Quagga Telnet Session    bgp graceful-restart restart-time 900
    Execute Command On Quagga Telnet Session    bgp graceful-restart
    Execute Command On Quagga Telnet Session    bgp graceful-restart preserve-fw-state
    Execute Command On Quagga Telnet Session    bgp bestpath as-path multipath-relax
    Execute Command On Quagga Telnet Session    neighbor ${odl_ip} send-remote-as ${as_number}
    Execute Command On Quagga Telnet Session    terminal length 0
    Execute Command On Quagga Telnet Session    neighbor ${odl_ip} update-source ${dcgw_ip}
    Execute Command On Quagga Telnet Session    no neighbor ${odl_ip} activate
    Execute Command On Quagga Telnet Session    address-family vpnv4
    Execute Command On Quagga Telnet Session    neighbor ${odl_ip} activate
    Execute Command On Quagga Telnet Session    neighbor ${odl_ip} attribute-unchanged next-hop
    Execute Command On Quagga Telnet Session    address-family ipv6
    Execute Command On Quagga Telnet Session    exit-address-family
    Execute Command On Quagga Telnet Session    exit
    ${output} =    Execute Command On Quagga Telnet Session    show running-config
    Log    ${output}
    Execute Command On Quagga Telnet Session    exit
    SSHLibrary.Close Connection
    [Return]    ${output}

Create L3VPN on Dcgateway
    [Arguments]    ${dcgw_ip}    ${vpn_name}    ${rd}    ${import_rt}    ${export_rt}
    [Documentation]    Create L3VPN on Dcgateway
    Create Quagga Telnet Session    ${dcgw_ip}    bgpd    sdncbgpc
    Execute Command On Quagga Telnet Session    configure terminal
    Execute Command On Quagga Telnet Session    router bgp ${AS_ID}
    Execute Command On Quagga Telnet Session    vrf ${vpn_name}
    Execute Command On Quagga Telnet Session    rd ${rd}
    Execute Command On Quagga Telnet Session    rt export ${export_rt}
    Execute Command On Quagga Telnet Session    rt import ${import_rt}
    Execute Command On Quagga Telnet Session    exit
    Execute Command On Quagga Telnet Session    exit
    SSHLibrary.Close Connection

Create Multi VPN on Dcgateway
    [Arguments]    ${dcgw_ip}    ${vpn_name}    ${rd}    ${import_rt}    ${export_rt}    ${dc_count}
    ...    ${start}=0
    [Documentation]    Create Multi VPN on Dcgateway
    : FOR    ${idx}    IN RANGE    ${start}    ${dc_count}
    \    ${output}    Create L3VPN on Dcgateway    ${DCGW_IP_LIST[${idx}]}    ${vpn_name}    ${rd}    ${DCGW_IMPORT_RT[0]}
    \    ...    ${DCGW_EXPORT_RT[0]}
    [Return]    ${output}

Configure BGP Preference
    [Arguments]    ${dcgw_ip}    ${preference}
    [Documentation]    Configure BGP Preference
    Create Quagga Telnet Session    ${dcgw_ip}    bgpd    sdncbgpc
    Execute Command On Quagga Telnet Session    configure terminal
    Execute Command On Quagga Telnet Session    router bgp ${AS_ID}
    Execute Command On Quagga Telnet Session    bgp default local-preference ${preference}
    Execute Command On Quagga Telnet Session    exit
    Execute Command On Quagga Telnet Session    do clear ip bgp *
    Sleep    10s
    Execute Command On Quagga Telnet Session    exit
    SSHLibrary.Close Connection

Add Routes
    [Arguments]    ${dcgw_ip}    ${rd}    ${network_ip}    ${label}
    [Documentation]    Add the Routes to DCGW
    Create Quagga Telnet Session    ${dcgw_ip}    bgpd    sdncbgpc
    Execute Command On Quagga Telnet Session    configure terminal
    Execute Command On Quagga Telnet Session    router bgp ${AS_ID}
    Execute Command On Quagga Telnet Session    address-family vpnv4
    Execute Command On Quagga Telnet Session    network ${network_ip} rd ${rd} tag ${label}
    Execute Command On Quagga Telnet Session    exit
    Execute Command On Quagga Telnet Session    exit
    SSHLibrary.Close Connection

Delete Routes
    [Arguments]    ${dcgw_ip}    ${rd}    ${network_ip}    ${label}
    [Documentation]    Delete the Routes from DCGW
    Create Quagga Telnet Session    ${dcgw_ip}    bgpd    sdncbgpc
    Execute Command On Quagga Telnet Session    configure terminal
    Execute Command On Quagga Telnet Session    router bgp ${AS_ID}
    Execute Command On Quagga Telnet Session    address-family vpnv4
    Execute Command On Quagga Telnet Session    no network ${network_ip} rd ${rd} tag ${label}
    Execute Command On Quagga Telnet Session    exit
    Execute Command On Quagga Telnet Session    exit
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

Enable Multipath On ODL
    [Documentation]    Enabling Multipath
    ${output} =    Issue_Command_On_Karaf_Console    ${multipath_fun_enable}
    Log    ${output}
    Should Not Contain    ${output}    ${ERROR}

Disable Multipath On ODL
    [Documentation]    Disabling Multipath
    ${output} =    Issue_Command_On_Karaf_Console    ${multipath_fun_disable}
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

Delete BGP Neighbor On ODL
    [Arguments]    ${additional_args}=${EMPTY}    ${verbose}=TRUE
    [Documentation]    Delete bgp config on odl
    : FOR    ${index}    IN RANGE    0    ${NUM_OF_DC_GW}
    \    ${output} =    set variable    configure-bgp -op delete-neighbor --ip ${DCGW_IP_LIST[${index}]} --as-num ${AS_ID} --use-source-ip ${ODL_MIP_IP}
    \    ${OP1} =    Issue_Command_On_Karaf_Console    ${output}
    \    Log    ${OP1}
    \    ${output1} =    Issue_Command_On_Karaf_Console    ${BGP_CACHE}
    \    Log    ${output1}

Configure BGP Neighbor On ODL
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
    \    Run Keyword And Ignore Error    VPN Delete L3VPN    vpnid=${VPN_INSTANCE_ID_VAL[${idx}]}

Verify BGP Neighbor On ODL
    [Arguments]    ${dcgw_count}    ${start}=${START_VALUE}
    [Documentation]    Verify BGP Neighbor on ODL
    ${output}=    Issue Command On Karaf Console    ${BGP_CACHE}
    : FOR    ${index}    IN RANGE    ${start}    ${dcgw_count}
    \    Should Contain    ${output}    ${DCGW_IP_LIST[${index}]}

Verify L3VPN On ODL
    [Arguments]    @{vpn_instance_list}
    [Documentation]    Verify BGP Neighbor on ODL
    : FOR    ${vpn_instance}    IN    @{vpn_instance_list}
    \    ${resp}    VPN Get L3VPN    vpnid=${vpn_instance}
    \    Should Contain    ${resp}    ${vpn_instance}

Verify L3VPN On DCGW
    [Arguments]    ${dcgw_count}    ${vpn_name}    ${rd}    ${import_rt}    ${export_rt}    ${start}=${START_VALUE}
    [Documentation]    Execute set of command on Dcgateway
    : FOR    ${index}    IN RANGE    ${start}    ${dcgw_count}
    \    ${output} =    Execute Show Command On Quagga    ${DCGW_IP_LIST[${index}]}    show running-config
    \    Log    ${output
    \    Should Contain    ${output}    vrf ${vpn_name}
    \    Should Contain    ${output}    rd ${rd}
    \    Should Contain    ${output}    rt import ${import_rt}
    \    Should Contain    ${output}    rt export ${export_rt}

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
    \    Should Contain    ${output}    ${DCGW_IP_LIST[${index}]}
    [Return]    ${output}

Check BGP VPNv4 Nbr On ODL
    [Arguments]    ${dcgw_count}    ${flag}=True    ${start}=${START_VALUE}
    [Documentation]    Check BGP Session On ODL
    ${output}=    Issue Command On Karaf Console    ${DISPLAY_VPN4_ALL}
    : FOR    ${index}    IN RANGE    ${start}    ${dcgw_count}
    \    Run Keyword If    ${flag}==True    Should Contain    ${output}    ${DCGW_IP_LIST[${index}]}
    \    ...    ELSE    Should Not Contain    ${output}    ${DCGW_IP_LIST[${index}]}
    [Return]    ${output}

Check BGP Nbr On DCGW
    [Arguments]    ${dcgw_count}    ${start}=${START_VALUE}
    [Documentation]    Verify BGP Config on DCGW
    : FOR    ${index}    IN RANGE    ${start}    ${dcgw_count}
    \    ${output} =    Execute Show Command On Quagga    ${DCGW_IP_LIST[${index}]}    show ip bgp vpnv4 all
    \    Log    ${output}
    \    Should Contain    ${output}    ${ODL_MIP_IP}
    [Return]    ${output}

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
    \    Should Match Regexp    ${output}    \\s*${prefix}\\s*${DCGW_IP_LIST[${index}]}    msg="FIB table does not contain ${DCGW_IP_LIST[${index}]} for ${prefix} prefix "

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
