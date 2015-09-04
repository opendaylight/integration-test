*** Settings ***
Documentation     netconf-connector CRUD test suite.
...
...               Copyright (c) 2015 Cisco Systems, Inc. and others. All rights reserved.
...
...               This program and the accompanying materials are made available under the
...               terms of the Eclipse Public License v1.0 which accompanies this distribution,
...               and is available at http://www.eclipse.org/legal/epl-v10.html
...
...
...               Query netconf-connector and see if it works. If it doesn't,
...               start repeating the query for a minute to see whether it goes
...               up or not.
Suite Setup       Setup_Everything
Suite Teardown    Teardown_Everything
Library           RequestsLibrary
Library           OperatingSystem
Library           SSHLibrary    prompt=]>    timeout=10s
Variables         ${CURDIR}/../../../variables/Variables.py
Resource          ${CURDIR}/../../../libraries/Utils.robot

*** Variables ***
${MININET_PROMPT}    ${DEFAULT_LINUX_PROMPT}

*** Test Cases ***
Check_Whether_Netconf_Connector_Works
    [Documentation]    Make one request to netconf-connector and see if it works.
    [Tags]    critical
    Check_Netconf_Connector

Wait_For_Netconf_Connector
    [Documentation]    Attempt to wait for the netconf-connector for 1 minute.
    [Tags]    critical
    BuiltIn.Wait_Until_Keyword_Succeeds    60s    1s    Check_Netconf_Connector

*** Keywords ***
Setup_Everything
    [Documentation]    Setup requests library.
    # Connect to the Mininet machine
    SSHLibrary.Open_Connection    ${MININET}
    Utils.Flexible_SSH_Login    ${MININET_USER}    ${MININET_PASSWORD}
    # Install test tool on the Mininet machine.
    ${urlbase}=    BuiltIn.Set_Variable    ${NEXUSURL_PREFIX}/content/repositories/opendaylight.snapshot/org/opendaylight/netconf/netconf-testtool
    ${version}=    SSHLibrary.Execute_Command    curl ${urlbase}/maven-metadata.xml | grep '<version>' | cut -d '>' -f 2 | cut -d '<' -f 1
    BuiltIn.Log    ${version}
    ${namepart}=    SSHLibrary.Execute_Command    curl ${urlbase}/${version}/maven-metadata.xml | grep value | head -n 1 | cut -d '>' -f 2 | cut -d '<' -f 1
    BuiltIn.Log    ${namepart}
    BuiltIn.Set_Suite_Variable    ${filename}    netconf-testtool-${namepart}-executable.jar
    BuiltIn.Log    ${filename}
    ${response}=    SSHLibrary.Execute_Command    wget -q -N ${urlbase}/${version}/${filename} 2>&1
    BuiltIn.Log    ${response}
    # Start the testool
    ${response}=    SSHLibrary.Execute_Command    mkdir schemas
    BuiltIn.Log    ${response}
    SSHLibrary.Start_Command    java -Xmx1G -XX:MaxPermSize=256M -jar netconf-testtool-0.4.0-20150725.025858-163-executable.jar --device-count 10 --debug true --schemas-dir `pwd`/schemas >testtool.log
    Builtin.Sleep    1s
    # Setup a requests session
    RequestsLibrary.Create_Session    ses    http://${CONTROLLER}:${RESTCONFPORT}    auth=${AUTH}
    # TODO: Do not include slash in ${OPERATIONAL_TOPO_API}, having it typed here is more readable.
    # TODO: Alternatively, create variable in Variables which starts with http.
    # Both TODOs would probably need to update every suite relying on current Variables.

Teardown_Everything
    [Documentation]    Destroy all sessions in the requests library.
    RequestsLibrary.Delete_All_Sessions
    # Stop testtool and download its log.
    # FIXME: This does not work very well. It seems there there is no 'killall'
    #        command on the mininet machine.
    ${response}=    SSHLibrary.Execute_Command    killall java
    BuiltIn.Log    ${response}
    ${response}=    OperatingSystem.Run    sshpass -p${MININET_PASSWORD} scp ${MININET_USER}@${MININET}:/home/${MININET_USER}/testtool.log .
    BuiltIn.Log    ${response}

Check_Netconf_Connector
    [Documentation]    Make a request to netconf connector's list of mounted devices and check that the request was successful.
    ${response}=    RequestsLibrary.Get    ses    restconf/config/network-topology:network-topology/topology/topology-netconf/node/controller-config/yang-ext:mount/config:modules/?prettyPrint=true
    BuiltIn.Log    ${response.text}
    BuiltIn.Should_Be_Equal_As_Strings    ${response.status_code}    200
