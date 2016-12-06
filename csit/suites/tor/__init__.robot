*** Settings ***
Documentation     Test suite for TOR Setup
Suite Setup       Start Suite
Suite Teardown    Stop Suite
Library           SSHLibrary
Library           Collections
Variables         ../../variables/Variables.py
Resource         ../../variables/Variables.robot
Resource          ../../libraries/Utils.robot
Resource          ../../libraries/KarafKeywords.robot
Resource          ../../variables/tor/Variables.robot
*** Variables ***

*** Keywords ***
Start Suite
    [Documentation]    Suite setup for TOR testcases
    Log    Start Suite Setup
    ${tor_conn_id}=    SSHLibrary.Open Connection    ${TOR_IP}    prompt=${DEFAULT_TOR_PROMPT}    timeout=30s
    Set Suite Variable    ${tor_conn_id}
    Log    ${tor_conn_id}
    Flexible SSH Login    ${TOR_USER}    ${TOR_PASSWORD}
    Execute Command    ${REM_OVSDB}
    Execute Command    ${REM_VTEPDB}
    Execute Command    ${EXPORT_OVS_HOME}
    Execute Command    ${CREATE_OVSDB}
    Execute Command    ${CREATE VTEP}
    Execute Command    ${SLEEP1S}
    Execute Command    ${START_OVSDB_SERVER} 
    Execute Command    ${INIT_TOR} 
    Execute Command    ${DETACH_VSWITCHD} 
    Execute Command    ${CREATE_TOR_BRIDGE}  
    Execute Command    ${SLEEP1S}
    ${output} =    Execute Command    ${OVS_SHOW}
    Log    ${output}
    Execute Command    ${ADD_VTEP_PS} 
    Execute Command    ${SET_VTEP_PS}
    Execute Command    ${SLEEP1S}
    Execute Command    ${START_OVSVTEP}

Stop Suite
    Log    Stop the tests
    Switch Connection    ${tor_conn_id}
    Log    ${tor_conn_id}
    Flexible SSH Login    ${TOR_USER}    ${TOR_PASSWORD}
#    Execute Command    ${KILL_VTEP_PROC} 
#    Execute Command    ${KILL_VSWITCHD_PROC}  
#    Execute Command    ${KILL_OVSDB_PROC}
    Execute Command    ${GREP_OVS}	
    close connection
