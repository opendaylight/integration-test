*** Settings ***
Documentation     For every node, set Karaf log level to ${ALTERNATIVE_KARAF_LOG_LEVEL}.
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
${ALTERNATIVE_KARAF_LOG_LEVEL}    INFO

*** Test Cases ***
Set_Levels
    [Documentation]    Issue log:set command on each Karaf. Retry few times on failure.
    # TODO: Extend ClusterManagement to use KarafKeywords.Execute_Controller_Karaf_Command_With_Retry_On_Background.
    BuiltIn.Wait_Until_Keyword_Succeeds    3x    1s    ClusterManagement.Run_Karaf_Command_On_List_Or_All    log:set ${ALTERNATIVE_KARAF_LOG_LEVEL}
