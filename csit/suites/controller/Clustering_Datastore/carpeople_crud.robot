*** Settings ***
Documentation     Suite for performing basic car/people CRUD operations on leaders and followers.
...
...               Copyright (c) 2016 Cisco Systems, Inc. and others. All rights reserved.
...
...               This program and the accompanying materials are made available under the
...               terms of the Eclipse Public License v1.0 which accompanies this distribution,
...               and is available at http://www.eclipse.org/legal/epl-v10.html
...
...
...               More precisely, Update operation is not executed, but some operations
...               are using specific RPCs which goes beyond "basic CRUD".
...
...               Cars are added by one big PUT to datastore on car Leader.
...               People are added in a loop with add-person RPC on a people Follower.
...               Cars are bought by chunks on each member, by loop with buy-car RPC.
...
...               All data is deleted at the end of the suite.
...               This suite expects car, people and car-people modules to have separate Shards.
Suite Setup       Setup
Default Tags      clustering    carpeople    critical
Library           Collections
Resource          ${CURDIR}/../../../libraries/CarPeople.robot
Resource          ${CURDIR}/../../../libraries/ClusterManagement.robot
Resource          ${CURDIR}/../../../libraries/TemplatedRequests.robot
Variables         ${CURDIR}/../../../variables/Variables.py

*** Variables ***
${CARPEOPLE_ITEMS}    ${30}
${VAR_DIR}        ${CURDIR}/../../../variables/carpeople/crud

*** Test Cases ***
Add_Cars_To_Leader
    [Documentation]    Add ${CARPEOPLE_ITEMS} cars to car Leader by one big PUT.
    TemplatedRequests.Put_As_Json_Templated    folder=${VAR_DIR}/cars    session=${car_leader_session}    iterations=${CARPEOPLE_ITEMS}

See_Added_Cars_On_Leader
    [Documentation]    GET response from Leader should match the PUT data.
    TemplatedRequests.Get_As_Json_Templated    folder=${VAR_DIR}/cars    session=${car_leader_session}    verify=True    iterations=${CARPEOPLE_ITEMS}

See_Added_Cars_On_Followers
    [Documentation]    The same check on other members.
    : FOR    ${session}    IN    @{car_follower_sessions}
    \    TemplatedRequests.Get_As_Json_Templated    folder=${VAR_DIR}/cars    session=${session}    verify=True    iterations=${CARPEOPLE_ITEMS}

Add_People_To_First_Follower
    [Documentation]    Add ${CARPEOPLE_ITEMS} people to people first Follower, loop of add-person.
    CarPeople.Add_Several_People    session=${people_first_follower_session}    iterations=${CARPEOPLE_ITEMS}

See_Added_People_On_Leader
    [Documentation]    GET response from Leader should match the added people.
    TemplatedRequests.Get_As_Json_Templated    folder=${VAR_DIR}/people    session=${people_leader_session}    verify=True    iterations=${CARPEOPLE_ITEMS}

See_Added_People_On_Followers
    [Documentation]    The same check on other members.
    : FOR    ${session}    IN    @{people_follower_sessions}
    \    TemplatedRequests.Get_As_Json_Templated    folder=${VAR_DIR}/people    session=${session}    verify=True    iterations=${CARPEOPLE_ITEMS}

Buy_Cars_On_Leader
    [Documentation]    Buy some cars on car-people Leader, loop of buy-car, ending segment of IDs.
    # Cars are numbered, leader gets chunk at the end, as that is few keypresses shorter.
    ${start_id} =    BuiltIn.Evaluate    (${NUM_ODL_SYSTEM} - 1) * ${items_per_follower} + 1
    CarPeople.Buy_Several_Cars    session=${car-people_leader_session}    iterations=${items_per_leader}    iter_start=${start_id}

Buy_Cars_On_Followers
    [Documentation]    On each Follower buy corresponding ID segment of cars in buy-car loop.
    ${start_id} =    BuiltIn.Set_Variable    1
    : FOR    ${session}    IN    @{car-people_follower_sessions}
    \    CarPeople.Buy_Several_Cars    session=${session}    iterations=${items_per_follower}    iter_start=${start_id}
    \    ${start_id} =    BuiltIn.Evaluate    ${start_id} + ${items_per_follower}

See_Added_CarPeople_On_Leader
    [Documentation]    GET car-person mappings from Leader to see all entries.
    TemplatedRequests.Get_As_Json_Templated    folder=${VAR_DIR}/car-people    session=${car-people_leader_session}    verify=True    iterations=${CARPEOPLE_ITEMS}

See_Added_CarPeople_On_Followers
    [Documentation]    The same check on other members.
    : FOR    ${session}    IN    @{car-people_follower_sessions}
    \    TemplatedRequests.Get_As_Json_Templated    folder=${VAR_DIR}/car-people    session=${session}    verify=True    iterations=${CARPEOPLE_ITEMS}

Delete_All_CarPeople_On_Leader
    [Documentation]    DELETE car-people container. No verification beyond http status.
    TemplatedRequests.Delete_Templated    folder=${VAR_DIR}/car-people    session=${car-people_leader_session}

Delete_All_People_On_Leader
    [Documentation]    DELETE people container. No verification beyond http status.
    TemplatedRequests.Delete_Templated    folder=${VAR_DIR}/people    session=${people_leader_session}

Delete_All_Cars_On_Leader
    [Documentation]    DELETE cars container. No verification beyond http status.
    TemplatedRequests.Delete_Templated    folder=${VAR_DIR}/cars    session=${car_leader_session}

*** Keywords ***
Setup
    [Documentation]    Initialize resources, memorize shard leaders, compute item distribution.
    ClusterManagement.ClusterManagement_Setup
    CarPeople.Set_Variables_For_Shard    shard_name=car
    CarPeople.Set_Variables_For_Shard    shard_name=people
    CarPeople.Set_Variables_For_Shard    shard_name=car-people
    ${follower_number} =    BuiltIn.Evaluate    ${CARPEOPLE_ITEMS} / ${NUM_ODL_SYSTEM}
    BuiltIn.Set_Suite_Variable    ${items_per_follower}    ${follower_number}
    ${leader_number} =    BuiltIn.Evaluate    ${CARPEOPLE_ITEMS} - (${NUM_ODL_SYSTEM} - 1) * ${follower_number}
    BuiltIn.Set_Suite_Variable    ${items_per_leader}    ${leader_number}
