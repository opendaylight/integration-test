*** Settings ***
Documentation     Test Suite for verification of TOR usecases
Suite Setup       Basic Suite Setup
Suite Teardown    Basic Suite Teardown
Library           OperatingSystem
Library           Collections
Library           SSHLibrary
Library           RequestsLibrary
Resource          ../../libraries/MininetKeywords.robot
Resource          ../../libraries/Utils.robot
Resource          ../../variables/Variables.robot
Resource          ../../variables/tor/Variables.robot

*** Test Cases ***
Verify TOR Physical Switch Table
    [Documentation]    To verify the physical switch table entry updated in the Verify Logical Switch Table Entry
    Log    Verify OVSDB client dump has Physical Switch Table entries
    ${output}=    Execute Command On TOR    ${GREP_OVSDB_DUMP_PHYSICAL_SWITCH}
    Log    ${output}
    Should Contain    "'${output}'"    "${PHYSICAL_SWITCH_NAME}"
    Should Contain    "'${output}"    "${PHYSICAL_SWITCH_IP}"
    Log    Physical Switch Table entries are present
    Log    Delete VTEP Manager and verify
    ${output}=    Execute Command On TOR    ${VTEP_DEL_MGR}
    Log    ${output}
    ${output}=    Execute Command On TOR    ${GREP_OVSDB_DUMP_MANAGER_TABLE}
    Should Not Contain    "'${output}'"    "${ODL_SYSTEM_IP}"
    ${output}=    Get Network Topology Hwvtep
    Log    ${output}
    Should Not Contain    ${output}    ${PHYSICAL_SWITCH_NAME}
    Should Not Contain    ${output}    ${PHYSICAL_SWITCH_IP}
    Should Not Contain    ${output}    ${ODL_SYSTEM_IP}
    Log    Verified that the entries are not present
    Log    Set manager and verify
    ${set_manager_command}=    Set Variable    ${VTEP_ADD_MGR}:${ODL_SYSTEM_IP}:${OVSDBPORT}
    Log    ${set_manager_command}
    ${output}=    Execute Command On TOR    ${set_manager_command}
    Log    ${output}
    ${output}=    Execute Command On TOR    ${GREP_OVSDB_DUMP_MANAGER_TABLE}
    Log    ${output}
    Should Contain    "'${output}'"    ${ODL_SYSTEM_IP}
    ${output}=    Get Network Topology Hwvtep
    Should Contain    ${output}    ${PHYSICAL_SWITCH_NAME}
    Should Contain    ${output}    ${PHYSICAL_SWITCH_IP}
    Should Contain    ${output}    ${ODL_SYSTEM_IP}
    Log    Verified that the entries are present

*** Keywords ***
Basic Suite Setup
    [Documentation]    Basic Suite Setup required for the TOR Test Suite
    RequestsLibrary.Create Session    alias=session    url=http://${ODL_SYSTEM_IP}:${RESTCONFPORT}    auth=${AUTH}    headers=${HEADERS}
    ${tor_conn_id}=    SSHLibrary.Open Connection    ${TOR_IP}    prompt=${DEFAULT_TOR_PROMPT}    timeout=30s
    Set Suite Variable    ${tor_conn_id}
    Log    ${tor_conn_id}
    ${ovs_conn_id}=    SSHLibrary.Open Connection    ${OVS_SWITCH_IP}    prompt=${DEFAULT_OVS_PROMPT}    timeout=30s
    Set Global Variable    ${ovs_conn_id}
    Log    ${ovs_conn_id}

Basic Suite Teardown
    [Documentation]    Basic Suite Teardown required after the TOR Test Suite
    Switch Connection    ${tor_conn_id}
    Log    ${tor_conn_id}
    close connection
    Switch Connection    ${ovs_conn_id}
    Log    ${ovs_conn_id}
    close connection

Execute Command On TOR
    [Arguments]    ${command}=help
    ${output} =    Run Command On Remote System    ${TOR_IP}    ${command}    user=${TOR_USER}    password=${TOR_PASSWORD}    prompt=${DEFAULT_TOR_PROMPT}
    [Return]    ${output}

Get Network Topology Hwvtep
    [Documentation]    Get all topology, nodes and tunnel switch details
    ${resp} =    RequestsLibrary.Get Request    session    ${OPERATIONAL_NODES_HWTEP}
    Log    ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200
    [Return]    ${resp.content}
