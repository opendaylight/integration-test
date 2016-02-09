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
    Wait Until Keyword Succeeds    40s    1s    Add Service Functions Using RestConf

Add Service Function Forwarders
    [Documentation]    Add Service Function Forwarders
    Wait Until Keyword Succeeds    40s    1s    Add Service Function Forwarders Using RestConf

Verify Valid NIC Redirect Command Add and Remove in CLI
    [Documentation]    Verification of NIC Console command add and remove.
    ${macaddresses}=    Fetch Mac Addresses    h1    h5
    ${macaddresses}=    Split String    ${macaddresses}    ${SPACE}
    ${source_macaddress}=    Get from List    ${macaddresses}    ${sourec_index}
    ${destination_macaddress}=    Get from List    ${macaddresses}    ${destination_index}
    ${id}=    Create Intent From Karaf Console For Redirect    ${source_macaddress}    ${destination_macaddress}    ${action}    ${service_name}
    Delete Intent From Karaf Console For Redirect    ${id}

Verify Ping In Mininet
    [Documentation]    Ping between hosts to verify no packet loss and 200ms should wait.
    ${mininet_conn_id}=    Wait Until Keyword Succeeds    10s    1s    Start Mininet    ${MININET}    ${redirect_topo}    ${custom}
    #Write    sudo apt-get install bridge-utils
    #Write    srvc1 ip addr del 10.0.0.6/8 dev srvc1-eth0
    #Write    srvc1 brctl addbr br0
    #Write    srvc1 brctl addif br0 srvc1-eth0
    #Write    srvc1 brctl addif br0 srvc1-eth1
    #Write    srvc1 ifconfig br0 up
    #Write    srvc1 tc qdisc add dev srvc1-eth1 root netem delay 200ms
    Write    h1 ping -c 10 h5
    ${result}    Read Until    mininet>
    Should Contain    ${result}    64 bytes
    Should Contain    ${result}    time=202 ms
    Stop Mininet    ${mininet_conn_id}

*** Keywords ***
Fetch Mac Addresses
    [Arguments]    ${host1}    ${host2}
    [Documentation]    Getting the source and destination host mac address.
    ${mininet_conn_id2}=    Wait Until Keyword Succeeds    10s    1s    Start Mininet    ${MININET}    ${redirect_topo}    ${custom}
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

