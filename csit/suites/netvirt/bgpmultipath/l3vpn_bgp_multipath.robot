*** Settings ***
Documentation     The objective of this testsuite is to test QBGP and ODL for multipath/ECMP support.
...               QBGP should be capable to receive multiple ECMP paths from different DC-GWs and
...               to export the ECMP paths to ODL instead of best path selection.
...               ODL should be capable to receive ECMP paths and it should program the FIB with ECMP paths.
Suite Setup       Start Suite
Suite Teardown    Stop Suite
Test Setup        SetupUtils.Setup_Test_With_Logging_And_Without_Fast_Failing
Test Teardown     Test Cleanup
Resource          ../../../libraries/BgpOperations.robot
Resource          ../../../libraries/KarafKeywords.robot
Resource          ../../../libraries/OpenStackOperations.robot
Resource          ../../../libraries/Utils.robot
Resource          ../../../libraries/VpnOperations.robot
Resource          ../../../variables/Variables.robot

*** Variables ***
@{DCGW_RD_IRT_ERT}    11:1    22:2    33:3
@{DCGW_IP_LIST}    ${TOOLS_SYSTEM_1_IP}    ${TOOLS_SYSTEM_2_IP}    ${TOOLS_SYSTEM_3_IP}
@{LABEL}          51    52    53
@{L3VPN_RD_IRT_ERT}    ["@{DCGW_RD_IRT_ERT}[0]"]    ["@{DCGW_RD_IRT_ERT}[1]"]    ["@{DCGW_RD_IRT_ERT}[2]"]
@{MAX_PATH_LIST}    1    2    3    8    64
@{MAX_PATH_INVALID_LIST}    -1    0    65
@{NETWORK_IP}     10.1.1.1    20.1.1.1    30.1.1.1    99.1.1.1
@{NUM_OF_ROUTES}    1    2    3    4    5    6
@{PREF_LIST}      100    101    102
@{VPN_NAME}       multipath_vpn_1    multipath_vpn_2    multipath_vpn_3
@{VPN_ID}         12345678-1234-1234-1234-123456789301    12345678-1234-1234-1234-123456789302    12345678-1234-1234-1234-123456789303
@{NETWORKS}       multipath_net_1    multipath_net_2    multipath_net_3
@{SUBNETS}        multipath_subnet_1    multipath_subnet_2    multipath_subnet_3
@{SUBNET_CIDR}    22.1.1.0/24    33.1.1.0/24    44.1.1.0/24
@{ROUTERS}        multipath_router_1    multipath_router_2    multipath_router_3
${AS_ID}          100
${VPNV4_ADDR_FAMILY}    vpnv4
${BGP_CACHE}      bgp-cache
${BGP_CONNECT}    bgp-connect -h ${ODL_SYSTEM_IP} -p 7644 add
${DISPLAY_VPN4_ALL}    show-bgp --cmd "ip bgp ${VPNV4_ADDR_FAMILY} all"
${DIPSLAY_FIB}    fib-show
${ENABLE}         enable
${DISABLE}        disable
${L3VPN_IMPORT_RT_12}    ["@{DCGW_RD_IRT_ERT}[0]","@{DCGW_RD_IRT_ERT}[1]"]
${L3VPN_IMPORT_RT_123}    ["@{DCGW_RD_IRT_ERT}[0]","@{DCGW_RD_IRT_ERT}[1]","@{DCGW_RD_IRT_ERT}[2]"]
${L3VPN_IMPORT_RT_23}    ["@{DCGW_RD_IRT_ERT}[1]","@{DCGW_RD_IRT_ERT}[2]"]
${MAXPATH_ERROR}    error: --maxpath range[1 - 64]
${NUM_OF_DCGW}    3
${NUM_OF_L3VPN}    3
${START_VALUE}    0

*** Test Cases ***
Verify ODL supports REST API/CLI for multipath configuration (enable/disable multipath)
    [Documentation]    Enable and disable multipath on ODL using karaf CLI and verifying it
    Configure Multipath On ODL    ${ENABLE}
    Verify Multipath    ${ENABLE}
    Configure Multipath On ODL    ${DISABLE}
    Verify Multipath    ${DISABLE}
    Configure Multipath On ODL    ${ENABLE}
    Verify Multipath    ${ENABLE}

Verify CSC supports REST API/CLI for max path configuration
    [Documentation]    Verify CSC supports REST API/CLI for max path configuration
    : FOR    ${idx}    IN RANGE    ${START_VALUE}    ${NUM_OF_DCGW}
    \    VpnOperations.VPN Create L3VPN    name=@{VPN_NAME}[${idx}]    vpnid=@{VPN_ID}[${idx}]    rd=@{L3VPN_RD_IRT_ERT}[${idx}]    exportrt=@{L3VPN_RD_IRT_ERT}[${idx}]    importrt=@{L3VPN_RD_IRT_ERT}[${idx}]
    VpnOperations.Verify L3VPN On ODL    @{VPN_ID}
    : FOR    ${dcgw}    IN    @{DCGW_IP_LIST}
    \    BgpOperations.Create L3VPN on DCGW    ${dcgw}    ${AS_ID}    @{VPN_NAME}[0]    @{DCGW_RD_IRT_ERT}[0]
    \    BgpOperations.Verify L3VPN On DCGW    ${dcgw}    @{VPN_NAME}[0]    @{DCGW_RD_IRT_ERT}[0]
    : FOR    ${idx}    IN RANGE    ${START_VALUE}    ${NUM_OF_DCGW}
    \    Configure Maxpath    @{MAX_PATH_LIST}[2]    @{DCGW_RD_IRT_ERT}[${idx}]
    \    BuiltIn.Wait Until Keyword Succeeds    10s    2s    Verify Maxpath    @{MAX_PATH_LIST}[2]    @{DCGW_RD_IRT_ERT}[${idx}]
    BuiltIn.Wait Until Keyword Succeeds    60s    10s    Check BGP VPNv4 Nbr On ODL    ${NUM_OF_DCGW}    False

Verify max-path error message with invalid inputs
    [Documentation]    Verify max path error message while configuring maxpath with invalid range
    VpnOperations.VPN Create L3VPN    name=@{VPN_NAME}[0]    vpnid=@{VPN_ID}[0]    rd=@{L3VPN_RD_IRT_ERT}[0]    exportrt=@{L3VPN_RD_IRT_ERT}[0]    importrt=@{L3VPN_RD_IRT_ERT}[0]
    VpnOperations.Verify L3VPN On ODL    @{VPN_ID}[0]
    : FOR    ${dcgw}    IN    @{DCGW_IP_LIST}
    \    BgpOperations.Create L3VPN on DCGW    ${dcgw}    ${AS_ID}    @{VPN_NAME}[0]    @{DCGW_RD_IRT_ERT}[0]
    \    BgpOperations.Verify L3VPN On DCGW    ${dcgw}    @{VPN_NAME}[0]    @{DCGW_RD_IRT_ERT}[0]
    : FOR    ${invalid}    IN    @{MAX_PATH_INVALID_LIST}
    \    Configure Maxpath    ${invalid}    @{DCGW_RD_IRT_ERT}[0]
    \    BuiltIn.Wait Until Keyword Succeeds    10s    2s    Verify Maxpath    ${invalid}    @{DCGW_RD_IRT_ERT}[0]
    BuiltIn.Wait Until Keyword Succeeds    60s    10s    Check BGP VPNv4 Nbr On ODL    ${NUM_OF_DCGW}    False

Verify ODL supports dynamic configuration changes for max path value
    [Documentation]    Verify ODL supports dynamic configuration changes for max path value
    VpnOperations.VPN Create L3VPN    name=@{VPN_NAME}[0]    vpnid=@{VPN_ID}[0]    rd=@{L3VPN_RD_IRT_ERT}[0]    exportrt=@{L3VPN_RD_IRT_ERT}[0]    importrt=@{L3VPN_RD_IRT_ERT}[0]
    VpnOperations.Verify L3VPN On ODL    @{VPN_ID}[0]
    VpnOperations.Associate VPN to Router    routerid=@{router_id_list}[0]    vpnid=@{VPN_ID}[0]
    : FOR    ${dcgw}    IN    @{DCGW_IP_LIST}
    \    BgpOperations.Create L3VPN on DCGW    ${dcgw}    ${AS_ID}    @{VPN_NAME}[0]    @{DCGW_RD_IRT_ERT}[0]
    \    BgpOperations.Verify L3VPN On DCGW    ${dcgw}    @{VPN_NAME}[0]    @{DCGW_RD_IRT_ERT}[0]
    Configure Maxpath    @{MAX_PATH_LIST}[2]    @{DCGW_RD_IRT_ERT}[0]
    BuiltIn.Wait Until Keyword Succeeds    10s    2s    Verify Maxpath    @{MAX_PATH_LIST}[2]    @{DCGW_RD_IRT_ERT}[0]
    : FOR    ${idx}    IN RANGE    ${START_VALUE}    ${NUM_OF_DCGW}
    \    BgpOperations.Add Routes On DCGW    @{DCGW_IP_LIST}[${idx}]    @{DCGW_RD_IRT_ERT}[0]    @{NETWORK_IP}[0]    @{LABEL}[${idx}]
    BuiltIn.Wait Until Keyword Succeeds    60s    10s    Check BGP VPNv4 Nbr On ODL    ${NUM_OF_DCGW}
    BuiltIn.Wait Until Keyword Succeeds    60s    10s    Verify Routing Entry On ODL    @{DCGW_RD_IRT_ERT}[0]    @{NETWORK_IP}[0]    @{NUM_OF_ROUTES}[2]
    BuiltIn.Wait Until Keyword Succeeds    30s    5s    Verify FIB Entry On ODL    @{NETWORK_IP}[0]    @{NUM_OF_ROUTES}[2]
    : FOR    ${index}    IN RANGE    0    3
    \    Configure Maxpath    @{MAX_PATH_LIST}[${index}]    @{DCGW_RD_IRT_ERT}[0]
    \    BuiltIn.Wait Until Keyword Succeeds    10s    2s    Verify Maxpath    @{MAX_PATH_LIST}[${index}]    @{DCGW_RD_IRT_ERT}[0]
    \    BuiltIn.Wait Until Keyword Succeeds    60s    10s    Verify Routing Entry On ODL    @{DCGW_RD_IRT_ERT}[0]    @{NETWORK_IP}[0]
    \    ...    @{NUM_OF_ROUTES}[2]
    \    BuiltIn.Wait Until Keyword Succeeds    60s    10s    Verify FIB Entry On ODL    @{NETWORK_IP}[0]    @{NUM_OF_ROUTES}[${index}]
    : FOR    ${idx}    IN RANGE    ${START_VALUE}    ${NUM_OF_DCGW}
    \    BgpOperations.Delete Routes From DCGW    @{DCGW_IP_LIST}[${idx}]    @{DCGW_RD_IRT_ERT}[0]    @{NETWORK_IP}[0]    @{LABEL}[${idx}]

Verify that ECMP path gets withdrawn by QBGP after disabling multipath
    [Documentation]    Verify that ECMP path gets withdrawn by QBGP after disabling multipath
    VpnOperations.VPN Create L3VPN    name=@{VPN_NAME}[0]    vpnid=@{VPN_ID}[0]    rd=@{L3VPN_RD_IRT_ERT}[0]    exportrt=@{L3VPN_RD_IRT_ERT}[0]    importrt=@{L3VPN_RD_IRT_ERT}[0]
    VpnOperations.Verify L3VPN On ODL    @{VPN_ID}[0]
    VpnOperations.Associate VPN to Router    routerid=@{router_id_list}[0]    vpnid=@{VPN_ID}[0]
    : FOR    ${dcgw}    IN    @{DCGW_IP_LIST}
    \    BgpOperations.Create L3VPN on DCGW    ${dcgw}    ${AS_ID}    @{VPN_NAME}[0]    @{DCGW_RD_IRT_ERT}[0]
    \    BgpOperations.Verify L3VPN On DCGW    ${dcgw}    @{VPN_NAME}[0]    @{DCGW_RD_IRT_ERT}[0]
    Configure Maxpath    @{MAX_PATH_LIST}[2]    @{DCGW_RD_IRT_ERT}[0]
    BuiltIn.Wait Until Keyword Succeeds    10s    2s    Verify Maxpath    @{MAX_PATH_LIST}[2]    @{DCGW_RD_IRT_ERT}[0]
    : FOR    ${idx}    IN RANGE    ${START_VALUE}    ${NUM_OF_DCGW}
    \    BgpOperations.Add Routes On DCGW    @{DCGW_IP_LIST}[${idx}]    @{DCGW_RD_IRT_ERT}[0]    @{NETWORK_IP}[0]    @{LABEL}[${idx}]
    BuiltIn.Wait Until Keyword Succeeds    60s    10s    Check BGP VPNv4 Nbr On ODL    ${NUM_OF_DCGW}
    BuiltIn.Wait Until Keyword Succeeds    60s    10s    Verify Routing Entry On ODL    @{DCGW_RD_IRT_ERT}[0]    @{NETWORK_IP}[0]    @{NUM_OF_ROUTES}[2]
    BuiltIn.Wait Until Keyword Succeeds    30s    5s    Verify FIB Entry On ODL    @{NETWORK_IP}[0]    @{NUM_OF_ROUTES}[2]
    Configure Maxpath    @{MAX_PATH_LIST}[0]    @{DCGW_RD_IRT_ERT}[0]
    BuiltIn.Wait Until Keyword Succeeds    60s    10s    Verify Routing Entry On ODL    @{DCGW_RD_IRT_ERT}[0]    @{NETWORK_IP}[0]    @{NUM_OF_ROUTES}[2]
    BuiltIn.Wait Until Keyword Succeeds    30s    5s    Verify FIB Entry On ODL    @{NETWORK_IP}[0]    @{NUM_OF_ROUTES}[0]
    Configure Maxpath    @{MAX_PATH_LIST}[2]    @{DCGW_RD_IRT_ERT}[0]
    BuiltIn.Wait Until Keyword Succeeds    60s    10s    Verify Routing Entry On ODL    @{DCGW_RD_IRT_ERT}[0]    @{NETWORK_IP}[0]    @{NUM_OF_ROUTES}[2]
    BuiltIn.Wait Until Keyword Succeeds    30s    5s    Verify FIB Entry On ODL    @{NETWORK_IP}[0]    @{NUM_OF_ROUTES}[2]
    : FOR    ${idx}    IN RANGE    ${START_VALUE}    ${NUM_OF_DCGW}
    \    BgpOperations.Delete Routes From DCGW    @{DCGW_IP_LIST}[${idx}]    @{DCGW_RD_IRT_ERT}[0]    @{NETWORK_IP}[0]    @{LABEL}[${idx}]

Verify ECMP path advertised by QBGP to CSC in case of distinct VRF
    [Documentation]    Verify ECMP path advertised by QBGP to CSC in case of distinct VRF
    : FOR    ${idx}    IN RANGE    0    2
    \    VpnOperations.VPN Create L3VPN    name=@{VPN_NAME}[${idx}]    vpnid=@{VPN_ID}[${idx}]    rd=@{L3VPN_RD_IRT_ERT}[${idx}]    exportrt=@{L3VPN_RD_IRT_ERT}[${idx}]    importrt=@{L3VPN_RD_IRT_ERT}[${idx}]
    \    VpnOperations.Verify L3VPN On ODL    @{VPN_ID}[${idx}]
    \    VpnOperations.Associate VPN to Router    routerid=@{router_id_list}[${idx}]    vpnid=@{VPN_ID}[${idx}]
    : FOR    ${idx}    IN RANGE    0    1
    \    BgpOperations.Create L3VPN on DCGW    @{DCGW_IP_LIST}[${idx}]    ${AS_ID}    @{VPN_NAME}[${idx}]    @{DCGW_RD_IRT_ERT}[0]
    : FOR    ${idx}    IN RANGE    1    ${NUM_OF_DCGW}
    \    BgpOperations.Create L3VPN on DCGW    @{DCGW_IP_LIST}[${idx}]    ${AS_ID}    @{VPN_NAME}[${idx}]    @{DCGW_RD_IRT_ERT}[1]
    : FOR    ${idx}    IN RANGE    0    2
    \    Configure Maxpath    @{MAX_PATH_LIST}[2]    @{DCGW_RD_IRT_ERT}[${idx}]
    \    BuiltIn.Wait Until Keyword Succeeds    10s    2s    Verify Maxpath    @{MAX_PATH_LIST}[2]    @{DCGW_RD_IRT_ERT}[${idx}]
    : FOR    ${idx}    IN RANGE    0    1
    \    BgpOperations.Add Routes On DCGW    @{DCGW_IP_LIST}[${idx}]    @{DCGW_RD_IRT_ERT}[0]    @{NETWORK_IP}[0]    @{LABEL}[${idx}]
    \    BgpOperations.Add Routes On DCGW    @{DCGW_IP_LIST}[${idx}]    @{DCGW_RD_IRT_ERT}[0]    @{NETWORK_IP}[1]    @{LABEL}[${idx}]
    : FOR    ${idx}    IN RANGE    1    ${NUM_OF_DCGW}
    \    BgpOperations.Add Routes On DCGW    @{DCGW_IP_LIST}[${idx}]    @{DCGW_RD_IRT_ERT}[1]    @{NETWORK_IP}[0]    @{LABEL}[${idx}]
    \    BgpOperations.Add Routes On DCGW    @{DCGW_IP_LIST}[${idx}]    @{DCGW_RD_IRT_ERT}[1]    @{NETWORK_IP}[1]    @{LABEL}[${idx}]
    : FOR    ${dcgw}    IN    @{DCGW_IP_LIST}
    \    Execute Show Command On Quagga    ${dcgw}    show running-config
    BuiltIn.Wait Until Keyword Succeeds    60s    10s    Check BGP VPNv4 Nbr On ODL    ${NUM_OF_DCGW}
    : FOR    ${idx}    IN RANGE    0    2
    \    BuiltIn.Wait Until Keyword Succeeds    60s    10s    Verify Routing Entry On ODL    @{DCGW_RD_IRT_ERT}[0]    @{NETWORK_IP}[${idx}]
    \    ...    @{NUM_OF_ROUTES}[0]
    \    BuiltIn.Wait Until Keyword Succeeds    60s    10s    Verify Routing Entry On ODL    @{DCGW_RD_IRT_ERT}[1]    @{NETWORK_IP}[${idx}]
    \    ...    @{NUM_OF_ROUTES}[1]
    \    BuiltIn.Wait Until Keyword Succeeds    30s    5s    Verify FIB Entry On ODL    @{NETWORK_IP}[${idx}]    @{NUM_OF_ROUTES}[2]
    : FOR    ${idx}    IN RANGE    0    2
    \    Verify Route Entry With Nexthop    @{DCGW_RD_IRT_ERT}[0]    @{NETWORK_IP}[${idx}]    start=0    end=1
    \    Verify Route Entry With Nexthop    @{DCGW_RD_IRT_ERT}[1]    @{NETWORK_IP}[${idx}]    start=1    end=3
    BgpOperations.Delete Routes From DCGW    @{DCGW_IP_LIST}[2]    @{DCGW_RD_IRT_ERT}[1]    @{NETWORK_IP}[0]    @{LABEL}[2]
    BgpOperations.Delete Routes From DCGW    @{DCGW_IP_LIST}[2]    @{DCGW_RD_IRT_ERT}[1]    @{NETWORK_IP}[1]    @{LABEL}[2]
    BuiltIn.Wait Until Keyword Succeeds    60s    10s    Check BGP VPNv4 Nbr On ODL    ${NUM_OF_DCGW}
    : FOR    ${idx}    IN RANGE    0    2
    \    BuiltIn.Wait Until Keyword Succeeds    60s    10s    Verify Routing Entry On ODL    @{DCGW_RD_IRT_ERT}[0]    @{NETWORK_IP}[${idx}]
    \    ...    @{NUM_OF_ROUTES}[0]
    \    BuiltIn.Wait Until Keyword Succeeds    60s    10s    Verify Routing Entry On ODL    @{DCGW_RD_IRT_ERT}[1]    @{NETWORK_IP}[${idx}]
    \    ...    @{NUM_OF_ROUTES}[0]
    \    BuiltIn.Wait Until Keyword Succeeds    30s    5s    Verify FIB Entry On ODL    @{NETWORK_IP}[${idx}]    @{NUM_OF_ROUTES}[1]
    Verify Leaking Route Across VPNs    @{DCGW_RD_IRT_ERT}[0]    @{DCGW_IP_LIST}[1]    @{DCGW_IP_LIST}[2]
    Verify Leaking Route Across VPNs    @{DCGW_RD_IRT_ERT}[1]    @{DCGW_IP_LIST}[0]
    : FOR    ${idx}    IN RANGE    0    1
    \    BgpOperations.Delete Routes From DCGW    @{DCGW_IP_LIST}[${idx}]    @{DCGW_RD_IRT_ERT}[0]    @{NETWORK_IP}[0]    @{LABEL}[${idx}]
    \    BgpOperations.Delete Routes From DCGW    @{DCGW_IP_LIST}[${idx}]    @{DCGW_RD_IRT_ERT}[0]    @{NETWORK_IP}[1]    @{LABEL}[${idx}]
    : FOR    ${idx}    IN RANGE    1    ${NUM_OF_DCGW}
    \    BgpOperations.Delete Routes From DCGW    @{DCGW_IP_LIST}[${idx}]    @{DCGW_RD_IRT_ERT}[1]    @{NETWORK_IP}[0]    @{LABEL}[${idx}]
    \    BgpOperations.Delete Routes From DCGW    @{DCGW_IP_LIST}[${idx}]    @{DCGW_RD_IRT_ERT}[1]    @{NETWORK_IP}[1]    @{LABEL}[${idx}]

Verify ECMP path advertised by QBGP to CSC when routes shared across VPNs
    [Documentation]    Verify ECMP path advertised by QBGP to CSC when routes shared across VPNs
    VpnOperations.VPN Create L3VPN    name=@{VPN_NAME}[0]    vpnid=@{VPN_ID}[0]    rd=@{L3VPN_RD_IRT_ERT}[0]    exportrt=@{L3VPN_RD_IRT_ERT}[0]    importrt=${L3VPN_IMPORT_RT_123}
    VpnOperations.VPN Create L3VPN    name=@{VPN_NAME}[1]    vpnid=@{VPN_ID}[1]    rd=@{L3VPN_RD_IRT_ERT}[1]    exportrt=@{L3VPN_RD_IRT_ERT}[0]    importrt=@{L3VPN_RD_IRT_ERT}[0]
    VpnOperations.VPN Create L3VPN    name=@{VPN_NAME}[2]    vpnid=@{VPN_ID}[2]    rd=@{L3VPN_RD_IRT_ERT}[2]    exportrt=@{L3VPN_RD_IRT_ERT}[0]    importrt=${L3VPN_IMPORT_RT_23}
    : FOR    ${idx}    IN RANGE    0    ${NUM_OF_DCGW}
    \    VpnOperations.Verify L3VPN On ODL    @{VPN_ID}[${idx}]
    \    VpnOperations.Associate VPN to Router    routerid=@{router_id_list}[${idx}]    vpnid=@{VPN_ID}[${idx}]
    \    BgpOperations.Create L3VPN on DCGW    @{DCGW_IP_LIST}[${idx}]    ${AS_ID}    @{VPN_NAME}[${idx}]    @{DCGW_RD_IRT_ERT}[${idx}]
    \    Configure Maxpath    @{MAX_PATH_LIST}[2]    @{DCGW_RD_IRT_ERT}[${idx}]
    \    BuiltIn.Wait Until Keyword Succeeds    10s    2s    Verify Maxpath    @{MAX_PATH_LIST}[2]    @{DCGW_RD_IRT_ERT}[${idx}]
    \    BgpOperations.Add Routes On DCGW    @{DCGW_IP_LIST}[${idx}]    @{DCGW_RD_IRT_ERT}[${idx}]    @{NETWORK_IP}[0]    @{LABEL}[${idx}]
    : FOR    ${dcgw}    IN    @{DCGW_IP_LIST}
    \    Execute Show Command On Quagga    ${dcgw}    show running-config
    BuiltIn.Wait Until Keyword Succeeds    60s    10s    Check BGP VPNv4 Nbr On ODL    ${NUM_OF_DCGW}
    BuiltIn.Wait Until Keyword Succeeds    60s    10s    Verify Routing Entry On ODL    @{DCGW_RD_IRT_ERT}[0]    @{NETWORK_IP}[0]    @{NUM_OF_ROUTES}[2]
    BuiltIn.Wait Until Keyword Succeeds    60s    10s    Verify Routing Entry On ODL    @{DCGW_RD_IRT_ERT}[1]    @{NETWORK_IP}[0]    @{NUM_OF_ROUTES}[0]
    BuiltIn.Wait Until Keyword Succeeds    60s    10s    Verify Routing Entry On ODL    @{DCGW_RD_IRT_ERT}[2]    @{NETWORK_IP}[0]    @{NUM_OF_ROUTES}[1]
    BuiltIn.Wait Until Keyword Succeeds    30s    5s    Verify FIB Entry On ODL    @{NETWORK_IP}[0]    @{NUM_OF_ROUTES}[5]
    Verify Route Entry With Nexthop    @{DCGW_RD_IRT_ERT}[0]    @{NETWORK_IP}[0]    start=0    end=3
    Verify Route Entry With Nexthop    @{DCGW_RD_IRT_ERT}[1]    @{NETWORK_IP}[0]    start=0    end=1
    Verify Route Entry With Nexthop    @{DCGW_RD_IRT_ERT}[2]    @{NETWORK_IP}[0]    start=1    end=3
    Configure Maxpath    @{MAX_PATH_LIST}[1]    @{DCGW_RD_IRT_ERT}[0]
    BuiltIn.Wait Until Keyword Succeeds    10s    2s    Verify Maxpath    @{MAX_PATH_LIST}[1]    @{DCGW_RD_IRT_ERT}[0]
    BuiltIn.Wait Until Keyword Succeeds    60s    10s    Check BGP VPNv4 Nbr On ODL    ${NUM_OF_DCGW}
    BuiltIn.Wait Until Keyword Succeeds    60s    10s    Verify Routing Entry On ODL    @{DCGW_RD_IRT_ERT}[0]    @{NETWORK_IP}[0]    @{NUM_OF_ROUTES}[2]
    BuiltIn.Wait Until Keyword Succeeds    60s    10s    Verify Routing Entry On ODL    @{DCGW_RD_IRT_ERT}[1]    @{NETWORK_IP}[0]    @{NUM_OF_ROUTES}[0]
    BuiltIn.Wait Until Keyword Succeeds    60s    10s    Verify Routing Entry On ODL    @{DCGW_RD_IRT_ERT}[2]    @{NETWORK_IP}[0]    @{NUM_OF_ROUTES}[1]
    BuiltIn.Wait Until Keyword Succeeds    30s    5s    Verify FIB Entry On ODL    @{NETWORK_IP}[0]    @{NUM_OF_ROUTES}[4]
    Verify Route Entry With Nexthop    @{DCGW_RD_IRT_ERT}[0]    @{NETWORK_IP}[0]    start=0    end=3
    Verify Route Entry With Nexthop    @{DCGW_RD_IRT_ERT}[1]    @{NETWORK_IP}[0]    start=0    end=1
    Verify Route Entry With Nexthop    @{DCGW_RD_IRT_ERT}[2]    @{NETWORK_IP}[0]    start=1    end=3
    : FOR    ${idx}    IN RANGE    0    ${NUM_OF_DCGW}
    \    BgpOperations.Delete Routes From DCGW    @{DCGW_IP_LIST}[${idx}]    @{DCGW_RD_IRT_ERT}[${idx}]    @{NETWORK_IP}[0]    @{LABEL}[${idx}]

Verify BGP routes advertised to CSC when QBGP receives only unequal cost routes
    [Documentation]    Verify BGP routes advertised to CSC when QBGP receives only unequal cost routes
    VpnOperations.VPN Create L3VPN    name=@{VPN_NAME}[0]    vpnid=@{VPN_ID}[0]    rd=@{L3VPN_RD_IRT_ERT}[0]    exportrt=@{L3VPN_RD_IRT_ERT}[0]    importrt=@{L3VPN_RD_IRT_ERT}[0]
    VpnOperations.Verify L3VPN On ODL    @{VPN_ID}[0]
    VpnOperations.Associate VPN to Router    routerid=@{router_id_list}[0]    vpnid=@{VPN_ID}[0]
    : FOR    ${dcgw}    IN    @{DCGW_IP_LIST}
    \    BgpOperations.Create L3VPN on DCGW    ${dcgw}    ${AS_ID}    @{VPN_NAME}[0]    @{DCGW_RD_IRT_ERT}[0]
    \    BgpOperations.Verify L3VPN On DCGW    ${dcgw}    @{VPN_NAME}[0]    @{DCGW_RD_IRT_ERT}[0]
    Configure Maxpath    @{MAX_PATH_LIST}[2]    @{DCGW_RD_IRT_ERT}[0]
    BuiltIn.Wait Until Keyword Succeeds    10s    2s    Verify Maxpath    @{MAX_PATH_LIST}[2]    @{DCGW_RD_IRT_ERT}[0]
    : FOR    ${idx}    IN RANGE    ${START_VALUE}    ${NUM_OF_DCGW}
    \    BgpOperations.Add Routes On DCGW    @{DCGW_IP_LIST}[${idx}]    @{DCGW_RD_IRT_ERT}[0]    @{NETWORK_IP}[0]    @{LABEL}[${idx}]
    : FOR    ${dcgw}    IN    @{DCGW_IP_LIST}
    \    Execute Show Command On Quagga    ${dcgw}    show running-config
    BuiltIn.Wait Until Keyword Succeeds    60s    10s    Check BGP VPNv4 Nbr On ODL    ${NUM_OF_DCGW}
    BuiltIn.Wait Until Keyword Succeeds    60s    10s    Verify Routing Entry On ODL    @{DCGW_RD_IRT_ERT}[0]    @{NETWORK_IP}[0]    @{NUM_OF_ROUTES}[2]
    BuiltIn.Wait Until Keyword Succeeds    30s    5s    Verify FIB Entry On ODL    @{NETWORK_IP}[0]    @{NUM_OF_ROUTES}[2]
    : FOR    ${idx}    IN RANGE    ${START_VALUE}    ${NUM_OF_DCGW}
    \    BgpOperations.Configure BGP Preference    @{DCGW_IP_LIST}[${idx}]    @{PREF_LIST}[${idx}]
    BuiltIn.Wait Until Keyword Succeeds    60s    10s    Verify Routing Entry On ODL    @{DCGW_RD_IRT_ERT}[0]    @{NETWORK_IP}[0]    @{NUM_OF_ROUTES}[2]
    BuiltIn.Wait Until Keyword Succeeds    30s    5s    Verify FIB Entry On ODL    @{NETWORK_IP}[0]    @{NUM_OF_ROUTES}[0]
    Verify Route Entry With Nexthop    @{DCGW_RD_IRT_ERT}[0]    @{NETWORK_IP}[0]    start=2    end=3
    Configure Maxpath    @{MAX_PATH_LIST}[1]    @{DCGW_RD_IRT_ERT}[0]
    BuiltIn.Wait Until Keyword Succeeds    10s    2s    Verify Maxpath    @{MAX_PATH_LIST}[1]    @{DCGW_RD_IRT_ERT}[0]
    : FOR    ${dcgw}    IN    @{DCGW_IP_LIST}
    \    BgpOperations.Configure BGP Preference    ${dcgw}    @{PREF_LIST}[0]
    BuiltIn.Wait Until Keyword Succeeds    60s    10s    Verify Routing Entry On ODL    @{DCGW_RD_IRT_ERT}[0]    @{NETWORK_IP}[0]    @{NUM_OF_ROUTES}[2]
    BuiltIn.Wait Until Keyword Succeeds    30s    5s    Verify FIB Entry On ODL    @{NETWORK_IP}[0]    @{NUM_OF_ROUTES}[2]
    : FOR    ${idx}    IN RANGE    ${START_VALUE}    ${NUM_OF_DCGW}
    \    BgpOperations.Delete Routes From DCGW    @{DCGW_IP_LIST}[${idx}]    @{DCGW_RD_IRT_ERT}[0]    @{NETWORK_IP}[0]    @{LABEL}[${idx}]

Verify ECMP routes on CSC, when QBGP receives combination of equal and unequal cost routes
    [Documentation]    Verify ECMP routes on CSC, when QBGP receives combination of equal and unequal cost routes
    VpnOperations.VPN Create L3VPN    name=@{VPN_NAME}[0]    vpnid=@{VPN_ID}[0]    rd=@{L3VPN_RD_IRT_ERT}[0]    exportrt=@{L3VPN_RD_IRT_ERT}[0]    importrt=@{L3VPN_RD_IRT_ERT}[0]
    VpnOperations.Verify L3VPN On ODL    @{VPN_ID}[0]
    VpnOperations.Associate VPN to Router    routerid=@{router_id_list}[0]    vpnid=@{VPN_ID}[0]
    : FOR    ${dcgw}    IN    @{DCGW_IP_LIST}
    \    BgpOperations.Create L3VPN on DCGW    ${dcgw}    ${AS_ID}    @{VPN_NAME}[0]    @{DCGW_RD_IRT_ERT}[0]
    \    BgpOperations.Verify L3VPN On DCGW    ${dcgw}    @{VPN_NAME}[0]    @{DCGW_RD_IRT_ERT}[0]
    Configure Maxpath    @{MAX_PATH_LIST}[2]    @{DCGW_RD_IRT_ERT}[0]
    BuiltIn.Wait Until Keyword Succeeds    10s    2s    Verify Maxpath    @{MAX_PATH_LIST}[2]    @{DCGW_RD_IRT_ERT}[0]
    : FOR    ${idx}    IN RANGE    ${START_VALUE}    ${NUM_OF_DCGW}
    \    BgpOperations.Add Routes On DCGW    @{DCGW_IP_LIST}[${idx}]    @{DCGW_RD_IRT_ERT}[0]    @{NETWORK_IP}[0]    @{LABEL}[${idx}]
    BuiltIn.Wait Until Keyword Succeeds    60s    10s    Check BGP VPNv4 Nbr On ODL    ${NUM_OF_DCGW}
    BuiltIn.Wait Until Keyword Succeeds    60s    10s    Verify Routing Entry On ODL    @{DCGW_RD_IRT_ERT}[0]    @{NETWORK_IP}[0]    @{NUM_OF_ROUTES}[2]
    BuiltIn.Wait Until Keyword Succeeds    30s    5s    Verify FIB Entry On ODL    @{NETWORK_IP}[0]    @{NUM_OF_ROUTES}[2]
    : FOR    ${idx}    IN RANGE    0    2
    \    BgpOperations.Configure BGP Preference    @{DCGW_IP_LIST}[${idx}]    @{PREF_LIST}[2]
    : FOR    ${idx}    IN RANGE    2    3
    \    BgpOperations.Configure BGP Preference    @{DCGW_IP_LIST}[${idx}]    @{PREF_LIST}[1]
    BuiltIn.Wait Until Keyword Succeeds    60s    10s    Verify Routing Entry On ODL    @{DCGW_RD_IRT_ERT}[0]    @{NETWORK_IP}[0]    @{NUM_OF_ROUTES}[2]
    BuiltIn.Wait Until Keyword Succeeds    30s    5s    Verify FIB Entry On ODL    @{NETWORK_IP}[0]    @{NUM_OF_ROUTES}[1]
    : FOR    ${idx}    IN RANGE    ${START_VALUE}    ${NUM_OF_DCGW}
    \    BgpOperations.Configure BGP Preference    @{DCGW_IP_LIST}[${idx}]    @{PREF_LIST}[${idx}]
    BuiltIn.Wait Until Keyword Succeeds    60s    10s    Verify Routing Entry On ODL    @{DCGW_RD_IRT_ERT}[0]    @{NETWORK_IP}[0]    @{NUM_OF_ROUTES}[2]
    BuiltIn.Wait Until Keyword Succeeds    30s    5s    Verify FIB Entry On ODL    @{NETWORK_IP}[0]    @{NUM_OF_ROUTES}[0]
    Verify Route Entry With Nexthop    @{DCGW_RD_IRT_ERT}[0]    @{NETWORK_IP}[0]    start=2    end=3
    : FOR    ${idx}    IN RANGE    ${START_VALUE}    ${NUM_OF_DCGW}
    \    BgpOperations.Delete Routes From DCGW    @{DCGW_IP_LIST}[${idx}]    @{DCGW_RD_IRT_ERT}[0]    @{NETWORK_IP}[0]    @{LABEL}[${idx}]
    : FOR    ${dcgw}    IN    @{DCGW_IP_LIST}
    \    BgpOperations.Configure BGP Preference    ${dcgw}    @{PREF_LIST}[0]

*** Keywords ***
Start Suite
    [Documentation]    Setup start suite
    VpnOperations.Basic Suite Setup
    Create Setup

Stop Suite
    [Documentation]    Deleting all BGP neighbors and configurations
    BgpOperations.Delete BGP Configuration On ODL    session
    OpenStackOperations.OpenStack Suite Teardown

Test Cleanup
    [Documentation]    Posttest case cleanup
    : FOR    ${l3vpn_rd}    IN    @{DCGW_RD_IRT_ERT}
    \    Configure Maxpath    @{MAX_PATH_LIST}[0]    ${l3vpn_rd}
    : FOR    ${vpn}    IN    @{VPN_ID}
    \    BuiltIn.Run Keyword And Ignore Error    VpnOperations.VPN Delete L3VPN    vpnid=${vpn}
    : FOR    ${dcgw}    IN    @{DCGW_IP_LIST}
    \    BuiltIn.Run Keyword And Ignore Error    BgpOperations.Delete L3VPN on DCGW    ${dcgw}    ${AS_ID}    @{VPN_NAME}

Create Setup
    [Documentation]    Starting BGP process on each DCGW and ODL
    ...    Verifying BGP neighbor session status
    ...    Creating 3 networks, 3 subnets, one router
    : FOR    ${dcgw}    IN    @{DCGW_IP_LIST}
    \    BgpOperations.Start Quagga Processes On DCGW    ${dcgw}
    BgpOperations.Start Quagga Processes On ODL    ${ODL_SYSTEM_IP}
    KarafKeywords.Issue Command On Karaf Console    ${BGP_CONNECT}
    BgpOperations.Create BGP Configuration On ODL    localas=${AS_ID}    routerid=${ODL_SYSTEM_IP}
    : FOR    ${dcgw}    IN    @{DCGW_IP_LIST}
    \    BgpOperations.AddNeighbor To BGP Configuration On ODL    remoteas=${AS_ID}    neighborAddr=${dcgw}
    \    ${output} =    BgpOperations.Get BGP Configuration On ODL    session
    \    BuiltIn.Should Contain    ${output}    ${dcgw}
    \    BgpOperations.Configure BGP And Add Neighbor On DCGW    ${dcgw}    ${AS_ID}    ${dcgw}    ${ODL_SYSTEM_IP}    @{VPN_NAME}[0]
    \    ...    @{DCGW_RD_IRT_ERT}[0]    @{NETWORK_IP}[3]
    \    BuiltIn.Wait Until Keyword Succeeds    120s    20s    BgpOperations.Verify BGP Neighbor Status On Quagga    ${dcgw}    ${ODL_SYSTEM_IP}
    : FOR    ${network}    IN    @{NETWORKS}
    \    OpenStackOperations.Create Network    ${network}
    BuiltIn.Wait Until Keyword Succeeds    10s    2s    Utils.Check For Elements At URI    ${NETWORK_URL}    ${NETWORKS}
    : FOR    ${index}    IN RANGE    0    3
    \    OpenStackOperations.Create SubNet    @{NETWORKS}[${index}]    @{SUBNETS}[${index}]    @{SUBNET_CIDR}[${index}]
    BuiltIn.Wait Until Keyword Succeeds    10s    2s    Utils.Check For Elements At URI    ${SUBNETWORK_URL}    ${SUBNETS}
    ${router_id_list}    BuiltIn.Create List    @{EMPTY}
    : FOR    ${router}    IN    @{ROUTERS}
    \    OpenStackOperations.Create Router    ${router}
    \    ${router_id} =    OpenStackOperations.Get Router Id    ${router}
    \    Collections.Append To List    ${router_id_list}    ${router_id}
    BuiltIn.Set Suite Variable    ${router_id_list}
    : FOR    ${index}    IN RANGE    0    3
    \    OpenStackOperations.Add Router Interface    @{ROUTERS}[${index}]    @{SUBNETS}[${index}]
    \    ${output} =    OpenStackOperations.Show Router Interface    @{ROUTERS}[${index}]
    \    ${subnet_id} =    OpenStackOperations.Get Subnet Id    @{SUBNETS}[${index}]
    \    BuiltIn.Should Contain    ${output}    ${subnet_id}

Configure Multipath On ODL
    [Arguments]    ${setting}
    [Documentation]    Enabling or disabling multipath on ODL using karaf CLI
    BuiltIn.Run Keyword If    '${setting}' == 'enable'    KarafKeywords.Issue Command On Karaf Console    odl:multipath -f ${VPNV4_ADDR_FAMILY} ${setting}
    ...    ELSE    KarafKeywords.Issue Command On Karaf Console    odl:multipath -f ${VPNV4_ADDR_FAMILY} ${setting}

Verify Multipath
    [Arguments]    ${setting}
    [Documentation]    verify multipath on ODL
    ${output} =    KarafKeywords.Issue Command On Karaf Console    ${BGP_CACHE}
    BuiltIn.Run Keyword If    '${setting}' == 'enable'    BuiltIn.Should Contain    ${output}    ${VPNV4_ADDR_FAMILY}
    ...    ELSE    BuiltIn.Should Not Contain    ${output}    ${VPNV4_ADDR_FAMILY}

Configure Maxpath
    [Arguments]    ${maxpath}    ${rd}
    [Documentation]    Setting maxpath on ODL using karaf CLI
    ${maxpath_command} =    BuiltIn.Set Variable    multipath -r ${rd} -f ${VPNV4_ADDR_FAMILY} -n ${maxpath} setmaxpath
    ${output} =    KarafKeywords.Issue Command On Karaf Console    ${maxpath_command}
    BuiltIn.Run Keyword If    0 < ${maxpath} < 65    BuiltIn.Should Not Contain    ${output}    ${MAXPATH_ERROR}
    ...    ELSE    BuiltIn.Should Contain    ${output}    ${MAXPATH_ERROR}

Verify Maxpath
    [Arguments]    ${maxpath}    ${rd}
    [Documentation]    Verify maxpath is set properly on ODL
    ${output} =    KarafKeywords.Issue Command On Karaf Console    ${BGP_CACHE}
    BuiltIn.Run Keyword If    0 < ${maxpath} < 65    BuiltIn.Should Match Regexp    ${output}    ${rd}\\s*${maxpath}
    ...    ELSE    BuiltIn.Should Not Match Regexp    ${output}    ${rd}\\s*${maxpath}

Check BGP VPNv4 Nbr On ODL
    [Arguments]    ${dcgw_count}    ${flag}=True    ${start}=${START_VALUE}
    [Documentation]    Check BGP VPNv4 neighbor all on ODL
    ${output} =    KarafKeywords.Issue Command On Karaf Console    ${DISPLAY_VPN4_ALL}
    : FOR    ${index}    IN RANGE    ${start}    ${dcgw_count}
    \    BuiltIn.Run Keyword If    ${flag}==True    BuiltIn.Should Contain    ${output}    ${DCGW_IP_LIST[${index}]}
    \    ...    ELSE    BuiltIn.Should Not Contain    ${output}    ${DCGW_IP_LIST[${index}]}

Verify Routing Entry On ODL
    [Arguments]    ${rd}    ${prefix}    ${no_of_times}
    [Documentation]    Verify routing table for specific prefix
    ${output} =    KarafKeywords.Issue Command On Karaf Console    show-bgp --cmd "ip bgp vrf ${rd}"
    BuiltIn.Should Contain X Times    ${output}    ${prefix}    ${no_of_times}    msg="Routing table does not contain ${prefix} prefix ${no_of_times} times"

Verify FIB Entry On ODL
    [Arguments]    ${prefix}    ${no_of_times}
    [Documentation]    Checking FIB entries with valid counts
    ${output} =    KarafKeywords.Issue Command On Karaf Console    ${DIPSLAY_FIB}
    BuiltIn.Should Contain X Times    ${output}    ${prefix}    ${no_of_times}    msg="FIB table does not contain ${prefix} prefix ${no_of_times} times"

Verify Route Entry With Nexthop
    [Arguments]    ${rd}    ${prefix}    ${start}=${START_VALUE}    ${end}=${NUM_OF_DCGW}
    [Documentation]    Verification of routes entry with correct nexthop
    ${output} =    KarafKeywords.Issue_Command_On_Karaf_Console    ${DIPSLAY_FIB}
    : FOR    ${index}    IN RANGE    ${start}    ${end}
    \    BuiltIn.Should Match Regexp    ${output}    \\s*${prefix}/32\\s*${DCGW_IP_LIST[${index}]}

Verify Leaking Route Across VPNs
    [Arguments]    ${rd}    @{nexthop_list}
    [Documentation]    Routes shoud not leak across multiple VPNs
    ${output} =    KarafKeywords.Issue_Command_On_Karaf_Console    show-bgp --cmd "ip bgp vrf ${rd}"
    : FOR    ${nexthop}    IN    @{nexthop_list}
    \    BuiltIn.Should Not Contain    ${output}    ${nexthop}
