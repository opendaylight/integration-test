*** Settings ***
Library           SSHLibrary
Resource          Utils.robot
Variables         ../variables/Variables.py

*** Keywords ***
Start Mininet Single Controller
    [Arguments]    ${controller}=${ODL_SYSTEM_IP}    ${options}=--topo tree,1 --switch ovsk,protocols=OpenFlow13    ${custom}=None    ${ofport}=6633    ${system}=${TOOLS_SYSTEM_IP}    ${user}=${TOOLS_SYSTEM_USER}
    ...    ${password}=    ${prompt}=${DEFAULT_LINUX_PROMPT}    ${prompt_timeout}=30s
    [Documentation]    Start Mininet with custom topology and connect to controller.
    ${mininet_conn_id}=    Open Connection    ${system}    prompt=${prompt}    timeout=${prompt_timeout}
    Set Suite Variable    ${mininet_conn_id}
    Flexible Ssh Login    user=${user}    password=${password}
    Run Keyword If    '${custom}' != 'None'    Put File    ${custom}
    Log    Clear any existing mininet
    ${output}=    Execute Command    sudo mn -c
    Log    ${output}
    ${output}=    Execute Command    sudo ps -elf | egrep 'usr/local/bin/mn' | egrep python | awk '{print "sudo kill -9",$4}' | sh
    Log    ${output}
    ${cmd}=    Set Variable    sudo mn --controller 'remote,ip=${controller},port=${ofport}' ${options}
    Log    Start mininet ${options} to ${controller}
    Write    ${cmd}
    Read Until    mininet>
    ${ovs_cmd}=    Set Variable    sudo ovs-vsctl show
    ${output}=    Run Command On Remote System    ${system}    ${ovs_cmd}    ${user}    ${password}    ${prompt}
    ...    ${prompt_timeout}
    Log    ${output}
    [Return]    ${mininet_conn_id}

Start Mininet Multiple Controllers
    [Arguments]    ${controller_index_list}    ${options}=--topo tree,1 --switch ovsk,protocols=OpenFlow13    ${custom}=None    ${ofport}=6633    ${system}=${TOOLS_SYSTEM_IP}    ${user}=${TOOLS_SYSTEM_USER}
    ...    ${password}=    ${prompt}=${DEFAULT_LINUX_PROMPT}    ${prompt_timeout}=30s
    [Documentation]    Start Mininet with custom topology and connect to all controllers in the ${controller_index_list}.
    ${mininet_conn_id}=    Open Connection    ${system}    prompt=${prompt}    timeout=${prompt_timeout}
    Set Suite Variable    ${mininet_conn_id}
    Flexible Ssh Login    user=${user}    password=${password}
    Run Keyword If    '${custom}' != 'None'    Put File    ${custom}
    Log    Clear any existing mininet
    ${output}=    Execute Command    sudo mn -c
    Log    ${output}
    ${output}=    Execute Command    sudo ps -elf | egrep 'usr/local/bin/mn' | egrep python | awk '{print "sudo kill -9",$4}' | sh
    Log    ${output}
    Log    Start mininet ${options}
    ${cmd}=    Set Variable    sudo mn ${options}
    Write    ${cmd}
    Read Until    mininet>
    Log    Create controller configuration
    ${ovs_opt}=    Set Variable
    : FOR    ${index}    IN    @{controller_index_list}
    \    ${ovs_opt}=    Catenate    ${ovs_opt}    ${SPACE}tcp:${ODL_SYSTEM_${index}_IP}:${ofport}
    \    Log    ${ovs_opt}
    Log    Find Number of OVS bridges
    ${ovs_cmd}=    Set Variable    sudo ovs-vsctl show | grep Bridge | wc -l
    ${num_bridges}    Run Command On Remote System    ${system}    ${ovs_cmd}    ${user}    ${password}    ${prompt}
    ...    ${prompt_timeout}
    ${num_bridges}=    Convert To Integer    ${num_bridges}
    Log    Configure OVS controllers ${ovs_opt} in all bridges
    : FOR    ${i}    IN RANGE    1    ${num_bridges+1}
    \    ${ovs_cmd}=    Set Variable    sudo ovs-vsctl show | grep Bridge | cut -c 12- | sort | head -${i} | tail -1
    \    ${bridge}=    Run Command On Remote System    ${system}    ${ovs_cmd}    ${user}    ${password}
    \    ...    ${prompt}    ${prompt_timeout}
    \    ${ovs_cmd}=    Set Variable    sudo ovs-vsctl set-controller ${bridge} ${ovs_opt}
    \    Run Command On Remote System    ${system}    ${ovs_cmd}    ${user}    ${password}    ${prompt}
    \    ...    ${prompt_timeout}
    Log    Check OVS configuratiom
    ${ovs_cmd}=    Set Variable    sudo ovs-vsctl show
    ${output}=    Run Command On Remote System    ${system}    ${ovs_cmd}    ${user}    ${password}    ${prompt}
    ...    ${prompt_timeout}
    Log    ${output}
    [Return]    ${mininet_conn_id}

Send Mininet Command
    [Arguments]    ${mininet_conn_id}    ${cmd}=help    ${prompt}=${DEFAULT_LINUX_PROMPT}
    [Documentation]    Sends Command ${cmd} to Mininet session ${mininet_conn_id} and returns read buffer response
    Switch Connection    ${mininet_conn_id}
    SSHLibrary.Write    ${cmd}
    ${output}=    Read Until    mininet>
    [Return]    ${output}

Send Mininet Command Multiple Sessions
    [Arguments]    ${mininet_conn_list}    ${cmd}=help    ${prompt}=${DEFAULT_LINUX_PROMPT}
    [Documentation]    Sends Command ${cmd} to Mininet sessions in ${mininet_conn_list} and returns list of read buffer responses.
    ${output_list}=    Create List
    : FOR    ${mininet_conn_id}    IN    @{mininet_conn_list}
    \    ${output}=    Send Mininet Command    ${mininet_conn_id}    ${cmd}    ${prompt}
    \    Append To List    ${output_list}    ${output}
    [Return]    ${output_list}

Stop Mininet And Exit
    [Arguments]    ${mininet_conn_id}    ${prompt}=${DEFAULT_LINUX_PROMPT}
    [Documentation]    Stops Mininet and exits session ${mininet_conn_id}
    Switch Connection    ${mininet_conn_id}
    SSHLibrary.Write    exit
    Read Until    ${prompt}
    Close Connection

Stop Mininet And Exit Multiple Sessions
    [Arguments]    ${mininet_conn_list}    ${prompt}=${DEFAULT_LINUX_PROMPT}
    [Documentation]    Stops Mininet and exits sessions in ${mininet_conn_list}.
    : FOR    ${mininet_conn_id}    IN    @{mininet_conn_list}
    \    Stop Mininet And Exit    ${mininet_conn_id}    ${prompt}
