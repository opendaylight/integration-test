*** Settings ***
Documentation     This test restarts all controllers to verify recovery of car data from persistene
...
...               Copyright (c) 2016 Cisco Systems, Inc. and others. All rights reserved.
...
...               This program and the accompanying materials are made available under the
...               terms of the Eclipse Public License v1.0 which accompanies this distribution,
...               and is available at http://www.eclipse.org/legal/epl-v10.html
...
...
...               TODO: Improve Test Case Documentation.
Suite Setup       Setup
Default Tags      3-node-cluster    critical
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
Add_Cars_On_Leader
    [Documentation]    Add cars in Leader.
    TemplatedRequests.Put_As_Json_Templated    folder=${VAR_DIR}/cars    session=${car_leader_session}    iterations=${CAR_ITEMS}

Kill_All_Members
    [Documentation]    Stop all controllers.
    ClusterManagement.Kill_Members_From_List_Or_All    confirm=True

Start_All_Members
    [Documentation]    Start all controllers.
    ClusterManagement.Start_Members_From_List_Or_All    wait_for_sync=True    timeout=${MEMBER_START_TIMEOUT}

Memorize_Leader_And_Followers
    [Documentation]    Find leader in the car shard.
    # TODO: Was wait_for_sync enough, or do we need additional wait specifically for car shards?
    Set_Variables_For_Shard    shard_name=car

See_Cars_On_Leader
    [Documentation]    Get cars from Leader, should match.
    TemplatedRequests.Get_As_Json_Templated    folder=${VAR_DIR}/cars    session=${car_leader_session}    verify=True    iterations=${CAR_ITEMS}

See_Cars_On_Followers
    [Documentation]    The same check on other members.
    : FOR    ${session}    IN    @{car_follower_sessions}
    \    TemplatedRequests.Get_As_Json_Templated    folder=${VAR_DIR}/cars    session=${session}    verify=True    iterations=${CAR_ITEMS}

Delete_Cars_On_Leader
    [Documentation]    Delete cars in new Leader.
    TemplatedRequests.Delete_Templated    folder=${VAR_DIR}/cars    session=${car_leader_session}

*** Keywords ***
Setup
    [Documentation]    Initialize resources, memorize shard leaders, compute item distribution.
    ClusterManagement.ClusterManagement_Setup
    CarPeople.Set_Variables_For_Shard    shard_name=car
