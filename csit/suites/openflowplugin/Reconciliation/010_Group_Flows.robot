*** Settings ***
Documentation     Test suite with independent flow tests
Suite Setup       Initialization Phase
Suite Teardown    Final Phase
Library           XML
Library           OperatingSystem
Library           RequestsLibrary
Resource          ../../../libraries/MininetKeywords.robot
Resource          ../../../libraries/FlowLib.robot
Resource          ../../../libraries/Utils.robot
Variables         ../../../variables/Variables.py

*** Variables ***
${XmlsDir}        ${CURDIR}/../../../variables/xmls
${groupfile1}     g4.xml
${groupfile2}     g5.xml
${flowfile}       f50.xml

*** Test Cases ***
Add Group 1 And Verify In Config Datastore
    [Documentation]    Add a group and verify.
    ${body}=    OperatingSystem.Get File    ${XmlsDir}/${groupfile1}
    FlowLib.Add Group To Controller And Verify    ${body}    openflow:1    1

Verify After Adding Group 1 In Operational DataStore
    [Documentation]    Get the group stats in operational.
    ${elements}=    BuiltIn.Create List    group-statistics    ref-count    packet-count    byte-count    buckets
    ...    weight    group-select
    BuiltIn.Wait Until Keyword Succeeds    10s    2s    Utils.Check For Elements At URI    ${OPERATIONAL_NODES_API}/node/openflow:1/group/1    ${elements}

Add Group 2 And Verify In Config Datastore
    [Documentation]    Add a group and verify.
    ${body}=    OperatingSystem.Get File    ${XmlsDir}/${groupfile2}
    FlowLib.Add Group To Controller And Verify    ${body}    openflow:1    2

Verify After Adding Group 2 In Operational DataStore
    [Documentation]    Get the group stats in operational.
    ${elements}=    BuiltIn.Create List    group-statistics    ref-count    packet-count    byte-count    buckets
    ...    watch_group    watch_port    group-ff
    BuiltIn.Wait Until Keyword Succeeds    10s    2s    Utils.Check For Elements At URI    ${OPERATIONAL_NODES_API}/node/openflow:1/group/2    ${elements}

Add Flow And Verify In Config Datastore
    [Documentation]    Add a flow pointing to the group and verify.
    ${body}    OperatingSystem.Get File    ${XmlsDir}/${flowfile}
    FlowLib.Add Flow To Controller And Verify    ${body}    openflow:1    0    1

Verify After Adding Flow In Operational DataStore
    [Documentation]    Get the flow stats in operational.
    ${elements}=    BuiltIn.Create List    group-action    group-id
    BuiltIn.Wait Until Keyword Succeeds    10s    2s    Utils.Check For Elements At URI    ${OPERATIONAL_NODES_API}/node/openflow:1/table/0/flow/1    ${elements}

Restart Mininet
    [Documentation]    Restart Mininet and verify.
    MininetKeywords.Stop Mininet And Exit    ${mininet_conn_id}
    ${mininet_conn_id}=    MininetKeywords.Start Mininet Single Controller
    BuiltIn.Set Suite Variable    ${mininet_conn_id}
    BuiltIn.Wait Until Keyword Succeeds    10s    1s    Are Switches Connected Topo

Verify Group 1 In Operational DataStore
    [Documentation]    Get the group stats in operational.
    ${elements}=    BuiltIn.Create List    group-statistics    ref-count    packet-count    byte-count    buckets
    ...    weight    group-select
    BuiltIn.Wait Until Keyword Succeeds    10s    2s    Utils.Check For Elements At URI    ${OPERATIONAL_NODES_API}/node/openflow:1/group/1    ${elements}

Verify Group 2 In Operational DataStore
    [Documentation]    Get the group stats in operational.
    ${elements}=    BuiltIn.Create List    group-statistics    ref-count    packet-count    byte-count    buckets
    ...    watch_group    watch_port    group-ff
    BuiltIn.Wait Until Keyword Succeeds    10s    2s    Utils.Check For Elements At URI    ${OPERATIONAL_NODES_API}/node/openflow:1/group/2    ${elements}

Verify Flow In Operational DataStore
    [Documentation]    Get the flow stats in operational.
    ${elements}=    BuiltIn.Create List    group-action    group-id
    BuiltIn.Wait Until Keyword Succeeds    10s    2s    Utils.Check For Elements At URI    ${OPERATIONAL_NODES_API}/node/openflow:1/table/0/flow/1    ${elements}

Remove Flow And Verify In Config Datastore
    [Documentation]    Remove the flow and verify.
    FlowLib.Remove Flow From Controller And Verify    openflow:1    0    1

Verify After Removing Flow In Operational DataStore
    [Documentation]    Get the flow stats in operational.
    BuiltIn.Wait Until Keyword Succeeds    10s    2s    Utils.No Content From URI    session    ${OPERATIONAL_NODES_API}/node/openflow:1/table/0/flow/1

Remove Group 2 And Verify In Config Datastore
    [Documentation]    Remove the group and verify.
    FlowLib.Remove Group From Controller And Verify    openflow:1    2

Verify After Removing Group 2 In Operational DataStore
    [Documentation]    Get the group stats in operational.
    BuiltIn.Wait Until Keyword Succeeds    10s    2s    Utils.No Content From URI    session    ${OPERATIONAL_NODES_API}/node/openflow:1/group/2

Remove Group 1 And Verify In Config Datastore
    [Documentation]    Remove the group and verify.
    FlowLib.Remove Group From Controller And Verify    openflow:1    1

Verify After Removing Group 1 In Operational DataStore
    [Documentation]    Get the group stats in operational.
    BuiltIn.Wait Until Keyword Succeeds    10s    2s    Utils.No Content From URI    session    ${OPERATIONAL_NODES_API}/node/openflow:1/group/1

*** Keywords ***
Initialization Phase
    [Documentation]    Starts mininet and verify if topology is in operational datastore.
    RequestsLibrary.Create Session    session    http://${ODL_SYSTEM_IP}:${RESTCONFPORT}    auth=${AUTH}    headers=${HEADERS_XML}
    ${mininet_conn_id}=    MininetKeywords.Start Mininet Single Controller
    BuiltIn.Set Suite Variable    ${mininet_conn_id}
    BuiltIn.Wait Until Keyword Succeeds    10s    1s    Are Switches Connected Topo

Final Phase
    [Documentation]    Stops mininet.
    MininetKeywords.Stop Mininet And Exit    ${mininet_conn_id}
    RequestsLibrary.Delete All Sessions

Are Switches Connected Topo
    [Documentation]    Checks wheather switches are connected to controller
    ${resp}=    RequestsLibrary.Get Request    session    ${OPERATIONAL_TOPO_API}/topology/flow:1    headers=${ACCEPT_XML}
    Log    ${resp.content}
    ${count}=    XML.Get Element Count    ${resp.content}    xpath=node
    Should Be Equal As Numbers    ${count}    1
