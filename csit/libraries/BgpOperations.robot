*** Settings ***
Documentation     This library contains keywords related to the BGP functionality.
Library           SSHLibrary
Resource          Utils.robot
Resource          ../variables/Variables.robot
Resource          TemplatedRequests.robot
Resource          KillPythonTool.robot

*** Variables ***
${VAR_BASE_BGP}    ${CURDIR}/../variables/bgpfunctional
${BGP_BMP_DIR}    ${CURDIR}/../variables/bgpfunctional/bmp_basic/filled_structure
${BGP_BMP_FEAT_DIR}    ${CURDIR}/../variables/bgpfunctional/bmp_basic/empty_structure

*** Keywords ***
Start Quagga Processes On ODL
    [Arguments]    ${odl_ip}
    [Documentation]    To start the zrpcd processes on ODL VM
    ${conn_id}=    Open_Connection_To_ODL_System    ip_address=${odl_ip}
    Switch Connection    ${conn_id}
    Write Commands Until Expected Prompt    cd /opt/quagga/etc/    ${DEFAULT_LINUX_PROMPT_STRICT}
    Write Commands Until Expected Prompt    sudo cp zebra.conf.sample zebra.conf    ${DEFAULT_LINUX_PROMPT_STRICT}
    Write Commands Until Expected Prompt    sudo /opt/quagga/etc/init.d/zrpcd start    ${DEFAULT_LINUX_PROMPT_STRICT}
    Write Commands Until Expected Prompt    ps -ef | grep zrpcd    ${DEFAULT_LINUX_PROMPT_STRICT}
    Write Commands Until Expected Prompt    netstat -nap | grep 7644    ${DEFAULT_LINUX_PROMPT_STRICT}
    Close Connection

Start Quagga Processes On DCGW
    [Arguments]    ${dcgw_ip}
    [Documentation]    To start the zrpcd, bgpd,and zebra processes on DCGW
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

Show Quagga Configuration On ODL
    [Arguments]    ${odl_ip}    ${rd}
    [Documentation]    Show quagga config from ODL
    Create Quagga Telnet Session    ${odl_ip}    bgpd    sdncbgpc
    Execute Command On Quagga Telnet Session    show running-config
    Execute Command On Quagga Telnet Session    show bgp neighbors
    Execute Command On Quagga Telnet Session    show ip bgp vrf ${rd}
    Execute Command On Quagga Telnet Session    exit
    Close Connection

Create Quagga Telnet Session
    [Arguments]    ${ip}    ${user}    ${password}
    [Documentation]    Create telnet session for Quagga
    ${conn_id}=    Open_Connection_To_Tools_System    ip_address=${ip}
    Switch Connection    ${conn_id}
    ${output} =    Write    telnet localhost ${user}
    ${output} =    Read Until    Password:
    ${output} =    Write    ${password}
    ${output} =    Read
    ${output} =    Write    terminal length 512
    ${output} =    Read

Execute Command On Quagga Telnet Session
    [Arguments]    ${command}
    [Documentation]    Execute command on Quagga telnet session(session should exist) and returns the output.
    SSHLibrary.Write    ${command}
    ${output} =    SSHLibrary.Read
    Log    ${output}
    [Return]    ${output}

Configure BGP And Add Neighbor On DCGW
    [Arguments]    ${dcgw_ip}    ${as_id}    ${router_id}    ${neighbor_ip}    ${vrf_name}    ${rd}
    ...    ${loopback_ip}
    [Documentation]    Configure BGP and add neighbor on the dcgw
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
    [Arguments]    ${dcgw_ip}    ${loopback_name}    ${loopback_ip}    ${user}=zebra    ${password}=zebra
    [Documentation]    Add loopback interface on DCGW
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
    [Arguments]    ${dcgw_ip}    ${cmd}    ${user}=bgpd    ${password}=sdncbgpc
    [Documentation]    Execute command on quagga and returns the ouput.
    Create Quagga Telnet Session    ${dcgw_ip}    ${user}    ${password}
    ${output} =    Execute Command On Quagga Telnet Session    ${cmd}
    Log    ${output}
    Execute Command On quagga Telnet Session    exit
    [Return]    ${output}

Verify BGP Neighbor Status On Quagga
    [Arguments]    ${dcgw_ip}    ${neighbor_ip}
    [Documentation]    Verify bgp neighbor status on quagga
    ${output} =    Execute Show Command On quagga    ${dcgw_ip}    show bgp neighbors ${neighbor_ip}
    Log    ${output}
    Should Contain    ${output}    BGP state = Established

Verify Routes On Quagga
    [Arguments]    ${dcgw_ip}    ${rd}    ${ip_list}
    [Documentation]    Verify routes on quagga
    ${output} =    Execute Show Command On quagga    ${dcgw_ip}    show ip bgp vrf ${rd}
    Log    ${output}
    : FOR    ${ip}    IN    @{ip_list}
    \    Should Contain    ${output}    ${ip}

Delete BGP Config On Quagga
    [Arguments]    ${dcgw_ip}    ${bgp_id}    ${user}=bgpd    ${password}=sdncbgpc
    [Documentation]    Delete BGP Config on Quagga
    Create Quagga Telnet Session    ${dcgw_ip}    ${user}    ${password}
    Execute Command On Quagga Telnet Session    configure terminal
    Execute Command On Quagga Telnet Session    no router bgp ${bgp_id}
    Execute Command On Quagga Telnet Session    end
    ${output} =    Execute Command On Quagga Telnet Session    show running-config
    Execute Command On Quagga Telnet Session    exit
    [Return]    ${output}

Create BGP Configuration On ODL
    [Arguments]    &{Kwargs}
    [Documentation]    Associate the created L3VPN to a network-id received as dictionary argument
    TemplatedRequests.Post_As_Json_Templated    folder=${VAR_BASE_BGP}/create_bgp    mapping=${Kwargs}    session=session

AddNeighbor To BGP Configuration On ODL
    [Arguments]    &{Kwargs}
    [Documentation]    Associate the created L3VPN to a network-id received as dictionary argument
    TemplatedRequests.Post_As_Json_Templated    folder=${VAR_BASE_BGP}/addNeighbor_bgp    mapping=${Kwargs}    session=session

Get BGP Configuration On ODL
    [Arguments]    ${odl_session}
    [Documentation]    Get bgp configuration
    ${resp} =    RequestsLibrary.Get Request    ${odl_session}    ${CONFIG_API}/ebgp:bgp/
    Log    ${resp.content}
    [Return]    ${resp.content}

Delete BGP Configuration On ODL
    [Arguments]    ${odl_session}
    [Documentation]    Delete BGP
    ${resp} =    RequestsLibrary.Delete Request    ${odl_session}    ${CONFIG_API}/ebgp:bgp/
    Log    ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200
    [Return]    ${resp.content}

Create External Tunnel Endpoint Configuration
    [Arguments]    &{Kwargs}
    [Documentation]    Create Tunnel End point
    TemplatedRequests.Post_As_Json_Templated    folder=${VAR_BASE_BGP}/create_etep    mapping=${Kwargs}    session=session

Delete External Tunnel Endpoint Configuration
    [Arguments]    &{Kwargs}
    [Documentation]    Delete Tunnel End point
    TemplatedRequests.Post_As_Json_Templated    folder=${VAR_BASE_BGP}/delete_etep    mapping=${Kwargs}    session=session

Get External Tunnel Endpoint Configuration
    [Arguments]    ${ip}
    [Documentation]    Get bgp configuration
    ${resp} =    RequestsLibrary.Get Request    session    ${CONFIG_API}/itm:dc-gateway-ip-list/dc-gateway-ip/${ip}/
    Log    ${resp.content}
    [Return]    ${resp.content}

Teardown_Everything
    [Documentation]    Create and Log the diff between expected and actual responses, make sure Python tool was killed.
    ...    Tear down imported Resources.
    KillPythonTool.Search_And_Kill_Remote_Python    'play\.py'
    RequestsLibrary.Delete_All_Sessions
    SSHLibrary.Close_All_Connections

Check_Example_Bgp_Rib_Content
    [Arguments]    ${substr}    ${error_message}=${JSONKEYSTR} not found, but expected.
    [Documentation]    Check the example-bgp-rib content for string
    ${response}=    RequestsLibrary.Get Request    operational    bgp-rib:bgp-rib/rib/example-bgp-rib
    BuiltIn.Log    ${response.status_code}
    BuiltIn.Log    ${response.text}
    BuiltIn.Should_Contain    ${response.text}    ${substr}    ${error_message}    values=False

Check_Example_Bgp_Rib_Does_Not_Contain
    [Arguments]    ${substr}    ${error_message}=${JSONKEYSTR} found, but not expected.
    [Documentation]    Check the example-bgp-rib does not contain the string
    ${response}=    RequestsLibrary.Get Request    operational    bgp-rib:bgp-rib/rib/example-bgp-rib
    BuiltIn.Log    ${response.status_code}
    BuiltIn.Log    ${response.text}
    BuiltIn.Should_Not_Contain    ${response.text}    ${substr}    ${error_message}    values=False

Check_Example_IPv4_Topology_Content
    [Arguments]    ${string_to_check}=${EMPTY}
    [Documentation]    Check the example-ipv4-topology content for string
    ${response}=    RequestsLibrary.Get Request    operational    topology/example-ipv4-topology
    BuiltIn.Log    ${response.status_code}
    BuiltIn.Log    ${response.text}
    BuiltIn.Should_Contain    ${response.text}    ${string_to_check}

Check_Example_IPv4_Topology_Does_Not_Contain
    [Arguments]    ${string_to_check}
    [Documentation]    Check the example-ipv4-topology does not contain the string
    ${response}=    RequestsLibrary.Get Request    operational    topology/example-ipv4-topology
    BuiltIn.Log    ${response.status_code}
    BuiltIn.Log    ${response.text}
    BuiltIn.Should_Not_Contain    ${response.text}    ${string_to_check}

Bmp_Monitor_Precondition
    [Arguments]    ${session}
    [Documentation]    Verify example-bmp-monitor presence in bmp-monitors
    &{mapping}    BuiltIn.Create_Dictionary    TOOL_IP=${TOOLS_SYSTEM_IP}
    BuiltIn.Wait_Until_Keyword_Succeeds    6x    10s    TemplatedRequests.Get_As_Json_Templated    folder=${BGP_BMP_FEAT_DIR}    mapping=${mapping}    verify=True
    ...    session=${session}

Bmp_Monitor_Postcondition
    [Arguments]    ${session}
    [Documentation]    Verifies if example-bmp-monitor data contains one peer.
    &{mapping}    BuiltIn.Create_Dictionary    TOOL_IP=${TOOLS_SYSTEM_IP}
    ${output}    BuiltIn.Wait_Until_Keyword_Succeeds    10x    5s    TemplatedRequests.Get_As_Json_Templated    folder=${BGP_BMP_DIR}    mapping=${mapping}
    ...    session=${session}    verify=True
    BuiltIn.Log    ${output}
