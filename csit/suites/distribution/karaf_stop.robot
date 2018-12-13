*** Settings ***
Documentation     Karaf stop suite.
...
...               Copyright (c) 2017 Cisco Systems, Inc. and others. All rights reserved.
...
...               This program and the accompanying materials are made available under the
...               terms of the Eclipse Public License v1.0 which accompanies this distribution,
...               and is available at http://www.eclipse.org/legal/epl-v10.html
...
...
...               Try to test whether Karaf stops correctly when stop script is used.
...
...               This suite should run as the last one, because it stops the karaf and does
...               not start again. And should try to stop karaf when enough features are installed.
...               Because of that it will be run after the karaf_sequence_install.robot
Suite Setup       SetupUtils.Setup_Utils_For_Setup_And_Teardown
Default Tags      critical    distribution    features
Resource          ${CURDIR}/../../libraries/ClusterManagement.robot
Resource          ${CURDIR}/../../libraries/SetupUtils.robot
Resource          ${CURDIR}/../../variables/Variables.robot

*** Variables ***
${STOP_TIMEOUT}    180s

*** Test Cases ***
Stop_Karaf_Within_Timeout
    [Documentation]    Try to stop karaf using delivered ./bin/stop script.
    ClusterManagement.Stop_Members_From_List_Or_All    timeout=${STOP_TIMEOUT}
