*** Settings ***
Documentation     Test suite for Routed RPC. 
Library           Collections
Library           ../../../libraries/RequestsLibrary.py
Library           ../../../libraries/Common.py
Library           ../../../libraries/CrudLibrary.py
Library           ../../../libraries/SettingsLibrary.py
Library           ../../../libraries/UtilLibrary.py
Library           ../../../libraries/ClusterStateLibrary.py
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

Add car-person mapping and get car-person mapping from Follower1
    [Documentation]     Add car-person and get car-person from Follower1
    [Documentation]  Note: This is done to enable working of rpc
	${resp}		AddCarPerson	${MEMBER2}	${PORT}	${0}
	${resp}		GetCarPersonMappings	${MEMBER2}	${PORT}	${0}
	Should Be Equal As Strings    ${resp.status_code}    200
	Should Contain	${resp.content}	user0

Purchase 100 cars using Follower 
    [Documentation]  Purchase 100 cars using Follower
	SLEEP	10
	${resp}		BuyCar	${MEMBER2}	${PORT}	${100}	
	${resp}		GetCarPersonMappings	${MEMBER2}	${PORT}	${0}
	Should Be Equal As Strings    ${resp.status_code}    200

Get Cars from Leader
    [Documentation]    Get 100 using Leader
	${resp}		Getcars	${MEMBER1}	${PORT}	${0}
	Should Be Equal As Strings    ${resp.status_code}    200
	Should Contain	${resp.content}		manufacturer9

Get persons from Leader
    [Documentation]    Get 11 Persons from Leader
	${resp}		GetPersons	${MEMBER1}	${PORT}	${0}
	Should Be Equal As Strings    ${resp.status_code}    200
	Should Contain	${resp.content}		user100

Get car-person mappings using Leader
   [Documentation] 	Get car-person mappings using Leader to see 100 entry
	${resp}		GetCarPersonMappings	${MEMBER1}	${PORT}	${0}
	Should Be Equal As Strings    ${resp.status_code}    200
	Should Contain	${resp.content}		user100

Stop Leader
   [Documentation] 	Stop Leader controller
	${resp}		Stopcontroller	${MEMBER1}	${USERNAME}	${PASSWORD}	${KARAF_HOME}
	SLEEP	30
	${resp}		Killcontroller	${MEMBER1}	${USERNAME}	${PASSWORD}	${KARAF_HOME}

	
Add cars and get cars from Follower1 
    [Documentation]    Add 100 cars and get added cars from Follower
	${resp}		AddCar	${MEMBER2}	${PORT}	${100}	
	${resp}		Getcars	${MEMBER2}	${PORT}	${0}
	Should Be Equal As Strings    ${resp.status_code}    200
	Should Contain	${resp.content}		manufacturer1

Add persons and get persons from Follower1
    [Documentation]    Add 100 persons and get persons
    [Documentation]    Note: There should be one person added first to enable rpc
	${resp}		AddPerson	${MEMBER2}	${PORT}	${0}	
	${resp}		AddPerson	${MEMBER2}	${PORT}	${100}	
	${resp}		GetPersons	${MEMBER2}	${PORT}	${0}
	Should Be Equal As Strings    ${resp.status_code}    200
	Should Contain	${resp.content}		user5
	SLEEP	10
	
Purchase 100 cars using Follower2 
    [Documentation]  Purchase 100 cars using Follower2
	${resp}		BuyCar	${MEMBER3}	${PORT}	${100}
	SLEEP	10
	${resp}		GetCarPersonMappings	${MEMBER3}	${PORT}	${0}
	Should Be Equal As Strings    ${resp.status_code}    200

Get Cars from Follower1
    [Documentation]    Get 100 using Follower1
	${resp}		Getcars	${MEMBER2}	${PORT}	${0}
	Should Be Equal As Strings    ${resp.status_code}    200
	Should Contain	${resp.content}		manufacturer9

Get persons from Follower1
    [Documentation]    Get 11 Persons from Follower1
	${resp}		GetPersons	${MEMBER2}	${PORT}	${0}
	Should Be Equal As Strings    ${resp.status_code}    200
	Should Contain	${resp.content}		user100

Get car-person mappings using Follower1
   [Documentation] 	Get car-person mappings using Follower1 to see 100 entry
	${resp}		GetCarPersonMappings	${MEMBER2}	${PORT}	${0}
	Should Be Equal As Strings    ${resp.status_code}    200
	Should Contain	${resp.content}		user100

Start Leader
   [Documentation] 	Start Leader controller	
	${resp}		Startcontroller	${MEMBER1}	${USERNAME}	${PASSWORD}	${KARAF_HOME}
	SLEEP	20

