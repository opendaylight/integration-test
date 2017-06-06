*** Settings ***
Documentation     Test suite for bug 6917 validation.
Suite Setup       Initialization Phase
Suite Teardown    Final Phase
Library           XML
Library           RequestsLibrary
Resource          ../../../libraries/MininetKeywords.robot
Resource          ../../../libraries/FlowLib.robot
Resource          ../../../variables/Variables.robot

*** Variables ***
${XmlsDir}        ${CURDIR}/../../../variables/xmls
${flowfile1}      f162.xml
${flowfile2}      f163.xml
${flowfile3}      f164.xml
${switch_idx}     1
${switch_name}    s${switch_idx}
${ODL_OF_PORT1}    6653

*** Test Cases ***
Add Flow And Check It Is In Operational DS
    [Documentation]    Add flow match IP and Ethertype IP
    FlowLib.Create Flow Variables For Suite From XML File    ${XmlsDir}/${flowfile1}
    FlowLib.Add Flow Via Restconf    ${switch_idx}    ${table_id}    ${data}
    BuiltIn.Wait Until Keyword Succeeds    10s    1s    FlowLib.Check Datastore Presence    ${flowfile1}    ${True}    ${True}
    ...    ${False}    ${True}

Update Flow With Invalid Match And Check It Is Not In Operational DS
    [Documentation]    Update flow removing Ethertype, this should remove flow from switch and operational DS
    FlowLib.Create Flow Variables For Suite From XML File    ${XmlsDir}/${flowfile2}
    FlowLib.Update Flow Via Restconf    ${switch_idx}    ${table_id}    ${flow_id}    ${data}
    FlowLib.Check Config Flow    ${True}    ${data}
    BuiltIn.Wait Until Keyword Succeeds    10s    1s    Utils.No Content From URI    session    ${OPERATIONAL_NODES_API}/node/openflow:${switch_idx}/table/${table_id}/flow/${flow_id}
    [Teardown]    Report_Failure_Due_To_Bug    7335

Create Two Active Switch To Controller Connections And Check OVS Connections
    [Documentation]    Make a second connection from switch s1 to a controller
    ${controller_opt} =    BuiltIn.Set Variable
    ${controller_opt} =    BuiltIn.Catenate    ${controller_opt}    ${SPACE}tcp:${ODL_SYSTEM_IP}:${ODL_OF_PORT}${SPACE}tcp:${ODL_SYSTEM_IP}:${ODL_OF_PORT1}
    Log    ${controller_opt}
    OVSDB.Set Controller In OVS Bridge    ${TOOLS_SYSTEM_IP}    s1    ${controller_opt}
    ${ovsdb-controller} =    Utils.Run Command On Mininet    ${TOOLS_SYSTEM_IP}    sudo ovs-vsctl list CONTROLLER
    Log    ${ovsdb-controller}
    BuiltIn.Wait Until Keyword Succeeds    10s    1s    OVSDB.Check OVS OpenFlow Connections    ${TOOLS_SYSTEM_IP}    2
    Log    Check OVS configuratiom
    SSHLibrary.Write    sh ovs-vsctl show
    SSHLibrary.Read Until    mininet>

Add Second Flow And Check It Is In Operational DS
    [Documentation]    Add flow match IP and Ethertype IP
    FlowLib.Create Flow Variables For Suite From XML File    ${XmlsDir}/${flowfile3}
    FlowLib.Add Flow Via Restconf    ${switch_idx}    ${table_id}    ${data}
    BuiltIn.Wait Until Keyword Succeeds    10s    1s    FlowLib.Check Datastore Presence    ${flowfile3}    ${True}    ${True}
    ...    ${False}    ${True}

*** Keywords ***
Initialization Phase
    [Documentation]    Starts mininet and verify if topology is in operational datastore.
    ${mininet_conn_id}=    MininetKeywords.Start Mininet Single Controller
    BuiltIn.Set Suite Variable    ${mininet_conn_id}
    RequestsLibrary.Create Session    session    http://${ODL_SYSTEM_IP}:${RESTCONFPORT}    auth=${AUTH}    headers=${HEADERS_XML}
    BuiltIn.Wait Until Keyword Succeeds    10s    1s    FlowLib.Check Switches In Topology    1

Final Phase
    [Documentation]    Stops mininet.
    BuiltIn.Run Keyword And Ignore Error    RequestsLibrary.Delete Request    session    ${CONFIG_NODES_API}
    MininetKeywords.Stop Mininet And Exit    ${mininet_conn_id}
    RequestsLibrary.Delete All Sessions
