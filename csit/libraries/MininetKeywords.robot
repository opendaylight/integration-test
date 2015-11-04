*** Settings ***
Library           SSHLibrary
Resource          Utils.robot
Variables         ../variables/Variables.py

*** Keywords ***
Start Mininet Single Controller
    [Arguments]    ${mininet}=${TOOLS_SYSTEM_IP}    ${controller}=${ODL_SYSTEM_IP}    ${options}=--topo tree,1 --switch ovsk,protocols=OpenFlow13    ${custom}=${EMPTY}    ${ofport}=6633
    [Documentation]    Start Mininet with custom topology and connect to controller.
    Log    Clear any existing mininet
    Clean Mininet System    ${mininet}
    ${mininet_conn_id}=    Open Connection    ${mininet}    prompt=${TOOLS_SYSTEM_PROMPT}    timeout=${DEFAULT_TIMEOUT}
    Set Suite Variable    ${mininet_conn_id}
    Flexible Mininet Login
    Run Keyword If    '${custom}' != '${EMPTY}'    Put File    ${custom}
    Log    Start mininet ${options} to ${controller}
    Write    sudo mn --controller 'remote,ip=${controller},port=${ofport}' ${options}
    Read Until    mininet>
    ${output}=    Run Command On Mininet    ${mininet}    sudo ovs-vsctl show
    Log    ${output}
    [Return]    ${mininet_conn_id}

Start Mininet Multiple Controllers
    [Arguments]    ${mininet}    ${controller_index_list}    ${options}=--topo tree,1 --switch ovsk,protocols=OpenFlow13    ${custom}=${EMPTY}    ${ofport}=6633
    [Documentation]    Start Mininet with custom topology and connect to all controllers in the ${controller_index_list}.
    Log    Clear any existing mininet
    Clean Mininet System    ${mininet}
    ${mininet_conn_id}=    Open Connection    ${mininet}    prompt=${TOOLS_SYSTEM_PROMPT}    timeout=${DEFAULT_TIMEOUT}
    Set Suite Variable    ${mininet_conn_id}
    Flexible Mininet Login
    Run Keyword If    '${custom}' != '${EMPTY}'    Put File    ${custom}
    Log    Start mininet ${options}
    Write    sudo mn ${options}
    Read Until    mininet>
    Log    Create controller configuration
    ${ovs_opt}=    Set Variable
    : FOR    ${index}    IN    @{controller_index_list}
    \    ${ovs_opt}=    Catenate    ${ovs_opt}    ${SPACE}tcp:${ODL_SYSTEM_${index}_IP}:${ofport}
    \    Log    ${ovs_opt}
    Log    Find Number of OVS bridges
    ${num_bridges}    Run Command On Mininet    ${mininet}    sudo ovs-vsctl show | grep Bridge | wc -l
    ${num_bridges}=    Convert To Integer    ${num_bridges}
    Log    Configure OVS controllers ${ovs_opt} in all bridges
    : FOR    ${i}    IN RANGE    1    ${num_bridges+1}
    \    ${bridge}=    Run Command On Mininet    ${mininet}    sudo ovs-vsctl show | grep Bridge | cut -c 12- | sort | head -${i} | tail -1
    \    Run Command On Mininet    ${mininet}    sudo ovs-vsctl set-controller ${bridge} ${ovs_opt}
    Log    Check OVS configuratiom
    ${output}=    Run Command On Mininet    ${mininet}    sudo ovs-vsctl show
    Log    ${output}
    [Return]    ${mininet_conn_id}

Send Mininet Command
    [Arguments]    ${mininet_conn_id}    ${cmd}=help
    [Documentation]    Sends Command ${cmd} to Mininet session ${mininet_conn_id} and returns read buffer response.
    Switch Connection    ${mininet_conn_id}
    SSHLibrary.Write    ${cmd}
    ${output}=    Read Until    mininet>
    [Return]    ${output}

Send Mininet Command Multiple Sessions
    [Arguments]    ${mininet_conn_list}    ${cmd}=help
    [Documentation]    Sends Command ${cmd} to Mininet sessions in ${mininet_conn_list} and returns list of read buffer responses.
    ${output_list}=    Create List
    : FOR    ${mininet_conn_id}    IN    @{mininet_conn_list}
    \    ${output}=    Send Mininet Command    ${mininet_conn_id}    ${cmd}
    \    Append To List    ${output_list}    ${output}
    [Return]    ${output_list}

Stop Mininet And Exit
    [Arguments]    ${mininet_conn_id}
    [Documentation]    Stops Mininet and exits session ${mininet_conn_id}
    Switch Connection    ${mininet_conn_id}
    SSHLibrary.Write    exit
    Read Until    ${TOOLS_SYSTEM_PROMPT}
    Close Connection

Stop Mininet And Exit Multiple Sessions
    [Arguments]    ${mininet_conn_list}
    [Documentation]    Stops Mininet and exits sessions in ${mininet_conn_list}.
    : FOR    ${mininet_conn_id}    IN    @{mininet_conn_list}
    \    Stop Mininet And Exit    ${mininet_conn_id}
