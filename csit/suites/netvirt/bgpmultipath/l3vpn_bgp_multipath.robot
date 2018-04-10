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
@{DCGW_RD}        1:1    2:2    3:3    4:4
@{DCGW_IMPORT_RT}    22:1    22:2    22:3
@{DCGW_EXPORT_RT}    11:1    11:2    11:3
@{DCGW_IP_LIST}    ${TOOLS_SYSTEM_1_IP}    ${TOOLS_SYSTEM_2_IP}    ${TOOLS_SYSTEM_3_IP}
@{LABEL}          51    52    53
@{L3VPN_RD}       ["11:1"]    ["22:2"]    ["33:3"]
@{L3VPN_IMPORT_RT}    ["11:1"]    ["11:2"]    ["11:3"]
@{L3VPN_EXPORT_RT}    ["22:1"]    ["22:2"]    ["22:3"]
@{MAX_PATH_LIST}    1    2    3    8    64
@{MAX_PATH_INVALID_LIST}    -1    0    65
@{MULTIPATH_RD}    11:1    22:2    33:3
@{NETWORK_IP}     10.1.1.1/32    20.1.1.1/32    30.1.1.1/32    40.1.1.1/32    50.1.1.1/32    60.1.1.1/32    70.1.1.1/32
...               80.1.1.1/32
@{NUM_OF_ROUTES}    0    1    2    3    4    5    6
@{PREF_LIST}      100    101    102
@{PREF_LIST_110}    110    110    101
@{PREF_LIST_120}    120    120    120
@{PREF_LIST_90}    90    90    101
@{RD}             11:1    22:2    33:3
@{VPN_NAME}       vpn1    vpn2    vpn3
@{VPN_INSTANCE_ID}    12345678-1234-1234-1234-123456789301    12345678-1234-1234-1234-123456789302    12345678-1234-1234-1234-123456789303
${AS_ID}          100
${Address-Families}    vpnv4
${BGP_CACHE}      bgp-cache
${BGP_CONNECT}    bgp-connect -h ${ODL_SYSTEM_IP} -p 7644 add
${DISPLAY_VPN4_ALL}    show-bgp --cmd "ip bgp vpnv4 all"
${DISPLAY_NBR}    show-bgp --cmd "bgp neighbors"
${DISPLAY_NBR_SUMMARY}    show-bgp --cmd "bgp summary"
${DISPLAY_VPN}    vpnservice:l3vpn-config-show
${DIPSLAY_FIB}    fib-show
${ERROR}          error: --maxpath range[1 - 64]
${INVALID_INPUT}    error: --maxpath range[1 - 64]
${L3VPN_IMPORT_RT_12}    ["11:1","11:2"]
${L3VPN_IMPORT_RT_123}    ["11:1","11:2","11:3"]
${L3VPN_IMPORT_RT_23}    ["11:2","11:3"]
${MULTIPATH_ENABLE}    odl:multipath -f lu enable
${MULTIPATH_DISABLE}    odl:multipath -f lu disable
${NUM_OF_DCGW}    3
${NUM_OF_L3VPN}    3
${ODL_MIP_IP}     ${ODL_SYSTEM_IP}
${ODL_ROUTER_ID}    ${ODL_SYSTEM_IP}
${START_VALUE}    0

*** Test Cases ***
TC1 Verify CSC supports REST API/CLI for multipath configuration (enable/disable multipath)
    [Documentation]    Verify CSC supports REST API/CLI for multipath configuration (enable/disable multipath)
    Enable Multipath On ODL
    Verify Multipath
    Disable Multipath On ODL
    Verify Multipath    False

TC2 Verify CSC supports REST API/CLI for max path configuration
    [Documentation]    Verify CSC supports REST API/CLI for max path configuration
    : FOR    ${idx}    IN RANGE    ${START_VALUE}    ${NUM_OF_DCGW}
    \    VpnOperations.VPN Create L3VPN    name=@{VPN_NAME}[${idx}]    vpnid=@{VPN_INSTANCE_ID}[${idx}]    rd=@{L3VPN_RD}[${idx}]    exportrt=@{L3VPN_EXPORT_RT}[${idx}]    importrt=@{L3VPN_IMPORT_RT}[${idx}]
    BuiltIn.Wait Until Keyword Succeeds    10s    2s    Verify L3VPN On ODL    @{VPN_INSTANCE_ID}
    : FOR    ${idx}    IN RANGE    ${START_VALUE}    ${NUM_OF_DCGW}
    \    Create L3VPN on Dcgateway    @{DCGW_IP_LIST}[${idx}]    @{VPN_NAME}[${idx}]    @{DCGW_RD}[${idx}]    @{DCGW_IMPORT_RT}[${idx}]    @{DCGW_EXPORT_RT}[${idx}]
    Check BGP Session On DCGW    ${NUM_OF_DCGW}
    Check BGP Session On ODL    ${NUM_OF_DCGW}
    Check BGP Nbr On ODL    ${NUM_OF_DCGW}
    Enable Multipath On ODL
    BuiltIn.Wait Until Keyword Succeeds    10s    2s    Verify Multipath
    : FOR    ${idx}    IN RANGE    ${START_VALUE}    ${NUM_OF_DCGW}
    \    Configure Maxpath    @{MAX_PATH_LIST}[2]    @{MULTIPATH_RD}[${idx}]
    : FOR    ${idx}    IN RANGE    ${START_VALUE}    ${NUM_OF_DCGW}
    \    BuiltIn.Wait Until Keyword Succeeds    10s    2s    Verify Maxpath    @{MAX_PATH_LIST}[2]    @{MULTIPATH_RD}[${idx}]
    Check BGP VPNv4 Nbr On ODL    ${NUM_OF_DCGW}    False

TC3 Verify max-path configuration value should not be 0/-ve, because it’s not supported
    [Documentation]    Verify max-path configuration value should not be 0/-ve, because it’s not supported
    VpnOperations.VPN Create L3VPN    name=@{VPN_NAME}[0]    vpnid=@{VPN_INSTANCE_ID}[0]    rd=@{L3VPN_RD}[0]    exportrt=@{L3VPN_EXPORT_RT}[0]    importrt=@{L3VPN_IMPORT_RT}[0]
    BuiltIn.Wait Until Keyword Succeeds    10s    2s    Verify L3VPN On ODL    ${VPN_INSTANCE_ID[0]}
    : FOR    ${idx}    IN RANGE    ${START_VALUE}    ${NUM_OF_DCGW}
    \    Create L3VPN on Dcgateway    @{DCGW_IP_LIST}[${idx}]    @{VPN_NAME}[0]    @{DCGW_RD}[0]    @{DCGW_IMPORT_RT}[0]    @{DCGW_EXPORT_RT}[0]
    Verify L3VPN On DCGW    ${NUM_OF_DCGW}    @{VPN_NAME}[0]    @{DCGW_RD}[0]    @{DCGW_IMPORT_RT}[0]    @{DCGW_EXPORT_RT}[0]
    Check BGP Session On DCGW    ${NUM_OF_DCGW}
    Check BGP Session On ODL    ${NUM_OF_DCGW}
    Check BGP Nbr On ODL    ${NUM_OF_DCGW}
    Enable Multipath On ODL
    Verify Multipath
    Configure Maxpath    @{MAX_PATH_INVALID_LIST}[0]    @{MULTIPATH_RD}[0]
    Verify Maxpath For Invalid Input    @{MULTIPATH_RD}[0]    @{MAX_PATH_INVALID_LIST}[0]
    Configure Maxpath    @{MAX_PATH_INVALID_LIST}[1]    @{MULTIPATH_RD}[0]
    Verify Maxpath For Invalid Input    @{MULTIPATH_RD}[0]    @{MAX_PATH_INVALID_LIST}[1]
    Configure Maxpath    @{MAX_PATH_INVALID_LIST}[2]    @{MULTIPATH_RD}[0]
    Verify Maxpath For Invalid Input    @{MULTIPATH_RD}[0]    @{MAX_PATH_INVALID_LIST}[2]
    Check BGP VPNv4 Nbr On ODL    ${NUM_OF_DCGW}    False

TC4 Verify that max path default is set to 8 and max path configurable is 64 on CSC
    [Documentation]    Verify that max path default is set to 8 and max path configurable is 64 on CSC
    VpnOperations.VPN Create L3VPN    name=@{VPN_NAME}[0]    vpnid=@{VPN_INSTANCE_ID}[0]    rd=@{L3VPN_RD}[0]    exportrt=@{L3VPN_EXPORT_RT}[0]    importrt=@{L3VPN_IMPORT_RT}[0]
    BuiltIn.Wait Until Keyword Succeeds    10s    2s    Verify L3VPN On ODL    ${VPN_INSTANCE_ID[0]}
    : FOR    ${idx}    IN RANGE    ${START_VALUE}    ${NUM_OF_DCGW}
    \    Create L3VPN on Dcgateway    @{DCGW_IP_LIST}[${idx}]    @{VPN_NAME}[0]    @{DCGW_RD}[0]    @{DCGW_IMPORT_RT}[0]    @{DCGW_EXPORT_RT}[0]
    Verify L3VPN On DCGW    ${NUM_OF_DCGW}    @{VPN_NAME}[0]    @{DCGW_RD}[0]    @{DCGW_IMPORT_RT}[0]    @{DCGW_EXPORT_RT}[0]
    Check BGP Session On DCGW    ${NUM_OF_DCGW}
    Check BGP Session On ODL    ${NUM_OF_DCGW}
    Check BGP Nbr On ODL    ${NUM_OF_DCGW}
    Enable Multipath On ODL
    Verify Multipath
    BuiltIn.Wait Until Keyword Succeeds    10s    2s    Configure Maxpath    @{MAX_PATH_LIST}[4]    @{MULTIPATH_RD}[0]
    BuiltIn.Wait Until Keyword Succeeds    10s    2s    Verify Maxpath    @{MAX_PATH_LIST}[4]    @{MULTIPATH_RD}[0]

TC5 Verify CSC supports dynamic configuration changes for max path value
    [Documentation]    Verify CSC supports dynamic configuration changes for max path value
    VpnOperations.VPN Create L3VPN    name=@{VPN_NAME}[0]    vpnid=@{VPN_INSTANCE_ID}[0]    rd=@{L3VPN_RD}[0]    exportrt=@{L3VPN_EXPORT_RT}[0]    importrt=@{L3VPN_IMPORT_RT}[0]
    BuiltIn.Wait Until Keyword Succeeds    10s    2s    Verify L3VPN On ODL    @{VPN_INSTANCE_ID}[0]
    : FOR    ${idx}    IN RANGE    ${START_VALUE}    ${NUM_OF_DCGW}
    \    Create L3VPN on Dcgateway    @{DCGW_IP_LIST}[${idx}]    @{VPN_NAME}[0]    @{DCGW_RD}[0]    @{DCGW_IMPORT_RT}[0]    @{DCGW_EXPORT_RT}[0]
    Verify L3VPN On DCGW    ${NUM_OF_DCGW}    @{VPN_NAME}[0]    @{DCGW_RD}[0]    @{DCGW_IMPORT_RT}[0]    @{DCGW_EXPORT_RT}[0]
    Check BGP Session On DCGW    ${NUM_OF_DCGW}
    Check BGP Session On ODL    ${NUM_OF_DCGW}
    Check BGP Nbr On ODL    ${NUM_OF_DCGW}
    Enable Multipath On ODL
    BuiltIn.Wait Until Keyword Succeeds    10s    2s    Verify Multipath
    Configure Maxpath    @{MAX_PATH_LIST}[2]    @{MULTIPATH_RD}[0]
    BuiltIn.Wait Until Keyword Succeeds    10s    2s    Verify Maxpath    @{MAX_PATH_LIST}[2]    @{MULTIPATH_RD}[0]
    : FOR    ${idx}    IN RANGE    ${START_VALUE}    ${NUM_OF_DCGW}
    \    Add Routes    @{DCGW_IP_LIST}[${idx}]    @{DCGW_RD}[0]    @{NETWORK_IP}[0]    @{LABEL}[${idx}]
    BuiltIn.Wait Until Keyword Succeeds    60s    10s    Check BGP VPNv4 Nbr On ODL    ${NUM_OF_DCGW}
    BuiltIn.Wait Until Keyword Succeeds    60s    10s    Verify Routing Entry    @{RD}[0]    @{NETWORK_IP}[0]    @{NUM_OF_ROUTES}[3]
    BuiltIn.Wait Until Keyword Succeeds    10s    2s    Verify FIB Entry    @{NETWORK_IP}[0]    @{NUM_OF_ROUTES}[3]
    Configure Maxpath    @{MAX_PATH_LIST}[1]    @{MULTIPATH_RD}[0]
    BuiltIn.Wait Until Keyword Succeeds    10s    2s    Verify Maxpath    @{MAX_PATH_LIST}[1]    @{MULTIPATH_RD}[0]
    BuiltIn.Wait Until Keyword Succeeds    10s    2s    Check BGP VPNv4 Nbr On ODL    ${NUM_OF_DCGW}
    BuiltIn.Wait Until Keyword Succeeds    10s    2s    Verify Routing Entry    @{RD}[0]    @{NETWORK_IP}[0]    @{NUM_OF_ROUTES}[3]
    BuiltIn.Wait Until Keyword Succeeds    10s    2s    Verify FIB Entry    @{NETWORK_IP}[0]    @{NUM_OF_ROUTES}[2]
    Configure Maxpath    @{MAX_PATH_LIST}[0]    @{MULTIPATH_RD}[0]
    BuiltIn.Wait Until Keyword Succeeds    10s    2s    Verify Maxpath    @{MAX_PATH_LIST}[0]    @{MULTIPATH_RD}[0]
    BuiltIn.Wait Until Keyword Succeeds    10s    2s    Check BGP VPNv4 Nbr On ODL    ${NUM_OF_DCGW}
    BuiltIn.Wait Until Keyword Succeeds    10s    2s    Verify Routing Entry    @{RD}[0]    @{NETWORK_IP}[0]    @{NUM_OF_ROUTES}[3]
    BuiltIn.Wait Until Keyword Succeeds    10s    2s    Verify FIB Entry    @{NETWORK_IP}[0]    @{NUM_OF_ROUTES}[1]
    Configure Maxpath    @{MAX_PATH_LIST}[2]    @{MULTIPATH_RD}[0]
    BuiltIn.Wait Until Keyword Succeeds    10s    2s    Verify Maxpath    @{MAX_PATH_LIST}[2]    @{MULTIPATH_RD}[0]
    BuiltIn.Wait Until Keyword Succeeds    10s    2s    Check BGP VPNv4 Nbr On ODL    ${NUM_OF_DCGW}
    BuiltIn.Wait Until Keyword Succeeds    10s    2s    Verify Routing Entry    @{RD}[0]    @{NETWORK_IP}[0]    @{NUM_OF_ROUTES}[3]
    BuiltIn.Wait Until Keyword Succeeds    30s    5s    Verify FIB Entry    @{NETWORK_IP}[0]    @{NUM_OF_ROUTES}[3]

TC6 Verify that ECMP path gets withdrawn by QBGP after disabling Multipath
    [Documentation]    Verify that ECMP path gets withdrawn by QBGP after disabling Multipath
    VpnOperations.VPN Create L3VPN    name=@{VPN_NAME}[0]    vpnid=@{VPN_INSTANCE_ID}[0]    rd=@{L3VPN_RD}[0]    exportrt=@{L3VPN_EXPORT_RT}[0]    importrt=@{L3VPN_IMPORT_RT}[0]
    BuiltIn.Wait Until Keyword Succeeds    10s    2s    Verify L3VPN On ODL    @{VPN_INSTANCE_ID}[0]
    : FOR    ${idx}    IN RANGE    ${START_VALUE}    ${NUM_OF_DCGW}
    \    Create L3VPN on Dcgateway    @{DCGW_IP_LIST}[${idx}]    @{VPN_NAME}[0]    @{DCGW_RD}[0]    @{DCGW_IMPORT_RT}[0]    @{DCGW_EXPORT_RT}[0]
    Verify L3VPN On DCGW    ${NUM_OF_DCGW}    @{VPN_NAME}[0]    @{DCGW_RD}[0]    @{DCGW_IMPORT_RT}[0]    @{DCGW_EXPORT_RT}[0]
    Check BGP Session On DCGW    ${NUM_OF_DCGW}
    Check BGP Session On ODL    ${NUM_OF_DCGW}
    Check BGP Nbr On ODL    ${NUM_OF_DCGW}
    Enable Multipath On ODL
    BuiltIn.Wait Until Keyword Succeeds    10s    2s    Configure Maxpath    @{MAX_PATH_LIST}[2]    @{MULTIPATH_RD}[0]
    BuiltIn.Wait Until Keyword Succeeds    10s    2s    Verify Maxpath    @{MAX_PATH_LIST}[2]    @{MULTIPATH_RD}[0]
    : FOR    ${idx}    IN RANGE    ${START_VALUE}    ${NUM_OF_DCGW}
    \    Add Routes    @{DCGW_IP_LIST}[${idx}]    @{DCGW_RD}[0]    @{NETWORK_IP}[0]    @{LABEL}[${idx}]
    BuiltIn.Wait Until Keyword Succeeds    60s    10s    Check BGP VPNv4 Nbr On ODL    ${NUM_OF_DCGW}
    BuiltIn.Wait Until Keyword Succeeds    60s    10s    Verify Routing Entry    @{RD}[0]    @{NETWORK_IP}[0]    @{NUM_OF_ROUTES}[3]
    BuiltIn.Wait Until Keyword Succeeds    10s    2s    Verify FIB Entry    @{NETWORK_IP}[0]    @{NUM_OF_ROUTES}[3]
    Configure Maxpath    @{MAX_PATH_LIST}[0]    @{MULTIPATH_RD}[0]
    BuiltIn.Wait Until Keyword Succeeds    10s    2s    Verify Routing Entry    @{RD}[0]    @{NETWORK_IP}[0]    @{NUM_OF_ROUTES}[3]
    BuiltIn.Wait Until Keyword Succeeds    10s    2s    Verify FIB Entry    @{NETWORK_IP}[0]    @{NUM_OF_ROUTES}[1]
    Configure Maxpath    @{MAX_PATH_LIST}[2]    @{MULTIPATH_RD}[0]
    BuiltIn.Wait Until Keyword Succeeds    10s    2s    Verify Routing Entry    @{RD}[0]    @{NETWORK_IP}[0]    @{NUM_OF_ROUTES}[3]
    BuiltIn.Wait Until Keyword Succeeds    10s    2s    Verify FIB Entry    @{NETWORK_IP}[0]    @{NUM_OF_ROUTES}[3]

TC7 Verify ECMP path advertised by QBGP to CSC in case of distinct VRF
    [Documentation]    Verify ECMP path advertised by QBGP to CSC in case of distinct VRF
    VpnOperations.VPN Create L3VPN    name=@{VPN_NAME}[0]    vpnid=@{VPN_INSTANCE_ID}[0]    rd=@{L3VPN_RD}[0]    exportrt=@{L3VPN_EXPORT_RT}[0]    importrt=@{L3VPN_IMPORT_RT}[0]
    VpnOperations.VPN Create L3VPN    name=@{VPN_NAME}[1]    vpnid=@{VPN_INSTANCE_ID}[1]    rd=@{L3VPN_RD}[1]    exportrt=@{L3VPN_EXPORT_RT}[1]    importrt=@{L3VPN_IMPORT_RT}[1]
    BuiltIn.Wait Until Keyword Succeeds    10s    2s    Verify L3VPN On ODL    @{VPN_INSTANCE_ID}[0]    @{VPN_INSTANCE_ID}[1]
    : FOR    ${idx}    IN RANGE    0    1
    \    Create L3VPN on Dcgateway    @{DCGW_IP_LIST}[${idx}]    @{VPN_NAME}[${idx}]    @{DCGW_RD}[0]    @{DCGW_IMPORT_RT}[0]    @{DCGW_EXPORT_RT}[0]
    : FOR    ${idx}    IN RANGE    1    ${NUM_OF_DCGW}
    \    Create L3VPN on Dcgateway    @{DCGW_IP_LIST}[${idx}]    @{VPN_NAME}[${idx}]    @{DCGW_RD}[1]    @{DCGW_IMPORT_RT}[1]    @{DCGW_EXPORT_RT}[1]
    Check BGP Session On DCGW    ${NUM_OF_DCGW}
    Check BGP Session On ODL    ${NUM_OF_DCGW}
    Check BGP Nbr On ODL    ${NUM_OF_DCGW}
    Enable Multipath On ODL
    BuiltIn.Wait Until Keyword Succeeds    10s    2s    Verify Multipath
    BuiltIn.Wait Until Keyword Succeeds    10s    2s    Configure Maxpath    @{MAX_PATH_LIST}[2]    @{MULTIPATH_RD}[0]
    BuiltIn.Wait Until Keyword Succeeds    10s    2s    Configure Maxpath    @{MAX_PATH_LIST}[2]    @{MULTIPATH_RD}[1]
    BuiltIn.Wait Until Keyword Succeeds    10s    2s    Verify Maxpath    @{MAX_PATH_LIST}[2]    @{MULTIPATH_RD}[0]
    BuiltIn.Wait Until Keyword Succeeds    10s    2s    Verify Maxpath    @{MAX_PATH_LIST}[2]    @{MULTIPATH_RD}[1]
    : FOR    ${idx}    IN RANGE    0    1
    \    Add Routes    @{DCGW_IP_LIST}[${idx}]    @{DCGW_RD}[0]    @{NETWORK_IP}[0]    @{LABEL}[${idx}]
    \    Add Routes    @{DCGW_IP_LIST}[${idx}]    @{DCGW_RD}[0]    @{NETWORK_IP}[1]    @{LABEL}[${idx}]
    : FOR    ${idx}    IN RANGE    1    ${NUM_OF_DCGW}
    \    Add Routes    @{DCGW_IP_LIST}[${idx}]    @{DCGW_RD}[1]    @{NETWORK_IP}[0]    @{LABEL}[${idx}]
    \    Add Routes    @{DCGW_IP_LIST}[${idx}]    @{DCGW_RD}[1]    @{NETWORK_IP}[1]    @{LABEL}[${idx}]
    BuiltIn.Wait Until Keyword Succeeds    60s    10s    Check BGP VPNv4 Nbr On ODL    ${NUM_OF_DCGW}
    BuiltIn.Wait Until Keyword Succeeds    60s    10s    Verify Routing Entry    @{RD}[0]    @{NETWORK_IP}[0]    @{NUM_OF_ROUTES}[1]
    BuiltIn.Wait Until Keyword Succeeds    10s    2s    Verify Routing Entry    @{RD}[0]    @{NETWORK_IP}[1]    @{NUM_OF_ROUTES}[1]
    BuiltIn.Wait Until Keyword Succeeds    10s    2s    Verify Routing Entry    @{RD}[1]    @{NETWORK_IP}[0]    @{NUM_OF_ROUTES}[2]
    BuiltIn.Wait Until Keyword Succeeds    10s    2s    Verify Routing Entry    @{RD}[1]    @{NETWORK_IP}[1]    @{NUM_OF_ROUTES}[2]
    BuiltIn.Wait Until Keyword Succeeds    10s    2s    Verify FIB Entry    @{NETWORK_IP}[0]    @{NUM_OF_ROUTES}[3]
    BuiltIn.Wait Until Keyword Succeeds    10s    2s    Verify FIB Entry    @{NETWORK_IP}[1]    @{NUM_OF_ROUTES}[3]
    Verify Route Entry With Nexthop    @{RD}[0]    @{NETWORK_IP}[0]    start=0    end=1
    Verify Route Entry With Nexthop    @{RD}[0]    @{NETWORK_IP}[1]    start=0    end=1
    Verify Route Entry With Nexthop    @{RD}[1]    @{NETWORK_IP}[0]    start=1    end=3
    Verify Route Entry With Nexthop    @{RD}[1]    @{NETWORK_IP}[1]    start=1    end=3
    Delete Routes    @{DCGW_IP_LIST}[2]    @{DCGW_RD}[1]    @{NETWORK_IP}[0]    @{LABEL}[2]
    Delete Routes    @{DCGW_IP_LIST}[2]    @{DCGW_RD}[1]    @{NETWORK_IP}[1]    @{LABEL}[2]
    BuiltIn.Wait Until Keyword Succeeds    30s    5s    Check BGP VPNv4 Nbr On ODL    ${NUM_OF_DCGW}    flag=False    start=2
    BuiltIn.Wait Until Keyword Succeeds    30s    5s    Verify Routing Entry    @{RD}[0]    @{NETWORK_IP}[0]    @{NUM_OF_ROUTES}[1]
    BuiltIn.Wait Until Keyword Succeeds    10s    2s    Verify Routing Entry    @{RD}[0]    @{NETWORK_IP}[1]    @{NUM_OF_ROUTES}[1]
    BuiltIn.Wait Until Keyword Succeeds    10s    2s    Verify Routing Entry    @{RD}[1]    @{NETWORK_IP}[0]    @{NUM_OF_ROUTES}[1]
    BuiltIn.Wait Until Keyword Succeeds    10s    2s    Verify Routing Entry    @{RD}[1]    @{NETWORK_IP}[1]    @{NUM_OF_ROUTES}[1]
    BuiltIn.Wait Until Keyword Succeeds    10s    2s    Verify FIB Entry    @{NETWORK_IP}[0]    @{NUM_OF_ROUTES}[2]
    BuiltIn.Wait Until Keyword Succeeds    10s    2s    Verify FIB Entry    @{NETWORK_IP}[1]    @{NUM_OF_ROUTES}[2]
    Verify Leaking Route Across VPNs    @{RD}[0]    @{DCGW_IP_LIST}[1]    @{DCGW_IP_LIST}[2]
    Verify Leaking Route Across VPNs    @{RD}[1]    @{DCGW_IP_LIST}[0]

TC8 Verify ECMP path advertised by QBGP to CSC when routes shared across VPNs
    [Documentation]    Verify ECMP path advertised by QBGP to CSC when routes shared across VPNs
    VpnOperations.VPN Create L3VPN    name=@{VPN_NAME}[0]    vpnid=@{VPN_INSTANCE_ID}[0]    rd=@{L3VPN_RD}[0]    importrt=${L3VPN_IMPORT_RT_123}    exportrt=@{L3VPN_EXPORT_RT}[0]
    VpnOperations.VPN Create L3VPN    name=@{VPN_NAME}[1]    vpnid=@{VPN_INSTANCE_ID}[1]    rd=@{L3VPN_RD}[1]    importrt=@{L3VPN_IMPORT_RT}[0]    exportrt=@{L3VPN_EXPORT_RT}[0]
    VpnOperations.VPN Create L3VPN    name=@{VPN_NAME}[2]    vpnid=@{VPN_INSTANCE_ID}[2]    rd=@{L3VPN_RD}[2]    importrt=${L3VPN_IMPORT_RT_23}    exportrt=@{L3VPN_EXPORT_RT}[0]
    BuiltIn.Wait Until Keyword Succeeds    10s    2s    Verify L3VPN On ODL    @{VPN_INSTANCE_ID}[0]    @{VPN_INSTANCE_ID}[1]    @{VPN_INSTANCE_ID}[2]
    Create L3VPN on Dcgateway    @{DCGW_IP_LIST}[0]    @{VPN_NAME}[0]    @{DCGW_RD}[0]    @{DCGW_IMPORT_RT}[0]    @{DCGW_EXPORT_RT}[0]
    Create L3VPN on Dcgateway    @{DCGW_IP_LIST}[1]    @{VPN_NAME}[1]    @{DCGW_RD}[1]    @{DCGW_IMPORT_RT}[0]    @{DCGW_EXPORT_RT}[1]
    Create L3VPN on Dcgateway    @{DCGW_IP_LIST}[2]    @{VPN_NAME}[2]    @{DCGW_RD}[2]    @{DCGW_IMPORT_RT}[0]    @{DCGW_EXPORT_RT}[2]
    Check BGP Session On DCGW    ${NUM_OF_DCGW}
    Check BGP Session On ODL    ${NUM_OF_DCGW}
    Check BGP Nbr On ODL    ${NUM_OF_DCGW}
    Enable Multipath On ODL
    BuiltIn.Wait Until Keyword Succeeds    10s    2s    Verify Multipath
    : FOR    ${idx}    IN RANGE    ${START_VALUE}    ${NUM_OF_DCGW}
    \    BuiltIn.Wait Until Keyword Succeeds    10s    2s    Configure Maxpath    @{MAX_PATH_LIST}[2]    @{MULTIPATH_RD}[${idx}]
    : FOR    ${idx}    IN RANGE    ${START_VALUE}    ${NUM_OF_DCGW}
    \    BuiltIn.Wait Until Keyword Succeeds    10s    2s    Verify Maxpath    @{MAX_PATH_LIST}[2]    @{MULTIPATH_RD}[${idx}]
    Add Routes    @{DCGW_IP_LIST}[0]    @{DCGW_RD}[0]    @{NETWORK_IP}[0]    @{LABEL}[0]
    Add Routes    @{DCGW_IP_LIST}[1]    @{DCGW_RD}[1]    @{NETWORK_IP}[0]    @{LABEL}[1]
    Add Routes    @{DCGW_IP_LIST}[2]    @{DCGW_RD}[2]    @{NETWORK_IP}[0]    @{LABEL}[2]
    BuiltIn.Wait Until Keyword Succeeds    60s    10s    Check BGP VPNv4 Nbr On ODL    ${NUM_OF_DCGW}
    BuiltIn.Wait Until Keyword Succeeds    60s    10s    Verify Routing Entry    @{RD}[0]    @{NETWORK_IP}[0]    @{NUM_OF_ROUTES}[3]
    BuiltIn.Wait Until Keyword Succeeds    10s    2s    Verify Routing Entry    @{RD}[1]    @{NETWORK_IP}[0]    @{NUM_OF_ROUTES}[1]
    BuiltIn.Wait Until Keyword Succeeds    10s    2s    Verify Routing Entry    @{RD}[2]    @{NETWORK_IP}[0]    @{NUM_OF_ROUTES}[2]
    BuiltIn.Wait Until Keyword Succeeds    10s    2s    Verify FIB Entry    @{NETWORK_IP}[0]    @{NUM_OF_ROUTES}[6]
    Verify Route Entry With Nexthop    @{RD}[0]    @{NETWORK_IP}[0]    start=0    end=3
    Verify Route Entry With Nexthop    @{RD}[1]    @{NETWORK_IP}[0]    start=0    end=1
    Verify Route Entry With Nexthop    @{RD}[2]    @{NETWORK_IP}[0]    start=1    end=3
    BuiltIn.Wait Until Keyword Succeeds    10s    2s    Configure Maxpath    @{MAX_PATH_LIST}[1]    @{MULTIPATH_RD}[0]
    BuiltIn.Wait Until Keyword Succeeds    10s    2s    Verify Maxpath    @{MAX_PATH_LIST}[1]    @{MULTIPATH_RD}[0]
    BuiltIn.Wait Until Keyword Succeeds    10s    2s    Check BGP VPNv4 Nbr On ODL    ${NUM_OF_DCGW}
    BuiltIn.Wait Until Keyword Succeeds    10s    2s    Verify Routing Entry    @{RD}[0]    @{NETWORK_IP}[0]    @{NUM_OF_ROUTES}[3]
    BuiltIn.Wait Until Keyword Succeeds    10s    2s    Verify Routing Entry    @{RD}[1]    @{NETWORK_IP}[0]    @{NUM_OF_ROUTES}[1]
    BuiltIn.Wait Until Keyword Succeeds    10s    2s    Verify Routing Entry    @{RD}[2]    @{NETWORK_IP}[0]    @{NUM_OF_ROUTES}[2]
    BuiltIn.Wait Until Keyword Succeeds    10s    2s    Verify FIB Entry    @{NETWORK_IP}[0]    @{NUM_OF_ROUTES}[5]
    Verify Route Entry With Nexthop    @{RD}[0]    @{NETWORK_IP}[0]    start=0    end=3
    Verify Route Entry With Nexthop    @{RD}[1]    @{NETWORK_IP}[0]    start=0    end=1
    Verify Route Entry With Nexthop    @{RD}[2]    @{NETWORK_IP}[0]    start=1    end=3

TC9 Verify BGP routes advertised to CSC when QBGP receives only unequal cost routes
    [Documentation]    Verify BGP routes advertised to CSC when QBGP receives only unequal cost routes
    VpnOperations.VPN Create L3VPN    name=@{VPN_NAME}[0]    vpnid=@{VPN_INSTANCE_ID}[0]    rd=@{L3VPN_RD}[0]    exportrt=@{L3VPN_EXPORT_RT}[0]    importrt=@{L3VPN_IMPORT_RT}[0]
    BuiltIn.Wait Until Keyword Succeeds    10s    2s    Verify L3VPN On ODL    @{VPN_INSTANCE_ID}[0]
    : FOR    ${idx}    IN RANGE    ${START_VALUE}    ${NUM_OF_DCGW}
    \    Create L3VPN on Dcgateway    @{DCGW_IP_LIST}[${idx}]    @{VPN_NAME}[0]    @{DCGW_RD}[0]    @{DCGW_IMPORT_RT}[0]    @{DCGW_EXPORT_RT}[0]
    Verify L3VPN On DCGW    ${NUM_OF_DCGW}    @{VPN_NAME}[0]    @{DCGW_RD}[0]    @{DCGW_IMPORT_RT}[0]    @{DCGW_EXPORT_RT}[0]
    Check BGP Session On DCGW    ${NUM_OF_DCGW}
    Check BGP Session On ODL    ${NUM_OF_DCGW}
    Check BGP Nbr On ODL    ${NUM_OF_DCGW}
    Enable Multipath On ODL
    BuiltIn.Wait Until Keyword Succeeds    10s    2s    Verify Multipath
    Configure Maxpath    @{MAX_PATH_LIST}[2]    @{MULTIPATH_RD}[0]
    BuiltIn.Wait Until Keyword Succeeds    10s    2s    Verify Maxpath    @{MAX_PATH_LIST}[2]    @{MULTIPATH_RD}[0]
    : FOR    ${idx}    IN RANGE    ${START_VALUE}    ${NUM_OF_DCGW}
    \    Add Routes    @{DCGW_IP_LIST}[${idx}]    @{DCGW_RD}[0]    @{NETWORK_IP}[0]    @{LABEL}[${idx}]
    BuiltIn.Wait Until Keyword Succeeds    60s    10s    Check BGP VPNv4 Nbr On ODL    ${NUM_OF_DCGW}
    BuiltIn.Wait Until Keyword Succeeds    60s    10s    Verify Routing Entry    @{RD}[0]    @{NETWORK_IP}[0]    @{NUM_OF_ROUTES}[3]
    BuiltIn.Wait Until Keyword Succeeds    10s    2s    Verify FIB Entry    @{NETWORK_IP}[0]    @{NUM_OF_ROUTES}[3]
    : FOR    ${idx}    IN RANGE    ${START_VALUE}    ${NUM_OF_DCGW}
    \    Configure BGP Preference    @{DCGW_IP_LIST}[${idx}]    @{PREF_LIST}[${idx}]
    BuiltIn.Wait Until Keyword Succeeds    30s    5s    Verify Routing Entry    @{RD}[0]    @{NETWORK_IP}[0]    @{NUM_OF_ROUTES}[3]
    BuiltIn.Wait Until Keyword Succeeds    10s    2s    Verify FIB Entry    @{NETWORK_IP}[0]    @{NUM_OF_ROUTES}[1]
    Verify Route Entry With Nexthop    @{RD}[0]    @{NETWORK_IP}[0]    start=2    end=3
    Configure Maxpath    @{MAX_PATH_LIST}[1]    @{MULTIPATH_RD}[0]
    BuiltIn.Wait Until Keyword Succeeds    10s    2s    Verify Maxpath    @{MAX_PATH_LIST}[1]    @{MULTIPATH_RD}[0]
    : FOR    ${idx}    IN RANGE    ${START_VALUE}    ${NUM_OF_DCGW}
    \    Configure BGP Preference    @{DCGW_IP_LIST}[${idx}]    @{PREF_LIST}[0]
    Check BGP Session On DCGW    ${NUM_OF_DCGW}
    Check BGP Session On ODL    ${NUM_OF_DCGW}
    Check BGP Nbr On ODL    ${NUM_OF_DCGW}
    BuiltIn.Wait Until Keyword Succeeds    30s    2s    Verify Routing Entry    @{RD}[0]    @{NETWORK_IP}[0]    @{NUM_OF_ROUTES}[3]
    BuiltIn.Wait Until Keyword Succeeds    30s    2s    Verify FIB Entry    @{NETWORK_IP}[0]    @{NUM_OF_ROUTES}[2]

TC10 Verify ECMP routes on CSC, when QBGP receives combination of equal and unequal cost routes
    [Documentation]    Verify ECMP routes on CSC, when QBGP receives combination of equal and unequal cost routes
    VpnOperations.VPN Create L3VPN    name=@{VPN_NAME}[0]    vpnid=@{VPN_INSTANCE_ID}[0]    rd=@{L3VPN_RD}[0]    exportrt=@{L3VPN_EXPORT_RT}[0]    importrt=@{L3VPN_IMPORT_RT}[0]
    BuiltIn.Wait Until Keyword Succeeds    10s    2s    Verify L3VPN On ODL    @{VPN_INSTANCE_ID}[0]
    : FOR    ${idx}    IN RANGE    ${START_VALUE}    ${NUM_OF_DCGW}
    \    Create L3VPN on Dcgateway    @{DCGW_IP_LIST}[${idx}]    @{VPN_NAME}[0]    @{DCGW_RD}[0]    @{DCGW_IMPORT_RT}[0]    @{DCGW_EXPORT_RT}[0]
    Verify L3VPN On DCGW    ${NUM_OF_DCGW}    @{VPN_NAME}[0]    @{DCGW_RD}[0]    @{DCGW_IMPORT_RT}[0]    @{DCGW_EXPORT_RT}[0]
    Check BGP Session On DCGW    ${NUM_OF_DCGW}
    Check BGP Session On ODL    ${NUM_OF_DCGW}
    Check BGP Nbr On ODL    ${NUM_OF_DCGW}
    Enable Multipath On ODL
    BuiltIn.Wait Until Keyword Succeeds    10s    2s    Verify Multipath
    BuiltIn.Wait Until Keyword Succeeds    10s    2s    Configure Maxpath    @{MAX_PATH_LIST}[2]    @{MULTIPATH_RD}[0]
    BuiltIn.Wait Until Keyword Succeeds    10s    2s    Verify Maxpath    @{MAX_PATH_LIST}[2]    @{MULTIPATH_RD}[0]
    : FOR    ${idx}    IN RANGE    ${START_VALUE}    ${NUM_OF_DCGW}
    \    Add Routes    @{DCGW_IP_LIST}[${idx}]    @{DCGW_RD}[0]    @{NETWORK_IP}[0]    @{LABEL}[${idx}]
    BuiltIn.Wait Until Keyword Succeeds    60s    10s    Check BGP VPNv4 Nbr On ODL    ${NUM_OF_DCGW}
    BuiltIn.Wait Until Keyword Succeeds    60s    10s    Verify Routing Entry    @{RD}[0]    @{NETWORK_IP}[0]    @{NUM_OF_ROUTES}[3]
    BuiltIn.Wait Until Keyword Succeeds    10s    2s    Verify FIB Entry    @{NETWORK_IP}[0]    @{NUM_OF_ROUTES}[3]
    : FOR    ${idx}    IN RANGE    0    2
    \    Configure BGP Preference    @{DCGW_IP_LIST}[${idx}]    @{PREF_LIST_110}[${idx}]
    : FOR    ${idx}    IN RANGE    2    3
    \    Configure BGP Preference    @{DCGW_IP_LIST}[${idx}]    @{PREF_LIST_110}[${idx}]
    BuiltIn.Wait Until Keyword Succeeds    30s    5s    Verify Routing Entry    @{RD}[0]    @{NETWORK_IP}[0]    @{NUM_OF_ROUTES}[3]
    BuiltIn.Wait Until Keyword Succeeds    10s    2s    Verify FIB Entry    @{NETWORK_IP}[0]    @{NUM_OF_ROUTES}[2]
    : FOR    ${idx}    IN RANGE    ${START_VALUE}    ${NUM_OF_DCGW}
    \    Configure BGP Preference    @{DCGW_IP_LIST}[${idx}]    @{PREF_LIST}[${idx}]
    BuiltIn.Wait Until Keyword Succeeds    10s    2s    Verify Routing Entry    @{RD}[0]    @{NETWORK_IP}[0]    @{NUM_OF_ROUTES}[3]
    BuiltIn.Wait Until Keyword Succeeds    10s    2s    Verify FIB Entry    @{NETWORK_IP}[0]    @{NUM_OF_ROUTES}[1]
    Verify Route Entry With Nexthop    @{RD}[0]    @{NETWORK_IP}[0]    start=2    end=3

TC11_Verify route resynchronization of DC-GW with QBGP after cluster reboot
    [Documentation]    Verify route resynchronization of DC-GW with QBGP after cluster reboot
    VpnOperations.VPN Create L3VPN    name=@{VPN_NAME}[0]    vpnid=@{VPN_INSTANCE_ID}[0]    rd=@{L3VPN_RD}[0]    importrt=@{L3VPN_IMPORT_RT}[0]    exportrt=@{L3VPN_EXPORT_RT}[0]
    VpnOperations.VPN Create L3VPN    name=@{VPN_NAME}[1]    vpnid=@{VPN_INSTANCE_ID}[1]    rd=@{L3VPN_RD}[1]    importrt=${L3VPN_IMPORT_RT_12}    exportrt=@{L3VPN_EXPORT_RT}[0]
    VpnOperations.VPN Create L3VPN    name=@{VPN_NAME}[2]    vpnid=@{VPN_INSTANCE_ID}[2]    rd=@{L3VPN_RD}[2]    importrt=@{L3VPN_IMPORT_RT}[2]    exportrt=@{L3VPN_EXPORT_RT}[1]
    BuiltIn.Wait Until Keyword Succeeds    10s    2s    Verify L3VPN On ODL    @{VPN_INSTANCE_ID}[0]    @{VPN_INSTANCE_ID}[1]    @{VPN_INSTANCE_ID}[2]
    Create L3VPN on Dcgateway    @{DCGW_IP_LIST}[0]    @{VPN_NAME}[0]    @{DCGW_RD}[0]    @{DCGW_IMPORT_RT}[0]    @{DCGW_EXPORT_RT}[0]
    : FOR    ${idx}    IN RANGE    0    2
    \    Create L3VPN on Dcgateway    @{DCGW_IP_LIST}[1]    @{VPN_NAME}[${idx}]    @{DCGW_RD}[${idx}]    @{DCGW_IMPORT_RT}[${idx}]    @{DCGW_EXPORT_RT}[${idx}]
    : FOR    ${idx}    IN RANGE    0    3
    \    Create L3VPN on Dcgateway    @{DCGW_IP_LIST}[2]    @{VPN_NAME}[${idx}]    @{DCGW_RD}[${idx}]    @{DCGW_IMPORT_RT}[${idx}]    @{DCGW_EXPORT_RT}[${idx}]
    Check BGP Session On DCGW    ${NUM_OF_DCGW}
    Check BGP Session On ODL    ${NUM_OF_DCGW}
    Check BGP Nbr On ODL    ${NUM_OF_DCGW}
    Enable Multipath On ODL
    BuiltIn.Wait Until Keyword Succeeds    10s    2s    Verify Multipath
    : FOR    ${idx}    IN RANGE    ${START_VALUE}    ${NUM_OF_DCGW}
    \    BuiltIn.Wait Until Keyword Succeeds    10s    2s    Configure Maxpath    @{MAX_PATH_LIST}[2]    @{MULTIPATH_RD}[${idx}]
    : FOR    ${idx}    IN RANGE    ${START_VALUE}    ${NUM_OF_DCGW}
    \    BuiltIn.Wait Until Keyword Succeeds    10s    2s    Verify Maxpath    @{MAX_PATH_LIST}[2]    @{MULTIPATH_RD}[${idx}]
    Add Routes    @{DCGW_IP_LIST}[0]    @{DCGW_RD}[0]    @{NETWORK_IP}[0]    @{LABEL}[0]
    : FOR    ${idx}    IN RANGE    0    2
    \    Add Routes    @{DCGW_IP_LIST}[1]    @{DCGW_RD}[${idx}]    @{NETWORK_IP}[0]    @{LABEL}[${idx}]
    : FOR    ${idx}    IN RANGE    0    3
    \    Add Routes    @{DCGW_IP_LIST}[2]    @{DCGW_RD}[${idx}]    @{NETWORK_IP}[0]    @{LABEL}[${idx}]
    : FOR    ${idx}    IN RANGE    0    2
    \    Configure BGP Preference    @{DCGW_IP_LIST}[${idx}]    @{PREF_LIST_110}[${idx}]
    Configure BGP Preference    @{DCGW_IP_LIST}[2]    @{PREF_LIST_110}[2]
    BuiltIn.Wait Until Keyword Succeeds    60s    10s    Check BGP VPNv4 Nbr On ODL    ${NUM_OF_DCGW}
    BuiltIn.Wait Until Keyword Succeeds    60s    10s    Verify Routing Entry    @{RD}[0]    @{NETWORK_IP}[0]    @{NUM_OF_ROUTES}[3]
    BuiltIn.Wait Until Keyword Succeeds    10s    2s    Verify Routing Entry    @{RD}[1]    @{NETWORK_IP}[0]    @{NUM_OF_ROUTES}[5]
    BuiltIn.Wait Until Keyword Succeeds    10s    2s    Verify Routing Entry    @{RD}[2]    @{NETWORK_IP}[0]    @{NUM_OF_ROUTES}[1]
    BuiltIn.Wait Until Keyword Succeeds    10s    2s    Verify FIB Entry    @{NETWORK_IP}[0]    @{NUM_OF_ROUTES}[5]
    Verify Route Entry With Nexthop    @{RD}[0]    @{NETWORK_IP}[0]    start=0    end=2
    Verify Route Entry With Nexthop    @{RD}[1]    @{NETWORK_IP}[0]    start=0    end=2
    Verify Route Entry With Nexthop    @{RD}[2]    @{NETWORK_IP}[0]    start=2    end=3
    Log    Restarting ODL Cluster
    BuiltIn.Wait Until Keyword Succeeds    60s    10s    Check BGP VPNv4 Nbr On ODL    ${NUM_OF_DCGW}
    BuiltIn.Wait Until Keyword Succeeds    60s    10s    Verify Routing Entry    @{RD}[0]    @{NETWORK_IP}[0]    @{NUM_OF_ROUTES}[3]
    BuiltIn.Wait Until Keyword Succeeds    10s    2s    Verify Routing Entry    @{RD}[1]    @{NETWORK_IP}[0]    @{NUM_OF_ROUTES}[5]
    BuiltIn.Wait Until Keyword Succeeds    10s    2s    Verify Routing Entry    @{RD}[2]    @{NETWORK_IP}[0]    @{NUM_OF_ROUTES}[1]
    BuiltIn.Wait Until Keyword Succeeds    10s    2s    Verify FIB Entry    @{NETWORK_IP}[0]    @{NUM_OF_ROUTES}[5]
    Verify Route Entry With Nexthop    @{RD}[0]    @{NETWORK_IP}[0]    start=0    end=2
    Verify Route Entry With Nexthop    @{RD}[1]    @{NETWORK_IP}[0]    start=0    end=2
    Verify Route Entry With Nexthop    @{RD}[2]    @{NETWORK_IP}[0]    start=2    end=3
    Delete Routes    @{DCGW_IP_LIST}[2]    @{DCGW_RD}[2]    @{NETWORK_IP}[0]    @{LABEL}[2]
    BuiltIn.Wait Until Keyword Succeeds    60s    10s    Verify Routing Entry    @{RD}[0]    @{NETWORK_IP}[0]    @{NUM_OF_ROUTES}[3]
    BuiltIn.Wait Until Keyword Succeeds    10s    2s    Verify Routing Entry    @{RD}[1]    @{NETWORK_IP}[0]    @{NUM_OF_ROUTES}[5]
    BuiltIn.Wait Until Keyword Succeeds    10s    2s    Verify Routing Entry    @{RD}[2]    @{NETWORK_IP}[0]    @{NUM_OF_ROUTES}[0]
    BuiltIn.Wait Until Keyword Succeeds    10s    2s    Verify FIB Entry    @{NETWORK_IP}[0]    @{NUM_OF_ROUTES}[4]

TC12_Verify equal cost route resynchronization of DC-GW with QBGP after ODL reboot/restart
    [Documentation]    Verify equal cost route resynchronization of DC-GW with QBGP after ODL reboot/restart
    VpnOperations.VPN Create L3VPN    name=@{VPN_NAME}[0]    vpnid=@{VPN_INSTANCE_ID}[0]    rd=@{L3VPN_RD}[0]    importrt=@{L3VPN_IMPORT_RT}[0]    exportrt=@{L3VPN_EXPORT_RT}[0]
    VpnOperations.VPN Create L3VPN    name=@{VPN_NAME}[1]    vpnid=@{VPN_INSTANCE_ID}[1]    rd=@{L3VPN_RD}[1]    importrt=${L3VPN_IMPORT_RT_12}    exportrt=@{L3VPN_EXPORT_RT}[0]
    VpnOperations.VPN Create L3VPN    name=@{VPN_NAME}[2]    vpnid=@{VPN_INSTANCE_ID}[2]    rd=@{L3VPN_RD}[2]    importrt=@{L3VPN_IMPORT_RT}[2]    exportrt=@{L3VPN_EXPORT_RT}[1]
    BuiltIn.Wait Until Keyword Succeeds    10s    2s    Verify L3VPN On ODL    @{VPN_INSTANCE_ID}[0]    @{VPN_INSTANCE_ID}[1]    @{VPN_INSTANCE_ID}[2]
    Create L3VPN on Dcgateway    @{DCGW_IP_LIST}[0]    @{VPN_NAME}[0]    @{DCGW_RD}[0]    @{DCGW_IMPORT_RT}[0]    @{DCGW_EXPORT_RT}[0]
    : FOR    ${idx}    IN RANGE    0    2
    \    Create L3VPN on Dcgateway    @{DCGW_IP_LIST}[1]    @{VPN_NAME}[${idx}]    @{DCGW_RD}[${idx}]    @{DCGW_IMPORT_RT}[${idx}]    @{DCGW_EXPORT_RT}[${idx}]
    : FOR    ${idx}    IN RANGE    0    3
    \    Create L3VPN on Dcgateway    @{DCGW_IP_LIST}[2]    @{VPN_NAME}[${idx}]    @{DCGW_RD}[${idx}]    @{DCGW_IMPORT_RT}[${idx}]    @{DCGW_EXPORT_RT}[${idx}]
    Check BGP Session On DCGW    ${NUM_OF_DCGW}
    Check BGP Session On ODL    ${NUM_OF_DCGW}
    Check BGP Nbr On ODL    ${NUM_OF_DCGW}
    Enable Multipath On ODL
    BuiltIn.Wait Until Keyword Succeeds    10s    2s    Verify Multipath
    : FOR    ${idx}    IN RANGE    ${START_VALUE}    ${NUM_OF_DCGW}
    \    BuiltIn.Wait Until Keyword Succeeds    10s    2s    Configure Maxpath    @{MAX_PATH_LIST}[2]    @{MULTIPATH_RD}[${idx}]
    : FOR    ${idx}    IN RANGE    ${START_VALUE}    ${NUM_OF_DCGW}
    \    BuiltIn.Wait Until Keyword Succeeds    10s    2s    Verify Maxpath    @{MAX_PATH_LIST}[2]    @{MULTIPATH_RD}[${idx}]
    Add Routes    @{DCGW_IP_LIST}[0]    @{DCGW_RD}[0]    @{NETWORK_IP}[0]    @{LABEL}[0]
    : FOR    ${idx}    IN RANGE    0    2
    \    Add Routes    @{DCGW_IP_LIST}[1]    @{DCGW_RD}[${idx}]    @{NETWORK_IP}[0]    @{LABEL}[${idx}]
    : FOR    ${idx}    IN RANGE    0    3
    \    Add Routes    @{DCGW_IP_LIST}[2]    @{DCGW_RD}[${idx}]    @{NETWORK_IP}[0]    @{LABEL}[${idx}]
    : FOR    ${idx}    IN RANGE    0    2
    \    Configure BGP Preference    @{DCGW_IP_LIST}[${idx}]    @{PREF_LIST_110}[${idx}]
    Configure BGP Preference    @{DCGW_IP_LIST}[2]    @{PREF_LIST_110}[2]
    BuiltIn.Wait Until Keyword Succeeds    60s    10s    Check BGP VPNv4 Nbr On ODL    ${NUM_OF_DCGW}
    BuiltIn.Wait Until Keyword Succeeds    60s    10s    Verify Routing Entry    @{RD}[0]    @{NETWORK_IP}[0]    @{NUM_OF_ROUTES}[3]
    BuiltIn.Wait Until Keyword Succeeds    10s    2s    Verify Routing Entry    @{RD}[1]    @{NETWORK_IP}[0]    @{NUM_OF_ROUTES}[5]
    BuiltIn.Wait Until Keyword Succeeds    10s    2s    Verify Routing Entry    @{RD}[2]    @{NETWORK_IP}[0]    @{NUM_OF_ROUTES}[1]
    BuiltIn.Wait Until Keyword Succeeds    10s    2s    Verify FIB Entry    @{NETWORK_IP}[0]    @{NUM_OF_ROUTES}[5]
    Verify Route Entry With Nexthop    @{RD}[0]    @{NETWORK_IP}[0]    start=0    end=2
    Verify Route Entry With Nexthop    @{RD}[1]    @{NETWORK_IP}[0]    start=0    end=2
    Verify Route Entry With Nexthop    @{RD}[2]    @{NETWORK_IP}[0]    start=2    end=3
    Log    Restarting ODL
    BuiltIn.Wait Until Keyword Succeeds    60s    10s    Check BGP VPNv4 Nbr On ODL    ${NUM_OF_DCGW}
    BuiltIn.Wait Until Keyword Succeeds    60s    10s    Verify Routing Entry    @{RD}[0]    @{NETWORK_IP}[0]    @{NUM_OF_ROUTES}[3]
    BuiltIn.Wait Until Keyword Succeeds    10s    2s    Verify Routing Entry    @{RD}[1]    @{NETWORK_IP}[0]    @{NUM_OF_ROUTES}[5]
    BuiltIn.Wait Until Keyword Succeeds    10s    2s    Verify Routing Entry    @{RD}[2]    @{NETWORK_IP}[0]    @{NUM_OF_ROUTES}[1]
    BuiltIn.Wait Until Keyword Succeeds    10s    2s    Verify FIB Entry    @{NETWORK_IP}[0]    @{NUM_OF_ROUTES}[5]
    Verify Route Entry With Nexthop    @{RD}[0]    @{NETWORK_IP}[0]    start=0    end=2
    Verify Route Entry With Nexthop    @{RD}[1]    @{NETWORK_IP}[0]    start=0    end=2
    Verify Route Entry With Nexthop    @{RD}[2]    @{NETWORK_IP}[0]    start=2    end=3
    Delete Routes    @{DCGW_IP_LIST}[2]    @{DCGW_RD}[2]    @{NETWORK_IP}[0]    @{LABEL}[2]
    BuiltIn.Wait Until Keyword Succeeds    60s    10s    Verify Routing Entry    @{RD}[0]    @{NETWORK_IP}[0]    @{NUM_OF_ROUTES}[3]
    BuiltIn.Wait Until Keyword Succeeds    10s    2s    Verify Routing Entry    @{RD}[1]    @{NETWORK_IP}[0]    @{NUM_OF_ROUTES}[5]
    BuiltIn.Wait Until Keyword Succeeds    10s    2s    Verify Routing Entry    @{RD}[2]    @{NETWORK_IP}[0]    @{NUM_OF_ROUTES}[0]
    BuiltIn.Wait Until Keyword Succeeds    10s    2s    Verify FIB Entry    @{NETWORK_IP}[0]    @{NUM_OF_ROUTES}[4]

TC13_Verify route resynchronization of DC-GW with QBGP, when one or more DC-GW fails/rebooted
    [Documentation]    Verify route resynchronization of DC-GW with QBGP, when one or more DC-GW fails/rebooted
    VpnOperations.VPN Create L3VPN    name=@{VPN_NAME}[0]    vpnid=@{VPN_INSTANCE_ID}[0]    rd=@{L3VPN_RD}[0]    exportrt=@{L3VPN_EXPORT_RT}[0]    importrt=@{L3VPN_IMPORT_RT}[0]
    BuiltIn.Wait Until Keyword Succeeds    10s    2s    Verify L3VPN On ODL    @{VPN_INSTANCE_ID}[0]
    : FOR    ${idx}    IN RANGE    ${START_VALUE}    ${NUM_OF_DCGW}
    \    Create L3VPN on Dcgateway    @{DCGW_IP_LIST}[${idx}]    @{VPN_NAME}[0]    @{DCGW_RD}[0]    @{DCGW_IMPORT_RT}[0]    @{DCGW_EXPORT_RT}[0]
    Verify L3VPN On DCGW    ${NUM_OF_DCGW}    @{VPN_NAME}[0]    @{DCGW_RD}[0]    @{DCGW_IMPORT_RT}[0]    @{DCGW_EXPORT_RT}[0]
    Check BGP Session On DCGW    ${NUM_OF_DCGW}
    Check BGP Session On ODL    ${NUM_OF_DCGW}
    Check BGP Nbr On ODL    ${NUM_OF_DCGW}
    Enable Multipath On ODL
    BuiltIn.Wait Until Keyword Succeeds    10s    2s    Verify Multipath
    BuiltIn.Wait Until Keyword Succeeds    10s    2s    Configure Maxpath    @{MAX_PATH_LIST}[2]    @{MULTIPATH_RD}[0]
    BuiltIn.Wait Until Keyword Succeeds    10s    2s    Verify Maxpath    @{MAX_PATH_LIST}[2]    @{MULTIPATH_RD}[0]
    : FOR    ${idx}    IN RANGE    ${START_VALUE}    ${NUM_OF_DCGW}
    \    Add Routes    @{DCGW_IP_LIST}[${idx}]    @{DCGW_RD}[0]    @{NETWORK_IP}[${idx}]    @{LABEL}[${idx}]
    BuiltIn.Wait Until Keyword Succeeds    60s    10s    Check BGP VPNv4 Nbr On ODL    ${NUM_OF_DCGW}
    BuiltIn.Wait Until Keyword Succeeds    60s    10s    Verify Routing Entry    @{RD}[0]    @{NETWORK_IP}[0]    @{NUM_OF_ROUTES}[1]
    BuiltIn.Wait Until Keyword Succeeds    10s    2s    Verify Routing Entry    @{RD}[0]    @{NETWORK_IP}[1]    @{NUM_OF_ROUTES}[1]
    BuiltIn.Wait Until Keyword Succeeds    10s    2s    Verify Routing Entry    @{RD}[0]    @{NETWORK_IP}[2]    @{NUM_OF_ROUTES}[1]
    BuiltIn.Wait Until Keyword Succeeds    10s    2s    Verify FIB Entry    @{NETWORK_IP}[0]    @{NUM_OF_ROUTES}[1]
    BuiltIn.Wait Until Keyword Succeeds    10s    2s    Verify FIB Entry    @{NETWORK_IP}[1]    @{NUM_OF_ROUTES}[1]
    BuiltIn.Wait Until Keyword Succeeds    10s    2s    Verify FIB Entry    @{NETWORK_IP}[2]    @{NUM_OF_ROUTES}[1]
    Verify Route Entry With Nexthop    @{RD}[0]    @{NETWORK_IP}[0]    start=0    end=1
    Verify Route Entry With Nexthop    @{RD}[0]    @{NETWORK_IP}[1]    start=1    end=2
    Verify Route Entry With Nexthop    @{RD}[0]    @{NETWORK_IP}[2]    start=2    end=3
    BgpOperations.Delete BGP Config On Quagga    @{DCGW_IP_LIST}[0]    ${AS_ID}
    BuiltIn.Wait Until Keyword Succeeds    60s    10s    Verify Routing Entry    @{RD}[0]    @{NETWORK_IP}[0]    @{NUM_OF_ROUTES}[0]
    BuiltIn.Wait Until Keyword Succeeds    10s    2s    Verify FIB Entry    @{NETWORK_IP}[0]    @{NUM_OF_ROUTES}[0]
    Configure BGP And Add Neighbor On DCGW    @{DCGW_IP_LIST}[0]    ${ODL_MIP_IP}    ${AS_ID}
    Create L3VPN on Dcgateway    @{DCGW_IP_LIST}[0]    @{VPN_NAME}[0]    @{DCGW_RD}[0]    @{DCGW_IMPORT_RT}[0]    @{DCGW_EXPORT_RT}[0]
    Verify L3VPN On DCGW    ${NUM_OF_DCGW}    @{VPN_NAME}[0]    @{DCGW_RD}[0]    @{DCGW_IMPORT_RT}[0]    @{DCGW_EXPORT_RT}[0]
    Add Routes    @{DCGW_IP_LIST}[0]    @{DCGW_RD}[0]    @{NETWORK_IP}[0]    @{LABEL}[0]
    BuiltIn.Wait Until Keyword Succeeds    60s    10s    Check BGP VPNv4 Nbr On ODL    ${NUM_OF_DCGW}
    BuiltIn.Wait Until Keyword Succeeds    60s    10s    Verify Routing Entry    @{RD}[0]    @{NETWORK_IP}[0]    @{NUM_OF_ROUTES}[1]
    BuiltIn.Wait Until Keyword Succeeds    10s    2s    Verify Routing Entry    @{RD}[0]    @{NETWORK_IP}[1]    @{NUM_OF_ROUTES}[1]
    BuiltIn.Wait Until Keyword Succeeds    10s    2s    Verify Routing Entry    @{RD}[0]    @{NETWORK_IP}[2]    @{NUM_OF_ROUTES}[1]
    BuiltIn.Wait Until Keyword Succeeds    10s    2s    Verify FIB Entry    @{NETWORK_IP}[0]    @{NUM_OF_ROUTES}[1]
    BuiltIn.Wait Until Keyword Succeeds    10s    2s    Verify FIB Entry    @{NETWORK_IP}[1]    @{NUM_OF_ROUTES}[1]
    BuiltIn.Wait Until Keyword Succeeds    10s    2s    Verify FIB Entry    @{NETWORK_IP}[2]    @{NUM_OF_ROUTES}[1]
    Verify Route Entry With Nexthop    @{RD}[0]    @{NETWORK_IP}[0]    start=0    end=1
    Verify Route Entry With Nexthop    @{RD}[0]    @{NETWORK_IP}[1]    start=1    end=2
    Verify Route Entry With Nexthop    @{RD}[0]    @{NETWORK_IP}[2]    start=2    end=3

TC15_Verify the scenario when CSC receives back to back route advertisement and withdrawal for the same prefix and single VRF
    [Documentation]    Verify the scenario when CSC receives back to back route advertisement and withdrawal for the same prefix and single VRF
    VpnOperations.VPN Create L3VPN    name=@{VPN_NAME}[0]    vpnid=@{VPN_INSTANCE_ID}[0]    rd=@{L3VPN_RD}[0]    exportrt=@{L3VPN_EXPORT_RT}[0]    importrt=@{L3VPN_IMPORT_RT}[0]
    BuiltIn.Wait Until Keyword Succeeds    10s    2s    Verify L3VPN On ODL    @{VPN_INSTANCE_ID}[0]
    : FOR    ${idx}    IN RANGE    ${START_VALUE}    ${NUM_OF_DCGW}
    \    Create L3VPN on Dcgateway    @{DCGW_IP_LIST}[${idx}]    @{VPN_NAME}[0]    @{DCGW_RD}[0]    @{DCGW_IMPORT_RT}[0]    @{DCGW_EXPORT_RT}[0]
    Verify L3VPN On DCGW    ${NUM_OF_DCGW}    @{VPN_NAME}[0]    @{DCGW_RD}[0]    @{DCGW_IMPORT_RT}[0]    @{DCGW_EXPORT_RT}[0]
    Check BGP Session On DCGW    ${NUM_OF_DCGW}
    Check BGP Session On ODL    ${NUM_OF_DCGW}
    Check BGP Nbr On ODL    ${NUM_OF_DCGW}
    Enable Multipath On ODL
    BuiltIn.Wait Until Keyword Succeeds    10s    2s    Verify Multipath
    BuiltIn.Wait Until Keyword Succeeds    10s    2s    Configure Maxpath    @{MAX_PATH_LIST}[2]    @{MULTIPATH_RD}[0]
    BuiltIn.Wait Until Keyword Succeeds    10s    2s    Verify Maxpath    @{MAX_PATH_LIST}[2]    @{MULTIPATH_RD}[0]
    : FOR    ${idx}    IN RANGE    ${START_VALUE}    ${NUM_OF_DCGW}
    \    Add Routes    @{DCGW_IP_LIST}[${idx}]    @{DCGW_RD}[0]    @{NETWORK_IP}[0]    @{LABEL}[${idx}]
    BuiltIn.Wait Until Keyword Succeeds    60s    10s    Check BGP VPNv4 Nbr On ODL    ${NUM_OF_DCGW}
    BuiltIn.Wait Until Keyword Succeeds    60s    10s    Verify Routing Entry    @{RD}[0]    @{NETWORK_IP}[0]    @{NUM_OF_ROUTES}[3]
    BuiltIn.Wait Until Keyword Succeeds    10s    2s    Verify FIB Entry    @{NETWORK_IP}[0]    @{NUM_OF_ROUTES}[3]
    Delete Routes    @{DCGW_IP_LIST}[2]    @{DCGW_RD}[0]    @{NETWORK_IP}[0]    @{LABEL}[2]
    BuiltIn.Wait Until Keyword Succeeds    60s    10s    Verify Routing Entry    @{RD}[0]    @{NETWORK_IP}[0]    @{NUM_OF_ROUTES}[2]
    BuiltIn.Wait Until Keyword Succeeds    10s    2s    Verify FIB Entry    @{NETWORK_IP}[0]    @{NUM_OF_ROUTES}[2]
    Delete Routes    @{DCGW_IP_LIST}[1]    @{DCGW_RD}[0]    @{NETWORK_IP}[0]    @{LABEL}[1]
    BuiltIn.Wait Until Keyword Succeeds    60s    10s    Verify Routing Entry    @{RD}[0]    @{NETWORK_IP}[0]    @{NUM_OF_ROUTES}[1]
    BuiltIn.Wait Until Keyword Succeeds    10s    2s    Verify FIB Entry    @{NETWORK_IP}[0]    @{NUM_OF_ROUTES}[1]
    Add Routes    @{DCGW_IP_LIST}[1]    @{DCGW_RD}[0]    @{NETWORK_IP}[0]    @{LABEL}[1]
    BuiltIn.Wait Until Keyword Succeeds    60s    10s    Verify Routing Entry    @{RD}[0]    @{NETWORK_IP}[0]    @{NUM_OF_ROUTES}[2]
    BuiltIn.Wait Until Keyword Succeeds    10s    2s    Verify FIB Entry    @{NETWORK_IP}[0]    @{NUM_OF_ROUTES}[2]
    Add Routes    @{DCGW_IP_LIST}[2]    @{DCGW_RD}[0]    @{NETWORK_IP}[0]    @{LABEL}[2]
    BuiltIn.Wait Until Keyword Succeeds    60s    10s    Verify Routing Entry    @{RD}[0]    @{NETWORK_IP}[0]    @{NUM_OF_ROUTES}[3]
    BuiltIn.Wait Until Keyword Succeeds    10s    2s    Verify FIB Entry    @{NETWORK_IP}[0]    @{NUM_OF_ROUTES}[3]

TC16_Verify the scenario when CSC receives back to back route advertisement and withdrawal for the same prefix and multi VRF after Qbpg restart
    [Documentation]    Verify the scenario when CSC receives back to back route advertisement and withdrawal for the same prefix and multi VRF after Qbgp
    ...    restart
    : FOR    ${idx}    IN RANGE    ${START_VALUE}    ${NUM_OF_DCGW}
    \    VpnOperations.VPN Create L3VPN    name=@{VPN_NAME}[${idx}]    vpnid=@{VPN_INSTANCE_ID}[${idx}]    rd=@{L3VPN_RD}[${idx}]    exportrt=@{L3VPN_EXPORT_RT}[${idx}]    importrt=@{L3VPN_IMPORT_RT}[${idx}]
    BuiltIn.Wait Until Keyword Succeeds    10s    2s    Verify L3VPN On ODL    @{VPN_INSTANCE_ID}[0]    @{VPN_INSTANCE_ID}[1]    @{VPN_INSTANCE_ID}[2]
    : FOR    ${idx}    IN RANGE    ${START_VALUE}    ${NUM_OF_DCGW}
    \    Create L3VPN on Dcgateway    @{DCGW_IP_LIST}[0]    @{VPN_NAME}[${idx}]    @{DCGW_RD}[${idx}]    @{DCGW_IMPORT_RT}[${idx}]    @{DCGW_EXPORT_RT}[${idx}]
    : FOR    ${idx}    IN RANGE    1    ${NUM_OF_DCGW}
    \    Create L3VPN on Dcgateway    @{DCGW_IP_LIST}[1]    @{VPN_NAME}[${idx}]    @{DCGW_RD}[${idx}]    @{DCGW_IMPORT_RT}[${idx}]    @{DCGW_EXPORT_RT}[${idx}]
    Create L3VPN on Dcgateway    @{DCGW_IP_LIST}[2]    @{VPN_NAME}[2]    @{DCGW_RD}[2]    @{DCGW_IMPORT_RT}[2]    @{DCGW_EXPORT_RT}[2]
    Check BGP Session On DCGW    ${NUM_OF_DCGW}
    Check BGP Session On ODL    ${NUM_OF_DCGW}
    Check BGP Nbr On ODL    ${NUM_OF_DCGW}
    Enable Multipath On ODL
    BuiltIn.Wait Until Keyword Succeeds    10s    2s    Verify Multipath
    : FOR    ${idx}    IN RANGE    ${START_VALUE}    ${NUM_OF_DCGW}
    \    BuiltIn.Wait Until Keyword Succeeds    10s    2s    Configure Maxpath    @{MAX_PATH_LIST}[2]    @{MULTIPATH_RD}[${idx}]
    : FOR    ${idx}    IN RANGE    ${START_VALUE}    ${NUM_OF_DCGW}
    \    BuiltIn.Wait Until Keyword Succeeds    10s    2s    Verify Maxpath    @{MAX_PATH_LIST}[2]    @{MULTIPATH_RD}[${idx}]
    : FOR    ${idx}    IN RANGE    ${START_VALUE}    ${NUM_OF_DCGW}
    \    Add Routes    @{DCGW_IP_LIST}[0]    @{DCGW_RD}[${idx}]    @{NETWORK_IP}[0]    @{LABEL}[0]
    : FOR    ${idx}    IN RANGE    1    ${NUM_OF_DCGW}
    \    Add Routes    @{DCGW_IP_LIST}[1]    @{DCGW_RD}[${idx}]    @{NETWORK_IP}[0]    @{LABEL}[1]
    Add Routes    @{DCGW_IP_LIST}[2]    @{DCGW_RD}[2]    @{NETWORK_IP}[0]    @{LABEL}[2]
    BuiltIn.Wait Until Keyword Succeeds    60s    10s    Check BGP VPNv4 Nbr On ODL    ${NUM_OF_DCGW}
    BuiltIn.Wait Until Keyword Succeeds    60s    10s    Verify Routing Entry    @{RD}[0]    @{NETWORK_IP}[0]    @{NUM_OF_ROUTES}[1]
    BuiltIn.Wait Until Keyword Succeeds    10s    2s    Verify Routing Entry    @{RD}[1]    @{NETWORK_IP}[0]    @{NUM_OF_ROUTES}[2]
    BuiltIn.Wait Until Keyword Succeeds    10s    2s    Verify Routing Entry    @{RD}[2]    @{NETWORK_IP}[0]    @{NUM_OF_ROUTES}[3]
    BuiltIn.Wait Until Keyword Succeeds    10s    2s    Verify FIB Entry    @{NETWORK_IP}[0]    @{NUM_OF_ROUTES}[6]
    Verify Route Entry With Nexthop    @{RD}[0]    @{NETWORK_IP}[0]    start=0    end=1
    Verify Route Entry With Nexthop    @{RD}[1]    @{NETWORK_IP}[0]    start=0    end=2
    Verify Route Entry With Nexthop    @{RD}[2]    @{NETWORK_IP}[0]    start=0    end=3
    Delete Routes    @{DCGW_IP_LIST}[0]    @{DCGW_RD}[0]    @{NETWORK_IP}[0]    @{LABEL}[0]
    Delete Routes    @{DCGW_IP_LIST}[1]    @{DCGW_RD}[1]    @{NETWORK_IP}[0]    @{LABEL}[1]
    Delete Routes    @{DCGW_IP_LIST}[2]    @{DCGW_RD}[2]    @{NETWORK_IP}[0]    @{LABEL}[2]
    BuiltIn.Wait Until Keyword Succeeds    60s    10s    Verify Routing Entry    @{RD}[0]    @{NETWORK_IP}[0]    @{NUM_OF_ROUTES}[0]
    BuiltIn.Wait Until Keyword Succeeds    60s    10s    Verify Routing Entry    @{RD}[1]    @{NETWORK_IP}[0]    @{NUM_OF_ROUTES}[1]
    BuiltIn.Wait Until Keyword Succeeds    10s    2s    Verify Routing Entry    @{RD}[2]    @{NETWORK_IP}[0]    @{NUM_OF_ROUTES}[2]
    BuiltIn.Wait Until Keyword Succeeds    10s    2s    Verify FIB Entry    @{NETWORK_IP}[0]    @{NUM_OF_ROUTES}[3]
    Add Routes    @{DCGW_IP_LIST}[0]    @{DCGW_RD}[0]    @{NETWORK_IP}[0]    @{LABEL}[0]
    Add Routes    @{DCGW_IP_LIST}[1]    @{DCGW_RD}[1]    @{NETWORK_IP}[0]    @{LABEL}[1]
    Add Routes    @{DCGW_IP_LIST}[2]    @{DCGW_RD}[2]    @{NETWORK_IP}[0]    @{LABEL}[2]
    BuiltIn.Wait Until Keyword Succeeds    60s    10s    Verify Routing Entry    @{RD}[0]    @{NETWORK_IP}[0]    @{NUM_OF_ROUTES}[1]
    BuiltIn.Wait Until Keyword Succeeds    60s    10s    Verify Routing Entry    @{RD}[1]    @{NETWORK_IP}[0]    @{NUM_OF_ROUTES}[2]
    BuiltIn.Wait Until Keyword Succeeds    10s    2s    Verify Routing Entry    @{RD}[2]    @{NETWORK_IP}[0]    @{NUM_OF_ROUTES}[3]
    BuiltIn.Wait Until Keyword Succeeds    10s    2s    Verify FIB Entry    @{NETWORK_IP}[0]    @{NUM_OF_ROUTES}[6]

*** Keywords ***
Start Suite
    [Documentation]    Setup Start Suite
    RequestsLibrary.Create_Session    alias=session    url=http://${ODL_SYSTEM_IP}:${RESTCONFPORT}    auth=${AUTH}
    TemplatedRequests.Create Default Session    timeout=${SESSION_TIMEOUT}
    Log Many    @{DCGW_IP_LIST}
    : FOR    ${dcgw}    IN    @{DCGW_IP_LIST}
    \    Start Quagga Processes On DCGW    ${dcgw}
    Start Quagga Processes On ODL    ${ODL_SYSTEM_IP}
    KarafKeywords.Issue_Command_On_Karaf_Console    ${BGP_CONNECT}
    BgpOperations.Create BGP Configuration On ODL    localas=${AS_ID}    routerid=${ODL_SYSTEM_IP}
    Configure BGP Neighbor On ODL    ${NUM_OF_DCGW}
    Wait Until Keyword Succeeds    10    2    Verify BGP Neighbor On ODL    ${NUM_OF_DCGW}
    : FOR    ${idx}    IN RANGE    ${START_VALUE}    ${NUM_OF_DCGW}
    \    Configure BGP And Add Neighbor On DCGW    ${DCGW_IP_LIST[${idx}]}    ${ODL_MIP_IP}    ${AS_ID}

Stop Suite
    [Documentation]    Deleting all BGP neighbors and configurations
    RequestsLibrary.Create_Session    alias=session    url=http://${ODL_SYSTEM_IP}:${RESTCONFPORT}    auth=${AUTH}
    : FOR    ${idx}    IN RANGE    ${START_VALUE}    ${NUM_OF_DCGW}
    \    ${output}    Pre Cleanup Configuration Check on Dcgateway    ${DCGW_IP_LIST[${idx}]}
    Delete BGP Neighbor On ODL    ${NUM_OF_DCGW}
    : FOR    ${idx}    IN RANGE    ${START_VALUE}    ${NUM_OF_DCGW}
    \    Configure Maxpath    @{MAX_PATH_LIST}[0]    ${MULTIPATH_RD[${idx}]}
    Delete L3VPN    ${NUM_OF_L3VPN}
    Disable Multipath On ODL
    : FOR    ${idx}    IN RANGE    ${START_VALUE}    ${NUM_OF_DCGW}
    \    ${output}    BgpOperations.Delete BGP Config On Quagga    ${DCGW_IP_LIST[${idx}]}    ${AS_ID}

Pretest Cleanup
    [Documentation]    Test Case Cleanup
    RequestsLibrary.Create_Session    alias=session    url=http://${ODL_SYSTEM_IP}:${RESTCONFPORT}    auth=${AUTH}
    : FOR    ${idx}    IN RANGE    ${START_VALUE}    ${NUM_OF_DCGW}
    \    ${output}    Pre Cleanup Configuration Check on Dcgateway    ${DCGW_IP_LIST[${idx}]}
    : FOR    ${idx}    IN RANGE    ${START_VALUE}    ${NUM_OF_DCGW}
    \    Configure Maxpath    @{MAX_PATH_LIST}[0]    ${MULTIPATH_RD[${idx}]}
    Delete L3VPN    ${NUM_OF_L3VPN}
    Disable Multipath On ODL
    : FOR    ${idx}    IN RANGE    ${START_VALUE}    ${NUM_OF_DCGW}
    \    ${output}    Delete BGP Config On Quagga    ${DCGW_IP_LIST[${idx}]}    ${AS_ID}
    : FOR    ${idx}    IN RANGE    ${START_VALUE}    ${NUM_OF_DCGW}
    \    Configure BGP And Add Neighbor On DCGW    ${DCGW_IP_LIST[${idx}]}    ${ODL_MIP_IP}    ${AS_ID}

Pre Cleanup Configuration Check on Dcgateway
    [Arguments]    ${dcgw_ip}
    [Documentation]    Execute set of command on Dcgateway
    BgpOperations.Execute Show Command On quagga    ${dcgw_ip}    show running-config
    SSHLibrary.Close Connection

Configure BGP And Add Neighbor On DCGW
    [Arguments]    ${dcgw_ip}    ${odl_ip}    ${as_number}
    [Documentation]    Configure BGP and add neighbor on the dcgw
    BgpOperations.Create Quagga Telnet Session    ${dcgw_ip}    bgpd    sdncbgpc
    BgpOperations.Execute Command On Quagga Telnet Session    configure terminal
    BgpOperations.Execute Command On Quagga Telnet Session    router bgp ${AS_ID}
    BgpOperations.Execute Command On Quagga Telnet Session    bgp router-id ${dcgw_ip}
    BgpOperations.Execute Command On Quagga Telnet Session    no bgp log-neighbor-changes
    BgpOperations.Execute Command On Quagga Telnet Session    bgp graceful-restart stalepath-time 90
    BgpOperations.Execute Command On Quagga Telnet Session    bgp graceful-restart stalepath-time 90
    BgpOperations.Execute Command On Quagga Telnet Session    bgp graceful-restart restart-time 900
    BgpOperations.Execute Command On Quagga Telnet Session    bgp graceful-restart
    BgpOperations.Execute Command On Quagga Telnet Session    bgp graceful-restart preserve-fw-state
    BgpOperations.Execute Command On Quagga Telnet Session    bgp bestpath as-path multipath-relax
    BgpOperations.Execute Command On Quagga Telnet Session    neighbor ${odl_ip} send-remote-as ${as_number}
    BgpOperations.Execute Command On Quagga Telnet Session    terminal length 0
    BgpOperations.Execute Command On Quagga Telnet Session    neighbor ${odl_ip} update-source ${dcgw_ip}
    BgpOperations.Execute Command On Quagga Telnet Session    no neighbor ${odl_ip} activate
    BgpOperations.Execute Command On Quagga Telnet Session    address-family vpnv4
    BgpOperations.Execute Command On Quagga Telnet Session    neighbor ${odl_ip} activate
    BgpOperations.Execute Command On Quagga Telnet Session    neighbor ${odl_ip} attribute-unchanged next-hop
    BgpOperations.Execute Command On Quagga Telnet Session    address-family ipv6
    BgpOperations.Execute Command On Quagga Telnet Session    exit-address-family
    BgpOperations.Execute Command On Quagga Telnet Session    exit
    BgpOperations.Execute Command On Quagga Telnet Session    show running-config
    BgpOperations.Execute Command On Quagga Telnet Session    exit
    SSHLibrary.Close Connection

Create L3VPN on Dcgateway
    [Arguments]    ${dcgw_ip}    ${vpn_name}    ${rd}    ${import_rt}    ${export_rt}
    [Documentation]    Create L3VPN on Dcgateway
    BgpOperations.Create Quagga Telnet Session    ${dcgw_ip}    bgpd    sdncbgpc
    BgpOperations.Execute Command On Quagga Telnet Session    configure terminal
    BgpOperations.Execute Command On Quagga Telnet Session    router bgp ${AS_ID}
    BgpOperations.Execute Command On Quagga Telnet Session    vrf ${vpn_name}
    BgpOperations.Execute Command On Quagga Telnet Session    rd ${rd}
    BgpOperations.Execute Command On Quagga Telnet Session    rt export ${export_rt}
    BgpOperations.Execute Command On Quagga Telnet Session    rt import ${import_rt}
    BgpOperations.Execute Command On Quagga Telnet Session    exit
    BgpOperations.Execute Command On Quagga Telnet Session    exit
    SSHLibrary.Close Connection

Configure BGP Preference
    [Arguments]    ${dcgw_ip}    ${preference}
    [Documentation]    Configure BGP Preference
    BgpOperations.Create Quagga Telnet Session    ${dcgw_ip}    bgpd    sdncbgpc
    BgpOperations.Execute Command On Quagga Telnet Session    configure terminal
    BgpOperations.Execute Command On Quagga Telnet Session    router bgp ${AS_ID}
    BgpOperations.Execute Command On Quagga Telnet Session    bgp default local-preference ${preference}
    BgpOperations.Execute Command On Quagga Telnet Session    exit
    BgpOperations.Execute Command On Quagga Telnet Session    do clear ip bgp *
    Sleep    10s
    BgpOperations.Execute Command On Quagga Telnet Session    exit
    SSHLibrary.Close Connection

Add Routes
    [Arguments]    ${dcgw_ip}    ${rd}    ${network_ip}    ${label}
    [Documentation]    Add the Routes to DCGW
    BgpOperations.Create Quagga Telnet Session    ${dcgw_ip}    bgpd    sdncbgpc
    BgpOperations.Execute Command On Quagga Telnet Session    configure terminal
    BgpOperations.Execute Command On Quagga Telnet Session    router bgp ${AS_ID}
    BgpOperations.Execute Command On Quagga Telnet Session    address-family vpnv4
    BgpOperations.Execute Command On Quagga Telnet Session    network ${network_ip} rd ${rd} tag ${label}
    BgpOperations.Execute Command On Quagga Telnet Session    exit
    BgpOperations.Execute Command On Quagga Telnet Session    exit
    SSHLibrary.Close Connection

Delete Routes
    [Arguments]    ${dcgw_ip}    ${rd}    ${network_ip}    ${label}
    [Documentation]    Delete the Routes from DCGW
    BgpOperations.Create Quagga Telnet Session    ${dcgw_ip}    bgpd    sdncbgpc
    BgpOperations.Execute Command On Quagga Telnet Session    configure terminal
    BgpOperations.Execute Command On Quagga Telnet Session    router bgp ${AS_ID}
    BgpOperations.Execute Command On Quagga Telnet Session    address-family vpnv4
    BgpOperations.Execute Command On Quagga Telnet Session    no network ${network_ip} rd ${rd} tag ${label}
    BgpOperations.Execute Command On Quagga Telnet Session    exit
    BgpOperations.Execute Command On Quagga Telnet Session    exit
    SSHLibrary.Close Connection

Enable Multipath On ODL
    [Documentation]    Enabling Multipath
    ${output} =    KarafKeywords.Issue_Command_On_Karaf_Console    ${MULTIPATH_ENABLE}
    Should Not Contain    ${output}    ${ERROR}

Disable Multipath On ODL
    [Documentation]    Disabling Multipath
    ${output} =    KarafKeywords.Issue_Command_On_Karaf_Console    ${MULTIPATH_DISABLE}
    Should Not Contain    ${output}    ${ERROR}

Configure Maxpath
    [Arguments]    ${maxpath}    ${rd}
    [Documentation]    Setting Maxpath
    ${maxpath_command}    Catenate    multipath -r    ${rd} -f lu -n ${maxpath} setmaxpath
    ${output} =    KarafKeywords.Issue_Command_On_Karaf_Console    ${maxpath_command}
    Run Keyword If    0 < ${maxpath} < 65    Should Not Contain    ${output}    ${ERROR}
    ...    ELSE    Should Contain    ${output}    ${INVALID_INPUT}

Verify Multipath
    [Arguments]    ${Enable}=True
    [Documentation]    Verify Multipath is Set properly
    ${PASSED}    ConvertToInteger    0
    ${output} =    KarafKeywords.Issue_Command_On_Karaf_Console    ${BGP_CACHE}
    Run Keyword If    ${Enable}==True    Should Contain    ${output}    ${Address-Families}
    ...    ELSE    Should Not Contain    ${output}    ${Address-Families}

Verify Maxpath
    [Arguments]    ${maxpath}    ${rd}
    [Documentation]    Verify Maxpath is Set Properly
    ${PASSED}    ConvertToInteger    0
    ${output} =    KarafKeywords.Issue_Command_On_Karaf_Console    ${BGP_CACHE}
    Should Match Regexp    ${output}    ${rd}\\s*${maxpath}
    Should Not Contain    ${output}    ${ERROR}

Verify Maxpath For Invalid Input
    [Arguments]    ${rd}    ${maxpath}
    [Documentation]    Verify Maxpath is Set Properly
    ${output} =    KarafKeywords.Issue_Command_On_Karaf_Console    ${BGP_CACHE}
    Should Not Match Regexp    ${output}    ${rd}\\s*${maxpath}

Delete BGP Neighbor On ODL
    [Arguments]    ${dcgw_count}
    [Documentation]    Delete bgp config on odl
    : FOR    ${index}    IN RANGE    0    ${dcgw_count}
    \    ${del_bgp_nbr} =    set variable    configure-bgp -op delete-neighbor --ip ${DCGW_IP_LIST[${index}]} --as-num ${AS_ID} --use-source-ip ${ODL_MIP_IP}
    \    KarafKeywords.Issue_Command_On_Karaf_Console    ${del_bgp_nbr}
    \    KarafKeywords.Issue_Command_On_Karaf_Console    ${BGP_CACHE}

Configure BGP Neighbor On ODL
    [Arguments]    ${dcgw_count}    ${start}=${START_VALUE}
    [Documentation]    Create bgp neighbor config on odl
    : FOR    ${index}    IN RANGE    ${start}    ${dcgw_count}
    \    ${add_bgp_nbr} =    set variable    configure-bgp -op add-neighbor --ip ${DCGW_IP_LIST[${index}]} --as-num ${AS_ID} --use-source-ip ${ODL_MIP_IP}
    \    KarafKeywords.Issue_Command_On_Karaf_Console    ${add_bgp_nbr}

Delete L3VPN
    [Arguments]    ${l3vpn_count}    ${start}=${START_VALUE}
    [Documentation]    Delete bgp l3vpn config on odl
    : FOR    ${idx}    IN RANGE    ${start}    ${l3vpn_count}
    \    Run Keyword And Ignore Error    VPN Delete L3VPN    vpnid=${VPN_INSTANCE_ID[${idx}]}

Verify BGP Neighbor On ODL
    [Arguments]    ${dcgw_count}    ${start}=${START_VALUE}
    [Documentation]    Verify BGP Neighbor on ODL
    ${output} =    KarafKeywords.Issue_Command_On_Karaf_Console    ${BGP_CACHE}
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
    \    ${output} =    BgpOperations.Execute Show Command On Quagga    ${DCGW_IP_LIST[${index}]}    show running-config
    \    Should Contain    ${output}    vrf ${vpn_name}
    \    Should Contain    ${output}    rd ${rd}
    \    Should Contain    ${output}    rt import ${import_rt}
    \    Should Contain    ${output}    rt export ${export_rt}

Check BGP Session On ODL
    [Arguments]    ${dcgw_count}    ${start}=${START_VALUE}
    [Documentation]    Check BGP Session On ODL
    : FOR    ${index}    IN RANGE    ${start}    ${dcgw_count}
    \    ${cmd}    Set Variable    show-bgp --cmd "bgp neighbors ${DCGW_IP_LIST[${index}]}"
    \    ${output} =    KarafKeywords.Issue_Command_On_Karaf_Console    ${cmd}
    \    Should Contain    ${output}    BGP state = Established

Check BGP Nbr On ODL
    [Arguments]    ${dcgw_count}    ${start}=${START_VALUE}
    [Documentation]    Check BGP Session On ODL
    ${output} =    KarafKeywords.Issue_Command_On_Karaf_Console    ${DISPLAY_NBR_SUMMARY}
    : FOR    ${index}    IN RANGE    ${start}    ${dcgw_count}
    \    Should Contain    ${output}    ${DCGW_IP_LIST[${index}]}

Check BGP VPNv4 Nbr On ODL
    [Arguments]    ${dcgw_count}    ${flag}=True    ${start}=${START_VALUE}
    [Documentation]    Check BGP Session On ODL
    ${output} =    KarafKeywords.Issue_Command_On_Karaf_Console    ${DISPLAY_VPN4_ALL}
    : FOR    ${index}    IN RANGE    ${start}    ${dcgw_count}
    \    Run Keyword If    ${flag}==True    Should Contain    ${output}    ${DCGW_IP_LIST[${index}]}
    \    ...    ELSE    Should Not Contain    ${output}    ${DCGW_IP_LIST[${index}]}

Check BGP Session On DCGW
    [Arguments]    ${dcgw_count}    ${start}=${START_VALUE}
    [Documentation]    Verify BGP Config on DCGW
    : FOR    ${index}    IN RANGE    ${start}    ${dcgw_count}
    \    Wait Until Keyword Succeeds    60s    10s    Verify BGP Neighbor Status On Quagga    ${DCGW_IP_LIST[${index}]}    ${ODL_MIP_IP}

Verify VPN Config
    [Arguments]    ${vpn_id}    ${rd}    ${no_of_vpn_config}    ${additional_args}=${EMPTY}    ${verbose}=TRUE
    [Documentation]    Check VPN Session are configured on ODL
    ${output} =    KarafKeywords.Issue_Command_On_Karaf_Console    ${vpn-session}
    Should Contain    ${output}    ${vpn_id}
    Should Contain    ${output}    ${rd}

Verify Routing Entry
    [Arguments]    ${rd}    ${prefix}    ${no_of_times}
    [Documentation]    Get the Route entry for specific RD
    ${output} =    KarafKeywords.Issue_Command_On_Karaf_Console    show-bgp --cmd "ip bgp vrf ${rd}"
    Should Contain X Times    ${output}    ${prefix}    ${no_of_times}    msg="Routing table does not contain ${prefix} prefix ${no_of_times} times"

Verify FIB Entry
    [Arguments]    ${prefix}    ${no_of_times}
    [Documentation]    Check FIB
    ${output} =    KarafKeywords.Issue_Command_On_Karaf_Console    ${DIPSLAY_FIB}
    Should Contain X Times    ${output}    ${prefix}    ${no_of_times}    msg="FIB table does not contain ${prefix} prefix ${no_of_times} times"

Verify Route Entry With Nexthop
    [Arguments]    ${rd}    ${prefix}    ${start}=${START_VALUE}    ${end}=dcgw_count
    [Documentation]    Verification of routes entry with correct nexthop
    ${output} =    KarafKeywords.Issue_Command_On_Karaf_Console    ${DIPSLAY_FIB}
    : FOR    ${index}    IN RANGE    ${start}    ${end}
    \    Should Match Regexp    ${output}    \\s*${prefix}\\s*${DCGW_IP_LIST[${index}]}    msg="FIB table does not contain ${DCGW_IP_LIST[${index}]} for ${prefix} prefix "

Verify Leaking Route Across VPNs
    [Arguments]    ${rd}    @{nexthop_list}
    [Documentation]    Verification of best routes in Routing table at ODL
    ${output} =    KarafKeywords.Issue_Command_On_Karaf_Console    show-bgp --cmd "ip bgp vrf ${rd}"
    : FOR    ${nexthop}    IN    @{nexthop_list}
    \    Should Not Contain    ${output}    ${nexthop}

Verify Best Route In RIB
    [Arguments]    ${output_str}    ${rd}    ${prefix}    ${nexthop}    ${best}=\\*>i
    [Documentation]    Verification of best routes in Routing table at ODL
    Should Match Regexp    ${output_str}    \\s*${best}${prefix}\\s*${nexthop}

Verify Equal Route In RIB
    [Arguments]    ${output_str}    ${rd}    ${prefix}    ${nexthop}    ${equal}=\\*=i
    [Documentation]    Verification of best routes in Routing table at ODL
    Should Match Regexp    ${output_str}    \\s*${equal}${prefix}\\s*${nexthop}

Check Routes on DC_GW
    [Arguments]    ${NUM_OF_DC_GW}    ${additional_args}=${EMPTY}    ${verbose}=TRUE
    [Documentation]    Verify the routes on DC_GW
    : FOR    ${index}    IN RANGE    0    ${NUM_OF_DC_GW}
    \    ${output} =    BgpOperations.Execute Show Command On Quagga    ${DCGW_IP_LIST[${index}]}    show ip bgp vpnv4 all
    \    Should Contain    ${output}    ${LOOPBACK_IP[${index}]}
