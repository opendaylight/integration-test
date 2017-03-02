*** Settings ***
Documentation     DOMNotificationBroker testing: No-loss rate
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
Suite Setup       Setup_Keyword
Suite Teardown    SSHLibrary.Close_All_Connections
Test Setup        SetupUtils.Setup_Test_With_Logging_And_Without_Fast_Failing
Test Teardown     SetupUtils.Teardown_Test_Show_Bugs_If_Test_Failed
Test Template     Dom_Notification_Broker_Test_Templ
Default Tags      critical
Library           SSHLibrary
Resource          ${CURDIR}/../../../libraries/MdsalLowlevel.robot
Resource          ${CURDIR}/../../../libraries/SetupUtils.robot

*** Variables ***
${TEST_DURATION_IN_SECONDS}       10
${PUBLISHER_SUBSCRIBER_PAIR_RATE}      ${5000}
${PUBLISHER_LISTENER_PREFIX}      working-pair-
${TESTED_MEMBER_INDEX}    1


*** Test Cases ***
Notifications_5k
    ${5000}

#Notifications_10k
#    ${10000}

#Notifications_20k
#    ${20000}
     

*** Keywords ***
Setup_Keyword
    SetupUtils.Setup_Utils_For_Setup_And_Teardown

Dom_Notification_Broker_Test_Templ
    [Arguments]     ${total_notification_rate}
    ${count} =    BuiltIn.Set_variable     ${0}
    : FOR    ${suffix}    IN RANGE    ${PUBLISHER_SUBSCRIBER_PAIR_RATE}    ${total_notification_rate}+1     ${PUBLISHER_SUBSCRIBER_PAIR_RATE}
    \    ${count} =     BuiltIn.Evaluate    ${count}+1
    \    MdsalLowlevel.Subscribe_Ynl    ${TESTED_MEMBER_INDEX}    ${PUBLISHER_LISTENER_PREFIX}${count}

    : FOR    ${index}    IN RANGE    1    ${count}+1
    \    MdsalLowlevel.Publish_Notifications    ${TESTED_MEMBER_INDEX}    ${PUBLISHER_LISTENER_PREFIX}${index}    ${TEST_DURATION_IN_SECONDS}    ${PUBLISHER_SUBSCRIBER_PAIR_RATE}

    BuiltIn.Sleep     ${TEST_DURATION_IN_SECONDS}

    ${sum_local_number}     BuiltIn.Set_Variable    ${0}    
    : FOR    ${index}    IN RANGE    1    ${count}+1
    \    ${all_not}    ${id_not}    ${err_not}    ${local_number} =     MdsalLowlevel.Unsubscribe_Ynl    ${TESTED_MEMBER_INDEX}    ${PUBLISHER_LISTENER_PREFIX}${index}
    \    BuiltIn.Should_Be_Equal_As_Numbers    ${err_not}    ${0}
    \    BuiltIn.Should_Not_Be_Equal_As_Numbers    ${local_number}    ${0}
    \    BuiltIn.Should_Be_Equal_As_Numbers    ${id_not}    ${local_number}
    \    ${rate} =    BuiltIn.Evaluate    ${local_number}/${TEST_DURATION_IN_SECONDS}
    \    BuiltIn.Should_Be_True    "${rate}" > "0.9*${PUBLISHER_SUBSCRIBER_PAIR_RATE}"
    \    BuiltIn.Should_Be_True    "${rate}" < "1.1*${PUBLISHER_SUBSCRIBER_PAIR_RATE}"
    \    ${sum_local_number} =     BuiltIn.Evaluate    ${sum_local_number}+${local_number}
    ${final_rate} =     BuiltIn.Evaluate     ${sum_local_number}/${TEST_DURATION_IN_SECONDS}
    BuiltIn.Should_Be_True    "${final_rate}" > "0.9*${total_notification_rate}"
    BuiltIn.Should_Be_True    "${final_rate}" < "1.1*${total_notification_rate}"
