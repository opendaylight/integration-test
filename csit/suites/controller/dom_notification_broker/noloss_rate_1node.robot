*** Settings ***
Test Template     Dom_Notification_Broker_Test_Templ

*** Variables ***
${TEST_DURATION}       3s
${PUBLISHER_SUBSCRIBER_PAIR_RATE}      5000
${PUBLISHER_PREFIX}      publisher-


*** Test Cases ***
Notifications_5k
    ${5000}

Notifications_10k
    ${10000}

Notifications_20k
    ${20000}
     

*** Keywords ***
Dom_Notification_Broker_Test_Templ
    [Arguments]     ${total_notification_rate}
    : FOR    ${rate}    IN RANGE    ${PUBLISHER_SUBSCRIBER_PAIR_RATE}    ${total_notification_rate}+1     ${PUBLISHER_SUBSCRIBER_PAIR_RATE}
    \   Log To Console     ${PUBLISHER_PREFIX}${rate}
