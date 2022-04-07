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
Test Setup        SetupUtils.Setup_Test_With_Logging_And_Without_Fast_Failing
Default Tags      clustering    carpeople    critical
Library           Collections
Resource          ${CURDIR}/../../../libraries/CarPeople.robot
Resource          ${CURDIR}/../../../libraries/ClusterManagement.robot
Resource          ${CURDIR}/../../../libraries/SetupUtils.robot
Resource          ${CURDIR}/../../../libraries/TemplatedRequests.robot
Variables         ${CURDIR}/../../../variables/Variables.py

*** Variables ***
${CARPEOPLE_ITEMS}    ${30}
${VAR_DIR}        ${CURDIR}/../../../variables/carpeople/crud

*** Test Cases ***
Add_People_To_First_Follower
    [Documentation]    Add ${CARPEOPLE_ITEMS} people to people first Follower, loop of add-person.
    CarPeople.Add_Several_People    session=${people_first_follower_session}    iterations=${CARPEOPLE_ITEMS}

*** Keywords ***
Setup
    [Documentation]    Initialize resources, memorize shard leaders, compute item distribution.
    SetupUtils.Setup_Utils_For_Setup_And_Teardown
    CarPeople.Set_Variables_For_Shard    shard_name=car
    CarPeople.Set_Variables_For_Shard    shard_name=people
    CarPeople.Set_Variables_For_Shard    shard_name=car-people
    ${follower_number} =    BuiltIn.Evaluate    ${CARPEOPLE_ITEMS} // ${NUM_ODL_SYSTEM}
    BuiltIn.Set_Suite_Variable    ${items_per_follower}    ${follower_number}
    ${leader_number} =    BuiltIn.Evaluate    ${CARPEOPLE_ITEMS} - (${NUM_ODL_SYSTEM} - 1) * ${follower_number}
    BuiltIn.Set_Suite_Variable    ${items_per_leader}    ${leader_number}
