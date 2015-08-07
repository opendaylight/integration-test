*** Settings ***
Documentation     Test suite for Routed RPC.
Resource          ../../../libraries/Utils.robot
Library           Collections
Library           RequestsLibrary
Library           ../../../libraries/Common.py
Library           ../../../libraries/CrudLibrary.py
Library           ../../../libraries/SettingsLibrary.py
Library           ../../../libraries/UtilLibrary.py
Library           ../../../libraries/ClusterStateLibrary.py
Variables         ../../../variables/Variables.py

*** Test Cases ***
Add cars and get cars from Leader
    [Documentation]    Add 100 cars and get added cars from Leader
    ${resp}    InitCar    ${CONTROLLER}    ${PORT}
    ${resp}    AddCar    ${CONTROLLER}    ${PORT}    ${100}
    ${resp}    Getcars    ${CONTROLLER}    ${PORT}    ${0}
    Should Be Equal As Strings    ${resp.status_code}    200
    Should Contain    ${resp.content}    manufacturer1

Add persons and get persons from Leader
    [Documentation]    Add 100 persons and get persons Note: There should be one person added first to enable rpc
    ${resp}    AddPerson    ${CONTROLLER}    ${PORT}    ${0}
    ${resp}    AddPerson    ${CONTROLLER}    ${PORT}    ${100}
    ${resp}    GetPersons    ${CONTROLLER}    ${PORT}    ${0}
    Should Be Equal As Strings    ${resp.status_code}    200
    Should Contain    ${resp.content}    user5

Add car-person mapping and get car-person mapping from Follower1
    [Documentation]    Add car-person and get car-person from Follower1 Note: This is done to enable working of rpc
    ${resp}    AddCarPerson    ${CONTROLLER1}    ${PORT}    ${0}
    ${resp}    GetCarPersonMappings    ${CONTROLLER1}    ${PORT}    ${0}
    Should Be Equal As Strings    ${resp.status_code}    200
    Should Contain    ${resp.content}    user0

Purchase 100 cars using Follower
    [Documentation]    Purchase 100 cars using Follower
    ${resp}    BuyCar    ${CONTROLLER1}    ${PORT}    ${100}
    ${resp}    GetCarPersonMappings    ${CONTROLLER1}    ${PORT}    ${0}
    Should Be Equal As Strings    ${resp.status_code}    200

Get Cars from Leader
    [Documentation]    Get 100 using Leader
    ${resp}    Getcars    ${CONTROLLER}    ${PORT}    ${0}
    Should Be Equal As Strings    ${resp.status_code}    200
    Should Contain    ${resp.content}    manufacturer9    cars not returned!

Get persons from Leader
    [Documentation]    Get 11 Persons from Leader
    ${resp}    GetPersons    ${CONTROLLER}    ${PORT}    ${0}
    Should Be Equal As Strings    ${resp.status_code}    200
    Should Contain    ${resp.content}    user100    people not returned!

Get car-person mappings using Leader
    [Documentation]    Get car-person mappings using Leader to see 100 entry
    ${resp}    GetCarPersonMappings    ${CONTROLLER}    ${PORT}    ${0}
    Should Be Equal As Strings    ${resp.status_code}    200
    Should Contain    ${resp.content}    user100    car-people not returned!

Stop Leader
    [Documentation]    Stop Leader controller
    Stop One Or More Controllers    ${CONTROLLER}
    Kill One Or More Controllers    ${CONTROLLER}

Add cars and get cars from Follower1
    [Documentation]    Add 100 cars and get added cars from Follower
    ${resp}    InitCar    ${CONTROLLER1}    ${PORT}
    ${resp}    AddCar    ${CONTROLLER1}    ${PORT}    ${100}
    ${resp}    Getcars    ${CONTROLLER1}    ${PORT}    ${0}
    Should Be Equal As Strings    ${resp.status_code}    200
    Should Contain    ${resp.content}    manufacturer1    cars not added!

Add persons and get persons from Follower1
    [Documentation]    Add 100 persons and get persons Note: There should be one person added first to enable rpc
    ${resp}    AddPerson    ${CONTROLLER1}    ${PORT}    ${0}
    ${resp}    AddPerson    ${CONTROLLER1}    ${PORT}    ${100}
    ${resp}    GetPersons    ${CONTROLLER1}    ${PORT}    ${0}
    Should Be Equal As Strings    ${resp.status_code}    200
    Should Contain    ${resp.content}    user5    car-people not initialized!

Purchase 100 cars using Follower2
    [Documentation]    Purchase 100 cars using Follower2
    ${resp}    BuyCar    ${CONTROLLER2}    ${PORT}    ${100}
    ${resp}    GetCarPersonMappings    ${CONTROLLER2}    ${PORT}    ${0}
    Should Be Equal As Strings    ${resp.status_code}    200

Get Cars from Follower1
    [Documentation]    Get 100 using Follower1
    ${resp}    Getcars    ${CONTROLLER1}    ${PORT}    ${0}
    Should Be Equal As Strings    ${resp.status_code}    200
    Should Contain    ${resp.content}    manufacturer9    cars not returned!

Get persons from Follower1
    [Documentation]    Get 11 Persons from Follower1
    ${resp}    GetPersons    ${CONTROLLER1}    ${PORT}    ${0}
    Should Be Equal As Strings    ${resp.status_code}    200
    Should Contain    ${resp.content}    user100    people not returned!

Get car-person mappings using Follower1
    [Documentation]    Get car-person mappings using Follower1 to see 100 entry
    ${resp}    GetCarPersonMappings    ${CONTROLLER1}    ${PORT}    ${0}
    Should Be Equal As Strings    ${resp.status_code}    200
    Should Contain    ${resp.content}    user100    car-people not returned!

Start Leader
    [Documentation]    Start Leader controller
    Start One Or More Controllers    ${CONTROLLER}
