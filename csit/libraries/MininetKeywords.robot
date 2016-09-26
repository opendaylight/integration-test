*** Settings ***
Documentation     Mininet library. This library is useful for tests using mininet tool to simulate devices.
Library           SSHLibrary
Resource          Utils.robot
Resource          OVSDB.robot
Resource          ClusterManagement.robot
Variables         ../variables/Variables.py

*** Keywords ***
Start Mininet Single Controller
    [Arguments]    ${mininet}=${TOOLS_SYSTEM_IP}    ${controller}=${ODL_SYSTEM_IP}    ${options}=--topo tree,1 --switch ovsk,protocols=OpenFlow13    ${custom}=${EMPTY}    ${ofport}=${ODL_OF_PORT}    ${timeout}=${DEFAULT_TIMEOUT}
    [Documentation]    Start Mininet with custom topology and connect to controller.
    Log    Clear any existing mininet
    Utils.Clean Mininet System    ${mininet}
    ${mininet_conn_id}=    SSHLibrary.Open Connection    ${mininet}    prompt=${TOOLS_SYSTEM_PROMPT}    timeout=${timeout}
    Set Suite Variable    ${mininet_conn_id}
    Utils.Flexible Mininet Login
    Run Keyword If    '${custom}' != '${EMPTY}'    Put File    ${custom}
    Log    Start mininet ${options} to ${controller}
    SSHLibrary.Write    sudo mn --controller 'remote,ip=${controller},port=${ofport}' ${options}
    SSHLibrary.Read Until    mininet>
    Log    Check OVS configuratiom
    SSHLibrary.Write    sh ovs-vsctl show
    SSHLibrary.Read Until    mininet>
    [Return]    ${mininet_conn_id}

Start Mininet Multiple Controllers
    [Arguments]    ${mininet}    ${controller_index_list}=${EMPTY}    ${options}=--topo tree,1 --switch ovsk,protocols=OpenFlow13    ${custom}=${EMPTY}    ${ofport}=${ODL_OF_PORT}    ${timeout}=${DEFAULT_TIMEOUT}
    [Documentation]    Start Mininet with custom topology and connect to list of controllers in ${controller_index_list} or all if no list is provided.
    ${index_list} =    ClusterManagement__Given_Or_Internal_Index_List    given_list=${controller_index_list}
    Log    Clear any existing mininet
    Utils.Clean Mininet System    ${mininet}
    ${mininet_conn_id}=    SSHLibrary.Open Connection    ${mininet}    prompt=${TOOLS_SYSTEM_PROMPT}    timeout=${timeout}
    Set Suite Variable    ${mininet_conn_id}
    Utils.Flexible Mininet Login
    Run Keyword If    '${custom}' != '${EMPTY}'    Put File    ${custom}
    Log    Start mininet ${options}
    SSHLibrary.Write    sudo mn ${options}
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

Verify Aggregate Flow From Mininet Session
    [Arguments]    ${mininet_conn}=${EMPTY}    ${flow_count}=0    ${time_out}=0s
    [Documentation]    Verify flow count per switch
    Wait Until Keyword Succeeds    ${time_out}    2s    MininetKeywords.Mininet Sync Status    ${mininet_conn}    ${flow_count}

Mininet Sync Status
    [Arguments]    ${mininet_conn}=${EMPTY}    ${flow_count}=0
    [Documentation]    Sync with mininet to match exact number of flows
    ${cmd} =    Set Variable    dpctl dump-aggregate -O OpenFlow13
    ${output}=    MininetKeywords.Send Mininet Command    ${mininet_conn}    ${cmd}
    ${flows}=    String.Get RegExp Matches    ${output}    (?<=flow_count\=).*?(?=\r)
    ${total_flows}=    BuiltIn.Evaluate    sum(map(int, ${flows}))
    Should Be Equal As Numbers    ${total_flows}    ${flow_count}

Verify Mininet Ping
    [Arguments]    ${host1}    ${host2}
    [Documentation]    Send ping from mininet and verify connectivity.
    Write    ${host1} ping -w 1 ${host2}
    ${result}=    Read Until    mininet>
    Should Contain    ${result}    64 bytes

Verify Mininet No Ping
    [Arguments]    ${host1}    ${host2}
    [Documentation]    Send ping from mininet and verify no conectivity.
    Write    ${host1} ping -w 1 ${host2}
    ${result}=    Read Until    mininet>
    Should Contain    ${result}    100% packet loss
