*** Settings ***
Documentation     This test restarts all controllers to verify recovery of car data from persistence.
...
...               Copyright (c) 2016 Cisco Systems, Inc. and others. All rights reserved.
...
...               This program and the accompanying materials are made available under the
...               terms of the Eclipse Public License v1.0 which accompanies this distribution,
...               and is available at http://www.eclipse.org/legal/epl-v10.html
...
...
...               Other models and shards (people, car-people) are not accessed by this suite.
...
...               All data is deleted at the end of the suite.
...               This suite expects car module to have a separate Shard.
Suite Setup       Setup
Default Tags      clustering    carpeople    critical
Library           Collections
Resource          ${CURDIR}/../../../libraries/CarPeople.robot
Resource          ${CURDIR}/../../../libraries/ClusterManagement.robot
Resource          ${CURDIR}/../../../libraries/TemplatedRequests.robot
Variables         ${CURDIR}/../../../variables/Variables.py

*** Variables ***
${CAR_ITEMS}      50
${MEMBER_START_TIMEOUT}    300s
${VAR_DIR}        ${CURDIR}/../../../variables/carpeople/crud

*** Test Cases ***
Add_Cars_On_Leader_And_Verify
    [Documentation]    Single big PUT to datastore to add cars to car Leader.
    TemplatedRequests.Put_As_Json_Templated    folder=${VAR_DIR}/cars    session=${car_leader_session}    iterations=${CAR_ITEMS}
    : FOR    ${session}    IN    @{ClusterManagement__session_list}
    \    TemplatedRequests.Get_As_Json_Templated    folder=${VAR_DIR}/cars    session=${session}    verify=True    iterations=${CAR_ITEMS}

Kill_All_Members
    [Documentation]    Kill all controllers.
    ClusterManagement.Kill_Members_From_List_Or_All    confirm=True

Start_All_Members
    [Documentation]    Start all controllers (should restore the persisted data).
    ClusterManagement.Start_Members_From_List_Or_All    wait_for_sync=True    timeout=${MEMBER_START_TIMEOUT}

Memorize_Leader_And_Followers
    [Documentation]    Locate current Leader of car Shard.
    BuiltIn.Wait_Until_Keyword_Succeeds    30s    2s    CarPeople.Set_Variables_For_Shard    shard_name=car

See_Cars_On_Leader
    [Documentation]    GET cars from Leader, should match the PUT data.
    TemplatedRequests.Get_As_Json_Templated    folder=${VAR_DIR}/cars    session=${car_leader_session}    verify=True    iterations=${CAR_ITEMS}

See_Cars_On_Followers
    [Documentation]    The same check on other members.
    : FOR    ${session}    IN    @{car_follower_sessions}
    \    TemplatedRequests.Get_As_Json_Templated    folder=${VAR_DIR}/cars    session=${session}    verify=True    iterations=${CAR_ITEMS}

Delete_Cars_On_Leader
    [Documentation]    Delete cars on the new Leader.
    TemplatedRequests.Delete_Templated    folder=${VAR_DIR}/cars    session=${car_leader_session}

*** Keywords ***
Setup
    [Documentation]    Initialize resources, memorize car shard leader and followers.
    ClusterManagement.ClusterManagement_Setup
    CarPeople.Set_Variables_For_Shard    shard_name=car
