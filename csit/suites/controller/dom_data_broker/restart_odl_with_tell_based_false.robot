*** Settings ***
Documentation     Unset tell-based protocol usage and restart odl cluster (kill and start)
...
...               Copyright (c) 2016 Cisco Systems, Inc. and others. All rights reserved.
...
...               This program and the accompanying materials are made available under the
...               terms of the Eclipse Public License v1.0 which accompanies this distribution,
...               and is available at http://www.eclipse.org/legal/epl-v10.html
Suite Setup       SetupUtils.Setup_Utils_For_Setup_And_Teardown
Suite Teardown    SSHLibrary.Close_All_Connections
Library           SSHLibrary
Resource          ${CURDIR}/../../../libraries/ClusterManagement.robot
Resource          ${CURDIR}/../../../libraries/KarafKeywords.robot
Resource          ${CURDIR}/../../../libraries/SetupUtils.robot
Resource          ${CURDIR}/../../../libraries/TemplatedRequests.robot

*** Variables ***
${PID}            org.opendaylight.controller.cluster.datastore.cfg
${PROPERTY}       use-tell-based-protocol
${VALUE_FALSE}    false

*** Test Cases ***
Unset_Tell_Based_Protocol_Usage
    KarafKeywords.Config_Admin_Property_Set    ${PID}    ${PROPERTY}    ${VALUE_FALSE}

Stop_All_Members
    [Documentation]    Kill every node, download karaf logs.
    ClusterManagement.Stop_Members_From_List_Or_All

Start_All_And_Sync
    [Documentation]    Start each memberand wait for sync.
    ClusterManagement.Start_Members_From_List_Or_All
    BuiltIn.Comment    Basic synch performed, but waits for specific functionality may still be needed.
    BuiltIn.Wait_Until_Keyword_Succeeds    2m    5s    Topology_Available
    ClusterManagement.Run_Bash_Command_On_List_Or_All    ps -ef | grep java

*** Keywords ***
Topology_Available
    ${session}=    ClusterManagement.Resolve_Http_Session_For_Member    1
    TemplatedRequests.Get_As_Json_From_Uri    /restconf/operational/network-topology:network-topology/topology/example-ipv4-topology    session=${session}
