*** Settings ***
Documentation     Checking Network created in OpenStack are pushed to OpenDaylight
Suite Setup	  Create Session    OSSession     http://${OPENSTACK}:9696    headers=${X-AUTH}    
Suite Teardown    Delete All Sessions
Library           SSHLibrary
Library           Collections
Library           OperatingSystem
Library           ../../../libraries/RequestsLibrary.py
Library           ../../../libraries/Common.py
Variables         ../../../variables/Variables.py
 
*** Variables ***
${ODLREST}       /controller/nb/v2/neutron/networks
${OSREST}        /v2.0/networks
${postNet}	{"network":{"name":"odl_network","admin_state_up":true}}
 
*** Test Cases ***
Check OpenStack Networks
	[Documentation]     Checking OpenStack Neutron for known networks
	[Tags]              Network Neutron OpenStack
        Log	${X-AUTH}
        ${resp}		get	OSSession	${OSREST}   
	Should be Equal As Strings	${resp.status_code}	200
        ${OSResult}	To Json		${resp.content}
        Set Suite Variable	${OSResult}
        Log	${OSResult}

Check OpenDaylight Networks
	[Documentation]    Checking OpenDaylight Neutron API for Known Networks
        [Tags] 		   Network Neutron OpenDaylight
        Create Session	ODLSession	http://${CONTROLLER}:${PORT}     headers=${HEADERS}  auth=${AUTH}
        ${resp} 	get	ODLSession	${ODLREST}    
	Should be Equal As Strings	${resp.status_code}	200
        ${ODLResult}	To Json		${resp.content}
        Set Suite Variable	${ODLResult}
        Log	${ODLResult}

Create Network 
	[Documentation]	   Create new network in OpenStack
	[Tags]		   Create Network OpenStack Neutron
        Log   	${postNet}
        ${resp}		post	OSSession	${OSREST}  data=${postNet}  
        Should be Equal As Strings	${resp.status_code}	201
	${result}	To JSON		${resp.content}
	${result}	Get From Dictionary	${result}	network	
        ${NETID}	Get From Dictionary	${result}	id
        Log	${result}
	Log	${NETID}
        Set Global Variable	${NETID}
        sleep    2

Check Network
	[Documentation]	  Check Network created in OpenDaylight
	[Tags]		Check  Network OpenDaylight
	${resp}		get	ODLSession	${ODLREST}/${NetID}
        Should be Equal As Strings	${resp.status_code}	200


