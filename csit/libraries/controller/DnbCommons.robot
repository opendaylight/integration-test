*** Settings ***
Documentation     DOMNotificationBroker testing: Common keywords
...
...               Copyright (c) 2017 Cisco Systems, Inc. and others. All rights reserved.
...
...               This program and the accompanying materials are made available under the
...               terms of the Eclipse Public License v1.0 which accompanies this distribution,
...               and is available at http://www.eclipse.org/legal/epl-v10.html
Library           ${CURDIR}/../MdsalLowlevelPy.py
Resource          ${CURDIR}/../MdsalLowlevel.robot

*** Variables ***
${DNB_PUBLISHER_SUBSCRIBER_PAIR_RATE}    ${5000}
${DNB_PUBLISHER_LISTENER_PREFIX}    working-pair-
${DNB_TESTED_MEMBER_INDEX}    1

*** Keywords ***
Dom_Notification_Broker_Test_Templ
    [Arguments]    ${total_notification_rate}    ${test_duration_in_seconds}
    [Documentation]    Test case template. Input parameter ${total_notification_rate} determines, how many publisher/subscriber
    ...    pais take part in the test case. For every ${DNB_PUBLISHER_SUBSCRIBER_PAIR_RATE} one pair is created.
    ...    The test case itself firstly subscribe listeners, then run publishers and at the end unsubscribe listeners
    ...    and check achieved rates.
    BuiltIn.Log    Overall requested rate: ${total_notification_rate}, test duration: ${test_duration_in_seconds} seconds.
    ${count} =    BuiltIn.Set_variable    ${0}
    : FOR    ${suffix}    IN RANGE    ${DNB_PUBLISHER_SUBSCRIBER_PAIR_RATE}    ${total_notification_rate}+1    ${DNB_PUBLISHER_SUBSCRIBER_PAIR_RATE}
    \    ${count} =    BuiltIn.Evaluate    ${count}+1
    \    MdsalLowlevel.Subscribe_Ynl    ${DNB_TESTED_MEMBER_INDEX}    ${DNB_PUBLISHER_LISTENER_PREFIX}${count}
    ${count} =    BuiltIn.Convert_To_Integer    ${count}
    MdsalLowlevelPy.Publish_Notifications    ${ODL_SYSTEM_${DNB_TESTED_MEMBER_INDEX}_IP}    ${DNB_PUBLISHER_LISTENER_PREFIX}    ${test_duration_in_seconds}    ${DNB_PUBLISHER_SUBSCRIBER_PAIR_RATE}    nrpairs=${count}
    ${sum_local_number}    BuiltIn.Set_Variable    ${0}
    ${low_limit_pair_rate} =    BuiltIn.Evaluate    0.9*${DNB_PUBLISHER_SUBSCRIBER_PAIR_RATE}
    ${high_limit_pair_rate} =    BuiltIn.Evaluate    1.1*${DNB_PUBLISHER_SUBSCRIBER_PAIR_RATE}
    : FOR    ${index}    IN RANGE    1    ${count}+1
    \    ${all_not}    ${id_not}    ${err_not}    ${local_number} =    MdsalLowlevel.Unsubscribe_Ynl    ${DNB_TESTED_MEMBER_INDEX}
    \    ...    ${DNB_PUBLISHER_LISTENER_PREFIX}${index}
    \    BuiltIn.Should_Be_Equal_As_Numbers    ${err_not}    ${0}
    \    BuiltIn.Should_Not_Be_Equal_As_Numbers    ${local_number}    ${0}
    \    BuiltIn.Should_Be_Equal_As_Numbers    ${id_not}    ${local_number}
    \    ${rate} =    BuiltIn.Evaluate    ${local_number}/${test_duration_in_seconds}
    \    BuiltIn.Should_Be_True    ${rate} > ${low_limit_pair_rate}
    \    BuiltIn.Should_Be_True    ${rate} < ${high_limit_pair_rate}
    \    ${sum_local_number} =    BuiltIn.Evaluate    ${sum_local_number}+${local_number}
    ${final_rate} =    BuiltIn.Evaluate    ${sum_local_number}/${test_duration_in_seconds}
    ${low_limit_final_rate} =    BuiltIn.Evaluate    0.9*${total_notification_rate}
    ${high_limit_final_rate} =    BuiltIn.Evaluate    1.1*${total_notification_rate}
    BuiltIn.Should_Be_True    ${final_rate} > ${low_limit_final_rate}
    BuiltIn.Should_Be_True    ${final_rate} < ${high_limit_final_rate}
