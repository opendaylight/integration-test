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
${DUMPFLOWS}    dpctl dump-flows
${SERVICE_FUNCTIONS_URI}    /restconf/config/service-function:service-functions/
${SERVICE_FUNCTIONS_FILE}    ${CURDIR}/../../../variables/redirect/service-functions.json
${SERVICE_FORWARDERS_URI}    /restconf/config/service-function-forwarder:service-function-forwarders/
${SERVICE_FORWARDERS_FILE}    ${CURDIR}/../../../variables/redirect/service-function-forwarders.json

*** Test Cases ***

Install NIC Redirect Features
    Install a Feature    odl-nic-core-mdsal
    Install a Feature    odl-nic-console
    Install a Feature    odl-nic-listeners

Verify NIC Redirect Features Installation
    [Documentation]    Verify if NIC Redirect required bundles are installed.
    ${output}=    Wait Until Keyword Succeeds    10s    1s    Issue Command On Karaf Console    bundle:list |grep of-renderer
    Should Contain    ${output}    Active

Verify NIC Console Environment
    [Documentation]    Installing NIC Console related features (odl-nic-core-mdsal odl-nic-console odl-nic-listeners)
    Verify Feature Is Installed    odl-nic-core-mdsal
    Verify Feature Is Installed    odl-nic-console
    Verify Feature Is Installed    odl-nic-listeners

Add Service Functions Using RestConf
    [Documentation]    Create a Service Function.
    Wait Until Keyword Succeeds    20s    1s    Add Elements To URI From File    ${SERVICE_FUNCTIONS_URI}    ${SERVICE_FUNCTIONS_FILE}

Add Service Function Forwarders Using RestConf
    [Documentation]    Create a Service Function Forwarders.
    Wait Until Keyword Succeeds    20s    1s    Add Elements To URI From File    ${SERVICE_FORWARDERS_URI}    ${SERVICE_FORWARDERS_FILE}

Verify NIC Redirect CLI Command and Mininet Ping
    [Documentation]    Verification of NIC Console command add and remove.
    # Step -1 : Bridge Utils Software Installation
    Install Bridge Utils
    # Step -2 : Opening Connectin With Mininet
    ${mininet_conn_id}=    Wait Until Keyword Succeeds    40s    1s    Start Mininet    ${MININET}    ${redirect_topo}    ${custom}
    # Step -3 : Reading Mac Addresses from Connected Mininet
    ${macaddresses}=    Fetch Mac Addresses    h1    h5
    ${macaddresses}=    Split String    ${macaddresses}    ${SPACE}
    ${source_macaddress}=    Get from List    ${macaddresses}    ${sourec_index}
    ${destination_macaddress}=    Get from List    ${macaddresses}    ${destination_index}
    # Step -4 : Executing CLI Command
    ${id}=    Create Intent From Karaf Console For Redirect    ${source_macaddress}    ${destination_macaddress}    ${action}    ${service_name}
    #Delete Intent From Karaf Console For Redirect    ${id}
    Switch Connection    ${mininet_conn_id}
    # Step -5 : Trying to Ping in Mininet
    Log    ******* Dump-flows ********
    write    ${DUMPFLOWS}
    ${result}    Read Until    mininet>
    Wait Until Keyword Succeeds    20s    1s    Verify Ping In Mininet






*** Keywords ***

Get Dumpflows
    ${temp}=    Write    dpctl dump-flows
    Log    ${temp}
    #Should Contain    ${temp}    s3
    #Should Contain    ${temp}    s4

Verify Ping In Mininet
    [Documentation]    Ping between hosts to verify no packet loss and 200ms should wait.
    ${out}=    Write    h1 ping -c 10 h5
    Log    ${out}
    ${result}    Read Until    mininet>
    Should Contain    ${result}    64 bytes
    Should Contain    ${result}    time=200 ms
    Stop Mininet    ${mininet_conn_id}

Install Bridge Utils
    ${conn_id}=    SSHLibrary.Open Connection    ${MININET}    prompt=${DEFAULT_LINUX_PROMPT}    timeout=30s
    SSHLibrary.Login_With_Public_Key    ${MININET_USER}    ${USER_HOME}/.ssh/${SSH_KEY}    any
    SSHLibrary.Execute Command    cat /etc/redhat-release
    SSHLibrary.Execute Command    lsb_release -a
    Wait Until Keyword Succeeds    20s    1s    SSHLibrary.Execute Command    sudo apt-get update
    Wait Until Keyword Succeeds    20s    1s    SSHLibrary.Execute Command    sudo apt-get install bridge-utils
    SSHLibrary.Execute Command    dpkg -i bridge-utils

Fetch Mac Addresses
    [Arguments]    ${host1}    ${host2}
    [Documentation]    Getting the source and destination host mac address.
    Wait Until Keyword Succeeds    20s    1s    write    ${host1} ifconfig -a | grep HWaddr
    ${destmacaddr}    Read Until    mininet>
    Wait Until Keyword Succeeds    20s    1s    write    ${host1} ifconfig -a | grep HWaddr
    ${destmacaddr}    Read Until    mininet>
    ${macaddress}=    Split String    ${destmacaddr}    ${SPACE}
    ${destmacaddr}=    Get from List    ${macaddress}    ${index}
    ${destmacaddress}=    Convert To Lowercase    ${destmacaddr}
    Wait Until Keyword Succeeds    20s    1s    write    ${host2} ifconfig -a | grep HWaddr
    ${sourcemacaddr}    Read Until    mininet>
    Wait Until Keyword Succeeds    20s    1s    write    ${host2} ifconfig -a | grep HWaddr
    ${sourcemacaddr}    Read Until    mininet>
    ${macaddress}=    Split String    ${sourcemacaddr}    ${SPACE}
    ${sourcemacaddr}=    Get from List    ${macaddress}    ${index}
    ${sourcemacaddress}=    Convert To Lowercase    ${sourcemacaddr}
    [Return]    ${sourcemacaddress} ${destmacaddress}

Start NIC Redirect Test Suite
    [Documentation]    Start Nic Redirect Rest Test Suite
    Create Session    session    http://${ODL_SYSTEM_IP}:${RESTCONFPORT}    auth=${AUTH}    headers=${HEADERS}
    Clean Mininet System
    Issue Command On Karaf Console    log:set trace org.opendaylight.nic

Stop NIC Redirect Test Suite
    [Documentation]    Stop Nic Redirect Test Suite
    Delete All Sessions

Create Intent From Karaf Console For Redirect
    [Arguments]    ${from}    ${to}    ${action}    ${service_name}
    [Documentation]    Creates an intent to the controller, and returns the id of the intent created.
    ${output}=    Issue Command On Karaf Console    intent:add -f ${from} -t ${to} -a ${action} -s ${service_name}
    Log    ${output}
    Should Contain    ${output}    Intent created
    ${output}=    Fetch From Left    ${output}    )
    ${output_split}=    Split String    ${output}    ${SPACE}
    ${id}=    Get From List    ${output_split}    3
    [Return]    ${id}

Delete Intent From Karaf Console For Redirect
    [Arguments]    ${id}
    [Documentation]    Removes an intent from the controller via the provided intent id.
    ${output}=    Issue Command On Karaf Console    intent:remove ${id}
    Should Contain    ${output}    Intent successfully removed
    ${output}=    Issue Command On Karaf Console    log:display |grep "initIntentsConfiguration: config populated: Intents"
    Should Contain    ${output}    ${id}

Start Mininet
    [Arguments]    ${system}=${MININET}    ${cmd}=${start}    ${custom}=    ${user}=${MININET_USER}    ${password}=${MININET_PASSWORD}    ${prompt}=${DEFAULT_LINUX_PROMPT}
    ...    ${prompt_timeout}=200s
    [Documentation]    Basic setup to start mininet with custom topology
    Log    Start the test on the base edition
    #Clean Mininet System
    ${mininet_conn_id}=    Open Connection    ${system}    prompt=${prompt}    timeout=${prompt_timeout}
    Set Suite Variable    ${mininet_conn_id}
    Flexible Mininet Login    user=${user}    password=${password}
    Write    brctl show
    Write    brctl show
    Read Until    >
    Put File    ${custom}
    Write    ${cmd}
    Read Until    mininet>
    #......temp checking
    Write    srvc1 ip addr del 10.0.0.6/8 dev srvc1-eth0
    Write    srvc1 brctl addbr br0
    Write    srvc1 brctl addif br0 srvc1-eth0
    Write    srvc1 brctl addif br0 srvc1-eth1
    Write    srvc1 ifconfig br0 up
    Write    srvc1 tc qdisc add dev srvc1-eth1 root netem delay 200ms
    #Log    ******* Dump-flows ********
    #write    ${DUMPFLOWS}
    #${result}    Read Until    mininet>
    #Log    ${result}
    #Log    ******* Dump-flows ********
    [Return]    ${mininet_conn_id}

Issue Command On Karaf Console
    [Arguments]    ${cmd}    ${controller}=${ODL_SYSTEM_IP}    ${karaf_port}=${KARAF_SHELL_PORT}    ${timeout}=300
    Open Connection    ${controller}    port=${karaf_port}    prompt=${KARAF_PROMPT}    timeout=${timeout}
    Login    ${KARAF_USER}    ${KARAF_PASSWORD}
    Write    ${cmd}
    ${output}    Read Until    ${KARAF_PROMPT}
    Close Connection
    Log    ${output}
    [Return]    ${output}
