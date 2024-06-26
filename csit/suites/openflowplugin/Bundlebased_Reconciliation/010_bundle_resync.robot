*** Settings ***
Documentation       Test suite for verifying Bundle based reconciliation with switch(OVS)

Library             XML
Library             ${CURDIR}/../../../../csit/libraries/XmlComparator.py
Resource            ../../../libraries/Utils.robot
Resource            ../../../libraries/OVSDB.robot
Resource            ../../../libraries/KarafKeywords.robot
Resource            ../../../libraries/FlowLib.robot
Resource            ../../../variables/Variables.robot
Resource            ../../../libraries/DataModels.robot
Resource            ../../../variables/openflowplugin/Variables.robot

Suite Setup         Start Suite
Suite Teardown      End Suite


*** Variables ***
${XMLSDIR}                  ${CURDIR}/../../../../csit/variables/openflowplugin
@{FLOWFILE}                 f279.xml    f280.xml    f281.xml    f282.xml    f283.xml    f284.xml    f278.xml
@{GROUPFILE}                g279.xml    g280.xml    g281.xml
@{GROUP_ID}                 1    2    3
${FLAG_MSG}                 "bundle-based-reconciliation-enabled configuration property was changed to 'true'"
${STATIC_FLOW}              table=91
@{DATA_MODELS}
...                         data/opendaylight-inventory:nodes?${RFC8040_CONFIG_CONTENT}
...                         data/opendaylight-inventory:nodes?${RFC8040_OPERATIONAL_CONTENT}
${INTEGRATION_BRIDGE}       br-int


*** Test Cases ***
TC01_Reconciliation check after switch restart
    [Documentation]    Verify the Bundle based reconciliation with switch(OVS) restart scenario
    Push Static Flow    ${TOOLS_SYSTEM_IP}
    ${switch_idx}    OVSDB.Get DPID    ${TOOLS_SYSTEM_IP}
    Push Flow Via Restcall    ${switch_idx}    ${FLOWFILE[6]}
    Utils.Run Command On Remote System    ${TOOLS_SYSTEM_IP}    sudo service openvswitch-switch restart
    Wait Until Keyword Succeeds    5s    1s    FlowLib.Check Operational Flow    ${True}    ${data}
    Log    Check if static flow is removed in the switch
    ${Ovs1Flow}    Utils.Run Command On Remote System
    ...    ${TOOLS_SYSTEM_IP}
    ...    sudo ovs-ofctl dump-flows ${INTEGRATION_BRIDGE} -OOpenflow13
    Should Not Contain    ${Ovs1Flow}    ${STATIC_FLOW}
    Log    Check if flows are pushed as bundle messages
    ${Resyncdone_msg}    BuiltIn.Set Variable    "Completing bundle based reconciliation for device ID:${switch_idx}"
    Check_Karaf_Log_Message_Count    ${Resyncdone_msg}    1

TC02_Reconcilation check with new switch added
    [Documentation]    Verify the Bundle based reconciliation pushing a group dependent flow in the new switch added
    Push Static Flow    ${TOOLS_SYSTEM_2_IP}
    ${switch_idx}    OVSDB.Get DPID    ${TOOLS_SYSTEM_2_IP}
    Push Groups Via Restcall    ${switch_idx}    0
    Push Flow Via Restcall    ${switch_idx}    ${FLOWFILE[0]}
    Utils.Run Command On Remote System    ${TOOLS_SYSTEM_2_IP}    sudo service openvswitch-switch restart
    Wait Until Keyword Succeeds    5s    1s    FlowLib.Check Operational Flow    ${True}    ${data}
    Log    Check if static flow is removed in the switch
    ${Ovs1Flow}    Utils.Run Command On Remote System
    ...    ${TOOLS_SYSTEM_2_IP}
    ...    sudo ovs-ofctl dump-flows ${INTEGRATION_BRIDGE} -OOpenflow13
    Should Not Contain    ${Ovs1Flow}    ${STATIC_FLOW}
    Log    Check if flows are pushed as bundle messages
    ${Resyncdone_msg}    BuiltIn.Set Variable    "Completing bundle based reconciliation for device ID:${switch_idx}"
    Check_Karaf_Log_Message_Count    ${Resyncdone_msg}    1

TC03_Reconciliation check by pushing group dependent flows
    [Documentation]    Verify the Bundle based reconciliation by pushing multiple group dependent flows
    ${switch_idx}    OVSDB.Get DPID    ${TOOLS_SYSTEM_2_IP}
    FOR    ${index}    IN RANGE    1    3
        Push Groups Via Restcall    ${switch_idx}    ${index}
    END
    FOR    ${index}    IN RANGE    1    6
        Push Flow Via Restcall    ${switch_idx}    ${FLOWFILE[${index}]}
        Set Test Variable    ${flowbody[${index}]}    ${data}
    END
    Utils.Run Command On Remote System    ${TOOLS_SYSTEM_2_IP}    sudo service openvswitch-switch restart
    FOR    ${index}    IN RANGE    1    6
        Wait Until Keyword Succeeds    5s    1s    FlowLib.Check Operational Flow    ${True}    ${flowbody[${index}]}
    END
    Log    Check if flows are pushed as bundle messages
    ${Resyncdone_msg}    BuiltIn.Set Variable    "Completing bundle based reconciliation for device ID:${switch_idx}"
    Check_Karaf_Log_Message_Count    ${Resyncdone_msg}    2


*** Keywords ***
Start Suite
    [Documentation]    Run at start of the suite
    Create Session    session    http://${ODL_SYSTEM_IP}:${RESTCONFPORT}    auth=${AUTH}    headers=${HEADERS_XML}
    KarafKeywords.Issue_Command_On_Karaf_Console
    ...    log:set DEBUG org.opendaylight.openflowplugin.applications.frm.impl.FlowNodeReconciliationImpl
    Check_Karaf_Log_Message_Count    ${FLAG_MSG}    1
    Configure DPN    ${TOOLS_SYSTEM_IP}
    Configure DPN    ${TOOLS_SYSTEM_2_IP}

End Suite
    [Documentation]    Run at end of the suite
    BuiltIn.Run Keyword And Ignore Error    RequestsLibrary.DELETE On Session    session    url=${RFC8040_NODES_API}
    KarafKeywords.Issue_Command_On_Karaf_Console
    ...    log:set INFO org.opendaylight.openflowplugin.applications.frm.impl.FlowNodeReconciliationImpl
    SSHLibrary.Close All Connections

Configure DPN
    [Documentation]    Add the bridge in the DPN specified and set manager,controller for the bridge
    [Arguments]    ${ip}
    Utils.Run Command On Remote System    ${ip}    sudo ovs-vsctl add-br ${INTEGRATION_BRIDGE}
    Utils.Run Command On Remote System    ${ip}    sudo ovs-vsctl set-manager tcp:${ODL_SYSTEM_IP}:6640
    Utils.Run Command On Remote System
    ...    ${ip}
    ...    sudo ovs-vsctl set-controller ${INTEGRATION_BRIDGE} tcp:${ODL_SYSTEM_IP}:6653
    Utils.Run Command On Remote System    ${ip}    sudo ovs-vsctl set bridge ${INTEGRATION_BRIDGE} protocols=OpenFlow13
    Wait Until Keyword Succeeds
    ...    20s
    ...    2s
    ...    DataModels.Get Model Dump
    ...    ${ODL_SYSTEM_IP}
    ...    ${DATA_MODELS}
    ...    ${RFC8040_RESTCONF_ROOT}

Push Static Flow
    [Documentation]    Add Static Flow in the DPN specified
    [Arguments]    ${ip}
    Utils.Run Command On Remote System    ${ip}    sudo ovs-ofctl dump-flows ${INTEGRATION_BRIDGE} -OOpenflow13
    Utils.Run Command On Remote System
    ...    ${ip}
    ...    sudo ovs-ofctl add-flow ${INTEGRATION_BRIDGE} table=91,ipv6,actions=dec_ttl -OOpenflow13

Push Flow Via Restcall
    [Documentation]    Adds Flow to the specified DPN via Restcall
    [Arguments]    ${switch_idx}    ${flowfile}
    FlowLib.Create Flow Variables For Suite From XML File    ${XMLSDIR}/${flowfile}
    FlowLib.Add Flow Via Restconf    ${switch_idx}    ${table_id}    ${data}
    BuiltIn.Set Test Variable    ${switch_idx}
    FlowLib.Check Config Flow    ${True}    ${data}
    Wait Until Keyword Succeeds    5s    1s    FlowLib.Check Operational Flow    ${True}    ${data}

Push Groups Via Restcall
    [Arguments]    ${switch_idx}    ${index}
    ${GROUP_BODY}    OperatingSystem.Get File    ${XMLSDIR}/${GROUPFILE[${index}]}
    ${node_id}    BuiltIn.Set Variable    openflow%3A${switch_idx}
    ${group_id}    BuiltIn.Set Variable    ${GROUP_ID[${index}]}
    FlowLib.Add Group To Controller And Verify    ${GROUP_BODY}    ${node_id}    ${group_id}
    Wait Until Keyword Succeeds
    ...    5s
    ...    1s
    ...    Utils.Get URI And Verify
    ...    ${RFC8040_NODES_API}/node=${node_id}/flow-node-inventory:group=${group_id}?content=nonconfig
