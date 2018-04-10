*** Settings ***
Documentation     The objective of this testsuite is to test QBGP and ODL for multipath/ECMP support.
...               QBGP should be capable to receive multiple ECMP paths from different DC-GWs and
...               to export the ECMP paths to ODL instead of best path selection.
...               ODL should be capable to receive ECMP paths and it should program the FIB with ECMP paths.
Suite Setup       Start Suite
Suite Teardown    Stop Suite
Test Teardown     Test Cleanup
Library           OperatingSystem
Library           RequestsLibrary
Resource          ../../../libraries/BgpOperations.robot
Resource          ../../../libraries/KarafKeywords.robot
Resource          ../../../libraries/OpenStackOperations.robot
Resource          ../../../libraries/SSHKeywords.robot
Resource          ../../../libraries/Utils.robot
Resource          ../../../libraries/VpnOperations.robot
Resource          ../../../variables/Variables.robot

*** Variables ***
@{DCGW_RD}        1:1    2:2    3:3    4:4
@{DCGW_IRT}       22:1    22:2    22:3
@{DCGW_ERT}       11:1    11:2    11:3
@{DCGW_IP_LIST}    ${TOOLS_SYSTEM_1_IP}    ${TOOLS_SYSTEM_2_IP}    ${TOOLS_SYSTEM_3_IP}
@{LABEL}          51    52    53
@{L3VPN_RD}       ["11:1"]    ["22:2"]    ["33:3"]
@{L3VPN_IRT}      ["11:1"]    ["11:2"]    ["11:3"]
@{L3VPN_ERT}      ["22:1"]    ["22:2"]    ["22:3"]
@{MAX_PATH_LIST}    1    2    3    8    64
@{MAX_PATH_INVALID_LIST}    -1    0    65
@{MULTIPATH_RD}    11:1    22:2    33:3
@{NETWORK_IP}     10.1.1.1/32    20.1.1.1/32    30.1.1.1/32
@{NUM_OF_ROUTES}    0    1    2    3    4    5    6
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
${DISPLAY_VPN4_ALL}    show-bgp --cmd "ip bgp vpnv4 all"
${DIPSLAY_FIB}    fib-show
${MAXPATH_ERROR}    error: --maxpath range[1 - 64]
${NUM_OF_DCGW}    3
${NUM_OF_L3VPN}    3
${START_VALUE}    0

*** Test Cases ***
Verify ODL supports REST API/CLI for multipath configuration (enable/disable multipath)
    [Documentation]    Verify ODL supports REST API/CLI for multipath configuration (enable/disable multipath)
    Enable Or Disable Multipath On ODL
    Verify Multipath
    Enable Or Disable Multipath On ODL    False
    Verify Multipath    False

Verify ODL supports REST API/CLI for max path configuration
    [Documentation]    Verify ODL supports REST API/CLI for max path configuration
    : FOR    ${idx}    IN RANGE    ${START_VALUE}    ${NUM_OF_DCGW}
    \    VpnOperations.VPN Create L3VPN    name=@{VPN_NAME}[${idx}]    vpnid=@{VPN_ID}[${idx}]    rd=@{L3VPN_RD}[${idx}]    exportrt=@{L3VPN_ERT}[${idx}]    importrt=@{L3VPN_IRT}[${idx}]
    BuiltIn.Wait Until Keyword Succeeds    10s    2s    Verify L3VPN On ODL    @{VPN_ID}
    Enable Or Disable Multipath On ODL
    BuiltIn.Wait Until Keyword Succeeds    10s    2s    Verify Multipath
    : FOR    ${idx}    IN RANGE    ${START_VALUE}    ${NUM_OF_DCGW}
    \    Configure Maxpath    @{MAX_PATH_LIST}[2]    @{MULTIPATH_RD}[${idx}]
    : FOR    ${idx}    IN RANGE    ${START_VALUE}    ${NUM_OF_DCGW}
    \    BuiltIn.Wait Until Keyword Succeeds    10s    2s    Verify Maxpath    @{MAX_PATH_LIST}[2]    @{MULTIPATH_RD}[${idx}]
    Check BGP VPNv4 Nbr On ODL    ${NUM_OF_DCGW}    False

Verify max-path configuration value should not be 0/-ve, because it’s not supported
    [Documentation]    Verify max-path configuration value should not be 0/-ve, because it’s not supported
    VpnOperations.VPN Create L3VPN    name=@{VPN_NAME}[0]    vpnid=@{VPN_ID}[0]    rd=@{L3VPN_RD}[0]    exportrt=@{L3VPN_ERT}[0]    importrt=@{L3VPN_IRT}[0]
    BuiltIn.Wait Until Keyword Succeeds    10s    2s    Verify L3VPN On ODL    ${VPN_ID[0]}
    Enable Or Disable Multipath On ODL
    Verify Multipath
    Configure Maxpath    @{MAX_PATH_INVALID_LIST}[0]    @{MULTIPATH_RD}[0]
    Verify Maxpath    @{MAX_PATH_INVALID_LIST}[0]    @{MULTIPATH_RD}[0]
    Configure Maxpath    @{MAX_PATH_INVALID_LIST}[1]    @{MULTIPATH_RD}[0]
    Verify Maxpath    @{MAX_PATH_INVALID_LIST}[1]    @{MULTIPATH_RD}[0]
    Configure Maxpath    @{MAX_PATH_INVALID_LIST}[2]    @{MULTIPATH_RD}[0]
    Verify Maxpath    @{MAX_PATH_INVALID_LIST}[2]    @{MULTIPATH_RD}[0]
    Check BGP VPNv4 Nbr On ODL    ${NUM_OF_DCGW}    False

Verify that max path default is set to 8 and max path configurable is 64 on ODL
    [Documentation]    Verify that max path default is set to 8 and max path configurable is 64 on ODL
    VpnOperations.VPN Create L3VPN    name=@{VPN_NAME}[0]    vpnid=@{VPN_ID}[0]    rd=@{L3VPN_RD}[0]    exportrt=@{L3VPN_ERT}[0]    importrt=@{L3VPN_IRT}[0]
    BuiltIn.Wait Until Keyword Succeeds    10s    2s    Verify L3VPN On ODL    ${VPN_ID[0]}
    Enable Or Disable Multipath On ODL
    Verify Multipath
    BuiltIn.Wait Until Keyword Succeeds    10s    2s    Configure Maxpath    @{MAX_PATH_LIST}[4]    @{MULTIPATH_RD}[0]
    BuiltIn.Wait Until Keyword Succeeds    10s    2s    Verify Maxpath    @{MAX_PATH_LIST}[4]    @{MULTIPATH_RD}[0]

Verify ODL supports dynamic configuration changes for max path value
    [Documentation]    Verify ODL supports dynamic configuration changes for max path value
    VpnOperations.VPN Create L3VPN    name=@{VPN_NAME}[0]    vpnid=@{VPN_ID}[0]    rd=@{L3VPN_RD}[0]    exportrt=@{L3VPN_ERT}[0]    importrt=@{L3VPN_IRT}[0]
    BuiltIn.Wait Until Keyword Succeeds    10s    2s    Verify L3VPN On ODL    @{VPN_ID}[0]
    VpnOperations.Associate VPN to Router    @{router_id_list}[0]    vpnid=@{VPN_ID}[0]
    : FOR    ${idx}    IN RANGE    ${START_VALUE}    ${NUM_OF_DCGW}
    \    Create L3VPN on Dcgateway    @{DCGW_IP_LIST}[${idx}]    @{VPN_NAME}[0]    @{DCGW_RD}[0]    @{DCGW_IRT}[0]    @{DCGW_ERT}[0]
    Verify L3VPN On DCGW    ${NUM_OF_DCGW}    @{VPN_NAME}[0]    @{DCGW_RD}[0]    @{DCGW_IRT}[0]    @{DCGW_ERT}[0]
    Check BGP Session On DCGW    ${NUM_OF_DCGW}
    Check BGP Session On ODL    ${NUM_OF_DCGW}
    Enable Or Disable Multipath On ODL
    BuiltIn.Wait Until Keyword Succeeds    10s    2s    Verify Multipath
    Configure Maxpath    @{MAX_PATH_LIST}[2]    @{MULTIPATH_RD}[0]
    BuiltIn.Wait Until Keyword Succeeds    10s    2s    Verify Maxpath    @{MAX_PATH_LIST}[2]    @{MULTIPATH_RD}[0]
    : FOR    ${idx}    IN RANGE    ${START_VALUE}    ${NUM_OF_DCGW}
    \    Add Routes    @{DCGW_IP_LIST}[${idx}]    @{DCGW_RD}[0]    @{NETWORK_IP}[0]    @{LABEL}[${idx}]
    BuiltIn.Wait Until Keyword Succeeds    60s    10s    Check BGP VPNv4 Nbr On ODL    ${NUM_OF_DCGW}
    BuiltIn.Wait Until Keyword Succeeds    60s    10s    Verify Routing Entry    @{MULTIPATH_RD}[0]    @{NETWORK_IP}[0]    @{NUM_OF_ROUTES}[3]
    BuiltIn.Wait Until Keyword Succeeds    10s    2s    Verify FIB Entry    @{NETWORK_IP}[0]    @{NUM_OF_ROUTES}[3]
    Configure Maxpath    @{MAX_PATH_LIST}[1]    @{MULTIPATH_RD}[0]
    BuiltIn.Wait Until Keyword Succeeds    10s    2s    Verify Maxpath    @{MAX_PATH_LIST}[1]    @{MULTIPATH_RD}[0]
    BuiltIn.Wait Until Keyword Succeeds    10s    2s    Check BGP VPNv4 Nbr On ODL    ${NUM_OF_DCGW}
    BuiltIn.Wait Until Keyword Succeeds    10s    2s    Verify Routing Entry    @{MULTIPATH_RD}[0]    @{NETWORK_IP}[0]    @{NUM_OF_ROUTES}[3]
    BuiltIn.Wait Until Keyword Succeeds    10s    2s    Verify FIB Entry    @{NETWORK_IP}[0]    @{NUM_OF_ROUTES}[2]
    Configure Maxpath    @{MAX_PATH_LIST}[0]    @{MULTIPATH_RD}[0]
    BuiltIn.Wait Until Keyword Succeeds    10s    2s    Verify Maxpath    @{MAX_PATH_LIST}[0]    @{MULTIPATH_RD}[0]
    BuiltIn.Wait Until Keyword Succeeds    10s    2s    Check BGP VPNv4 Nbr On ODL    ${NUM_OF_DCGW}
    BuiltIn.Wait Until Keyword Succeeds    10s    2s    Verify Routing Entry    @{MULTIPATH_RD}[0]    @{NETWORK_IP}[0]    @{NUM_OF_ROUTES}[3]
    BuiltIn.Wait Until Keyword Succeeds    10s    2s    Verify FIB Entry    @{NETWORK_IP}[0]    @{NUM_OF_ROUTES}[1]
    Configure Maxpath    @{MAX_PATH_LIST}[2]    @{MULTIPATH_RD}[0]
    BuiltIn.Wait Until Keyword Succeeds    10s    2s    Verify Maxpath    @{MAX_PATH_LIST}[2]    @{MULTIPATH_RD}[0]
    BuiltIn.Wait Until Keyword Succeeds    10s    2s    Check BGP VPNv4 Nbr On ODL    ${NUM_OF_DCGW}
    BuiltIn.Wait Until Keyword Succeeds    10s    2s    Verify Routing Entry    @{MULTIPATH_RD}[0]    @{NETWORK_IP}[0]    @{NUM_OF_ROUTES}[3]
    BuiltIn.Wait Until Keyword Succeeds    30s    5s    Verify FIB Entry    @{NETWORK_IP}[0]    @{NUM_OF_ROUTES}[3]

*** Keywords ***
Start Suite
    [Documentation]    Setup start suite
    VpnOperations.Basic Suite Setup
    BuiltIn.Log Many    @{DCGW_IP_LIST}
    : FOR    ${dcgw}    IN    @{DCGW_IP_LIST}
    \    BgpOperations.Start Quagga Processes On DCGW    ${dcgw}
    BgpOperations.Start Quagga Processes On ODL    ${ODL_SYSTEM_IP}
    KarafKeywords.Issue_Command_On_Karaf_Console    ${BGP_CONNECT}
    BgpOperations.Create BGP Configuration On ODL    localas=${AS_ID}    routerid=${ODL_SYSTEM_IP}
    : FOR    ${dcgw}    IN    @{DCGW_IP_LIST}
    \    BgpOperations.AddNeighbor To BGP Configuration On ODL    remoteas=${AS_ID}    neighborAddr=${dcgw}
    \    ${output} =    BgpOperations.Get BGP Configuration On ODL    session
    \    BuiltIn.Should Contain    ${output}    ${dcgw}
    : FOR    ${idx}    IN RANGE    ${START_VALUE}    ${NUM_OF_DCGW}
    \    Add BGP Neighbor On DCGW    ${DCGW_IP_LIST[${idx}]}    ${ODL_SYSTEM_IP}    ${AS_ID}
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
    Log    ${router_id_list}
    : FOR    ${index}    IN RANGE    0    3
    \    Add Router Interface    @{ROUTERS}[${index}]    @{SUBNETS}[${index}]
    \    ${output} =    OpenStackOperations.Show Router Interface    @{ROUTERS}[${index}]
    \    ${subnet_id} =    OpenStackOperations.Get Subnet Id    @{SUBNETS}[${index}]
    \    BuiltIn.Should Contain    ${output}    ${subnet_id}

Stop Suite
    [Documentation]    Deleting all BGP neighbors and configurations
    BgpOperations.Delete BGP Configuration On ODL    session
    OpenStackOperations.OpenStack Cleanup All

Test Cleanup
    [Documentation]    Posttest case cleanup
    : FOR    ${idx}    IN RANGE    ${START_VALUE}    ${NUM_OF_DCGW}
    \    Configure Maxpath    @{MAX_PATH_LIST}[0]    ${MULTIPATH_RD[${idx}]}
    Delete L3VPN    ${NUM_OF_L3VPN}
    Disable Multipath On ODL
    : FOR    ${idx}    IN RANGE    ${START_VALUE}    ${NUM_OF_DCGW}
    \    BgpOperations.Delete BGP Config On Quagga    ${DCGW_IP_LIST[${idx}]}    ${AS_ID}
    : FOR    ${idx}    IN RANGE    ${START_VALUE}    ${NUM_OF_DCGW}
    \    Add BGP Neighbor On DCGW    ${DCGW_IP_LIST[${idx}]}    ${ODL_SYSTEM_IP}    ${AS_ID}

Add BGP Neighbor On DCGW
    [Arguments]    ${dcgw_ip}    ${odl_ip}    ${as_number}
    [Documentation]    Configure BGP and add neighbor on the dcgateway
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
    [Teardown]    SSHLibrary.Close Connection

Create L3VPN on Dcgateway
    [Arguments]    ${dcgw_ip}    ${vpn_name}    ${rd}    ${import_rt}    ${export_rt}
    [Documentation]    Create L3VPN on dcgateway
    BgpOperations.Create Quagga Telnet Session    ${dcgw_ip}    bgpd    sdncbgpc
    BgpOperations.Execute Command On Quagga Telnet Session    configure terminal
    BgpOperations.Execute Command On Quagga Telnet Session    router bgp ${AS_ID}
    BgpOperations.Execute Command On Quagga Telnet Session    vrf ${vpn_name}
    BgpOperations.Execute Command On Quagga Telnet Session    rd ${rd}
    BgpOperations.Execute Command On Quagga Telnet Session    rt export ${export_rt}
    BgpOperations.Execute Command On Quagga Telnet Session    rt import ${import_rt}
    BgpOperations.Execute Command On Quagga Telnet Session    end
    [Teardown]    SSHLibrary.Close Connection

Add Routes
    [Arguments]    ${dcgw_ip}    ${rd}    ${network_ip}    ${label}
    [Documentation]    Add the routes to dcgateway
    BgpOperations.Create Quagga Telnet Session    ${dcgw_ip}    bgpd    sdncbgpc
    BgpOperations.Execute Command On Quagga Telnet Session    configure terminal
    BgpOperations.Execute Command On Quagga Telnet Session    router bgp ${AS_ID}
    BgpOperations.Execute Command On Quagga Telnet Session    address-family vpnv4
    BgpOperations.Execute Command On Quagga Telnet Session    network ${network_ip} rd ${rd} tag ${label}
    BgpOperations.Execute Command On Quagga Telnet Session    end
    [Teardown]    SSHLibrary.Close Connection

Enable Or Disable Multipath On ODL
    [Arguments]    ${enable}=True
    [Documentation]    Enabling multipath on ODL using karaf CLI
    Run Keyword If    ${enable}==True    KarafKeywords.Issue_Command_On_Karaf_Console    odl:multipath -f ${VPNV4_ADDR_FAMILY} enable
    ...    ELSE    KarafKeywords.Issue_Command_On_Karaf_Console    odl:multipath -f ${VPNV4_ADDR_FAMILY} disable

Configure Maxpath
    [Arguments]    ${maxpath}    ${rd}
    [Documentation]    Setting maxpath on ODL using karaf CLI
    ${maxpath_command}    Catenate    multipath -r    ${rd} -f ${VPNV4_ADDR_FAMILY} -n ${maxpath} setmaxpath
    ${output} =    KarafKeywords.Issue_Command_On_Karaf_Console    ${maxpath_command}
    Run Keyword If    0 < ${maxpath} < 65    BuiltIn.Should Not Contain    ${output}    ${MAXPATH_ERROR}
    ...    ELSE    BuiltIn.Should Contain    ${output}    ${MAXPATH_ERROR}

Verify Multipath
    [Arguments]    ${enable}=True
    [Documentation]    Verifying multipath is set properly on ODL
    ${output} =    KarafKeywords.Issue_Command_On_Karaf_Console    ${BGP_CACHE}
    Run Keyword If    ${enable}==True    BuiltIn.Should Contain    ${output}    ${VPNV4_ADDR_FAMILY}
    ...    ELSE    BuiltIn.Should Not Contain    ${output}    ${VPNV4_ADDR_FAMILY}

Verify Maxpath
    [Arguments]    ${maxpath}    ${rd}
    [Documentation]    Verify maxpath is set properly on ODL
    ${output} =    KarafKeywords.Issue_Command_On_Karaf_Console    ${BGP_CACHE}
    Run Keyword If    0 < ${maxpath} < 65    BuiltIn.Should Match Regexp    ${output}    ${rd}\\s*${maxpath}    BuiltIn.Should Not Contain    ${output}
    ...    ${MAXPATH_ERROR}
    ...    ELSE    BuiltIn.Should Not Match Regexp    ${output}    ${rd}\\s*${maxpath}

Delete L3VPN
    [Arguments]    ${l3vpn_count}    ${start}=${START_VALUE}
    [Documentation]    Delete BGP L3VPN configuration on ODL
    : FOR    ${idx}    IN RANGE    ${start}    ${l3vpn_count}
    \    BuiltIn.Run Keyword And Ignore Error    VpnOperations.VPN Delete L3VPN    vpnid=${VPN_ID[${idx}]}

Verify L3VPN On ODL
    [Arguments]    @{vpn_instance_list}
    [Documentation]    Verify BGP neighbor on ODL
    : FOR    ${vpn_instance}    IN    @{vpn_instance_list}
    \    ${resp} =    VpnOperations.VPN Get L3VPN    vpnid=${vpn_instance}
    \    BuiltIn.Should Contain    ${resp}    ${vpn_instance}

Verify L3VPN On DCGW
    [Arguments]    ${dcgw_count}    ${vpn_name}    ${rd}    ${import_rt}    ${export_rt}    ${start}=${START_VALUE}
    [Documentation]    Execute set of command on dcgateway
    : FOR    ${index}    IN RANGE    ${start}    ${dcgw_count}
    \    ${output} =    BgpOperations.Execute Show Command On Quagga    ${DCGW_IP_LIST[${index}]}    show running-config
    \    BuiltIn.Should Contain    ${output}    vrf ${vpn_name}
    \    BuiltIn.Should Contain    ${output}    rd ${rd}
    \    BuiltIn.Should Contain    ${output}    rt import ${import_rt}
    \    BuiltIn.Should Contain    ${output}    rt export ${export_rt}

Check BGP Session On ODL
    [Arguments]    ${dcgw_count}    ${start}=${START_VALUE}
    [Documentation]    Check BGP session on ODL
    : FOR    ${index}    IN RANGE    ${start}    ${dcgw_count}
    \    ${cmd}    BuiltIn.Set Variable    show-bgp --cmd "bgp neighbors ${DCGW_IP_LIST[${index}]}"
    \    ${output} =    KarafKeywords.Issue_Command_On_Karaf_Console    ${cmd}
    \    BuiltIn.Should Contain    ${output}    BGP state = Established

Check BGP VPNv4 Nbr On ODL
    [Arguments]    ${dcgw_count}    ${flag}=True    ${start}=${START_VALUE}
    [Documentation]    Check BGP VPNv4 neighbor all on ODL
    ${output} =    KarafKeywords.Issue_Command_On_Karaf_Console    ${DISPLAY_VPN4_ALL}
    : FOR    ${index}    IN RANGE    ${start}    ${dcgw_count}
    \    BuiltIn.Run Keyword If    ${flag}==True    BuiltIn.Should Contain    ${output}    ${DCGW_IP_LIST[${index}]}
    \    ...    ELSE    BuiltIn.Should Not Contain    ${output}    ${DCGW_IP_LIST[${index}]}

Check BGP Session On DCGW
    [Arguments]    ${dcgw_count}    ${start}=${START_VALUE}
    [Documentation]    Verify BGP neighborship status on DCGW
    : FOR    ${index}    IN RANGE    ${start}    ${dcgw_count}
    \    BuiltIn.Wait Until Keyword Succeeds    60s    10s    Verify BGP Neighbor Status On Quagga    ${DCGW_IP_LIST[${index}]}    ${ODL_SYSTEM_IP}

Verify Routing Entry
    [Arguments]    ${rd}    ${prefix}    ${no_of_times}
    [Documentation]    Get the route entry for specific RD
    ${output} =    KarafKeywords.Issue_Command_On_Karaf_Console    show-bgp --cmd "ip bgp vrf ${rd}"
    BuiltIn.Should Contain X Times    ${output}    ${prefix}    ${no_of_times}    msg="Routing table does not contain ${prefix} prefix ${no_of_times} times"

Verify FIB Entry
    [Arguments]    ${prefix}    ${no_of_times}
    [Documentation]    Checking FIB entries with valid counts
    ${output} =    KarafKeywords.Issue_Command_On_Karaf_Console    ${DIPSLAY_FIB}
    BuiltIn.Should Contain X Times    ${output}    ${prefix}    ${no_of_times}    msg="FIB table does not contain ${prefix} prefix ${no_of_times} times"
