*** Settings ***
Library           Collections
Library           CrudLibrary.py
Library           SettingsLibrary.py
Resource          DatastoreCRUD.robot

*** Keywords ***
Add Cars And Verify
    [Arguments]    ${controller_ip}    ${num_cars}    ${timeout}=3s
    [Documentation]    Initializes shard and then adds the specified number of cars and performs a GET as a check.
    ${resp}    InitCar    ${controller_ip}    ${PORT}
    Should Be Equal As Strings    ${resp.status_code}    204
    ${resp}    AddCar    ${controller_ip}    ${RESTCONFPORT}    ${num_cars}    204
    Should Be Equal As Strings    ${resp.status_code}    204
    Wait Until Keyword Succeeds    ${timeout}    1s    Get Cars And Verify    ${controller_ip}    ${num_cars}

Add Cars And Verify Without Init
    [Arguments]    ${controller_ip}    ${num_cars}    ${timeout}=3s
    [Documentation]    Adds cars to an initialized cars shard then performs a GET as a check.
    Comment    First car add may return 409, but subsequent should be 204
    ${resp}    AddCar    ${controller_ip}    ${RESTCONFPORT}    ${num_cars}    204    409
    Should Be Equal As Strings    ${resp.status_code}    204
    Wait Until Keyword Succeeds    ${timeout}    1s    Get Cars And Verify    ${controller_ip}    ${num_cars}

Get Cars And Verify
    [Arguments]    ${controller_ip}    ${num_cars}
    [Documentation]    Gets cars and verifies that the manufacturer is correct.
    # TODO: Future enhanement: verify all fields.
    ${resp}    Getcars    ${controller_ip}    ${RESTCONFPORT}    ${0}
    Should Be Equal As Strings    ${resp.status_code}    200
    : FOR    ${i}    IN RANGE    1    ${num_cars}+1
    \    Should Contain    ${resp.content}    manufacturer${i}

Add People And Verify
    [Arguments]    ${controller_ip}    ${num_people}    ${timeout}=3s
    [Documentation]    Note: The first AddPerson call passed with 0 posts directly to the data store to get
    ...    the people container created so the subsequent AddPerson RPC calls that put to the
    ...    person list will succeed.
    ${resp}    AddPerson    ${controller_ip}    ${RESTCONFPORT}    ${0}    204
    Should Be Equal As Strings    ${resp.status_code}    204
    Wait Until Keyword Succeeds    ${timeout}    1s    Get One Person And Verify    ${controller_ip}    ${0}
    ${resp}    AddPerson    ${controller_ip}    ${RESTCONFPORT}    ${num_people}    200
    Wait Until Keyword Succeeds    ${timeout}    1s    Get People And Verify    ${controller_ip}    ${num_people}

Add People And Verify Without Init
    [Arguments]    ${controller_ip}    ${num_people}    ${timeout}=3s
    [Documentation]    Adds people to an initialized people shard then performs a GET as a check.
    ${resp}    AddPerson    ${controller_ip}    ${RESTCONFPORT}    ${num_people}    200
    Should Be Equal As Strings    ${resp.status_code}    200
    Wait Until Keyword Succeeds    ${timeout}    1s    Get People And Verify    ${controller_ip}    ${num_people}

Get One Person And Verify
    [Arguments]    ${controller_ip}    ${number}
    [Documentation]    Gets a person and verifies that the user ID is correct.
    # TODO: Future enhanement: verify all fields.
    ${resp}    GetPersons    ${controller_ip}    ${RESTCONFPORT}    ${0}
    Should Be Equal As Strings    ${resp.status_code}    200
    Should Contain    ${resp.content}    user${number}

Get People And Verify
    [Arguments]    ${controller_ip}    ${num_people}
    [Documentation]    Gets multiple people and verifies that the user IDs are correct.
    # TODO: Future enhanement: verify all fields.
    ${resp}    GetPersons    ${controller_ip}    ${RESTCONFPORT}    ${0}
    Should Be Equal As Strings    ${resp.status_code}    200
    : FOR    ${i}    IN RANGE    1    ${num_people}+1
    \    Should Contain    ${resp.content}    user${i}

Add Car Person And Verify
    [Arguments]    ${controller_ip}    ${timeout}=3s
    [Documentation]    Add a car-person via the data store and get the car-person from Leader.
    ...    Note: This is done to get the car-people container created so subsequent
    ...    BuyCar RPC puts to the car-person list will succeed.
    AddCarPerson    ${controller_ip}    ${RESTCONFPORT}    ${0}
    Wait Until Keyword Succeeds    ${timeout}    1s    Get One Car-Person Mapping And Verify    ${controller_ip}    ${0}

Get One Car-Person Mapping And Verify
    [Arguments]    ${controller_ip}    ${number}
    [Documentation]    Gets a car person mapping and verifies that the user ID is correct.
    ${resp}    GetCarPersonMappings    ${controller_ip}    ${RESTCONFPORT}    ${0}
    Should Be Equal As Strings    ${resp.status_code}    200
    Should Contain    ${resp.content}    user${number}

Get Car-Person Mappings And Verify
    [Arguments]    ${controller_ip}    ${num_entries}
    ${resp}    GetCarPersonMappings    ${controller_ip}    ${RESTCONFPORT}    ${0}
    Should Be Equal As Strings    ${resp.status_code}    200
    : FOR    ${i}    IN RANGE    1    ${num_entries}+1
    \    Should Contain    ${resp.content}    user${i}

Buy Cars And Verify
    [Arguments]    ${controller_ip}    ${num_entries}    ${start}=${0}    ${timeout}=3s
    BuyCar    ${controller_ip}    ${RESTCONFPORT}    ${num_entries}    ${start}
    ${total_entries}    Evaluate    ${start}+${num_entries}
    Wait Until Keyword Succeeds    ${timeout}    1s    Get Car-Person Mappings And Verify    ${controller_ip}    ${total_entries}

Check Cars Deleted
    [Arguments]    ${controller_ip}
    ${resp}    Getcars    ${controller_ip}    ${RESTCONFPORT}    ${0}
    Should Be Equal As Strings    ${resp.status_code}    404

Delete All Cars And Verify
    [Arguments]    ${controller_ip}   ${timeout}=3s
    DeleteAllCars    ${controller_ip}    ${RESTCONFPORT}    ${0}
    Wait Until Keyword Succeeds    ${timeout}    1s    Check Cars Deleted    ${controller_ip}

Check People Deleted
    [Arguments]    ${controller_ip}
    ${resp}    GetPersons    ${controller_ip}    ${RESTCONFPORT}    ${0}
    Should Be Equal As Strings    ${resp.status_code}    404

Delete All People And Verify
    [Arguments]    ${controller_ip}    ${timeout}=3s
    DeleteAllPersons    ${controller_ip}    ${RESTCONFPORT}    ${0}
    Wait Until Keyword Succeeds    ${timeout}    1s    Check People Deleted    ${controller_ip}

Check Cars-Persons Deleted
    [Arguments]    ${controller_ip}
    ${resp}    GetCarPersonMappings    ${controller_ip}    ${RESTCONFPORT}    ${0}
    Should Be Equal As Strings    ${resp.status_code}    404

Delete All Cars-Persons And Verify
    [Arguments]    ${controller_ip}    ${timeout}=3s
    DeleteAllCarsPersons    ${controller_ip}    ${RESTCONFPORT}    ${0}
    Wait Until Keyword Succeeds    ${timeout}    1s    Check Cars-Persons Deleted    ${controller_ip}

Delete All Entries From Shards
    [Documentation]    Delete All Shards.
    [Arguments]    @{controllers}
    : FOR    ${ip}    IN    @{controllers}
    \    Delete All Cars And Verify    ${ip}
    : FOR    ${ip}    IN    @{controllers}
    \    Delete All People And Verify    ${ip}
    : FOR    ${ip}    IN    @{controllers}
    \    Delete All Cars-Persons And Verify    ${ip}

Check Cars
    [Arguments]    ${controller_ip}    ${nth_car}
    [Documentation]    Verifies that the first through nth car is present.
    ${resp}    Getcars    ${controller_ip}    ${RESTCONFPORT}    ${0}
    Should Be Equal As Strings    ${resp.status_code}    200
    : FOR    ${INDEX}    IN RANGE    1    ${nth_car}
    \    ${counter}=    Convert to String    ${INDEX}
    \    Log    manufacturer${counter}
    \    Should Contain    ${resp.content}    manufacturer${counter}

Check People
    [Arguments]    ${controller_ip}    ${nth_person}
    [Documentation]    Verifies that the first through nth person is present.
    ${resp}    GetPersons    ${controller_ip}    ${RESTCONFPORT}    ${0}
    Should Be Equal As Strings    ${resp.status_code}    200
    : FOR    ${INDEX}    IN RANGE    1    ${nth_person}
    \    ${counter}=    Convert to String    ${INDEX}
    \    Log    user${counter}
    \    Should Contain    ${resp.content}    user${counter}

Check CarPeople
    [Arguments]    ${controller_ip}    ${nth_carperson}
    [Documentation]    Verifies that the first through nth car-person is present.
    ${resp}    GetCarPersonMappings    ${controller_ip}    ${RESTCONFPORT}    ${0}
    Should Be Equal As Strings    ${resp.status_code}    200
    : FOR    ${INDEX}    IN RANGE    1    ${nth_carperson}
    \    ${counter}=    Convert to String    ${INDEX}
    \    Log    user${counter}
    \    Should Contain    ${resp.content}    user${counter}

Check Elements In Shards
    [Arguments]    ${controller_ip}    ${nth}
    [Documentation]    Check all shards for nth elements
    wait until keyword succeeds    3    1    Check Cars    ${controller_ip}    ${nth}
    wait until keyword succeeds    3    1    Check People    ${controller_ip}    ${nth}
    wait until keyword succeeds    3    1    Check CarPeople    ${controller_ip}    ${nth}

Initialize Cars
    [Arguments]    ${controller_ip}    ${field bases}
    [Documentation]    Initializes the cars shard by creating a 0th car with POST then deleting it.
    ...    Field bases are a dictionary of datastore record field values onto which is appended
    ...    an incremental value to uniquely identify the record from which it came.
    ...    Typically, you will use the Create Dictionary keyword on arguments which look like this:
    ...    id=${EMPTY} category=coupe model=model manufacturer=mfg year=2
    ${node}=    Set Variable    ${EMPTY}
    ${prefix}=    Set Variable    {"car:cars":{"car-entry":[{
    ${postfix}=    Set Variable    }]}}
    Create Records    ${controller_ip}    ${node}    ${0}    ${0}    ${prefix}    ${field bases}
    ...    ${postfix}
    ${node}=    Set Variable    car:cars/car-entry
    Delete Records    ${controller_ip}    ${node}    ${0}    ${0}

Create Cars
    [Arguments]    ${controller_ip}    ${first}    ${last}    ${field bases}
    [Documentation]    Creates cars with record IDs of specified range using POST.
    ...    If first and last are equal, only one record is updated.
    ...    Field bases are a dictionary of datastore record field values onto which is appended
    ...    an incremental value to uniquely identify the record from which it came.
    ...    Typically, you will use the Create Dictionary keyword on an argument which looks like this:
    ...    id=${EMPTY} category=coupe model=model manufacturer=mfg year=2
    ${node}=    Set Variable    car:cars
    ${prefix}=    Set Variable    {"car-entry":[{
    ${postfix}=    Set Variable    }]}
    Create Records    ${controller_ip}    ${node}    ${first}    ${last}    ${prefix}    ${field bases}
    ...    ${postfix}

Update Cars
    [Arguments]    ${controller_ip}    ${first}    ${last}    ${field bases}
    [Documentation]    Updates cars with record IDs of the specified using PUT.
    ...    If first and last are equal, only one record is updated.
    ...    Field bases are a dictionary of datastore record field values onto which is appended
    ...    an incremental value to uniquely identify the record from which it came.
    ...    Typically, you will use the Create Dictionary keyword on arguments which look like this:
    ...    id=${EMPTY} category=coupe model=model manufacturer=mfg year=2
    ${node}=    Set Variable    car:cars/car-entry
    ${prefix}=    Set Variable    {"car-entry":[{
    ${postfix}=    Set Variable    }]}
    Update Records    ${controller_ip}    ${node}    ${first}    ${last}    ${prefix}    ${field bases}
    ...    ${postfix}

Read All Cars
    [Arguments]    ${controller_ip}
    [Documentation]    Returns all records from the cars shard in JSON format.
    ${node}=    Set Variable    car:cars
    ${result}=    Read Records    ${controller_ip}    ${node}
    [Return]    ${result}

Read One Car
    [Arguments]    ${controller_ip}    ${id}
    [Documentation]    Returns the specified record from the cars shard in JSON format.
    ${node}=    Set Variable    car:cars/car-entry/${id}
    ${result}=    Read Records    ${controller_ip}    ${node}
    [Return]    ${result}

Remove All Cars
    [Arguments]    ${controller_ip}
    [Documentation]    Deletes all records from the cars shard.
    ${node}=    Set Variable    car:cars
    Delete All Records    ${controller_ip}    ${node}

Remove Cars
    [Arguments]    ${controller_ip}    ${first}    ${last}
    [Documentation]    Deletes the specified range of records from the cars shard.
    ${node}=    Set Variable    car:cars/car-entry
    Delete Records    ${controller_ip}    ${node}    ${first}    ${last}
