*** Settings ***
Documentation     Basic library verification suite, handling cars/people in 1-node setup.
...
...               Copyright (c) 2016 Cisco Systems, Inc. and others. All rights reserved.
...
...               This program and the accompanying materials are made available under the
...               terms of the Eclipse Public License v1.0 which accompanies this distribution,
...               and is available at http://www.eclipse.org/legal/epl-v10.html
...
...               This is a lightweight and stripped-down functional analogue of performance suite.
...               Intention is to use this as a verify suite for changes in TemplatedRequests resource.
Suite Setup       Start_Suite
Test Setup        SetupUtils.Setup_Test_With_Logging_And_Without_Fast_Failing
Test Teardown     SetupUtils.Teardown_Test_Show_Bugs_If_Test_Failed
Variables         ${CURDIR}/../../../variables/Variables.py
Resource          ${CURDIR}/../../../libraries/SetupUtils.robot
Resource          ${CURDIR}/../../../libraries/TemplatedRequests.robot

*** Variables ***
${VAR_BASE}       ${CURDIR}/../../../variables/carpeople/libtest
${BULK_SIZE}      2
${TIMEOUT_BUG_4220}    60s

*** Test Cases ***
Wait_For_Rpcs
    [Documentation]    Issue (invalid) RPC requests until 501 goes away (or timeout expires).
    ...    See https://bugs.opendaylight.org/show_bug.cgi?id=4220
    BuiltIn.Wait_Until_Keyword_Succeeds    ${TIMEOUT_BUG_4220}    5s    Check_Rpc_Readiness

Add_And_Verify_Person
    [Documentation]    Add a person entry, verify it is seen in the datastore.
    TemplatedRequests.Put_As_Json_Templated    folder=${VAR_BASE}/person
    TemplatedRequests.Get_As_Json_Templated    folder=${VAR_BASE}/person    verify=True

Add_And_Verify_Car
    [Documentation]    Add a car entry, verify it is seen in the datastore.
    TemplatedRequests.Put_As_Json_Templated    folder=${VAR_BASE}/car
    TemplatedRequests.Get_As_Json_Templated    folder=${VAR_BASE}/car    verify=True

Purchase_And_Verify_Car
    [Documentation]    Post RPC to buy a car.
    TemplatedRequests.Post_As_Json_Templated    folder=${VAR_BASE}/purchase
    TemplatedRequests.Get_As_Json_Templated    folder=${VAR_BASE}/car_person    verify=True

Delete_CarPerson
    [Documentation]    Remove the car-people entry from the datastore.
    TemplatedRequests.Delete_Templated    folder=${VAR_BASE}/car_person
    # TODO: Add specific error check on Get attempt.

Delete_Car
    [Documentation]    Remove the car entry from the datastore.
    TemplatedRequests.Delete_Templated    folder=${VAR_BASE}/car
    # TODO: Add specific error check on Get attempt.

Delete_Person
    [Documentation]    Remove the person entry from the datastore.
    TemplatedRequests.Delete_Templated    folder=${VAR_BASE}/person
    # TODO: Add specific error check on Get attempt.

Add_And_Verify_People
    [Documentation]    Create container with several people, verify it is seen in the datastore..
    TemplatedRequests.Post_As_Json_Templated    folder=${VAR_BASE}/people    iterations=${BULK_SIZE}
    TemplatedRequests.Get_As_Json_Templated    folder=${VAR_BASE}/people    verify=True    iterations=${BULK_SIZE}

Add_And_Verify_Cars
    [Documentation]    Create container with several cars, verify it is seen in the datastore.
    TemplatedRequests.Post_As_Json_Templated    folder=${VAR_BASE}/cars    iterations=${BULK_SIZE}
    TemplatedRequests.Get_As_Json_Templated    folder=${VAR_BASE}/cars    verify=True    iterations=${BULK_SIZE}
    # TODO: Add cases with purchase loop.

Delete_CarsPeople
    [Documentation]    Remove cars-people container from the datastore.
    TemplatedRequests.Delete_Templated    folder=${VAR_BASE}/cars_people
    # TODO: Add specific error check on Get attempt.

Delete_Cars
    [Documentation]    Remove cars container from the datastore.
    TemplatedRequests.Delete_Templated    folder=${VAR_BASE}/cars
    # TODO: Add specific error check on Get attempt.

Delete_People
    [Documentation]    Remove people container from the datastore.
    TemplatedRequests.Delete_Templated    folder=${VAR_BASE}/people
    # TODO: Add specific error check on Get attempt.

*** Keywords ***
Start_Suite
    [Documentation]    Suite setup keyword
    SetupUtils.Setup_Utils_For_Setup_And_Teardown
    TemplatedRequests.Create_Default_Session

Check_Rpc_Readiness
    [Documentation]    Issue invalid RPC requests and assert appropriate http status code
    # So far only buy-car is checked, but other RPCs such as add-car may be added later.
    ${status}    ${message} =    BuiltIn.Run_Keyword_And_Ignore_Error    TemplatedRequests.Post_As_Json_To_Uri    uri=restconf/operations/car-purchase:buy-car    data={"input":{}}
    # TODO: Create template directory for this?
    BuiltIn.Should_Not_Contain    ${message}    '50
