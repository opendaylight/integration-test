*** Settings ***
Documentation     For every node, set Karaf log level to ${alternative_karaf_log_level}.
...
...               Copyright (c) 2016 Cisco Systems, Inc. and others. All rights reserved.
...
...               This program and the accompanying materials are made available under the
...               terms of the Eclipse Public License v1.0 which accompanies this distribution,
...               and is available at http://www.eclipse.org/legal/epl-v10.html
...
...
...               This suite is useful for testing, run it after readiness.
...               Do not forget to specify other variables if suites afterwards manipulate log level.
...               Use revert_log_levels.robot to restore log levels to the default value.
Suite Setup       ClusterManagement.ClusterManagement_Setup
Default Tags      clustering
Resource          ${CURDIR}/../../libraries/ClusterManagement.robot

*** Variables ***
${alternative_karaf_log_level}    INFO

*** Test Cases ***
Set_Levels
    [Documentation]    Issue log:set command on each Karaf.
    ClusterManagement.Run_Karaf_Command_On_List_Or_All    log:set ${alternative_karaf_log_level}
