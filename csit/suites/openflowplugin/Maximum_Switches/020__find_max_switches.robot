*** Settings ***
Documentation       Test suite to find maximum switches which can be connected to the controller

Library             SSHLibrary
Resource            ../../../libraries/Utils.robot
Variables           ../../../variables/Variables.py
Library             ../../../libraries/ScaleClient.py
Library             OperatingSystem

Suite Setup         Start Suite
Suite Teardown      Utils.Stop Mininet


*** Variables ***
${start}        sudo python DynamicMininet.py
${max_sw}       500
${step_sw}      10
${init_sw}      10
${max_found}    0
${outfile}      max_found.csv


*** Test Cases ***
Find Max Switches
    [Documentation]    Will find out max switches starting from ${start_sw} till reaching ${max_sw} with step defined by ${step_sw}
    ${init_sw}    Convert to Integer    ${init_sw}
    ${max_sw}    Convert to Integer    ${max_sw}
    ${step_sw}    Convert to Integer    ${step_sw}
    FOR    ${exp_sw}    IN RANGE    ${init_sw}    ${max_sw+1}    ${step_sw}
        BuiltIn.Wait Until Keyword Succeeds    120s    1s    Verify Switches Connected    ${exp_sw}
        ${max_found}    Set Variable    ${exp_sw}
        Set Suite variable    ${max_found}
        Add Switches    10
    END
    [Teardown]    Log Store Max Found


*** Keywords ***
Start Suite
    [Documentation]    Starts mininet with requested number of switches
    Log    Start the test on the base edition
    ${mininet_conn_id}    Open Connection    ${TOOLS_SYSTEM_IP}    prompt=${TOOLS_SYSTEM_PROMPT}    timeout=1800
    Set Suite Variable    ${mininet_conn_id}
    Login With Public Key    ${TOOLS_SYSTEM_USER}    ${USER_HOME}/.ssh/${SSH_KEY}    any
    Put File    ${CURDIR}/../../../libraries/DynamicMininet.py    DynamicMininet.py
    Execute Command    sudo ovs-vsctl set-manager ptcp:6644
    Execute Command    sudo mn -c
    Write    ${start}
    Read Until    mininet>
    Write    start ${ODL_SYSTEM_IP} ${init_sw}
    Read Until    mininet>
    Wait Until Keyword Succeeds    10s    1s    Verify Switches Connected    ${init_sw}

Add Switches
    [Documentation]    Adds requested number of switches to the network
    [Arguments]    ${nr_switches}
    Write    add_switches ${nr_switches}
    Read Until    mininet>

Verify Switches Connected
    [Documentation]    Verifies if switches are connected/present in operational inventory
    [Arguments]    ${exp_switches}
    ${sw}    ${rep}    ${found}    Flow Stats Collected    controller=${ODL_SYSTEM_IP}
    Should Be Equal As Numbers    ${sw}    ${exp_switches}

Log Store Max Found
    [Documentation]    Logs the found number
    Log To Console    ${max_found}
    Log    ${max_found}
    Append To File    ${out_file}    Max\n${max_found}
