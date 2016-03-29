*** Settings ***
Suite Setup    Get List Of Available Features
Library           String
Library           Collections
Resource          ../../libraries/ClusterKeywords.robot
Resource          ../../libraries/KarafKeywords.robot
Resource          ../../libraries/Utils.robot
Resource          ../../libraries/ScalarClosures.robot
Resource          ../../libraries/WaitUtils.robot
Resource          ./port_assignments.robot
Variables         ../../variables/Variables.py

*** Variables ***
# to only test a subset of features, define them here, otherwise set @{features_override} to no value to
# get all odl- features
@{features_override}    odl-l2switch-switch-ui    odl-lacp-plugin    odl-lacp-rest    odl-lacp-ui    odl-lispflowmapping-inmemorydb    odl-lispflowmapping-mappingservice    odl-lispflowmapping-mappingservice-shell    odl-lispflowmapping-models    odl-lispflowmapping-msmr    odl-lispflowmapping-neutron    odl-lispflowmapping-southbound    odl-lispflowmapping-ui    odl-lmax    odl-mdsal-all    odl-mdsal-apidocs    odl-mdsal-benchmark    odl-mdsal-binding    odl-mdsal-binding-api    odl-mdsal-binding-base    odl-mdsal-binding-dom-adapter    odl-mdsal-binding-runtime    odl-mdsal-broker    odl-mdsal-broker-local    odl-mdsal-clustering    odl-mdsal-clustering-commons    odl-mdsal-common    odl-mdsal-common    odl-mdsal-distributed-datastore    odl-mdsal-dom    odl-mdsal-dom-api    odl-mdsal-dom-broker    odl-mdsal-models    odl-mdsal-remoterpc-connector    odl-mdsal-xsql    odl-message-bus    odl-message-bus-collector    odl-messaging4transport

*** Test Cases ***
Install Features By Project On Fresh Karaf Instance And Check Ports
    @{ODL_FEATURES}=    Set Variable If    ${features_override} != []    ${features_override}    ${ODL_FEATURES}
    : FOR    ${feature}    IN    @{ODL_FEATURES}
    \    Start Karaf Cleanly
    \    ${initial_tcp_port_list}=    Get List Of Opened Ports    tcp
    \    ${initial_udp_port_list}=    Get List Of Opened Ports    udp
    \    Log To Console    Installing ${feature}
    \    Install Feature And Wait Until Ports Have All Come Up    ${feature}
    \    Wait Until Keyword Succeeds    30s    5s    Verify Expected Ports Are Listening    ${initial_tcp_port_list}    ${initial_udp_port_list}   ${feature}

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

Count List Of Opened Ports
    [Documentation]    Create a list of open ports that are owned by a java process
    ${output}=    Run Command On Controller    cmd=sudo netstat -lptun | grep 'java' | wc -l
    [Return]    ${output}


Get List Of Opened Ports
    [Documentation]    Create a list of open ports that are owned by a java process
    [Arguments]    ${transport_protocol}=${EMPTY}
    ${output}=    Run Command On Controller    cmd=sudo netstat -lptun | grep '${transport_protocol}.*java' | awk '{print $4}' | rev | cut -d':' -f 1 | rev
    @{port_list}=    Split String    ${output}    \n
    # In the case that no ports are listed (which happens frequently for udp) we need to remove
    # the empty element that ends up in the list
    Remove Values From List    ${port_list}    ${EMPTY}
    [Return]    @{port_list}

Install Feature And Wait Until Ports Have All Come Up
    [Arguments]    ${features_to_install}
    : FOR    ${feature}    IN    ${features_to_install}
    \    Issue Command On Karaf Console    feature:install ${feature}    timeout=60s
    Wait Until New Ports Are No Longer Coming Up

Wait Until New Ports Are No Longer Coming Up
    [Documentation]    Wait for some time to allow any loading features to bring up
    ...    any (and all) of it's ports.
    # The below three lines might not be easy to understand on the surface, but the idea
    # is to poll on the number of ports opened and wait until that number stabilizes
    # it's considered stabilized if the number of ports opened has not changed for
    # ${count} times.  The polling interval ${period} and ${timeout} are also defined.
    ${getter}=    ScalarClosures.Closure_From_Keyword_And_Arguments    Count List Of Opened Ports
    ${validator}=    ScalarClosures.Closure_From_Keyword_And_Arguments    WaitUtils.Limiting_Stability_Safe_Stateful_Validator_As_Keyword    state_holder    data_holder    valid_minimum=0
    WaitUtils.Wait_For_Getter_And_Safe_Stateful_Validator_Consecutive_Success    timeout=180s    period=2s    count=10    getter=${getter}    safe_validator=${validator}

Verify Expected Ports Are Listening
    [Arguments]    ${initial_tcp_ports}    ${initial_udp_ports}    ${feature}
    # Check TCP Ports
    ${final_tcp_ports}=    Get List Of Opened Ports    tcp
    ${expected_tcp_ports}=    Create List
    Append To List    ${expected_tcp_ports}    @{initial_tcp_ports}
    Append To List    ${expected_tcp_ports}    @{tcp_ports-${feature}}
    Sort List    ${expected_tcp_ports}
    Sort List    ${final_tcp_ports}
    Lists Should Be Equal    ${expected_tcp_ports}    ${final_tcp_ports}
    # Check UDP Ports
    ${final_udp_ports}=    Get List Of Opened Ports    udp
    ${expected_udp_ports}=    Create List
    # There is a slight difference in how UDP ports are checked.  The port_assignment file
    # is expected to have a tcp_ports variable defined for *every* feature.  So in the
    # above, you can see ${tcp_ports-${feature}} being used.  In order to reduce the overall
    # size of the ports_assignments file, we won't require a ${udp_ports-${feature}} definition
    # unless there is an explicit UDP port being opened.  Because of that, we need to catch
    # the case when it doesn't exist and assign it an empty list.
    @{project_defined_udp_ports}=    Get Variable Value    @{udp_ports-${feature}}    @{EMPTY}
    Append To List    ${expected_tcp_ports}    @{initial_udp_ports}
    Append To List    ${expected_udp_ports}    @{project_defined_udp_ports}
    Sort List    ${expected_udp_ports}
    Sort List    ${final_udp_ports}
    Lists Should Be Equal    ${expected_udp_ports}    ${final_udp_ports}

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
