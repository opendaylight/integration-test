*** Settings ***
Documentation     Test suite for Routed RPC. 
Library           Collections
Library           ../../../libraries/RequestsLibrary.py
Library           ../../../libraries/Common.py
Library           ../../../libraries/CrudLibrary.py
Library           ../../../libraries/SettingsLibrary.py
Library           ../../../libraries/UtilLibrary.py
Variables         ../../../variables/Variables.py

*** Variables ***
${REST_CONTEXT}    /restconf/config/


*** Test Cases *** 
Add cars and get cars from Leader 
    [Documentation]    Add 100 cars and get added cars from Leader
	${resp}		AddCar	${MEMBER1}	${PORT}	${100}	
	${resp}		Getcars	${MEMBER1}	${PORT}	${0}
	Should Be Equal As Strings    ${resp.status_code}    200
	Should Contain     ${resp.content}   manufacturer1	
           	
Add persons and get persons from Leader 
    [Documentation]    Add 100 persons and get persons
    [Documentation]    Note: There should be one person added first to enable rpc
	${resp}		AddPerson	${MEMBER1}	${PORT}	${0}	
	${resp}		AddPerson	${MEMBER1}	${PORT}	${100}	
	${resp}		GetPersons	${MEMBER1}	${PORT}	${0}
	Should Be Equal As Strings    ${resp.status_code}    200
	Should Contain     ${resp.content}   user5
	SLEEP	10	

Add car-person mapping and get car-person mapping from Follower1
    [Documentation]	Add car-person and get car-person from Leader
    [Documentation]	Note: This is done to enable working of rpc
        ${resp}		AddCarPerson	${MEMBER2}	${PORT}	${0}
        ${resp}		GetCarPersonMappings	${MEMBER2}	${PORT}	${0}
	Should Be Equal As Strings	${resp.status_code}	200
        Should Contain	${resp.content}	user0
	SLEEP	5

Purchase 100 cars using Follower1 
    [Documentation]  Purchase 100 cars using Follower1
	${resp}		BuyCar	${MEMBER2}	${PORT}	${100}
	${resp}		GetCarPersonMappings	${MEMBER2}	${PORT}	${0}
	Should Be Equal As Strings    ${resp.status_code}    200

Get Cars from Leader
    [Documentation]    Get 100 using Leader
	${resp}		Getcars	${MEMBER1}	${PORT}	${0}
        Should Be Equal As Strings    ${resp.status_code}    200
        Should Contain     ${resp.content}   manufacturer99

Get persons from Leader
    [Documentation]    Get 101 Persons from Leader
	${resp}		GetPersons	${MEMBER1}	${PORT}	${0}
        Should Be Equal As Strings    ${resp.status_code}    200
        Should Contain     ${resp.content}   user100

Get car-person mappings using Leader
   [Documentation] 	Get 101 car-person mappings using Leader to see 100 entry
	${resp}		GetCarPersonMappings	${MEMBER1}	${PORT}	${0}
	Should Be Equal As Strings    ${resp.status_code}    200
	Should Contain     ${resp.content}   user100
