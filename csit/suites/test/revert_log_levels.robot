*** Settings ***
Documentation     For every node, set Karaf log level to ${DEFAULT_KARAF_LOG_LEVEL}.
...           
...               Copyright (c) 2016 Cisco Systems, Inc. and others. All rights reserved.
...           
...               This program and the accompanying materials are made available under the
...               terms of the Eclipse Public License v1.0 which accompanies this distribution,
...               and is available at http://www.eclipse.org/legal/epl-v10.html
...           
...           
...               This suite is useful for testing, run it after primary site to kep karaf.log shorter.
Suite Setup       ClusterManagement.ClusterManagement_Setup
Default Tags      clustering
Resource          ${CURDIR}/../../libraries/ClusterManagement.robot

*** Variables ***
${DEFAULT_KARAF_LOG_LEVEL}    INFO

*** Test Cases ***
Set_Levels
    [Documentation]    Issue log:set command on each Karaf.
    ClusterManagement.Run_Karaf_Command_On_List_Or_All    log:set ${DEFAULT_KARAF_LOG_LEVEL}
