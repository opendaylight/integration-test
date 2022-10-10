*** Settings ***
Documentation       This library contains keywords related to the BGP functionality.

Library             SSHLibrary
Library             String
Library             BgpRpcClient.py    ${TOOLS_SYSTEM_IP}
Resource            ../variables/Variables.robot
Resource            CompareStream.robot
Resource            Utils.robot
Resource            KillPythonTool.robot
Resource            TemplatedRequests.robot


*** Variables ***
${BGP_BMP_DIR}              ${CURDIR}/../variables/bgpfunctional/bmp_basic/filled_structure
${BGP_BMP_FEAT_DIR}         ${CURDIR}/../variables/bgpfunctional/bmp_basic/empty_structure
${BGP_RIB_URI}              bgp-rib:bgp-rib/rib=example-bgp-rib
${BGP_TOPOLOGY_URI}         ${TOPOLOGY_URL}=example-ipv4-topology
${VAR_BASE_BGP}             ${CURDIR}/../variables/bgpfunctional
${RIB_NAME}                 example-bgp-rib
&{APP_PEER}                 IP=${ODL_SYSTEM_IP}    BGP_RIB=${RIB_NAME}
${BGP_CONFIG_SERVER_CMD}    bgp-connect -h ${ODL_SYSTEM_IP} -p 7644 add
${VPNV4_ADDR_FAMILY}        vpnv4
${DISPLAY_VPN4_ALL}         show-bgp --cmd "ip bgp ${VPNV4_ADDR_FAMILY} all"


*** Keywords ***
Start Quagga Processes On ODL
    [Documentation]    To start the zrpcd processes on ODL VM
    [Arguments]    ${odl_ip}
    ${conn_id} =    Open_Connection_To_ODL_System    ip_address=${odl_ip}
    Switch Connection    ${conn_id}
    Write Commands Until Expected Prompt    cd /opt/quagga/etc/    ${DEFAULT_LINUX_PROMPT_STRICT}
    Write Commands Until Expected Prompt    sudo cp zebra.conf.sample zebra.conf    ${DEFAULT_LINUX_PROMPT_STRICT}
    Write Commands Until Expected Prompt    sudo /opt/quagga/etc/init.d/zrpcd start    ${DEFAULT_LINUX_PROMPT_STRICT}
    Write Commands Until Expected Prompt    ps -ef | grep zrpcd    ${DEFAULT_LINUX_PROMPT_STRICT}
    Write Commands Until Expected Prompt    netstat -nap | grep 7644    ${DEFAULT_LINUX_PROMPT_STRICT}
    Close Connection

Restart BGP Processes On ODL
    [Documentation]    To restart the bgpd , qthriftd processes on ODL VM
    [Arguments]    ${odl_ip}
    ${conn_id} =    Open_Connection_To_ODL_System    ip_address=${odl_ip}
    Switch Connection    ${conn_id}
    Write Commands Until Expected Prompt    sudo pkill -f bgpd    ${DEFAULT_LINUX_PROMPT_STRICT}
    Start Quagga Processes On ODL    ${odl_ip}

Start Quagga Processes On DCGW
    [Documentation]    To start the zrpcd, bgpd,and zebra processes on DCGW
    [Arguments]    ${dcgw_ip}
    ${dcgw_conn_id} =    Open_Connection_To_Tools_System    ip_address=${dcgw_ip}
    Switch Connection    ${dcgw_conn_id}
    Write Commands Until Expected Prompt    cd /opt/quagga/etc/    ${DEFAULT_LINUX_PROMPT_STRICT}
    Write Commands Until Expected Prompt    sudo cp zebra.conf.sample zebra.conf    ${DEFAULT_LINUX_PROMPT_STRICT}
    Write Commands Until Expected Prompt    sudo /opt/quagga/etc/init.d/zrpcd start    ${DEFAULT_LINUX_PROMPT_STRICT}
    Write Commands Until Expected Prompt    ps -ef | grep zrpcd    ${DEFAULT_LINUX_PROMPT_STRICT}
    Write Commands Until Expected Prompt    cd /opt/quagga/sbin/    ${DEFAULT_LINUX_PROMPT_STRICT}
    ${output} =    Write    sudo ./bgpd &
    ${output} =    Read Until    pid
    Log    ${output}
    ${output} =    Write    sudo ./zebra &
    ${output} =    Read
    Log    ${output}
    Write Commands Until Expected Prompt    ps -ef | grep bgpd    ${DEFAULT_LINUX_PROMPT_STRICT}
    Write Commands Until Expected Prompt    ps -ef | grep zebra    ${DEFAULT_LINUX_PROMPT_STRICT}
    Write Commands Until Expected Prompt    netstat -nap | grep 7644    ${DEFAULT_LINUX_PROMPT_STRICT}

Restart BGP Processes On DCGW
    [Documentation]    To Restart the zrpcd, bgpd and zebra processes on DCGW
    [Arguments]    ${dcgw_ip}
    ${dcgw_conn_id} =    Open_Connection_To_Tools_System    ip_address=${dcgw_ip}
    Switch Connection    ${dcgw_conn_id}
    Write Commands Until Expected Prompt    sudo pkill -f bgpd    ${DEFAULT_LINUX_PROMPT_STRICT}
    Start Quagga Processes On DCGW    ${dcgw_ip}

Stop BGP Processes On Node
    [Documentation]    To stop the bgpd , qthriftd processes on specific node given by user.
    [Arguments]    ${node_ip}
    Utils.Run Command On Remote System    ${node_ip}    sudo pkill -f bgpd
    Utils.Run Command On Remote System    ${node_ip}    sudo pkill -f zrpcd

Show Quagga Configuration On ODL
    [Documentation]    Show quagga config from ODL
    [Arguments]    ${odl_ip}    ${rd}
    Create Quagga Telnet Session    ${odl_ip}    bgpd    sdncbgpc
    Execute Command On Quagga Telnet Session    show running-config
    Execute Command On Quagga Telnet Session    show bgp neighbors
    Execute Command On Quagga Telnet Session    show ip bgp vrf ${rd}
    Execute Command On Quagga Telnet Session    exit
    Close Connection

Create Quagga Telnet Session
    [Documentation]    Create telnet session for Quagga
    [Arguments]    ${ip}    ${user}    ${password}
    ${conn_id} =    Open_Connection_To_Tools_System    ip_address=${ip}
    Switch Connection    ${conn_id}
    ${output} =    Write    telnet localhost ${user}
    ${output} =    Read Until    Password:
    ${output} =    Write    ${password}
    ${output} =    Read
    ${output} =    Write    terminal length 512
    ${output} =    Read

Execute Command On Quagga Telnet Session
    [Documentation]    Execute command on Quagga telnet session(session should exist) and returns the output.
    [Arguments]    ${command}
    SSHLibrary.Write    ${command}
    ${output} =    SSHLibrary.Read
    Log    ${output}
    RETURN    ${output}

Configure BGP And Add Neighbor On DCGW
    [Documentation]    Configure BGP and add neighbor on the dcgw
    [Arguments]    ${dcgw_ip}    ${as_id}    ${router_id}    ${neighbor_ip}    ${vrf_name}    ${rd}
    ...    ${loopback_ip}
    Create Quagga Telnet Session    ${dcgw_ip}    bgpd    sdncbgpc
    Execute Command On Quagga Telnet Session    configure terminal
    Execute Command On Quagga Telnet Session    router bgp ${as_id}
    Execute Command On Quagga Telnet Session    bgp router-id ${router_id}
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
    Execute Command On Quagga Telnet Session    show running-config
    Execute Command On Quagga Telnet Session    exit

Add Loopback Interface On DCGW
    [Documentation]    Add loopback interface on DCGW
    [Arguments]    ${dcgw_ip}    ${loopback_name}    ${loopback_ip}    ${user}=zebra    ${password}=zebra
    Create Quagga Telnet Session    ${dcgw_ip}    ${user}    ${password}
    Execute Command On Quagga Telnet Session    enable
    Execute Command On Quagga Telnet Session    ${password}
    Execute Command On Quagga Telnet Session    configure terminal
    Execute Command On Quagga Telnet Session    interface ${loopback_name}
    Execute Command On Quagga Telnet Session    ip address ${loopback_ip}/32
    Execute Command On Quagga Telnet Session    exit
    Execute Command On Quagga Telnet Session    end
    Execute Command On Quagga Telnet Session    show running-config
    Execute Command On Quagga Telnet Session    exit

Execute Show Command On Quagga
    [Documentation]    Execute command on quagga and returns the ouput.
    [Arguments]    ${dcgw_ip}    ${cmd}    ${user}=bgpd    ${password}=sdncbgpc
    Create Quagga Telnet Session    ${dcgw_ip}    ${user}    ${password}
    ${output} =    Execute Command On Quagga Telnet Session    ${cmd}
    Log    ${output}
    Execute Command On quagga Telnet Session    exit
    RETURN    ${output}

Verify BGP Neighbor Status On Quagga
    [Documentation]    Verify bgp neighbor status on quagga
    [Arguments]    ${dcgw_ip}    ${neighbor_ip}
    ${output} =    Execute Show Command On quagga    ${dcgw_ip}    show bgp neighbors ${neighbor_ip}
    Log    ${output}
    Should Contain    ${output}    BGP state = Established

Setup BGP Peering On ODL
    [Documentation]    Setup BGP peering between ODL and given neighbor IP.
    ...    Configuring and starting BGP on ODL node with given AS number
    ...    Adding and verifying BGP neighbor
    [Arguments]    ${odl_ip}    ${as_id}    ${nbr_ip}
    KarafKeywords.Issue Command On Karaf Console    ${BGP_CONFIG_SERVER_CMD}
    BgpOperations.Create BGP Configuration On ODL    localas=${as_id}    routerid=${odl_ip}
    BgpOperations.AddNeighbor To BGP Configuration On ODL    remoteas=${as_id}    neighborAddr=${nbr_ip}
    ${output} =    BgpOperations.Get BGP Configuration On ODL    session
    BuiltIn.Should Contain    ${output}    ${nbr_ip}

Setup BGP Peering On DCGW
    [Documentation]    Setup BGP peering between DCGW and given neighbor IP.
    ...    Configuring,adding neighbor on DCGW node and verifying BGP neighbor.
    [Arguments]    ${dcgw_ip}    ${as_id}    ${nbr_ip}    ${vrf_name}    ${rd}    ${loopback_ip}
    BgpOperations.Configure BGP And Add Neighbor On DCGW
    ...    ${dcgw_ip}
    ...    ${as_id}
    ...    ${dcgw_ip}
    ...    ${nbr_ip}
    ...    ${vrf_name}
    ...    ${rd}
    ...    ${loopback_ip}
    ${output} =    BgpOperations.Execute Show Command On Quagga    ${dcgw_ip}    ${RUN_CONFIG}
    BuiltIn.Should Contain    ${output}    ${nbr_ip}

Verify Routes On Quagga
    [Documentation]    Verify routes on quagga
    [Arguments]    ${dcgw_ip}    ${rd}    ${ip_list}
    ${output} =    Execute Show Command On quagga    ${dcgw_ip}    show ip bgp vrf ${rd}
    Log    ${output}
    FOR    ${ip}    IN    @{ip_list}
        Should Contain    ${output}    ${ip}
    END

Delete BGP Config On Quagga
    [Documentation]    Delete BGP Config on Quagga
    [Arguments]    ${dcgw_ip}    ${bgp_id}    ${user}=bgpd    ${password}=sdncbgpc
    Create Quagga Telnet Session    ${dcgw_ip}    ${user}    ${password}
    Execute Command On Quagga Telnet Session    configure terminal
    Execute Command On Quagga Telnet Session    no router bgp ${bgp_id}
    Execute Command On Quagga Telnet Session    end
    ${output} =    Execute Command On Quagga Telnet Session    show running-config
    Execute Command On Quagga Telnet Session    exit
    RETURN    ${output}

Create L3VPN on DCGW
    [Documentation]    Creating L3VPN on DCGW
    [Arguments]    ${dcgw_ip}    ${as_id}    ${vpn_name}    ${rd}
    BgpOperations.Create Quagga Telnet Session    ${dcgw_ip}    bgpd    sdncbgpc
    BgpOperations.Execute Command On Quagga Telnet Session    configure terminal
    BgpOperations.Execute Command On Quagga Telnet Session    router bgp ${as_id}
    BgpOperations.Execute Command On Quagga Telnet Session    vrf ${vpn_name}
    BgpOperations.Execute Command On Quagga Telnet Session    rd ${rd}
    BgpOperations.Execute Command On Quagga Telnet Session    rt export ${rd}
    BgpOperations.Execute Command On Quagga Telnet Session    rt import ${rd}
    BgpOperations.Execute Command On Quagga Telnet Session    end

Delete L3VPN on DCGW
    [Documentation]    Deleting L3VPN on DCGW
    [Arguments]    ${dcgw_ip}    ${as_id}    @{vpns}
    BgpOperations.Create Quagga Telnet Session    ${dcgw_ip}    bgpd    sdncbgpc
    BgpOperations.Execute Command On Quagga Telnet Session    configure terminal
    BgpOperations.Execute Command On Quagga Telnet Session    router bgp ${as_id}
    FOR    ${vpn}    IN    @{vpns}
        BgpOperations.Execute Command On Quagga Telnet Session    no vrf ${vpn}
    END
    BgpOperations.Execute Command On Quagga Telnet Session    end

Verify L3VPN On DCGW
    [Documentation]    Verify L3VPN vrf name and rd value on DCGW
    [Arguments]    ${dcgw_ip}    ${vpn_name}    ${rd}
    ${output} =    BgpOperations.Execute Show Command On Quagga    ${dcgw_ip}    show running-config
    BuiltIn.Should Contain    ${output}    vrf ${vpn_name}
    BuiltIn.Should Contain    ${output}    rd ${rd}

Add Routes On DCGW
    [Documentation]    Add routes on DCGW
    [Arguments]    ${dcgw_ip}    ${rd}    ${network_ip}    ${label}
    BgpOperations.Create Quagga Telnet Session    ${dcgw_ip}    bgpd    sdncbgpc
    BgpOperations.Execute Command On Quagga Telnet Session    configure terminal
    BgpOperations.Execute Command On Quagga Telnet Session    router bgp ${AS_ID}
    BgpOperations.Execute Command On Quagga Telnet Session    address-family vpnv4 unicast
    BgpOperations.Execute Command On Quagga Telnet Session    network ${network_ip}/32 rd ${rd} tag ${label}
    BgpOperations.Execute Command On Quagga Telnet Session    end

Create BGP Configuration On ODL
    [Documentation]    Associate the created L3VPN to a network-id received as dictionary argument
    [Arguments]    &{Kwargs}
    TemplatedRequests.Post_As_Json_Templated
    ...    folder=${VAR_BASE_BGP}/create_bgp
    ...    mapping=${Kwargs}
    ...    session=session

AddNeighbor To BGP Configuration On ODL
    [Documentation]    Associate the created L3VPN to a network-id received as dictionary argument
    [Arguments]    &{Kwargs}
    CompareStream.Run_Keyword_If_Less_Than_Magnesium
    ...    TemplatedRequests.Post_As_Json_Templated
    ...    folder=${VAR_BASE_BGP}/addNeighbor_bgp
    ...    mapping=${Kwargs}
    ...    session=session
    CompareStream.Run_Keyword_If_At_Least_Magnesium
    ...    TemplatedRequests.Post_As_Json_Templated
    ...    folder=${VAR_BASE_BGP}/addNeighborsContainer_bgp
    ...    mapping=${Kwargs}
    ...    session=session

Get BGP Configuration On ODL
    [Documentation]    Get bgp configuration
    [Arguments]    ${odl_session}
    ${resp} =    RequestsLibrary.Get Request    ${odl_session}    ${CONFIG_API}/ebgp:bgp/
    Log    ${resp.text}
    RETURN    ${resp.text}

Delete BGP Configuration On ODL
    [Documentation]    Delete BGP
    [Arguments]    ${odl_session}
    ${resp} =    RequestsLibrary.Delete Request    ${odl_session}    ${CONFIG_API}/ebgp:bgp/
    Log    ${resp.text}
    Should Be Equal As Strings    ${resp.status_code}    200
    RETURN    ${resp.text}

Create External Tunnel Endpoint Configuration
    [Documentation]    Create Tunnel End point
    [Arguments]    &{Kwargs}
    TemplatedRequests.Post_As_Json_Templated
    ...    folder=${VAR_BASE_BGP}/create_etep
    ...    mapping=${Kwargs}
    ...    session=session

Delete External Tunnel Endpoint Configuration
    [Documentation]    Delete Tunnel End point
    [Arguments]    &{Kwargs}
    TemplatedRequests.Post_As_Json_Templated
    ...    folder=${VAR_BASE_BGP}/delete_etep
    ...    mapping=${Kwargs}
    ...    session=session

Get External Tunnel Endpoint Configuration
    [Documentation]    Get bgp configuration
    [Arguments]    ${ip}
    ${resp} =    RequestsLibrary.Get Request    session    ${CONFIG_API}/itm:dc-gateway-ip-list/dc-gateway-ip/${ip}/
    Log    ${resp.text}
    RETURN    ${resp.text}

Teardown_Everything
    [Documentation]    Create and Log the diff between expected and actual responses, make sure Python tool was killed.
    ...    Tear down imported Resources.
    KillPythonTool.Search_And_Kill_Remote_Python    'play\.py'
    RequestsLibrary.Delete_All_Sessions
    SSHLibrary.Close_All_Connections

Check_Example_Bgp_Rib_Content
    [Documentation]    Check the example-bgp-rib content for string
    [Arguments]    ${session}    ${substr}    ${error_message}=${JSONKEYSTR} not found, but expected.
    ${response} =    RequestsLibrary.Get Request    ${session}    ${REST_API}/${BGP_RIB_URI}?content=nonconfig
    BuiltIn.Log    ${response.status_code}
    BuiltIn.Log    ${response.text}
    BuiltIn.Should_Contain    ${response.text}    ${substr}    ${error_message}    values=False

Check_Example_Bgp_Rib_Does_Not_Contain
    [Documentation]    Check the example-bgp-rib does not contain the string
    [Arguments]    ${session}    ${substr}    ${error_message}=${JSONKEYSTR} found, but not expected.
    ${response} =    RequestsLibrary.Get Request    ${session}    ${REST_API}/${BGP_RIB_URI}?content=nonconfig
    BuiltIn.Log    ${response.status_code}
    BuiltIn.Log    ${response.text}
    BuiltIn.Should_Not_Contain    ${response.text}    ${substr}    ${error_message}    values=False

Check_Example_IPv4_Topology_Content
    [Documentation]    Check the example-ipv4-topology content for string
    [Arguments]    ${session}    ${string_to_check}=${EMPTY}
    ${response} =    RequestsLibrary.Get Request    ${session}    ${REST_API}/${BGP_TOPOLOGY_URI}?content=nonconfig
    BuiltIn.Log    ${response.status_code}
    BuiltIn.Log    ${response.text}
    BuiltIn.Should_Contain    ${response.text}    ${string_to_check}

Check_Example_IPv4_Topology_Does_Not_Contain
    [Documentation]    Check the example-ipv4-topology does not contain the string
    [Arguments]    ${session}    ${string_to_check}
    ${response} =    RequestsLibrary.Get Request    ${session}    ${REST_API}/${BGP_TOPOLOGY_URI}?content=nonconfig
    BuiltIn.Log    ${response.status_code}
    BuiltIn.Log    ${response.text}
    BuiltIn.Should_Not_Contain    ${response.text}    ${string_to_check}

Bmp_Monitor_Precondition
    [Documentation]    Verify example-bmp-monitor presence in bmp-monitors
    [Arguments]    ${session}
    &{mapping} =    BuiltIn.Create_Dictionary    TOOL_IP=${TOOLS_SYSTEM_IP}
    BuiltIn.Wait_Until_Keyword_Succeeds
    ...    6x
    ...    10s
    ...    TemplatedRequests.Get_As_Json_Templated
    ...    folder=${BGP_BMP_FEAT_DIR}
    ...    mapping=${mapping}
    ...    verify=True
    ...    session=${session}

Bmp_Monitor_Postcondition
    [Documentation]    Verifies if example-bmp-monitor data contains one peer.
    [Arguments]    ${session}
    &{mapping} =    BuiltIn.Create_Dictionary    TOOL_IP=${TOOLS_SYSTEM_IP}
    ${output} =    BuiltIn.Wait_Until_Keyword_Succeeds
    ...    10x
    ...    5s
    ...    TemplatedRequests.Get_As_Json_Templated
    ...    folder=${BGP_BMP_DIR}
    ...    mapping=${mapping}
    ...    session=${session}
    ...    verify=True
    BuiltIn.Log    ${output}

Odl_To_Play_Template
    [Arguments]    ${totest}    ${dir}    ${remove}=True
    ${announce_hex} =    OperatingSystem.Get_File    ${dir}/${totest}/announce_${totest}.hex
    ${announce_hex} =    String.Remove_String    ${announce_hex}    \n
    ${withdraw_hex} =    OperatingSystem.Get_File    ${dir}/${totest}/withdraw_${totest}.hex
    ${withdraw_hex} =    String.Remove_String    ${withdraw_hex}    \n
    IF    '${remove}' == 'True'    BgpRpcClient.play_clean
    TemplatedRequests.Post_As_Xml_Templated    ${dir}/${totest}/app    mapping=${APP_PEER}    session=${CONFIG_SESSION}
    ${update} =    BuiltIn.Wait_Until_Keyword_Succeeds    3x    2s    Get_Update_Message
    Verify_Two_Hex_Messages_Are_Equal    ${update}    ${announce_hex}
    BgpRpcClient.play_clean
    Remove_Configured_Routes    ${totest}    ${dir}
    ${update} =    BuiltIn.Wait_Until_Keyword_Succeeds    3x    2s    Get_Update_Message
    Verify_Two_Hex_Messages_Are_Equal    ${update}    ${withdraw_hex}
    [Teardown]    Remove_Configured_Routes    ${totest}    ${dir}

Play_To_Odl_Template
    [Arguments]    ${totest}    ${dir}    ${ipv}=ipv4
    &{adj_rib_in} =    BuiltIn.Create_Dictionary
    ...    PATH=peer\=bgp:%2F%2F${TOOLS_SYSTEM_IP}/adj-rib-in
    ...    BGP_RIB=${RIB_NAME}
    &{effective_rib_in} =    BuiltIn.Create_Dictionary
    ...    PATH=peer\=bgp:%2F%2F${TOOLS_SYSTEM_IP}/effective-rib-in
    ...    BGP_RIB=${RIB_NAME}
    &{loc_rib} =    BuiltIn.Create_Dictionary    PATH=loc-rib    BGP_RIB=${RIB_NAME}
    ${announce_hex} =    OperatingSystem.Get_File    ${dir}/${totest}/announce_${totest}.hex
    ${withdraw_hex} =    OperatingSystem.Get_File    ${dir}/${totest}/withdraw_${totest}.hex
    BgpRpcClient.play_clean
    BgpRpcClient.play_send    ${announce_hex}
    BuiltIn.Wait_Until_Keyword_Succeeds
    ...    3x
    ...    2s
    ...    TemplatedRequests.Get_As_Json_Templated
    ...    ${dir}/${totest}/rib
    ...    mapping=${adj_rib_in}
    ...    session=${CONFIG_SESSION}
    ...    verify=True
    BuiltIn.Wait_Until_Keyword_Succeeds
    ...    3x
    ...    2s
    ...    TemplatedRequests.Get_As_Json_Templated
    ...    ${dir}/${totest}/rib
    ...    mapping=${effective_rib_in}
    ...    session=${CONFIG_SESSION}
    ...    verify=True
    BuiltIn.Wait_Until_Keyword_Succeeds
    ...    3x
    ...    2s
    ...    TemplatedRequests.Get_As_Json_Templated
    ...    ${dir}/${totest}/rib
    ...    mapping=${loc_rib}
    ...    session=${CONFIG_SESSION}
    ...    verify=True
    BgpRpcClient.play_send    ${withdraw_hex}
    BuiltIn.Wait_Until_Keyword_Succeeds
    ...    3x
    ...    2s
    ...    TemplatedRequests.Get_As_Json_Templated
    ...    ${dir}/empty_routes/${ipv}
    ...    mapping=${loc_rib}
    ...    session=${CONFIG_SESSION}
    ...    verify=True
    [Teardown]    BgpRpcClient.play_send    ${withdraw_hex}

Play_To_Odl_Non_Removal_Template
    [Arguments]    ${totest}    ${dir}    ${ipv}=ipv4
    ${announce_hex} =    OperatingSystem.Get_File    ${dir}/${totest}/announce_${totest}.hex
    BgpRpcClient.play_clean
    BgpRpcClient.play_send    ${announce_hex}
    &{loc_rib} =    BuiltIn.Create_Dictionary    PATH=loc-rib    BGP_RIB=${RIB_NAME}
    BuiltIn.Wait_Until_Keyword_Succeeds
    ...    3x
    ...    2s
    ...    TemplatedRequests.Get_As_Json_Templated
    ...    ${dir}/${totest}/rib
    ...    mapping=${loc_rib}
    ...    session=${CONFIG_SESSION}
    ...    verify=True

Get_Update_Message
    [Documentation]    Returns hex update message.
    ${update} =    BgpRpcClient.play_get
    BuiltIn.Should_Not_Be_Equal    ${update}    ${Empty}
    RETURN    ${update}

Remove_Configured_Routes
    [Documentation]    Removes the route if present.
    [Arguments]    ${totest}    ${dir}
    BuiltIn.Run_Keyword_And_Ignore_Error
    ...    TemplatedRequests.Delete_Templated
    ...    ${dir}/${totest}/app
    ...    mapping=${APP_PEER}
    ...    session=${CONFIG_SESSION}

Verify_Two_Hex_Messages_Are_Equal
    [Documentation]    Verifies two hex messages are equal even in case, their arguments are misplaced.
    ...    Compares length of the hex messages and sums hex messages arguments as integers and compares results.
    [Arguments]    ${hex_1}    ${hex_2}
    ${len_1} =    BuiltIn.Get_Length    ${hex_1}
    ${len_2} =    BuiltIn.Get_Length    ${hex_2}
    BuiltIn.Should_Be_Equal    ${len_1}    ${len_2}
    ${sum_1} =    BgpRpcClient.Sum_Hex_Message    ${hex_1}
    ${sum_2} =    BgpRpcClient.Sum_Hex_Message    ${hex_2}
    BuiltIn.Should_Be_Equal    ${sum_1}    ${sum_2}

Check BGP VPNv4 Nbr On ODL
    [Documentation]    Check all BGP VPNv4 neighbor on ODL
    [Arguments]    ${dcgw_count}    ${flag}=True    ${start}=${START_VALUE}
    ${output} =    KarafKeywords.Issue Command On Karaf Console    ${DISPLAY_VPN4_ALL}
    FOR    ${index}    IN RANGE    ${start}    ${dcgw_count}
        IF    ${flag}==True
            BuiltIn.Should Contain    ${output}    ${DCGW_IP_LIST[${index}]}
        ELSE
            BuiltIn.Should Not Contain    ${output}    ${DCGW_IP_LIST[${index}]}
        END
    END
