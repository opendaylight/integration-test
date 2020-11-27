*** Settings ***
Documentation     DOMNotificationBroker testing: Common keywords
...
...               Copyright (c) 2017 Cisco Systems, Inc. and others. All rights reserved.
...
...               This program and the accompanying materials are made available under the
...               terms of the Eclipse Public License v1.0 which accompanies this distribution,
...               and is available at http://www.eclipse.org/legal/epl-v10.html
Library           Collections
Resource          ${CURDIR}/../MdsalLowlevel.robot
Resource          ${CURDIR}/../ScalarClosures.robot
Resource          ${CURDIR}/../WaitUtils.robot

*** Variables ***
# There is half a megabyte of output.xml per check.
# Even with check period of 15 seconds that makes more than 2 GB of output,
# which is too much for processing into log.html (out of memory errors).
${DNB_CHECK_PERIOD_IN_SECONDS}    600
${DNB_CHECK_TOLERANCE_IN_SECONDS}    ${${DNB_CHECK_PERIOD_IN_SECONDS}*1.2}
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
    WaitUtils.WU_Setup
    ${count} =    BuiltIn.Set_variable    ${0}
    FOR    ${suffix}    IN RANGE    ${DNB_PUBLISHER_SUBSCRIBER_PAIR_RATE}    ${total_notification_rate}+1    ${DNB_PUBLISHER_SUBSCRIBER_PAIR_RATE}
        ${count} =    BuiltIn.Evaluate    ${count}+1
        MdsalLowlevel.Subscribe_Ynl    ${DNB_TESTED_MEMBER_INDEX}    ${DNB_PUBLISHER_LISTENER_PREFIX}${count}
    END
    ${count} =    BuiltIn.Convert_To_Integer    ${count}
    FOR    ${index}    IN RANGE    1    ${count}+1
        MdsalLowlevel.Start_Publish_Notifications    ${DNB_TESTED_MEMBER_INDEX}    ${DNB_PUBLISHER_LISTENER_PREFIX}${index}    ${test_duration_in_seconds}    ${DNB_PUBLISHER_SUBSCRIBER_PAIR_RATE}
    END
    ${getter} =    ScalarClosures.Closure_From_Keyword_And_Arguments    Get_Notifications_Active_Status    ${DNB_TESTED_MEMBER_INDEX}    ${count}
    ${validator} =    ScalarClosures.Closure_From_Keyword_And_Arguments    Check_Notifications_Active_Status    data_holder
    ${validation_timeout_in_seconds} =    BuiltIn.Evaluate    ${test_duration_in_seconds}+${DNB_CHECK_TOLERANCE_IN_SECONDS}
    WaitUtils.Wait_For_Getter_Failure_Or_Stateless_Validator_Pass    timeout=${validation_timeout_in_seconds}s    period=${DNB_CHECK_PERIOD_IN_SECONDS}s    getter=${getter}    stateless_validator=${validator}
    ${sum_local_number}    BuiltIn.Set_Variable    ${0}
    ${low_limit_pair_rate} =    BuiltIn.Evaluate    0.9*${DNB_PUBLISHER_SUBSCRIBER_PAIR_RATE}
    ${high_limit_pair_rate} =    BuiltIn.Evaluate    1.1*${DNB_PUBLISHER_SUBSCRIBER_PAIR_RATE}
    FOR    ${index}    IN RANGE    1    ${count}+1
        ${all_not}    ${id_not}    ${err_not}    ${local_number} =    MdsalLowlevel.Unsubscribe_Ynl    ${DNB_TESTED_MEMBER_INDEX}
        ...    ${DNB_PUBLISHER_LISTENER_PREFIX}${index}
        BuiltIn.Should_Be_Equal_As_Numbers    ${err_not}    ${0}
        BuiltIn.Should_Not_Be_Equal_As_Numbers    ${local_number}    ${0}
        BuiltIn.Should_Be_Equal_As_Numbers    ${id_not}    ${local_number}
        ${rate} =    BuiltIn.Evaluate    ${local_number}/${test_duration_in_seconds}
        BuiltIn.Should_Be_True    ${rate} > ${low_limit_pair_rate}
        BuiltIn.Should_Be_True    ${rate} < ${high_limit_pair_rate}
        ${sum_local_number} =    BuiltIn.Evaluate    ${sum_local_number}+${local_number}
    END
    ${final_rate} =    BuiltIn.Evaluate    ${sum_local_number}/${test_duration_in_seconds}
    ${low_limit_final_rate} =    BuiltIn.Evaluate    0.9*${total_notification_rate}
    ${high_limit_final_rate} =    BuiltIn.Evaluate    1.1*${total_notification_rate}
    BuiltIn.Should_Be_True    ${final_rate} > ${low_limit_final_rate}
    BuiltIn.Should_Be_True    ${final_rate} < ${high_limit_final_rate}

Get_Notifications_Active_Status
    [Arguments]    ${node_to_ask}    ${nr_pairs}
    ${active_list} =    BuiltIn.Create_List
    FOR    ${index}    IN RANGE    1    ${nr_pairs}+1
        ${active}    ${publ_count}    ${last_error}    MdsalLowlevel.Check_Publish_Notifications    ${node_to_ask}    ${DNB_PUBLISHER_LISTENER_PREFIX}${index}
        Collections.Append_To_List    ${active_list}    ${active}
        BuiltIn.Should_Be_Equal    ${EMPTY}    ${last_error}
    END
    BuiltIn.Return_From_Keyword    ${active_list}

Check_Notifications_Active_Status
    [Arguments]    ${active_list}
    FOR    ${active}    IN    @{active_list}
        BuiltIn.Should_Be_Equal    ${False}    ${active}
    END
