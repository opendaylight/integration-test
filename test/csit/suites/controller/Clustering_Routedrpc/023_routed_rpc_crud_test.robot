*** Settings ***
Documentation     Test suite for Routed RPC.
Library           Collections
Library           RequestsLibrary
Library           ../../../libraries/Common.py
Library           ../../../libraries/CrudLibrary.py
Library           ../../../libraries/SettingsLibrary.py
Library           ../../../libraries/UtilLibrary.py
Variables         ../../../variables/Variables.py

*** Variables ***
@{controllers}    ${CONTROLLER}    ${CONTROLLER1}    ${CONTROLLER2}

*** Test Cases ***
Add cars and get cars from Leader
    [Documentation]    Add 100 cars and get added cars from Leader
    ${resp}    InitCar    ${CONTROLLER}    ${PORT}
    ${resp}    AddCar    ${CONTROLLER}    ${PORT}    ${100}
    ${resp}    Getcars    ${CONTROLLER}    ${PORT}    ${0}
    Should Be Equal As Strings    ${resp.status_code}    200
    Should Contain    ${resp.content}    manufacturer1    cars not added!

Add persons and get persons from Leader
    [Documentation]    Add 100 persons and get persons Note: There should be one person added first to enable rpc
    ${resp}    AddPerson    ${CONTROLLER}    ${PORT}    ${0}
    ${resp}    AddPerson    ${CONTROLLER}    ${PORT}    ${100}
    ${resp}    GetPersons    ${CONTROLLER}    ${PORT}    ${0}
    Should Be Equal As Strings    ${resp.status_code}    200
    Should Contain    ${resp.content}    user5    people not added!

Add car-person mapping and get car-person mapping from Follower1
    [Documentation]    Add car-person and get car-person from Leader Note: This is done to enable working of rpc
    ${resp}    AddCarPerson    ${CONTROLLER1}    ${PORT}    ${0}
    ${resp}    GetCarPersonMappings    ${CONTROLLER1}    ${PORT}    ${0}
    Should Be Equal As Strings    ${resp.status_code}    200
    Should Contain    ${resp.content}    user0    car-person not initialized!

Purchase 100 cars using Follower1
    [Documentation]    Purchase 100 cars using Follower1
    ${resp}    BuyCar    ${CONTROLLER1}    ${PORT}    ${100}
    ${resp}    GetCarPersonMappings    ${CONTROLLER1}    ${PORT}    ${0}
    Should Be Equal As Strings    ${resp.status_code}    200

Get Cars from Leader
    [Documentation]    Get 100 using Leader
    ${resp}    Getcars    ${CONTROLLER}    ${PORT}    ${0}
    Should Be Equal As Strings    ${resp.status_code}    200
    Should Contain    ${resp.content}    manufacturer99

Get persons from Leader
    [Documentation]    Get 101 Persons from Leader
    ${resp}    GetPersons    ${CONTROLLER}    ${PORT}    ${0}
    Should Be Equal As Strings    ${resp.status_code}    200
    Should Contain    ${resp.content}    user100

Get car-person mappings using Leader
    [Documentation]    Get 101 car-person mappings using Leader to see 100 entry
    ${resp}    GetCarPersonMappings    ${CONTROLLER}    ${PORT}    ${0}
    Should Be Equal As Strings    ${resp.status_code}    200
    Should Contain    ${resp.content}    user100
