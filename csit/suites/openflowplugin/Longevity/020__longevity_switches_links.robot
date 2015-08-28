*** Settings ***
Documentation     Beta Version of the Longevity Test.  Currently:
...               1.  runs one iteration of the switch scale test based on ${NUM_SWITCHES}
...               2.  runs one iteration of the link scale test based on ${NUM_LINKS}
...               Steps 1 and 2 are run in a psuedo infinite loop and before each loop is
...               run, a time check is made against the ${TEST_LENGTH}. If the test duration
...               has expired, the loop is exited and the test is marked PASS
...
...               If either of steps 1 or 2 fail to reach their configured value of ${NUM_SWITCHES}
...               or ${NUM_LINKS} the test will exit immediately and not continue.
Suite Setup       Longevity Suite Setup
Suite Teardown    Longevity Suite Teardown
Library           RequestsLibrary
Library           DateTime
Variables         ../../../variables/Variables.py
Resource          ../../../libraries/Scalability.robot

*** Variables ***
${NUM_SWITCHES}           200
${NUM_LINKS}              20
${TEST_LENGTH}            2 hours


*** Test Cases ***
Longevity Test
    [Documentation]    Uses switch and link scale test functionality in a loop for given period of time
    #  This loop is not infinite, so going "sufficiently large" for now.
    : FOR  ${i}  IN RANGE    1    65536
    \    ${expiration_flag}=    Check If There Is A Reason To Exit Test Or If Duration Has Expired
    \    Exit For Loop If    "${expiration_flag}" == "True"
    \    ${switch_count}=    Find Max Switches    ${NUM_SWITCHES}     ${NUM_SWITCHES}     ${NUM_SWITCHES}
    \    Check If There Is A Reason To Exit Test Or If Duration Has Expired    ${switch_count}    ${NUM_SWITCHES}    Switch count not correct
    \    ${link_count}=    Find Max Links    ${NUM_LINKS}    ${NUM_LINKS}    ${NUM_LINKS}
    \    Check If There Is A Reason To Exit Test Or If Duration Has Expired    ${link_count}    ${NUM_LINKS}    Link count not correct

*** Keywords ***
Check If There Is A Reason To Exit Test Or If Duration Has Expired
    [Documentation]    In order to simplify the main test case, this keyword will make all the neccessary checks
    ...    to determine if the test should FAIL and quit because of some problem.  It will also return a bool to
    ...    indicate if the requested duration of the longevity test has elapsed.  The caller does not have to use
    ...    that return value.
    [Arguments]    ${comparator1}=1    ${comparator2}=1    ${comparator_failure_message}=null
    Should Be Equal    ${comparator1}    ${comparator2}    ${comparator_failure_message}
    Verify Controller Is Not Dead    ${CONTROLLER}
    ${is_expired}=    Check If Test Duration Is Expired
    [Return]    ${is_expired}

Check If Test Duration Is Expired
    [Documentation]    Compares the current time with that of the suite variable ${end_time} to determine if the
    ...    test duration has expired.
    ${test_is_expired}=  Set Variable    False
    ${current_time}=    Get Current Date
    ${current_time}=    Convert Date    ${current_time}    epoch
    ${test_is_expired}=    Set Variable If    "${current_time}" > "${end_time}"    True
    [Return]    ${test_is_expired}

Longevity Suite Setup
    [Documentation]    In addtion to opening the REST session to the controller, the ${end_time} that this
    ...    test should not exceed is calculated and made in to a suite wide variable.
    Create Session    session    http://${CONTROLLER}:${RESTCONFPORT}    auth=${AUTH}    headers=${HEADERS_XML}
    ${mininet_conn_id}=    Open Connection    ${MININET}    prompt=${DEFAULT_LINUX_PROMPT}
    Login With Public Key    ${MININET_USER}    ${USER_HOME}/.ssh/${SSH_KEY}    any
    Log     Copying ${CREATE_FULLYMESH_TOPOLOGY_FILE_PATH} file to Mininet VM
    Put File  ${CURDIR}/../../../${CREATE_FULLYMESH_TOPOLOGY_FILE_PATH}
    Close Connection
    ${start_time}=    Get Current Date
    ${end_time}=    Add Time To Date    ${start_time}    ${TEST_LENGTH}
    ${end_time}=    Convert Date    ${end_time}    epoch
    Set Suite Variable    ${end_time}

Longevity Suite Teardown
    [Documentation]    Any cleanup neccessary to allow this test to be run in a static environment should go here
    ...    Currently, the same steps needed for the scalability suites should suffice.
    Scalability Suite Teardown
