*** Settings ***
Documentation       Library to provide ovsdb access to mininet topologies

Library             SSHLibrary
Library             ${CURDIR}/VsctlListParser.py
Library             Collections


*** Variables ***
${SH_BR_CMD}            ovs-vsctl list Bridge
${SH_CNTL_CMD}          ovs-vsctl list Controller
${SHOW_OVS_VERSION}     sudo ovs-vsctl show | grep version
${GET_LOCAL_IP}         sudo ovs-vsctl list Open_vSwitch | grep local_ip=
${ovs_switch_data}      ${None}
${lprompt}              mininet>
${lcmd_prefix}          sh


*** Keywords ***
Initialize If Shell Used
    [Arguments]    ${prompt}    ${cmd_prefix}
    BuiltIn.Set Suite variable    ${lprompt}    ${prompt}
    BuiltIn.Set Suite variable    ${lcmd_prefix}    ${cmd_prefix}

Get Ovsdb Data
    [Documentation]    Gets ovs data and parse them.
    [Arguments]    ${prompt}=mininet>
    SSHLibrary.Write    ${lcmd_prefix} ${SH_BR_CMD}
    ${brstdout}=    SSHLibrary.Read_Until    ${lprompt}
    Log    ${brstdout}
    SSHLibrary.Write    ${lcmd_prefix} ${SH_CNTL_CMD}
    ${cntlstdout}=    SSHLibrary.Read_Until    ${lprompt}
    Log    ${cntlstdout}
    ${data}    ${bridegs}    ${controllers}=    VsctlListParser.Parse    ${brstdout}    ${cntlstdout}
    BuiltIn.Log    ${data}
    BuiltIn.Set Suite Variable    ${ovs_switch_data}    ${data}
    RETURN    ${data}

Get Controllers Uuid
    [Documentation]    Returns controllers uuid
    [Arguments]    ${switch}    ${controller}    ${update_data}=${False}
    IF    ${update_data}==${True}    Get Ovsdb Data
    ${bridge}=    Collections.Get From Dictionary    ${ovs_switch_data}    ${switch}
    ${cntls}=    Collections.Get From Dictionary    ${bridge}    controller
    ${cntl}=    Collections.Get From Dictionary    ${cntls}    ${controller}
    ${uuid}=    Collections.Get From Dictionary    ${cntl}    _uuid
    RETURN    ${uuid}

Execute OvsVsctl Show Command
    [Documentation]    Executes ovs-vsctl show command and returns stdout, no check nor change is performed
    SSHLibrary.Write    ${lcmd_prefix} ovs-vsctl show
    ${output}=    SSHLibrary.Read_Until    ${lprompt}
    Log    ${output}

Set Bridge Controllers
    [Documentation]    Adds controller to the bridge
    [Arguments]    ${bridge}    ${controllers}    ${ofversion}=13    ${disconnected}=${False}
    ${cmd}=    BuiltIn.Set Variable    ${lcmd_prefix} ovs-vsctl set bridge ${bridge} protocols=OpenFlow${ofversion}
    SSHLibrary.Write    ${cmd}
    ${output}=    SSHLibrary.Read_Until    ${lprompt}
    Log    ${output}
    ${cmd}=    BuiltIn.Set Variable    ${lcmd_prefix} ovs-vsctl set-controller ${bridge}
    FOR    ${cntl}    IN    @{controllers}
        ${cmd}=    BuiltIn.Set Variable If
        ...    ${disconnected}==${False}
        ...    ${cmd} tcp:${cntl}:6653
        ...    ${cmd} tcp:${cntl}:6654
    END
    BuiltIn.Log    ${cmd}
    SSHLibrary.Write    ${cmd}
    ${output}=    SSHLibrary.Read_Until    ${lprompt}
    Log    ${output}

Disconnect Switch From Controller And Verify Disconnected
    [Documentation]    Disconnects the switch from the controller by setting the incorrect port
    [Arguments]    ${switch}    ${controller}    ${update_data}=${False}    ${verify_disconnected}=${True}
    IF    ${update_data}==${True}    Get Ovsdb Data
    ${uuid}=    Get Controllers Uuid    ${switch}    ${controller}
    ${cmd}=    BuiltIn.Set Variable
    ...    ${lcmd_prefix} ovs-vsctl set Controller ${uuid} target="tcp\\:${controller}\\:6654"
    SSHLibrary.Write    ${cmd}
    ${output}=    SSHLibrary.Read_Until    ${lprompt}
    Log    ${output}
    IF    ${verify_disconnected}==${False}    RETURN
    BuiltIn.Wait Until Keyword Succeeds
    ...    5x
    ...    2s
    ...    Should Be Disconnected
    ...    ${switch}
    ...    ${controller}
    ...    update_data=${True}
    [Teardown]    Execute OvsVsctl Show Command

Reconnect Switch To Controller And Verify Connected
    [Documentation]    Reconnects the switch back to the controller by setting the correct port
    [Arguments]    ${switch}    ${controller}    ${update_data}=${False}    ${verify_connected}=${True}
    IF    ${update_data}==${True}    Get Ovsdb Data
    ${uuid}=    Get Controllers Uuid    ${switch}    ${controller}
    ${cmd}=    BuiltIn.Set Variable
    ...    ${lcmd_prefix} ovs-vsctl set Controller ${uuid} target="tcp\\:${controller}\\:6653"
    SSHLibrary.Write    ${cmd}
    ${output}=    SSHLibrary.Read_Until    ${lprompt}
    Log    ${output}
    IF    ${verify_connected}==${False}    RETURN
    BuiltIn.Wait Until Keyword Succeeds
    ...    5x
    ...    2s
    ...    Should Be Connected
    ...    ${switch}
    ...    ${controller}
    ...    update_data=${True}
    [Teardown]    Execute OvsVsctl Show Command

Should Be Connected
    [Documentation]    Check if the switch is connected
    [Arguments]    ${switch}    ${controller}    ${update_data}=${False}
    ${connected}=    OvsManager__Is_Connected    ${switch}    ${controller}    update_data=${update_data}
    BuiltIn.Should Be True    ${connected}

Should Be Disconnected
    [Documentation]    Check if the switch is disconnected
    [Arguments]    ${switch}    ${controller}    ${update_data}=${False}
    ${connected}=    OvsManager__Is_Connected    ${switch}    ${controller}    update_data=${update_data}
    BuiltIn.Should Be Equal    ${connected}    ${False}

OvsManager__Is_Connected
    [Documentation]    Return is_connected boolean value
    [Arguments]    ${switch}    ${controller}    ${update_data}=${False}
    IF    ${update_data}==${True}    Get Ovsdb Data
    ${bridge}=    Collections.Get From Dictionary    ${ovs_switch_data}    ${switch}
    ${cntls}=    Collections.Get From Dictionary    ${bridge}    controller
    ${cntl}=    Collections.Get From Dictionary    ${cntls}    ${controller}
    ${connected}=    Collections.Get From Dictionary    ${cntl}    is_connected
    RETURN    ${connected}
    [Teardown]    Execute OvsVsctl Show Command

Should Be Master
    [Documentation]    Verifies the master role
    [Arguments]    ${switch}    ${controller}    ${update_data}=${False}
    ${role}=    Get Node Role    ${switch}    ${controller}    update_data=${update_data}
    BuiltIn.Should Be Equal    ${role}    master

Should Be Slave
    [Documentation]    Verifies the slave role
    [Arguments]    ${switch}    ${controller}    ${update_data}=${False}
    ${role}=    Get Node Role    ${switch}    ${controller}    update_data=${update_data}
    BuiltIn.Should Be Equal    ${role}    slave

Get Node Role
    [Documentation]    Returns the controllers role
    [Arguments]    ${switch}    ${controller}    ${update_data}=${False}
    IF    ${update_data}==${True}    Get Ovsdb Data
    ${bridge}=    Collections.Get From Dictionary    ${ovs_switch_data}    ${switch}
    ${cntls}=    Collections.Get From Dictionary    ${bridge}    controller
    ${cntl}=    Collections.Get From Dictionary    ${cntls}    ${controller}
    ${role}=    Collections.Get From Dictionary    ${cntl}    role
    RETURN    ${role}

Get Master Node
    [Documentation]    Gets controller which is a master
    [Arguments]    ${switch}    ${update_data}=${False}
    ${master}=    BuiltIn.Set Variable    ${None}
    IF    ${update_data}==${True}    Get Ovsdb Data
    ${bridge}=    Collections.Get From Dictionary    ${ovs_switch_data}    ${switch}
    ${cntls_dict}=    Collections.Get From Dictionary    ${bridge}    controller
    ${cntls_items}=    Collections.Get Dictionary Items    ${cntls_dict}
    FOR    ${key}    ${value}    IN    @{cntls_items}
        Log    ${key} : ${value}
        ${role}=    Collections.Get From Dictionary    ${value}    role
        IF    "${role}"=="master"
            BuiltIn.Should Be Equal    ${master}    ${None}
        END
        ${master}=    BuiltIn.Set Variable If    "${role}"=="master"    ${key}    ${master}
    END
    BuiltIn.Should Not Be Equal    ${master}    ${None}
    RETURN    ${master}

Get Slave Nodes
    [Documentation]    Returns a list of ips of slave nodes for particular switch
    [Arguments]    ${switch}    ${update_data}=${False}
    ${slaves}=    BuiltIn.Create List
    IF    ${update_data}==${True}    Get Ovsdb Data
    ${bridge}=    Collections.Get From Dictionary    ${ovs_switch_data}    ${switch}
    ${cntls_dict}=    Collections.Get From Dictionary    ${bridge}    controller
    ${cntls_items}=    Collections.Get Dictionary Items    ${cntls_dict}
    FOR    ${key}    ${value}    IN    @{cntls_items}
        Log    ${key} : ${value}
        ${role}=    Collections.Get From Dictionary    ${value}    role
        IF    "${role}"=="slave"
            Collections.Append To List    ${slaves}    ${key}
        END
    END
    RETURN    ${slaves}

Setup Clustered Controller For Switches
    [Documentation]    The idea of this keyword is to setup clustered controller and to be more or less sure that the role is filled correctly. The problem is when
    ...    more controllers are being set up at once, the role shown in Controller ovsdb table is not the same as we can see from wireshark traces.
    ...    Now we set disconnected controllers and we will connect them expecting that the first connected controller will be master.
    [Arguments]    ${switches}    ${controller_ips}    ${verify_connected}=${False}
    FOR    ${switch_name}    IN    @{switches}
        Set Bridge Controllers    ${switch_name}    ${controller_ips}    disconnected=${True}
        # now we need to enable one node which will be master
    END
    OvsManager.Get Ovsdb Data
    FOR    ${switch_name}    IN    @{switches}
        ${own}=    Collections.Get From List    ${controller_ips}    0
        Reconnect Switch To Controller And Verify Connected    ${switch_name}    ${own}    verify_connected=${False}
        # now we need to wait till master controllers are connected
    END
    BuiltIn.Wait Until Keyword Succeeds
    ...    5x
    ...    2s
    ...    OvsManager__Verify_Masters_Connected
    ...    ${switches}
    ...    update_data=${True}
    # now we can enable slaves
    OvsManager__Enable_Slaves    ${switches}    verify_connected=${verify_connected}

OvsManager__Verify_Masters_Connected
    [Documentation]    Private keyword, the existence of master means it is verified
    [Arguments]    ${switches}    ${update_data}=${False}
    IF    ${update_data}==${True}    Get Ovsdb Data
    FOR    ${switch_name}    IN    @{switches}
        Get Master Node    ${switch_name}
    END

OvsManager__Enable_Slaves
    [Documentation]    This is a private keyword to enable diconnected controllers
    [Arguments]    ${switches}    ${update_data}=${False}    ${verify_connected}=${False}
    IF    ${update_data}==${True}    Get Ovsdb Data
    FOR    ${switch_name}    IN    @{switches}
        OvsManager__Enable_Slaves_For_Switch    ${switch_name}    verify_connected=${verify_connected}
    END

OvsManager__Enable_Slaves_For_Switch
    [Documentation]    This is a private keyword, verification is not reliable yet, enables disconnected controllers
    [Arguments]    ${switch}    ${update_data}=${False}    ${verify_connected}=${False}
    IF    ${update_data}==${True}    Get Ovsdb Data
    ${bridge}=    Collections.Get From Dictionary    ${ovs_switch_data}    ${switch}
    ${cntls_dict}=    Collections.Get From Dictionary    ${bridge}    controller
    ${cntls_items}=    Collections.Get Dictionary Items    ${cntls_dict}
    FOR    ${cntl_id}    ${cntl_value}    IN    @{cntls_items}
        Log    ${cntl_id} : ${cntl_value}
        ${role}=    Collections.Get From Dictionary    ${cntl_value}    role
        ${connected}=    Collections.Get From Dictionary    ${cntl_value}    is_connected
        IF    ${connected}==${False}
            Reconnect Switch To Controller And Verify Connected
            ...    ${switch}
            ...    ${cntl_id}
            ...    verify_connected=${verify_connected}
        END
    END

Get Dump Flows Count
    [Documentation]    Count the number of dump flows for a given table id
    ...    and grep with port_mac if provided
    [Arguments]    ${conn_id}    ${acl_sr_table_id}    ${port_mac}=""
    ${cmd}=    BuiltIn.Set Variable
    ...    sudo ovs-ofctl dump-flows br-int -OOpenFlow13 | grep table=${acl_sr_table_id} | grep ${port_mac} | wc -l
    SSHLibrary.Switch Connection    ${conn_id}
    ${output}=    Utils.Write Commands Until Expected Prompt    ${cmd}    ${DEFAULT_LINUX_PROMPT_STRICT}
    @{list}=    String.Split String    ${output}
    RETURN    ${list[0]}

Get Packet Count From Table
    [Documentation]    Return packet count for the specific table no.
    [Arguments]    ${system_ip}    ${br_name}    ${table_no}    ${addtioanal_args}=${EMPTY}
    ${flow_output}=    Utils.Run Command On Remote System
    ...    ${system_ip}
    ...    sudo ovs-ofctl dump-flows -O Openflow13 ${br_name} | grep ${table_no} ${addtioanal_args}
    @{output}=    String.Split String    ${flow_output}    \r\n
    ${flow}=    Collections.Get From List    ${output}    0
    ${packetcountlist}=    String.Get Regexp Matches    ${flow}    n_packets=([0-9]+),    1
    ${packetcount}=    Collections.Get From List    ${packetcountlist}    0
    RETURN    ${packetcount}

Get Packet Count In Table For IP
    [Documentation]    Capture packetcount for IP in Table
    [Arguments]    ${os_compute_ip}    ${table_no}    ${ip_address}    ${additional_args}=${EMPTY}
    ${cmd}=    BuiltIn.Set Variable
    ...    sudo ovs-ofctl dump-flows br-int -OOpenFlow13 | grep table=${table_no} | grep ${ip_address} ${additional_args}
    ${output}=    Utils.Run Command On Remote System And Log    ${os_compute_ip}    ${cmd}
    @{output_list}=    String.Split String    ${output}    \r\n
    ${flow}=    Collections.Get From List    ${output_list}    0
    ${packetcount_list}=    String.Get Regexp Matches    ${flow}    n_packets=([0-9]+)    1
    ${count}=    Collections.Get From List    ${packetcount_list}    0
    RETURN    ${count}

Verify Ovs Version Greater Than Or Equal To
    [Documentation]    Get ovs version and verify greater than required version
    [Arguments]    ${ovs_version}    @{nodes}
    FOR    ${ip}    IN    @{nodes}
        ${output}=    Utils.Run Command On Remote System    ${ip}    ${SHOW_OVS_VERSION}
        ${version}=    String.Get Regexp Matches    ${output}    \[0-9].\[0-9]
        ${result}=    BuiltIn.Convert To Number    ${version[0]}
        BuiltIn.Should Be True    ${result} >= ${ovs_version}
    END

Get OVS Local Ip
    [Documentation]    Get local ip of compute node ovsdb
    [Arguments]    ${ip}
    ${cmd_output}=    Utils.Run Command On Remote System    ${ip}    ${GET_LOCAL_IP}
    ${localip}=    String.Get Regexp Matches    ${cmd_output}    (\[0-9]+\.\[0-9]+\.\[0-9]+\.\[0-9]+)
    RETURN    ${localip}[0]
