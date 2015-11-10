*** Settings ***
Documentation     Test suite to find maximum switches which can be connected to the controller
Suite Setup       Start Suite
Suite Teardown    Utils.Stop Suite
Library           SSHLibrary
Resource          ../../../libraries/Utils.robot
Variables         ../../../variables/Variables.py
Library           ../../../libraries/ScaleClient.py
Library           OperatingSystem

*** Variables ***
${start}          sudo python DynamicMininet.py
${max_sw}         2400
${step_sw}        12
${init_sw}        12
${max_found}      0
${outfile}        max_found.csv
${mininet_conn_ids_list}   Create List

*** Test Cases ***
Find Max Switches
    [Documentation]    Will find out max switches starting from ${start_sw} till reaching ${max_sw} with step defined by ${step_sw}
    ${init_sw}    Convert to Integer    ${init_sw}
    ${max_sw}    Convert to Integer    ${max_sw}
    ${step_sw}    Convert to Integer    ${step_sw}
    : FOR    ${exp_sw}    IN RANGE    ${init_sw}    ${max_sw+1}    ${step_sw}
    \    BuiltIn.Wait Until Keyword Succeeds    120s    1s    Verify Switches Connected    ${exp_sw}
    \    ${max_found}=    Set Variable    ${exp_sw}
    \    Set Suite variable    ${max_found}
    \    :FOR   ${mininet_system}   IN RANGE    ${NUM_TOOLS_SYSTEM}
    \    \  Add Switches    Evaluate    ${step_sw}/${NUM_TOOLS_SYSTEM}
    [Teardown]    Log Store Max Found

*** Keywords ***
Start Suite
    [Documentation]    Starts mininet with requested number of switches
    Log    Start the test on the base edition
    : FOR    ${mininet_system}    IN RANGE    ${NUM_TOOLS_SYSTEM}
    \   ${temp_tools_system_var}=   TOOLS_SYSTEM_${mininet_system}_IP
    \   Append To List    ${mininet_conn_ids_list}    Open Connection    ${!temp_tools_system_var}    prompt=>    timeout=1800
    \   Set Suite Variable  ${mininet_conn_ids_list}
    \   Login With Public Key    ${MININET_USER}    ${USER_HOME}/.ssh/${SSH_KEY}    any
    \   Put File    ${CURDIR}/../../../libraries/DynamicMininet.py    DynamicMininet.py
    \   Execute Command    sudo ovs-vsctl set-manager ptcp:6644
    \   Execute Command    sudo mn -c
    \   Write    ${start}
    \   Read Until    mininet>
    \   Write    start  ${ODL_SYSTEM_1_IP}    Evaluate    ${init_sw}/${NUM_TOOLS_SYSTEM}
    \   Read Until    mininet>
    \   Wait Until Keyword Succeeds    10s    1s    Verify Switches Connected    Evaluate    ${init_sw}/${NUM_TOOLS_SYSTEM}

Add Switches
    [Arguments]    ${nr_switches}
    [Documentation]    Adds requested number of switches to the network
    Write    add_switches ${nr_switches}
    Read Until    mininet>

Verify Switches Connected
    [Arguments]    ${exp_switches}
    [Documentation]    Verifies if switches are connected/present in operational inventory
    ${sw}    ${rep}    ${found}=    Flow Stats Collected    controller=${ODL_SYSTEM_IP}
    Should Be Equal As Numbers    ${sw}    ${exp_switches}

Log Store Max Found
    [Documentation]    Logs the found number
    Log To Console    ${max_found}
    Append To File    ${out_file}    Max\n${max_found}
