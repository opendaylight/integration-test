*** Settings ***
Documentation       Mininet library. This library is useful for tests using mininet tool to simulate devices.

Library             SSHLibrary
Resource            SSHKeywords.robot
Resource            Utils.robot
Resource            OVSDB.robot
Resource            ClusterManagement.robot
Variables           ../variables/Variables.py


*** Variables ***
${switch_private_key}       switch.key
${switch_certificate}       switch.crt
${controller_ca_list}       cachain.crt
${topology_file}            create_fullymesh.py
${topology_file_path}       MininetTopo/${topology_file}


*** Keywords ***
Start Mininet Single Controller
    [Documentation]    Start Mininet with custom topology and connect to controller.
    [Arguments]    ${mininet}=${TOOLS_SYSTEM_IP}    ${controller}=${ODL_SYSTEM_IP}    ${options}=--topo tree,1    ${custom}=${EMPTY}    ${ofversion}=13    ${ofport}=${ODL_OF_PORT}
    ...    ${timeout}=${DEFAULT_TIMEOUT}
    Log    Clear any existing mininet
    Utils.Clean Mininet System    ${mininet}
    ${mininet_conn_id}=    SSHKeywords.Open_Connection_To_Tools_System    ip_address=${mininet}    timeout=${timeout}
    Set Suite Variable    ${mininet_conn_id}
    IF    '${custom}' != '${EMPTY}'    Put File    ${custom}
    Log    Start mininet ${options} to ${controller}
    SSHLibrary.Write
    ...    sudo mn --controller 'remote,ip=${controller},port=${ofport}' ${options} --switch ovsk,protocols=OpenFlow${ofversion}
    SSHLibrary.Read Until    mininet>
    Log    Check OVS configuratiom
    SSHLibrary.Write    sh ovs-vsctl show
    SSHLibrary.Read Until    mininet>
    RETURN    ${mininet_conn_id}

Start Mininet Multiple Controllers
    [Documentation]    Start Mininet with custom topology and connect to list of controllers in ${controller_index_list} or all if no list is provided.
    [Arguments]    ${mininet}=${TOOLS_SYSTEM_IP}    ${controller_index_list}=${EMPTY}    ${options}=--topo tree,1    ${custom}=${EMPTY}    ${ofversion}=13    ${ofport}=${ODL_OF_PORT}
    ...    ${protocol}=tcp    ${timeout}=${DEFAULT_TIMEOUT}
    ${index_list}=    ClusterManagement.List Indices Or All    given_list=${controller_index_list}
    Log    Clear any existing mininet
    Utils.Clean Mininet System    ${mininet}
    ${mininet_conn_id}=    SSHKeywords.Open_Connection_To_Tools_System    ip_address=${mininet}    timeout=${timeout}
    Set Suite Variable    ${mininet_conn_id}
    IF    '${custom}' != '${EMPTY}'    Put File    ${custom}
    IF    '${protocol}' == 'ssl'    Install Certificates In Mininet
    Log    Start mininet ${options}
    SSHLibrary.Write    sudo mn ${options}
    SSHLibrary.Read Until    mininet>
    Log    Create controller configuration
    ${controller_opt}=    Set Variable
    FOR    ${index}    IN    @{index_list}
        ${controller_opt}=    Catenate    ${controller_opt}    ${SPACE}${protocol}:${ODL_SYSTEM_${index}_IP}:${ofport}
        Log    ${controller_opt}
    END
    Log    Open extra SSH connection to configure the OVS bridges
    SSHKeywords.Open_Connection_To_Tools_System    ip_address=${mininet}    timeout=${timeout}
    ${num_bridges}=    SSHLibrary.Execute Command    sudo ovs-vsctl show | grep Bridge | wc -l
    ${num_bridges}=    Convert To Integer    ${num_bridges}
    ${bridges}=    Create List
    FOR    ${i}    IN RANGE    1    ${num_bridges+1}
        ${bridge}=    SSHLibrary.Execute Command
        ...    sudo ovs-vsctl show | grep Bridge | cut -c 12- | sort | head -${i} | tail -1
        SSHLibrary.Execute Command
        ...    sudo ovs-vsctl del-controller ${bridge} && sudo ovs-vsctl set bridge ${bridge} protocols=OpenFlow${ofversion}
        Collections.Append To List    ${bridges}    ${bridge}
    END
    Log    Configure OVS controllers ${controller_opt} in all bridges
    FOR    ${bridge}    IN    @{bridges}
        SSHLibrary.Execute Command    sudo ovs-vsctl set-controller ${bridge} ${controller_opt}
    END
    Log    Check OVS configuratiom
    ${output}=    SSHLibrary.Execute Command    sudo ovs-vsctl show
    Log    ${output}
    SSHLibrary.Close Connection
    RETURN    ${mininet_conn_id}

Start Mininet Multiple Hosts
    [Documentation]    Start mininet 1 switch with ${hosts} hosts attached.
    [Arguments]    ${hosts}    ${mininet}=${TOOLS_SYSTEM_IP}    ${controller}=${ODL_SYSTEM_IP}    ${ofversion}=13    ${ofport}=${ODL_OF_PORT}    ${mininet_timeout}=${DEFAULT_TIMEOUT}
    Log    Start Mininet Linear
    MininetKeywords.StartMininet Single Controller
    ...    options=--topo single,${hosts} --mac
    ...    ofversion=${ofversion}
    ...    ofport=${ofport}
    ...    timeout=${mininet_timeout}

Start Mininet Linear
    [Documentation]    Start mininet linear topology with ${switches} nodes.
    [Arguments]    ${switches}    ${mininet}=${TOOLS_SYSTEM_IP}    ${controller}=${ODL_SYSTEM_IP}    ${ofversion}=13    ${ofport}=${ODL_OF_PORT}    ${mininet_timeout}=${DEFAULT_TIMEOUT}
    Log    Start Mininet Linear
    MininetKeywords.StartMininet Single Controller
    ...    options=--topo linear,${switches}
    ...    ofversion=${ofversion}
    ...    ofport=${ofport}
    ...    timeout=${mininet_timeout}

Start Mininet Full Mesh
    [Documentation]    Start a custom mininet topology.
    [Arguments]    ${switches}    ${mininet}=${TOOLS_SYSTEM_IP}    ${controller}=${ODL_SYSTEM_IP}    ${ofversion}=13    ${ofport}=${ODL_OF_PORT}    ${hosts}=0
    ...    ${mininet_timeout}=${DEFAULT_TIMEOUT}
    ${mininet_conn_id}=    SSHLibrary.Open Connection
    ...    ${mininet}
    ...    prompt=${TOOLS_SYSTEM_PROMPT}
    ...    timeout=${mininet_timeout}
    Set Suite Variable    ${mininet_conn_id}
    SSHKeywords.Flexible_Mininet_Login
    Log    Copying ${topology_file_path} file to Mininet VM and Creating Full Mesh topology
    SSHLibrary.Put File    ${CURDIR}/${topology_file_path}
    SSHLibrary.Write    python ${topology_file} ${switches} ${hosts} 00:00:00:00:00:00 10.0.0.0
    SSHLibrary.Read Until    ${TOOLS_SYSTEM_PROMPT}
    Log    Start Mininet Full Mesh
    SSHLibrary.Write
    ...    sudo mn --controller=remote,ip=${controller},port=${ofport} --custom switch.py --topo demotopo --switch ovsk,protocols=OpenFlow${ofversion}
    SSHLibrary.Read Until    mininet>
    Log    Check OVS configuratiom
    SSHLibrary.Write    sh ovs-vsctl show
    ${output}=    Read Until    mininet>
    # Ovsdb connection is sometimes lost after mininet is started. Checking if the connection is alive before proceeding.
    Should Not Contain    ${output}    database connection failed

Send Mininet Command
    [Documentation]    Sends Command ${cmd} to Mininet session ${mininet_conn} and returns read buffer response.
    [Arguments]    ${mininet_conn}=${EMPTY}    ${cmd}=help
    IF    """${mininet_conn}""" != ""
        SSHLibrary.Switch Connection    ${mininet_conn}
    END
    SSHLibrary.Write    ${cmd}
    ${output}=    SSHLibrary.Read Until    mininet>
    RETURN    ${output}

Send Mininet Command Multiple Sessions
    [Documentation]    Sends Command ${cmd} to Mininet sessions in ${mininet_conn_list} and returns list of read buffer responses.
    [Arguments]    ${mininet_conn_list}    ${cmd}=help
    ${output_list}=    Create List
    FOR    ${mininet_conn}    IN    @{mininet_conn_list}
        ${output}=    Utils.Send Mininet Command    ${mininet_conn}    ${cmd}
        Collections.Append To List    ${output_list}    ${output}
    END
    RETURN    ${output_list}

Stop Mininet And Exit
    [Documentation]    Stops Mininet and exits session ${mininet_conn}
    [Arguments]    ${mininet_conn}=${EMPTY}
    IF    """${mininet_conn}""" != ""
        SSHLibrary.Switch Connection    ${mininet_conn}
    END
    SSHLibrary.Write    exit
    SSHLibrary.Read Until    ${TOOLS_SYSTEM_PROMPT}
    SSHLibrary.Close Connection

Stop Mininet And Exit Multiple Sessions
    [Documentation]    Stops Mininet and exits sessions in ${mininet_conn_list}.
    [Arguments]    ${mininet_conn_list}
    FOR    ${mininet_conn}    IN    @{mininet_conn_list}
        MininetKeywords.Stop Mininet And Exit    ${mininet_conn}
    END

Disconnect Cluster Mininet
    [Documentation]    Break and restore controller to mininet connection via iptables.
    [Arguments]    ${action}=break    ${member_index_list}=${EMPTY}
    ${index_list}=    ClusterManagement.List_Indices_Or_All    given_list=${member_index_list}
    FOR    ${index}    IN    @{index_list}
        ${rule}=    BuiltIn.Set Variable
        ...    OUTPUT -p all --source ${ODL_SYSTEM_${index}_IP} --destination ${TOOLS_SYSTEM_IP} -j DROP
        ${command}=    BuiltIn.Set Variable If
        ...    '${action}'=='restore'
        ...    sudo /sbin/iptables -D ${rule}
        ...    sudo /sbin/iptables -I ${rule}
        Log To Console    ${ODL_SYSTEM_${index}_IP}
        Utils.Run Command On Controller    ${ODL_SYSTEM_${index}_IP}    cmd=${command}
        ${command}=    BuiltIn.Set Variable    sudo /sbin/iptables -L -n
        ${output}=    Utils.Run Command On Controller    cmd=${command}
        BuiltIn.Log    ${output}
    END

Verify Aggregate Flow From Mininet Session
    [Documentation]    Verify flow count per switch
    [Arguments]    ${mininet_conn}=${EMPTY}    ${flow_count}=0    ${time_out}=0s
    Wait Until Keyword Succeeds
    ...    ${time_out}
    ...    2s
    ...    MininetKeywords.Check Flows In Mininet
    ...    ${mininet_conn}
    ...    ${flow_count}

Check Flows In Mininet
    [Documentation]    Sync with mininet to match exact number of flows
    [Arguments]    ${mininet_conn}=${EMPTY}    ${flow_count}=0
    IF    """${mininet_conn}""" != ""
        SSHLibrary.Switch Connection    ${mininet_conn}
    END
    ${cmd}=    Set Variable    dpctl dump-aggregate -O OpenFlow13
    ${output}=    MininetKeywords.Send Mininet Command    ${mininet_conn}    ${cmd}
    ${flows}=    String.Get RegExp Matches    ${output}    (?<=flow_count\=).*?(?=\r)
    ${total_flows}=    BuiltIn.Evaluate    sum(map(int, ${flows}))
    Should Be Equal As Numbers    ${total_flows}    ${flow_count}

Verify Mininet Ping
    [Documentation]    Send ping from mininet and verify connectivity.
    [Arguments]    ${host1}    ${host2}
    SSHLibrary.Write    ${host1} ping -w 3 ${host2}
    ${result}=    SSHLibrary.Read Until    mininet>
    Should Contain    ${result}    64 bytes

Verify Mininet No Ping
    [Documentation]    Send ping from mininet and verify no conectivity.
    [Arguments]    ${host1}    ${host2}
    SSHLibrary.Write    ${host1} ping -w 3 ${host2}
    ${result}=    SSHLibrary.Read Until    mininet>
    Should Contain    ${result}    100% packet loss

Ping All Hosts
    [Documentation]    Do one round of ping from one host to all other hosts in mininet.
    ...    Note that a single ping failure will exit the loop and return a non zero value.
    [Arguments]    @{host_list}
    ${source}=    Get From List    ${host_list}    ${0}
    FOR    ${h}    IN    @{host_list}
        ${status}=    Ping Two Hosts    ${source}    ${h}    1
        IF    ${status}!=${0}            BREAK
    END
    RETURN    ${status}

Ping Two Hosts
    [Documentation]    Ping between mininet hosts. Must be used only after a mininet session is in place.
    ...    Returns non zero value if there is 100% packet loss.
    [Arguments]    ${host1}    ${host2}    ${pingcount}=2
    SSHLibrary.Write    ${host1} ping -c ${pingcount} ${host2}
    ${out}=    SSHLibrary.Read Until    mininet>
    ${ret}=    String.Get Lines Matching Regexp    ${out}    .*100% packet loss.*
    ${len}=    Get Length    ${ret}
    RETURN    ${len}

Get Mininet Hosts
    [Documentation]    Get all the hosts from mininet
    ${host_list}=    Create List
    SSHLibrary.Write    nodes
    ${out}=    SSHLibrary.Read Until    mininet>
    @{words}=    String.Split String    ${out}    ${SPACE}
    FOR    ${item}    IN    @{words}
        ${h}=    String.Get Lines Matching Regexp    ${item}    h[0-9]*
        IF    '${h}' != '${EMPTY}'
            Collections.Append To List    ${host_list}    ${h}
        END
    END
    RETURN    ${host_list}

Install Certificates In Mininet
    [Documentation]    Copy and install certificates in simulator.
    Comment    Copy Certificates
    SSHLibrary.Put File    ${CURDIR}/tls/${switch_private_key}    .
    SSHLibrary.Put File    ${CURDIR}/tls/${switch_certificate}    .
    SSHLibrary.Put File    ${CURDIR}/tls/${controller_ca_list}    .
    Comment    Install Certificates
    SSHLibrary.Execute Command
    ...    sudo mv ${switch_private_key} /etc/openvswitch && sudo mv ${switch_certificate} /etc/openvswitch && sudo mv ${controller_ca_list} /etc/openvswitch
    SSHLibrary.Execute Command
    ...    sudo ovs-vsctl set-ssl /etc/openvswitch/${switch_private_key} /etc/openvswitch/${switch_certificate} /etc/openvswitch/${controller_ca_list}
    ${std_out}=    SSHLibrary.Execute Command    sudo ovs-vsctl get-ssl
    Log    ${std_out}
