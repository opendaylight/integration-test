*** Settings ***
Documentation     Test suite for verifying Bundle based reconciliation with switch(OVS)
Suite Setup       Start Suite
Suite Teardown    End Suite
Library           XML
Library           ${CURDIR}/../../../../csit/libraries/XmlComparator.py
Resource          ../../../libraries/Utils.robot
Resource          ../../../libraries/OVSDB.robot
Resource          ../../../libraries/KarafKeywords.robot
Resource          ../../../libraries/FlowLib.robot
Variables         ../../../variables/Variables.robot

*** Variables ***
${XMLSDIR}    ${CURDIR}/../../../../csit/variables/openflowplugin
@{FLOWFILE}     f278.xml    f279.xml    f280.xml    f281.xml    f282.xml    f283.xml    f284.xml
@{GROUPFILE}    dumy.xml    g279.xml    g280.xml    g281.xml
@{GROUP_ID}    1    2    3
${FLAG_MSG}    "bundle-based-reconciliation-enabled configuration property was changed to 'true'"
${STATIC_FLOW}    table=91
${LOG_PATH}    ${WORKSPACE}/${BUNDLEFOLDER}/data/log/*
@{FLOWBODY}

*** Testcases ***
TC01_Reconciliation check after switch restart
    [Documentation]    Verify the Bundle based reconciliation with switch(OVS) restart scenario
    Push Static Flow    ${OS_CONTROL_NODE_IP}
    ${switch_idx}    OVSDB.Get DPID    ${OS_CONTROL_NODE_IP}
    Push Flow Via Restcall    ${OS_CONTROL_NODE_IP}    ${FLOWFILE[0]}    ${switch_idx}
    Utils.Run Command On Remote System    ${OS_CONTROL_NODE_IP}    sudo service openvswitch-switch restart
    Wait Until Keyword Succeeds    30s    1s    FlowLib.Check Operational Flow    ${True}    ${data}
    Log    Check if static flow is removed in the switch
    ${Ovs1Flow}    Utils.Run Command On Remote System    ${OS_CONTROL_NODE_IP}    sudo ovs-ofctl dump-flows br-int -OOpenflow13
    Should Not Contain    ${Ovs1Flow}    ${STATIC_FLOW}
    Log    Check if flows are pushed as bundle messages
    BuiltIn.Set Suite Variable    ${RESYNCDONE_MSG}    Completing bundle based reconciliation for device ID:${switch_idx}
    Check Karaf Log Have Messages    ${RESYNCDONE_MSG}    1

TC02_Reconcilation check with new switch added
     [Documentation]    Verify the Bundle based reconciliation pushing a group dependent flow in the new switch added
    Push Static Flow    ${OS_COMPUTE_1_IP}
    Push Groups Via Restcall    ${OS_COMPUTE_1_IP}    1
    ${switch_idx}    OVSDB.Get DPID    ${OS_COMPUTE_1_IP}
    Push Flow Via Restcall    ${OS_COMPUTE_1_IP}    ${FLOWFILE[1]}    ${switch_idx}
    Utils.Run Command On Remote System    ${OS_COMPUTE_1_IP}    sudo service openvswitch-switch restart
    Wait Until Keyword Succeeds    30s    1s    FlowLib.Check Operational Flow    ${True}    ${data}
    Log    Check if static flow is removed in the switch
    ${Ovs1Flow}    Utils.Run Command On Remote System    ${OS_COMPUTE_1_IP}    sudo ovs-ofctl dump-flows br-int -OOpenflow13
    Should Not Contain    ${Ovs1Flow}    ${STATIC_FLOW}
    Log    Check if flows are pushed as bundle messages
    BuiltIn.Set Suite Variable    ${RESYNCDONE_MSG}    Completing bundle based reconciliation for device ID:${switch_idx}
   Check Karaf Log Have Messages    ${RESYNCDONE_MSG}    1

TC03_Reconciliation check by pushing group dependent flows
    [Documentation]    Verify the Bundle based reconciliation by pushing multiple group dependent flows
    ${switch_idx}    OVSDB.Get DPID    ${OS_COMPUTE_1_IP}
    : FOR    ${index}    In Range    2    4
    \    Push Groups Via Restcall    ${OS_COMPUTE_1_IP}    ${index}
    : FOR    ${index}    In Range    2    7
    \    Push Flow Via Restcall    ${OS_COMPUTE_1_IP}    ${FLOWFILE[${index}]}    ${switch_idx}
    \    Set Suite Variable    ${FLOWBODY[${index}]}    ${data}
    Utils.Run Command On Remote System    ${OS_COMPUTE_1_IP}    sudo service openvswitch-switch restart
    : FOR    ${index}    In Range    2    7
    \    Wait Until Keyword Succeeds    30s    1s    FlowLib.Check Operational Flow    ${True}    ${FLOWBODY[${index}]}
    Log    Check if flows are pushed as bundle messages
    ${dpn_id}    OVSDB.Get DPID    ${OS_COMPUTE_1_IP}
    BuiltIn.Set Suite Variable    ${RESYNCDONE_MSG}    Completing bundle based reconciliation for device ID:${dpn_id}
    Check Karaf Log Have Messages    ${RESYNCDONE_MSG}    2

*** Keywords ***
Start Suite
    [Documentation]    Run at start of the suite
    Create Session    session    http://${ODL_SYSTEM_IP}:${RESTCONFPORT}    auth=${AUTH}    headers=${HEADERS_XML}
    KarafKeywords.Issue_Command_On_Karaf_Console    log:set DEBUG org.opendaylight.openflowplugin.applications.frm.impl.FlowNodeReconciliationImpl
    Check Karaf Log Have Messages    ${FLAG_MSG}    1

End Suite
    [Documentation]    Run at end of the suite
    Delete Flows
    Delete Groups
    KarafKeywords.Issue_Command_On_Karaf_Console    log:set INFO org.opendaylight.openflowplugin.applications.frm.impl.FlowNodeReconciliationImpl
    SSHLibrary.Close All Connections

Check Karaf Log Have Messages
    [Arguments]    ${message}    ${count}
    [Documentation]    Checks if Karaf log has Messages the specified number of time
    ${output}    Utils.Run Command On Controller    ${ODL_SYSTEM_IP}    grep -o "${message}" ${LOG_PATH} | wc -l
    Should Be Equal As Strings    ${output}    ${count}

Push Static Flow
    [Arguments]    ${ip}
    [Documentation]    Add Static Flow in the DPN specified
    Log    Add Static Flow
    Utils.Run Command On Remote System    ${ip}    sudo ovs-ofctl add-flow br-int table=91,ipv6,actions=dec_ttl -OOpenflow13

Push Flow Via Restcall
    [Arguments]    ${ip}    ${flowfile}    ${switch_idx}
    [Documentation]    Adds Flow in the DPN specified via Restcall
    FlowLib.Create Flow Variables For Suite From XML File    ${XMLSDIR}/${flowfile}
    FlowLib.Add Flow Via Restconf    ${switch_idx}    ${table_id}    ${data}
    BuiltIn.Set Suite Variable    ${switch_idx}
    BuiltIn.Set Suite Variable    ${data}
    FlowLib.Check Config Flow    ${True}    ${data}
    Wait Until Keyword Succeeds    30s    1s    FlowLib.Check Operational Flow    ${True}    ${data}

Push Groups Via Restcall
    [Arguments]    ${ip}    ${index}
    ${GROUP_BODY}    OperatingSystem.Get File   ${XMLSDIR}/${GROUPFILE[${index}]}
    ${node_id}    OVSDB.Get DPID    ${ip}
    ${node_id}    BuiltIn.Set Variable    openflow:${node_id}
    FlowLib.Add Group To Controller And Verify    ${GROUP_BODY}    ${node_id}    ${GROUP_ID[${index}-1]}

Delete Flows
    : FOR    ${index}    In Range    0    7
    \    ${node_id}    Run Keyword If    ${index} != 0    OVSDB.Get DPID    ${OS_COMPUTE_1_IP}    ELSE    OVSDB.Get DPID    ${OS_CONTROL_NODE_IP}
    \    FlowLib.Create Flow Variables For Suite From XML File    ${XMLSDIR}/${FLOWFILE[${index}]}
    \    FlowLib.Delete Flow Via Restconf    ${node_id}    ${table_id}    ${flow_id}

Delete Groups
    : FOR    ${index}    In Range    1    4
    \    ${node_id}    OVSDB.Get DPID    ${OS_COMPUTE_1_IP}
    \    ${node_id}    BuiltIn.Set Variable    openflow:${node_id}
    \    ${GROUP_BODY}    OperatingSystem.Get File   ${XMLSDIR}/${GROUPFILE[${index}]}
    \    FlowLib.Create Flow Variables For Suite From XML File    ${XMLSDIR}/${FLOWFILE[${index}]}
    \    FlowLib.Remove Group From Controller And Verify    ${node_id}    ${GROUP_ID[${index}-1]}
