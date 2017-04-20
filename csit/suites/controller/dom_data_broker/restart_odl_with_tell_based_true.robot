*** Settings ***
Documentation     Set tell-based protocol usage
...
...               Copyright (c) 2016 Cisco Systems, Inc. and others. All rights reserved.
...
...               This program and the accompanying materials are made available under the
...               terms of the Eclipse Public License v1.0 which accompanies this distribution,
...               and is available at http://www.eclipse.org/legal/epl-v10.html
...
...               Suite stops all odl nodes, uncomment usage of tell-based protocol in
...               config file and starts all nodes again.
Suite Setup       SetupUtils.Setup_Utils_For_Setup_And_Teardown
Suite Teardown    SSHLibrary.Close_All_Connections
Library           SSHLibrary
Resource          ${CURDIR}/../../../libraries/ClusterManagement.robot
Resource          ${CURDIR}/../../../libraries/SetupUtils.robot

*** Variables ***
${DATASTORE_CFG}    /${WORKSPACE}/${BUNDLEFOLDER}/etc/org.opendaylight.controller.cluster.datastore.cfg

*** Test Cases ***
Kill_All_Members
    [Documentation]    Kill every odl node.
    ClusterManagement.Kill_Members_From_List_Or_All

Set_Tell_Based_Protocol_Usage
    [Documentation]    Uncomment the flag usage line in config file
    ClusterManagement.Run_Bash_Command_On_List_Or_All    sed -ie "s/#use-tell-based-protocol=/use-tell-based-protocol=/g" ${DATASTORE_CFG}
    ClusterManagement.Run_Bash_Command_On_List_Or_All    cat ${DATASTORE_CFG}

Start_All_And_Sync
    [Documentation]    Start each member and wait for sync.
    ClusterManagement.Start_Members_From_List_Or_All
    ClusterManagement.Run_Bash_Command_On_List_Or_All    ps -ef | grep java
