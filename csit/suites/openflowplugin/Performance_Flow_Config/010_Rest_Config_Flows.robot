*** Settings ***
Documentation     Test suite with connection of multiple switches
Suite Setup       Utils.Start Suite
Suite Teardown    Utils.Stop Suite
Library           OperatingSystem
Library           XML
Library           Process
Library           RequestsLibrary
Resource          ../../../libraries/Utils.robot
Variables         ../../../variables/Variables.py

*** Variables ***
${switches}       25
${flows}          2000
${threads}        5
${start}          sudo mn --controller=remote,ip=${ODL_SYSTEM_IP} --topo linear,${switches},1 --switch ovsk,protocols=OpenFlow13
${PERFSCRIPT}     ${CURDIR}/../../../../tools/odl-mdsal-clustering-tests/clustering-performance-test/flow_add_delete_test.py
${PARSESCRIPT}    ${CURDIR}/../../../../tools/odl-mdsal-clustering-tests/clustering-performance-test/create_plot_data_files.py

*** Test Cases ***
Check Switches Connected
    [Documentation]    Checks wheather switches are connected to controller.
    [Setup]    Start Http Session
    Wait Until Keyword Succeeds    5    1    Are Switches Connected    ${switches}
    [Teardown]    Stop Http Session

Configure And Deconfigure Flows
    [Documentation]    Runs the flow peformance script and the script that parses the results to csv file.
    ${result}=    Process.Run Process    ${PERFSCRIPT}    --host    ${ODL_SYSTEM_IP}    --flows    ${flows}
    ...    --threads    ${threads}    --auth    shell=yes
    Log    ${result.stdout}
    OperatingSystem.Create File    out.log.txt    content=${result.stdout}
    Log    ${result.stderr}
    Should Be Equal As Integers    ${result.rc}    0
    ${result}=    Process.Run Process    python    ${PARSESCRIPT}

*** Keywords ***
Start Http Session
    [Documentation]    Starts http session.
    Log    http://${ODL_SYSTEM_IP}:${RESTCONFPORT} auth=${AUTH} headers=${HEADERS_XML}
    RequestsLibrary.Create Session    tcsession    http://${ODL_SYSTEM_IP}:${RESTCONFPORT}    auth=${AUTH}    headers=${HEADERS_XML}

Are Switches Connected
    [Arguments]    ${switches}
    [Documentation]    Checks Topology Contains a fix number ${switches} of switces.
    ${resp}=    RequestsLibrary.Get Request    tcsession    /restconf/operational/network-topology:network-topology/topology/flow:1    headers=${ACCEPT_XML}
    Log    ${resp.content}
    ${count}=    XML.Get Element Count    ${resp.content}    xpath=node
    Should Be Equal As Numbers    ${count}    ${switches}

Stop Http Session
    [Documentation]    Stops http session.
    RequestsLibrary.Delete All Sessions
