*** Settings ***
Documentation     Test for verifying libraries for handling cars/people work in 1-node setup..
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
Variables         ${CURDIR}/../../../variables/Variables.py
Resource          ${CURDIR}/../../../libraries/SetupUtils.robot
Resource          ${CURDIR}/../../../libraries/TemplatedRequests.robot

*** Variables ***
${VAR_BASE}       ${CURDIR}/../../../variables/carpeople

*** Test Cases ***
Add_Person
    [Documentation]    Add a person. Tis time with Post.
    TemplatedRequests.Post_As_Json_Templated    folder=${VAR_BASE}/add_person

Verify_Person
    [Documentation]    Get people to see the person was added.
    ${people_data} =    TemplatedRequests.Get_As_Json_Templated    folder=${VAR_BASE}/add_person
    TemplatedRequests.Verify_Response_As_Json_Templated    response=${people_data}    folder=${VAR_BASE}/add_person

Add_Car
    [Documentation]    Add a car.
    TemplatedRequests.Put_As_Json_Templated    folder=${VAR_BASE}/add_car

Verify_Car
    [Documentation]    Get cars to see the car was added.
    ${cars_data} =    TemplatedRequests.Get_As_Json_Templated    folder=${VAR_BASE}/add_car
    TemplatedRequests.Verify_Response_As_Json_Templated    response=${cars_data}    folder=${VAR_BASE}/add_car

Purchase_Car
    [Documentation]    Post RPC to buy a car.
    TemplatedRequests.Post_As_Json_Templated    folder=${VAR_BASE}/purchase_car

Verify_Purchase
    [Documentation]    Get cars-people to se the car was purchased.
    ${carpeople_data} =    TemplatedRequests.Get_As_Json_Templated    folder=${VAR_BASE}/car_person
    TemplatedRequests.Verify_Response_As_Json_Templated    response=${people_data}    folder=${VAR_BASE}/car_person

Delete_CarPerson
    [Documentation]    Remove car-people entry from the datastore.
    TemplatedRequests.Delete_Templated    folder=${VAR_BASE}/car_person
    # TODO: Add specific error check on Get attempt.

Delete_Car
    [Documentation]    Remove cars entry from the datastore.
    TemplatedRequests.Delete_Templated    folder=${VAR_BASE}/add_car
    # TODO: Add specific error check on Get attempt.

Delete_Person
    [Documentation]    Remove people entry from the datastore.
    TemplatedRequests.Delete_Templated    folder=${VAR_BASE}/add_person
    # TODO: Add specific error check on Get attempt.

*** Keywords ***
Start_Suite
    [Documentation]    Suite setup keyword
    SetupUtils.Setup_Utils_For_Setup_And_Teardown
    TemplatedRequests.Create_Default_Session
