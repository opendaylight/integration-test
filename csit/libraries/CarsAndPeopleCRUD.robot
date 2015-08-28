*** Settings ***
Library           Collections
Resource          DatastoreCRUD.robot

*** Keywords ***
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
    Create Records    ${controller_ip}    ${node}    ${0}    ${0}    ${prefix}    ${field bases}    ${postfix}
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
    Create Records    ${controller_ip}    ${node}    ${first}    ${last}    ${prefix}    ${field bases}    ${postfix}

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
    Update Records    ${controller_ip}    ${node}    ${first}    ${last}    ${prefix}    ${field bases}    ${postfix}

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

Delete All Cars
    [Arguments]    ${controller_ip}
    [Documentation]    Deletes all records from the cars shard.
    ${node}=    Set Variable    car:cars
    Delete All Records    ${controller_ip}    ${node}

Delete Cars
    [Arguments]    ${controller_ip}    ${first}    ${last}
    [Documentation]    Deletes the specified range of records from the cars shard.
    ${node}=    Set Variable    car:cars/car-entry
    Delete Records    ${controller_ip}    ${node}    ${first}    ${last}
