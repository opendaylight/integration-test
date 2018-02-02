*** Settings ***
Documentation     Mininet library. This library is useful for tests using mininet tool to simulate devices.
Library           SSHLibrary
Resource          SSHKeywords.robot
Resource          Utils.robot
Resource          OVSDB.robot
Resource          ClusterManagement.robot
Variables         ../variables/Variables.py

*** Variables ***
${topology_file}    create_fullymesh.py
${topology_file_path}    MininetTopo/${topology_file}

*** Keywords ***
Start Mininet Single Controller
    [Arguments]    ${mininet}=${TOOLS_SYSTEM_IP}    ${controller}=${ODL_SYSTEM_IP}    ${options}=--topo tree,1    ${custom}=${EMPTY}    ${ofport}=${ODL_OF_PORT}    ${timeout}=${DEFAULT_TIMEOUT}
    [Documentation]    Start Mininet with custom topology and connect to controller.
    Log    Clear any existing mininet
    Utils.Clean Mininet System    ${mininet}
    ${mininet_conn_id}=    SSHLibrary.Open Connection    ${mininet}    prompt=${TOOLS_SYSTEM_PROMPT}    timeout=${timeout}
    Set Suite Variable    ${mininet_conn_id}
    SSHKeywords.Flexible Mininet Login
    Run Keyword If    '${custom}' != '${EMPTY}'    Put File    ${custom}
    Log    Start mininet ${options} to ${controller}
    SSHLibrary.Write    sudo mn --switch ovsk,protocols=OpenFlow13 --controller 'remote,ip=${controller},port=${ofport}' ${options}
    SSHLibrary.Read Until    mininet>
    Log    Check OVS configuratiom
    SSHLibrary.Write    sh ovs-vsctl show
    SSHLibrary.Read Until    mininet>
    [Return]    ${mininet_conn_id}

Start Mininet Multiple Controllers
    [Arguments]    ${mininet}    ${controller_index_list}=${EMPTY}    ${options}=--topo tree,1    ${custom}=${EMPTY}    ${ofport}=${ODL_OF_PORT}    ${timeout}=${DEFAULT_TIMEOUT}
    [Documentation]    Start Mininet with custom topology and connect to list of controllers in ${controller_index_list} or all if no list is provided.
    ${index_list} =    ClusterManagement.List Indices Or All    given_list=${controller_index_list}
    Log    Clear any existing mininet
    Utils.Clean Mininet System    ${mininet}
    ${mininet_conn_id}=    SSHLibrary.Open Connection    ${mininet}    prompt=${TOOLS_SYSTEM_PROMPT}    timeout=${timeout}
    Set Suite Variable    ${mininet_conn_id}
    SSHKeywords.Flexible Mininet Login
    Run Keyword If    '${custom}' != '${EMPTY}'    Put File    ${custom}
    Log    Start mininet ${options}
    SSHLibrary.Write    sudo mn --switch ovsk,protocols=OpenFlow13 ${options}
    SSHLibrary.Read Until    mininet>
    Log    Create controller configuration
    ${controller_opt}=    Set Variable
    : FOR    ${index}    IN    @{index_list}
    \    ${controller_opt}=    Catenate    ${controller_opt}    ${SPACE}tcp:${ODL_SYSTEM_${index}_IP}:${ofport}
    \    Log    ${controller_opt}
    Log    Find Number of OVS bridges
    ${num_bridges}    Utils.Run Command On Mininet    ${mininet}    sudo ovs-vsctl show | grep Bridge | wc -l
    ${num_bridges}=    Convert To Integer    ${num_bridges}
    Log    Configure OVS controllers ${controller_opt} in all bridges
    : FOR    ${i}    IN RANGE    1    ${num_bridges+1}
    \    ${bridge}=    Utils.Run Command On Mininet    ${mininet}    sudo ovs-vsctl show | grep Bridge | cut -c 12- | sort | head -${i} | tail -1
    \    OVSDB.Set Controller In OVS Bridge    ${mininet}    ${bridge}    ${controller_opt}
    Log    Check OVS configuratiom
    SSHLibrary.Write    sh ovs-vsctl show
    SSHLibrary.Read Until    mininet>
    [Return]    ${mininet_conn_id}

Start Mininet Multiple Hosts
    [Arguments]    ${hosts}    ${mininet}=${TOOLS_SYSTEM_IP}    ${controller}=${ODL_SYSTEM_IP}    ${mininet_timeout}=${DEFAULT_TIMEOUT}
    [Documentation]    Start mininet 1 switch with ${hosts} hosts attached.
    Log    Start Mininet Linear
    MininetKeywords.StartMininet Single Controller    options=--topo single,${hosts} --mac --switch ovsk,protocols=OpenFlow13    timeout=${mininet_timeout}

Start Mininet Linear
    [Arguments]    ${switches}    ${mininet}=${TOOLS_SYSTEM_IP}    ${controller}=${ODL_SYSTEM_IP}    ${mininet_timeout}=${DEFAULT_TIMEOUT}
    [Documentation]    Start mininet linear topology with ${switches} nodes.
    Log    Start Mininet Linear
    MininetKeywords.StartMininet Single Controller    options=--topo linear,${switches} --switch ovsk,protocols=OpenFlow13    timeout=${mininet_timeout}

Start Mininet Full Mesh
    [Arguments]    ${switches}    ${mininet}=${TOOLS_SYSTEM_IP}    ${controller}=${ODL_SYSTEM_IP}    ${hosts}=0    ${mininet_timeout}=${DEFAULT_TIMEOUT}
    [Documentation]    Start a custom mininet topology.
    ${mininet_conn_id}=    SSHLibrary.Open Connection    ${mininet}    prompt=${TOOLS_SYSTEM_PROMPT}    timeout=${mininet_timeout}
    Set Suite Variable    ${mininet_conn_id}
    SSHKeywords.Flexible_Mininet_Login
    Log    Copying ${topology_file_path} file to Mininet VM and Creating Full Mesh topology
    SSHLibrary.Put File    ${CURDIR}/${topology_file_path}
    SSHLibrary.Write    python ${topology_file} ${switches} ${hosts} 00:00:00:00:00:00 10.0.0.0
    SSHLibrary.Read Until    ${TOOLS_SYSTEM_PROMPT}
    Log    Start Mininet Full Mesh
    SSHLibrary.Write    sudo mn --controller=remote,ip=${controller} --custom switch.py --topo demotopo --switch ovsk,protocols=OpenFlow13
    SSHLibrary.Read Until    mininet>
    Log    Check OVS configuratiom
    SSHLibrary.Write    sh ovs-vsctl show
    ${output}=    Read Until    mininet>
    # Ovsdb connection is sometimes lost after mininet is started. Checking if the connection is alive before proceeding.
    Should Not Contain    ${output}    database connection failed

Send Mininet Command
    [Arguments]    ${mininet_conn}=${EMPTY}    ${cmd}=help
    [Documentation]    Sends Command ${cmd} to Mininet session ${mininet_conn} and returns read buffer response.
    Run Keyword If    """${mininet_conn}""" != ""    SSHLibrary.Switch Connection    ${mininet_conn}
    SSHLibrary.Write    ${cmd}
    ${output}=    SSHLibrary.Read Until    mininet>
    [Return]    ${output}

Send Mininet Command Multiple Sessions
    [Arguments]    ${mininet_conn_list}    ${cmd}=help
    [Documentation]    Sends Command ${cmd} to Mininet sessions in ${mininet_conn_list} and returns list of read buffer responses.
    ${output_list}=    Create List
    : FOR    ${mininet_conn}    IN    @{mininet_conn_list}
    \    ${output}=    Utils.Send Mininet Command    ${mininet_conn}    ${cmd}
    \    Append To List    ${output_list}    ${output}
    [Return]    ${output_list}

Stop Mininet And Exit
    [Arguments]    ${mininet_conn}=${EMPTY}
    [Documentation]    Stops Mininet and exits session ${mininet_conn}
    Run Keyword If    """${mininet_conn}""" != ""    SSHLibrary.Switch Connection    ${mininet_conn}
    SSHLibrary.Write    exit
    SSHLibrary.Read Until    ${TOOLS_SYSTEM_PROMPT}
    SSHLibrary.Close Connection

Stop Mininet And Exit Multiple Sessions
    [Arguments]    ${mininet_conn_list}
    [Documentation]    Stops Mininet and exits sessions in ${mininet_conn_list}.
    : FOR    ${mininet_conn}    IN    @{mininet_conn_list}
    \    MininetKeywords.Stop Mininet And Exit    ${mininet_conn}

Disconnect Cluster Mininet
    [Arguments]    ${action}=break    ${member_index_list}=${EMPTY}
    [Documentation]    Break and restore controller to mininet connection via iptables.
    ${index_list} =    ClusterManagement.List_Indices_Or_All    given_list=${member_index_list}
    : FOR    ${index}    IN    @{index_list}
    \    ${rule} =    BuiltIn.Set Variable    OUTPUT -p all --source ${ODL_SYSTEM_${index}_IP} --destination ${TOOLS_SYSTEM_IP} -j DROP
    \    ${command} =    BuiltIn.Set Variable If    '${action}'=='restore'    sudo /sbin/iptables -D ${rule}    sudo /sbin/iptables -I ${rule}
    \    Log To Console    ${ODL_SYSTEM_${index}_IP}
    \    Utils.Run Command On Controller    ${ODL_SYSTEM_${index}_IP}    cmd=${command}
    \    ${command} =    BuiltIn.Set Variable    sudo /sbin/iptables -L -n
    \    ${output} =    Utils.Run Command On Controller    cmd=${command}
    \    BuiltIn.Log    ${output}

Verify Aggregate Flow From Mininet Session
    [Arguments]    ${mininet_conn}=${EMPTY}    ${flow_count}=0    ${time_out}=0s
    [Documentation]    Verify flow count per switch
    Wait Until Keyword Succeeds    ${time_out}    2s    MininetKeywords.Check Flows In Mininet    ${mininet_conn}    ${flow_count}

Check Flows In Mininet
    [Arguments]    ${mininet_conn}=${EMPTY}    ${flow_count}=0
    [Documentation]    Sync with mininet to match exact number of flows
    Run Keyword If    """${mininet_conn}""" != ""    SSHLibrary.Switch Connection    ${mininet_conn}
    ${cmd} =    Set Variable    dpctl dump-aggregate -O OpenFlow13
    ${output}=    MininetKeywords.Send Mininet Command    ${mininet_conn}    ${cmd}
    ${flows}=    String.Get RegExp Matches    ${output}    (?<=flow_count\=).*?(?=\r)
    ${total_flows}=    BuiltIn.Evaluate    sum(map(int, ${flows}))
    Should Be Equal As Numbers    ${total_flows}    ${flow_count}

Verify Mininet Ping
    [Arguments]    ${host1}    ${host2}
    [Documentation]    Send ping from mininet and verify connectivity.
    SSHLibrary.Write    ${host1} ping -w 3 ${host2}
    ${result}=    SSHLibrary.Read Until    mininet>
    Should Contain    ${result}    64 bytes

Verify Mininet No Ping
    [Arguments]    ${host1}    ${host2}
    [Documentation]    Send ping from mininet and verify no conectivity.
    SSHLibrary.Write    ${host1} ping -w 3 ${host2}
    ${result}=    SSHLibrary.Read Until    mininet>
    Should Contain    ${result}    100% packet loss

Ping All Hosts
    [Arguments]    @{host_list}
    [Documentation]    Do one round of ping from one host to all other hosts in mininet.
    ...    Note that a single ping failure will exit the loop and return a non zero value.
    ${source}=    Get From List    ${host_list}    ${0}
    : FOR    ${h}    IN    @{host_list}
    \    ${status}=    Ping Two Hosts    ${source}    ${h}    1
    \    Exit For Loop If    ${status}!=${0}
    [Return]    ${status}

Ping Two Hosts
    [Arguments]    ${host1}    ${host2}    ${pingcount}=2
    [Documentation]    Ping between mininet hosts. Must be used only after a mininet session is in place.
    ...    Returns non zero value if there is 100% packet loss.
    SSHLibrary.Write    ${host1} ping -c ${pingcount} ${host2}
    ${out}=    SSHLibrary.Read Until    mininet>
    ${ret}=    String.Get Lines Matching Regexp    ${out}    .*100% packet loss.*
    ${len}=    Get Length    ${ret}
    [Return]    ${len}

Get Mininet Hosts
    [Documentation]    Get all the hosts from mininet
    ${host_list}=    Create List
    SSHLibrary.Write    nodes
    ${out}=    SSHLibrary.Read Until    mininet>
    @{words}=    String.Split String    ${out}    ${SPACE}
    : FOR    ${item}    IN    @{words}
    \    ${h}=    String.Get Lines Matching Regexp    ${item}    h[0-9]*
    \    Run Keyword If    '${h}' != '${EMPTY}'    Append To List    ${host_list}    ${h}
    [Return]    ${host_list}
