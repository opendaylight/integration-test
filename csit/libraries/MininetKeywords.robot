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
    Log    Starting mininet to ${controller}
    Write    ${cmd}
    Read Until    mininet>
    [Return]    ${mininet_conn_id}

Start Mininet Multiple Controllers
    [Arguments]    ${primary}    ${connection_list}    ${options}=--topo tree,1 --switch ovsk,protocols=OpenFlow13    ${custom}=None    ${ofport}=6633    ${system}=${TOOLS_SYSTEM_IP}
    ...    ${user}=${TOOLS_SYSTEM_USER}    ${password}=    ${prompt}=${DEFAULT_LINUX_PROMPT}    ${prompt_timeout}=30s
    [Documentation]    Start Mininet with custom topology and connect to one primary instance and multiple secondary controllers indexes.
    ${mininet_conn_id}=    Open Connection    ${system}    prompt=${prompt}    timeout=${prompt_timeout}
    Set Suite Variable    ${mininet_conn_id}
    Flexible Ssh Login    user=${user}    password=${password}
    Run Keyword If    '${custom}' != 'None'    Put File    ${custom}
    Log    Clear any existing mininet
    ${output}=    Execute Command    sudo mn -c
    Log    ${output}
    ${output}=    Execute Command    sudo ps -elf | egrep 'usr/local/bin/mn' | egrep python | awk '{print "sudo kill -9",$4}' | sh
    Log    ${output}
    ${cmd}=    Set Variable    sudo mn --controller 'remote,ip=${ODL_SYSTEM_${primary}_IP},port=${ofport}' ${options}
    Log    Starting mininet with primary connection to ${ODL_SYSTEM_${primary}_IP}
    Write    ${cmd}
    Read Until    mininet>
    Sleep    1
    ${ovs_opt}=    Set Variable
    : FOR    ${connection}    IN    @{connection_list}
    \    ${ovs_opt}=    Catenate    ${ovs_opt}    ${SPACE}tcp:${ODL_SYSTEM_${connection}_IP}:${ofport}
    \    Log    ${ovs_opt}
    ${ovs_cmd}=    Set Variable    sudo ovs-vsctl show | grep Bridge | wc -l
    ${num_bridges}    Run Command On Remote System    ${system}    ${ovs_cmd}    ${user}    ${password}    ${prompt}
    ...    ${prompt_timeout}
    ${num_bridges}=    Convert To Integer    ${num_bridges}
    : FOR    ${i}    IN RANGE    1    ${num_bridges+1}
    \    ${ovs_cmd}=    Set Variable    sudo ovs-vsctl show | grep Bridge | cut -c 12- | sort | head -${i} | tail -1
    \    ${bridge}=    Run Command On Remote System    ${system}    ${ovs_cmd}    ${user}    ${password}
    \    ...    ${prompt}    ${prompt_timeout}
    \    ${ovs_cmd}=    Set Variable    sudo ovs-vsctl set-controller ${bridge} ${ovs_opt}
    \    Run Command On Remote System    ${system}    ${ovs_cmd}    ${user}    ${password}    ${prompt}
    \    ...    ${prompt_timeout}
    Sleep    1
    ${ovs_cmd}=    Set Variable    sudo ovs-vsctl show
    ${output}=    Run Command On Remote System    ${system}    ${ovs_cmd}    ${user}    ${password}    ${prompt}
    ...    ${prompt_timeout}
    Log    ${output}
    [Return]    ${mininet_conn_id}

Send Mininet Command
    [Arguments]    ${mininet_conn_id}    ${cmd}=help    ${prompt}=${DEFAULT_LINUX_PROMPT}
    [Documentation]    Sends Command to Mininet console and returns read buffer response
    Switch Connection    ${mininet_conn_id}
    SSHLibrary.Write    ${cmd}
    ${output}=    Read Until    mininet>
    [Return]    ${output}

Stop Mininet And Exit
    [Arguments]    ${mininet_conn_id}    ${prompt}=${DEFAULT_LINUX_PROMPT}
    [Documentation]    Stops Mininet and exits
    Switch Connection    ${mininet_conn_id}
    SSHLibrary.Write    exit
    Read Until    ${prompt}
    Close Connection
