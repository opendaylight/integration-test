*** Settings ***
Documentation     This library contains keywords related to the BGP functionality.
Library           SSHLibrary
Resource          Utils.robot
Resource          ../variables/Variables.robot

*** Variables ***
${VAR_BASE_BGP}    ${CURDIR}/../variables/bgpfunctional

*** Keywords ***
Get Quagga Conection On DCGW
    [Arguments]     ${DCGW_SYSTEM_IP}
    [Documentation]    Login to the DCGW
    ${dcgw_conn_id}=    SSHLibrary.Open Connection    ${DCGW_SYSTEM_IP}    prompt=${DEFAULT_LINUX_PROMPT}
    Log    ${dcgw_conn_id}
    Utils.Flexible SSH Login    ${DEFAULT_USER}    ${EMPTY}
    SSHLibrary.Set Client Configuration    timeout=${default_devstack_prompt_timeout}
    [Return]    ${dcgw_conn_id}

Start Quagga Processes on ODL
    [Arguments]     ${ODL_SYSTEM_IP}
    [Documentation]    To start the zrpcd, bgpd,and zebra processes on ODL VM
    ${conn_id}=    SSHLibrary.Open Connection    ${ODL_SYSTEM_IP}    prompt=${DEFAULT_LINUX_PROMPT}
    Switch Connection    ${conn_id}
    ${output} =    Write Commands Until Expected Prompt    cd /opt/quagga/etc/    ]>
    Log     ${output}
    ${output} =    Write Commands Until Expected Prompt    sudo cp zebra.conf.sample zebra.conf     ]>
    Log    ${output}
    ${output} =    Write Commands Until Expected Prompt    sudo /opt/quagga/etc/init.d/zrpcd start    ]>
    Log    ${output}
    ${output} =    Write Commands Until Expected Prompt    ps -ef | grep zrpcd    ]>
    Log    ${output}
    ${output} =    Write Commands Until Expected Prompt    ps -ef | grep bgpd    ]>
    Log    ${output}
    ${output} =    Write Commands Until Expected Prompt    ps -ef | grep zebra    ]>
    Log    ${output}
    ${output} =    Write Commands Until Expected Prompt    netstat -nap | grep 7644    ]>
    Log    ${output}
    Close Connection

Start Quagga Processes On DCGW
    [Arguments]     ${dcgw_conn_id}
    [Documentation]    To start the zrpcd, bgpd,and zebra processes on DCGW
    Switch Connection    ${dcgw_conn_id}
    ${output} =    Write Commands Until Expected Prompt    cd /opt/quagga/etc/    ]>
    Log    ${output}
    ${output} =    Write Commands Until Expected Prompt    sudo cp zebra.conf.sample zebra.conf     ]>
    Log    ${output}
    ${output} =    Write Commands Until Expected Prompt    sudo /opt/quagga/etc/init.d/zrpcd start    ]>
    Log    ${output}
    ${output} =    Write Commands Until Expected Prompt    ps -ef | grep zrpcd    ]>
    Log    ${output}
    ${output} =    Write Commands Until Expected Prompt    cd /opt/quagga/sbin/    ]>
    Log    ${output}
    ${output} =    Write    sudo ./bgpd &
    ${output} =    Read Until    pid
    Log    ${output}
    ${output} =    Write    sudo ./zebra &
    ${output} =    Read
    Log    ${output}
    ${output} =    Write Commands Until Expected Prompt    ps -ef | grep bgpd    ]>
    Log    ${output}
    ${output} =    Write Commands Until Expected Prompt    ps -ef | grep zebra    ]>
    Log    ${output}
    ${output} =    Write Commands Until Expected Prompt    netstat -nap | grep 7644    ]>
    Log    ${output}

Get Quagga configuration from ODL
    [Arguments]    ${odl_ip}    ${rd}
    [Documentation]    Get quagga config from ODL
    ${conn_id}=    SSHLibrary.Open Connection    ${odl_ip}    prompt=${DEFAULT_LINUX_PROMPT}
    Log    ${conn_id}
    Utils.Flexible SSH Login    ${DEFAULT_USER}    ${EMPTY}
    SSHLibrary.Set Client Configuration    timeout=${default_devstack_prompt_timeout}
    Create Quagga Telnet Session    ${conn_id}    bgpd    sdncbgpc
    Execute Command On Quagga Telnet Session    show running-config 
    Execute Command On Quagga Telnet Session    show bgp neighbors
    Execute Command On Quagga Telnet Session    show ip bgp vrf ${rd}
    Execute Command On Quagga Telnet Session    exit
    Close Connection

Create Quagga Telnet Session
    [Arguments]    ${dcgw_conn_id}     ${user}    ${password}
    [Documentation]    Execute cmd on DCGW and returns the ouput.
    Switch Connection    ${dcgw_conn_id}
    ${output} =    Write    telnet localhost ${user}
    Log    ${output}
    ${output} =    Read Until    Password:
    Log    ${output}
    ${output} =    Write    ${password}
    Log    ${output}
    ${output} =    Read
    Log    ${output}
    ${output} =    Write    terminal length 512
    ${output} =    Read
    Log    ${output}
	
Execute Command On Quagga Telnet Session
    [Arguments]    ${command}
    [Documentation]    Execute command on Quagga telnet session(session should exist) and returns the output.
    SSHLibrary.Write    ${command}
    ${output} =    SSHLibrary.Read
    Log    ${output}
    [Return]    ${output}

Create BGP and Add Neighbor On quagga
    [Arguments]      ${dcgw_conn_id}    ${as_id}     ${router_id}    ${neighbor_ip}     ${vrf_name}}    ${rd}    ${loopback_ip}
    [Documentation]    Execute cmd on quagga and returns the ouput.
    Create Quagga Telnet Session      ${dcgw_conn_id}     bgpd     sdncbgpc
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
                                                network ${loopback_ip}/32 rd ${rd} tag ${as_id}
    Execute Command On Quagga Telnet Session    neighbor ${neighbor_ip} activate
    Execute Command On Quagga Telnet Session    end
    ${output} =    Execute Command On Quagga Telnet Session    show running-config
    Log    ${output}
    Execute Command On Quagga Telnet Session    exit

Add Loopback Interface On Quagga
    [Arguments]    ${dcgw_conn_id}    ${loopback_name}    ${loopback_ip}    ${user}=zebra    ${password}=zebra
    [Documentation]    Execute cmd on Quagga and returns the ouput.
    Create Quagga Telnet Session      ${dcgw_conn_id}     ${user}     ${password}
    Execute Command On Quagga Telnet Session    enable
    Execute Command On Quagga Telnet Session    ${password}
    Execute Command On Quagga Telnet Session    configure terminal
    Execute Command On Quagga Telnet Session    interface ${loopback_name}
    Execute Command On Quagga Telnet Session    ip address ${loopback_ip}
    Execute Command On Quagga Telnet Session    exit
    Execute Command On Quagga Telnet Session    end
    ${output} =     Execute Command On Quagga Telnet Session    show running-config
    Log    ${output}
    Execute Command On Quagga Telnet Session    exit

Execute Show Command On Quagga
    [Arguments]    ${dcgw_conn_id}     ${cmd}    ${user}=bgpd    ${password}=sdncbgpc
    [Documentation]    Execute command on quagga and returns the ouput.
    Create Quagga Telnet Session      ${dcgw_conn_id}    ${user}     ${password}
    ${output} =    Execute Command On Quagga Telnet Session    ${cmd}
    Log    ${output}
    Execute Command On quagga Telnet Session    exit
    [Return]    ${output}
	
Verify Routes On Quagga
    [Arguments]    ${dcgw_conn_id}    ${rd}     ${ip_list}
    [Documentation]    Verify routes on quagga 
    ${output} =    Execute Show Command On quagga    ${dcgw_conn_id}    show ip bgp vrf ${rd}    
    Log    ${output}
    : FOR    ${ip}    IN    @{ip_list}
    \    Should Contain    ${output}    ${ip}

Delete BGP Config On Quagga
    [Arguments]    ${dcgw_conn_id}    ${bgp_id}     ${user}=bgpd    ${password}=sdncbgpc
    [Documentation]    Delete BGP Config on Quagga 
    Quagga Telnet Session      ${dcgw_conn_id}     ${user}     ${password} 
    Execute Command On Quagga Telnet Session      configure terminal
    Execute Command On Quagga Telnet Session      no router bgp ${bgp_id}
    Execute Command On Quagga Telnet Session      end
    ${output} =    Execute Command On Quagga Telnet Session    show running-config
    Log    ${output}
    Execute Command On Quagga Telnet Session      exit

Check BGP Neighborship State Is Established
    [Documentation]     Checks whether the neighborship state is established
    ${output} =     Execute Command On DCGW      show bgp neighbors ${ODL_SYSTEM_IP}
    Log    ${output}
    Should Contain    ${output}    BGP state = Established

Create BGP Configuration On ODL
    [Arguments]    &{Kwargs}
    [Documentation]    Associate the created L3VPN to a network-id received as dictionary argument
    TemplatedRequests.Post_As_Json_Templated    folder=${VAR_BASE_BGP}/create_bgp    mapping=${Kwargs}    session=session

AddNeighbor To BGP Configuration On ODL
    [Arguments]    &{Kwargs}
    [Documentation]    Associate the created L3VPN to a network-id received as dictionary argument
    TemplatedRequests.Post_As_Json_Templated    folder=${VAR_BASE_BGP}/addNeighbor_bgp    mapping=${Kwargs}    session=session

AddVRF To BGP Configuration On ODL
    [Arguments]    &{Kwargs}
    [Documentation]    Associate the created L3VPN to a network-id received as dictionary argument
    TemplatedRequests.Post_As_Json_Templated    folder=${VAR_BASE_BGP}/addVRF_bgp    mapping=${Kwargs}    session=session

Get BGP Configuration On ODL
    [Documentation]    Get bgp configuration
    ${resp} =    RequestsLibrary.Get Request    session    ${CONFIG_API}/ebgp:bgp/
    Log    ${resp.content}
    [Return]    ${resp.content}

Delete BGP Configuration On ODL
    [Documentation]    Delete BGP
    ${resp} =    RequestsLibrary.Delete Request    session    ${CONFIG_API}/ebgp:bgp/
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
