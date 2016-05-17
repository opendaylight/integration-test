*** Settings ***
Documentation     OCP agent library. This library is useful for tests using ocp agent tool to simulate RRH devices.
Library           SSHLibrary
Resource          Utils.robot
Resource          OVSDB.robot
Variables         ../variables/Variables.py

*** Keywords ***
Install Agent
    [Arguments]    ${mininet}=${TOOLS_SYSTEM_IP}    ${controller}=${ODL_SYSTEM_IP}
    [Documentation]    Start Agent with custom topology and connect to controller.
    Log    Clear any existing Agent
    ${conn_id}=    SSHLibrary.Open Connection    ${mininet}    prompt=${TOOLS_SYSTEM_PROMPT}    timeout=${DEFAULT_TIMEOUT}
    Set Suite Variable    ${conn_id}
    Utils.Flexible Mininet Login
    SSHLibrary.Write    rm -rf /tmp/agent
    SSHLibrary.Write    git clone https://git.opendaylight.org/gerrit/ocpplugin.git /tmp/agent
    SSHLibrary.Read Until    Checking connectivity... done
    SSHLibrary.Write    cd /tmp/agent/simple-agent
    SSHLibrary.Write    mvn clean compile
    SSHLibrary.Read Until    BUILD SUCCESS
    Log    Agent installed
    Close Connection

Start Emulator Single
    [Arguments]    ${mininet}=${TOOLS_SYSTEM_IP}    ${controller}=${ODL_SYSTEM_IP}    ${vendorID}=TST    ${serialNumber}=100
    [Documentation]    Start Agent with custom topology and connect to controller.
    ${mininet_conn_id}=    SSHLibrary.Open Connection    ${mininet}    prompt=${TOOLS_SYSTEM_PROMPT}    timeout=${DEFAULT_TIMEOUT}
    Set Suite Variable    ${mininet_conn_id}
    Utils.Flexible Mininet Login
    SSHLibrary.Write    java -cp /tmp/agent/simple-agent/target/classes/ org.opendaylight.ocpplugin.OcpAgent ${controller} 1033 ${vendorID} ${serialNumber}
    SSHLibrary.Read Until   getParamResp
    [Return]    ${mininet_conn_id}

Stop Emulator And Exit
    [Arguments]    ${mininet_conn_id}
    [Documentation]    Stops Agent and exits session ${mininet_conn_id}
    SSHLibrary.Switch Connection    ${mininet_conn_id}
    Close Connection
