*** Settings ***
Documentation     DOMNotificationBroker longevity testing: No-loss rate
...
...               Copyright (c) 2017 Cisco Systems, Inc. and others. All rights reserved.
...
...               This program and the accompanying materials are made available under the
...               terms of the Eclipse Public License v1.0 which accompanies this distribution,
...               and is available at http://www.eclipse.org/legal/epl-v10.html
...
...               Provides routing of YANG notifications from publishers to subscribers.
...               The purpose of this test is to determine the broker can forward messages without
...               loss. We do this on a single-node setup by incrementally adding publishers and
...               subscribers.
Suite Setup       SetupUtils.Setup_Utils_For_Setup_And_Teardown    http_timeout=125
Suite Teardown    SSHLibrary.Close_All_Connections
Test Setup        SetupUtils.Setup_Test_With_Logging_And_Without_Fast_Failing
Test Teardown     SetupUtils.Teardown_Test_Show_Bugs_If_Test_Failed
Default Tags      critical
Test Template     DnbCommons.Dom_Notification_Broker_Test_Templ
Library           SSHLibrary
Resource          ${CURDIR}/../../../libraries/controller/DnbCommons.robot
Resource          ${CURDIR}/../../../libraries/SetupUtils.robot

*** Variables ***
# TODO: change back to 24h when releng has more granular steps to kill VMs than days; now 23h=82800s
${LONGEVITY_TEST_DURATION_IN_SECS}    82800
${NOTIFICATION_RATE}    ${60000}

*** Test Cases ***
Notifications_longevity
    ${NOTIFICATION_RATE}    ${LONGEVITY_TEST_DURATION_IN_SECS}
