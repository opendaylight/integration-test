*** Settings ***
Documentation     DOMDataBroker testing: Leader Isolation
...
...               Copyright (c) 2017 Cisco Systems, Inc. and others. All rights reserved.
...
...               This program and the accompanying materials are made available under the
...               terms of the Eclipse Public License v1.0 which accompanies this distribution,
...               and is available at http://www.eclipse.org/legal/epl-v10.html
...
...               The goal is to ensure the datastore succeeds in basic isolation/rejoin scenario,
...               simulating either a network partition, or a prolonged GC pause.
Suite Setup       SetupUtils.Setup_Utils_For_Setup_And_Teardown
Suite Teardown    SSHLibrary.Close_All_Connections
Test Setup        SetupUtils.Setup_Test_With_Logging_And_Without_Fast_Failing
Test Teardown     SetupUtils.Teardown_Test_Show_Bugs_If_Test_Failed
Default Tags      critical
#Test Template     DnbCommons.Dom_Notification_Broker_Test_Templ
Library           SSHLibrary
Resource          ${CURDIR}/../../../libraries/controller/DdbCommons.robot
Resource          ${CURDIR}/../../../libraries/MdsalLowlevel.robot
Resource          ${CURDIR}/../../../libraries/SetupUtils.robot

*** Test Cases ***
Test1
    BuiltIn.Sleep     1s
