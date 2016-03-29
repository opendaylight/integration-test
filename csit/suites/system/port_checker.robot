*** Settings ***
Suite Setup    Get List Of Available Features
Library           String
Library           Collections
Resource          ../../libraries/ClusterKeywords.robot
Resource          ../../libraries/KarafKeywords.robot
Resource          ../../libraries/Utils.robot
Resource          ../../variables/DIDM/Variables.robot
Resource          ../../libraries/ScalarClosures.robot
Resource          ../../libraries/WaitUtils.robot
Resource          ./port_assignments.robot
Variables         ../../variables/Variables.py

*** Variables ***
# to only test a subset of features, define them here, otherwise set @{features_override} to no value to
# get all odl- features
@{features_override}        odl-alto-nonstandard-types    odl-alto-northbound    odl-alto-release    odl-alto-resourcepool    odl-alto-simpleird    odl-alto-spce    odl-alto-standard-northbound-route    odl-alto-standard-resource-translator    odl-alto-standard-service-models    odl-alto-standard-types    odl-benchmark-api    odl-bgpcep-bgp    odl-bgpcep-bgp-all    odl-bgpcep-bgp-benchmark    odl-bgpcep-bgp-dependencies

*** Test Cases ***
Install Features By Project On Fresh Karaf Instance And Check Ports
    @{ODL_FEATURES}=    Set Variable If    ${features_override} != []    ${features_override}    ${ODL_FEATURES}
    : FOR    ${feature}    IN    @{ODL_FEATURES}
    \    Start Karaf Cleanly
    \    ${initial_port_list}=    Get List Of Opened Ports
    \    Log To Console    Installing ${feature}
    \    Install Feature And Wait Until Ports Have All Come Up    ${feature}
    \    Wait Until Keyword Succeeds    30s    5s    Verify Expected Ports Are Listening    ${initial_port_list}    ${feature}

*** Keywords ***
Get List Of Available Features
    [Documentation]    Issue "feature:list" and collect all features starting with "odl-" and set a suite
    ...    variable ${ODL_FEATURES} with that list.
    Start Karaf Cleanly
    ${output}=    Issue Command On Karaf Console    feature:list --no-format -o | grep odl
    @{ODL_FEATURES}=    Create List
    @{lines}=    Split to lines    ${output}
    :FOR    ${line}    IN    @{lines}
    \    ${line}=    Remove String    ${line}    \x1b[43;30m
    \    ${line}=    Remove String    ${line}    \x1b[m\x1b[m
    \    ${feature}    Fetch From Left    ${line}    ${SPACE}
    # need to make sure the prompt doesn't end up as a feature
    \    Run Keyword If    "opendaylight-user" not in $feature    Append To List    ${ODL_FEATURES}    ${feature}
    Set Suite Variable    @{ODL_FEATURES}
    Log    Available features: ${ODL_FEATURES}

Get List Of Opened Ports
    [Documentation]    Create a list of open ports that are owned by a java process
    ${output}=    Run Command On Controller    cmd=sudo netstat -lptun | grep java | awk '{print $4}' | rev | cut -d':' -f 1 | rev
    @{port_list}=    Split String    ${output}    \n
    [Return]    @{port_list}

Install Feature And Wait Until Ports Have All Come Up
    [Arguments]    ${features_to_install}
    : FOR    ${feature}    IN    ${features_to_install}
    \    Issue Command On Karaf Console    feature:install ${feature}    timeout=60s
    # : FOR    ${feature}    IN    ${features_to_install}
    # \    Wait Until Keyword Succeeds    30s    3s    Check Karaf Log Has Messages    "Successfully pushed"    ${feature}
    Wait Until New Ports Are No Longer Coming Up

Wait Until New Ports Are No Longer Coming Up
    # idea here is to try and know when no more new ports have stopped coming up by checking three times over
    # the course of 10s and if port lists are all the same.  Trying this for 30s
    : FOR     ${i}    IN RANGE     3
    \    ${port_check_1}=    Get List Of Opened Ports
    \    Sleep     5s
    \    ${port_check_2}=    Get List Of Opened Ports
    \    Sleep     5s
    \    ${port_check_3}=    Get List Of Opened Ports
    \    Return From Keyword If     "${port_check_1}" == "${port_check_2}" and "${port_check_1}" == "${port_check_3}"
    # if we got here, then ports were changing so failing to point that out
    Fail

Verify Expected Ports Are Listening
    [Arguments]    ${initial_ports}    ${feature}
    ${final_ports}=    Get List Of Opened Ports
    ${expected_ports}=    Create List
    Append To List    ${expected_ports}    @{initial_ports}
    Append To List    ${expected_ports}    @{ports-${feature}}
    Sort List    ${expected_ports}
    Sort List    ${final_ports}
    Lists Should Be Equal    ${expected_ports}    ${final_ports}

Ensure Karaf SSH Port Is Up
    ${ports}=    Get List Of Opened Ports
    Should Contain    ${ports}    ${KARAF_SHELL_PORT}

Start Karaf Cleanly
    Kill One Or More Controllers    ${ODL_SYSTEM_IP}
    Clean One Or More Journals    ${ODL_SYSTEM_IP}
    Clean One Or More Snapshots    ${ODL_SYSTEM_IP}
    Clean One Or More Data Directories    ${ODL_SYSTEM_IP}
    Clean Runtime Configs    ${ODL_SYSTEM_IP}
    Start One Or More Controllers    ${ODL_SYSTEM_IP}
    Wait Until Keyword Succeeds    30s    3s    Ensure Karaf SSH Port Is Up
