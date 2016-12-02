*** Settings ***
Documentation     Test Suite for verification of TOR usecases
Suite Setup       Basic Suite Setup
Library           OperatingSystem
Library           Collections
Library           SSHLibrary
Library           RequestsLibrary
Resource          ../../../libraries/MininetKeywords.robot
Resource          ../../../libraries/Utils.robot
Resource          Variables.robot

*** Test Cases ***
Verify TOR Physical Switch Table
    [Documentation]    To verify the physical switch table entry updated in the Verify Logical Switch Table Entry
    Log    Verify OVSDB client dump has Physical Switch Table entries
    ${output}=    Execute Command On TOR    ${GREP_OVSDB_DUMP_PHYSICAL_SWITCH}
    Log    ${output}
    Should Contain    "'${output}'"    "${PHYSICAL_SWITCH_NAME}"
    Should Contain    "'${output}"    "${PHYSICAL_SWITCH_IP}"
    Log    Physical Switch Table entries present

    Log    To verify that Manager table entries are not present in OVSDB client dump
    ${output}=    Execute Command On TOR    ${GREP_OVSDB_DUMP_MANAGER_TABLE}
    Should Not Contain    "'${output}'"    "${ODL_SYSTEM_IP}"
    Log    Manager table entries are not present

    Log    To verify from the ODL
    #${output}=    Get Data From URI    session    http://${ODL_SYSTEM_IP}:8181${OPERATIONS_API}/network-topology:network-topology/topology/hwvtep:1   
    ${output}=    Get Network Topology Hwvtep
    Should Not Contains    ${PHYSICAL_SWITCH_NAME}
    Should Not Contains    ${PHYSICAL_SWITCH_IP}
    Should Not Contains    ${ODL_SYSTEM_IP}
   
    #    # To set manager to ovs
    #    ${set_manager_command}=    sudo ovs-vsctl set-manager tcp:${CONTROLLER_IP}:6640
    #    ${outpu}=    Execute Command on OVS    ${OVS_IP}    ${set_manager_command}
    #
    #    # To verify that Manager table entries are not present in OVSDB client dump
    #    ${output}=    Execute Command On TOR    ${tor_conn_id}    ${GREP_OVSDB_DUMP_MANAGER_TABLE}
    #    Should Contain    ${output}    ${CONTROLLER_IP}
    #
    #    # To verify from the ODL
    #    ${output}=    Get Network Topology Hwvtep
    #    Should Contains    ${PHYSICAL_SWITCH_NAME}
    #    Should Contains    ${PHYSICAL_SWITCH_IP}
    #    Should Contains    ${CONTROLLER_IP}
    #

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

Execute Command On TOR
    [Arguments]    ${command}=help
    ${output} =    Run Command On Remote System    ${TOR_IP}    ${command}    user=${TOR_USER}    password=${TOR_PASSWORD}    prompt=${DEFAULT_TOR_PROMPT}
    [Return]    ${output}

Get Network Topology Hwvtep
    [Documentation]    Get all topology, nodes and tunnel switch details
    ${resp} =    RequestsLibrary.Get Request    session    ${OPERATIONS_API}/network-topology:network-topology/topology/hwvtep:1
    Log    ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200
    [Return]    ${resp.content}

L
    [Arguments]    ${string}
    Log To Console    ${string}
