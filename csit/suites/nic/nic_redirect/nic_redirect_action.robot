*** Settings ***
Documentation     Test suite for NIC Redirect.
...
...               Copyright (c) 2016 NEC. All rights reserved.
...
...               This program and the accompanying materials are made available under the
...               terms of the Eclipse Public License v1.0 which accompanies this distribution,
...               and is available at http://www.eclipse.org/legal/epl-v10.html
Suite Setup       Start NIC Redirect Test Suite
Suite Teardown    Stop NIC Redirect Test Suite
Library           SSHLibrary
Library           Collections
Library           String
Library           DateTime
Library           json
Library           RequestsLibrary
Library           ../../../libraries/Common.py
Variables         ../../../variables/Variables.py
Resource          ../../../libraries/NicKeywords.robot
Resource          ../../../libraries/Scalability.robot
Resource          ../../../libraries/Utils.robot

*** Variables ***
${custom}    ${CURDIR}/../../../libraries/${CREATE_REDIRECT_PATH_TOPOLOGY_PATH}
${redirect_topo}     sudo mn --controller=remote,ip=${ODL_SYSTEM_IP} --custom redirect_test.py --topo mytopo2
${index}          7
${sourec_index}    0
${destination_index}    1
${action}    redirect
${service_name}    srvc1

*** Test Cases ***
All Cases
    Verify NIC Redirect Features Installation
    Verify NIC Console Environment
    # Step-1
    Add Service Functions
    Add Service Function Forwarders
    Install Bridge Utils
    ${mininet_conn_id}=    Start Mininet    ${MININET}    ${redirect_topo}    ${custom}
    Log    ${mininet_conn_id}
    Wait Until Keyword Succeeds    20s    1s    Mininet Commands
    # Step-2
    ${macaddresses}=    Fetch Mac Addresses    h1    h5
    ${macaddresses}=    Split String    ${macaddresses}    ${SPACE}
    ${source_macaddress}=    Get from List    ${macaddresses}    ${sourec_index}
    ${destination_macaddress}=    Get from List    ${macaddresses}    ${destination_index}
    ${id}=    Create Intent From Karaf Console For Redirect    ${source_macaddress}    ${destination_macaddress}    ${action}    ${service_name}
    Log    ${id}
    # Step-3
    #Wait Until Keyword Succeeds    20s    1s    Mininet Commands
    # Step-4
    Wait Until Keyword Succeeds    20s    1s    Mininet Ping

*** Keywords ***
Verify NIC Redirect Features Installation
    [Documentation]    Verify if NIC Redirect required bundles are installed.
    ${output}=    Wait Until Keyword Succeeds    10s    1s    Issue Command On Karaf Console    bundle:list |grep of-renderer
    Should Contain    ${output}    Active

Verify NIC Console Environment
    [Documentation]    Installing NIC Console related features (odl-nic-core-mdsal odl-nic-console odl-nic-listeners)
    Verify Feature Is Installed    odl-nic-core-mdsal
    Verify Feature Is Installed    odl-nic-console
    Verify Feature Is Installed    odl-nic-listeners

Add Service Functions
    [Documentation]    Add Service Functions
    Wait Until Keyword Succeeds    20s    1s    Add Service Functions Using RestConf

Add Service Function Forwarders
    [Documentation]    Add Service Function Forwarders
    Wait Until Keyword Succeeds    20s    1s    Add Service Function Forwarders Using RestConf

Get Dumpflows
    ${temp}=    Write    dpctl dump-flows
    Log    ${temp}

Mininet Commands
    Write    srvc1 ip addr del 10.0.0.6/8 dev srvc1-eth0
    Write    srvc1 brctl addbr br0
    Write    srvc1 brctl addif br0 srvc1-eth0
    Write    srvc1 brctl addif br0 srvc1-eth1
    Write    srvc1 ifconfig br0 up
    Write    srvc1 tc qdisc add dev srvc1-eth1 root netem delay 200ms

Mininet Ping
    Get Dumpflows
    Write    h1 ping -c 10 h5
    ${result}    Read Until    mininet>
    Log    ${result}
    Should Contain    ${result}    64 bytes

Install Bridge Utils
    ${conn_id}=    SSHLibrary.Open Connection    ${ODL_SYSTEM_IP}    prompt=${DEFAULT_LINUX_PROMPT}    timeout=30s
    SSHLibrary.Login_With_Public_Key    ${ODL_SYSTEM_USER}    ${USER_HOME}/.ssh/${SSH_KEY}    any
    Wait Until Keyword Succeeds    20s    1s    SSHLibrary.Execute Command    sudo apt-get install bridge-utils

Fetch Mac Addresses
    [Arguments]    ${host1}    ${host2}
    [Documentation]    Getting the source and destination host mac address.
    #${mininet_conn_id2}=    Start Mininet    ${MININET}    ${redirect_topo}    ${custom}
    write    ${host1} ifconfig -a | grep HWaddr
    ${sourcemacaddr}    Read Until    mininet>
    ${macaddress}=    Split String    ${sourcemacaddr}    ${SPACE}
    ${sourcemacaddr}=    Get from List    ${macaddress}    ${index}
    ${sourcemacaddress}=    Convert To Lowercase    ${sourcemacaddr}
    write    ${host2} ifconfig -a | grep HWaddr
    ${destmacaddr}    Read Until    mininet>
    ${macaddress}=    Split String    ${destmacaddr}    ${SPACE}
    ${destmacaddr}=    Get from List    ${macaddress}    ${index}
    ${destmacaddress}=    Convert To Lowercase    ${destmacaddr}
    [Return]    ${sourcemacaddress} ${destmacaddress}

Start Mininet
    [Arguments]    ${system}=${TOOLS_SYSTEM_IP}    ${cmd}=${start}    ${custom}=    ${user}=${TOOLS_SYSTEM_USER}    ${password}=${TOOLS_SYSTEM_PASSWORD}    ${prompt}=${DEFAULT_LINUX_PROMPT}
    ...    ${prompt_timeout}=120s
    Clean Mininet System
    ${mininet_conn_id}=    Open Connection    ${system}    prompt=${prompt}    timeout=${prompt_timeout}
    Set Suite Variable    ${mininet_conn_id}
    Flexible Mininet Login    user=${user}    password=${password}
    Put File    ${custom}
    Write    ${cmd}
    ${conn_log}    Read Until    mininet>
    Log    ${conn_log}
    [Return]    ${mininet_conn_id}

