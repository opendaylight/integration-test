*** Settings ***
Documentation     The objective of this testsuite is to test QBGP and ODL for multipath/ECMP support.
...               QBGP should be capable to receive multiple ECMP paths from different DC-GWs and
...               to export the ECMP paths to ODL instead of best path selection.
...               ODL should be capable to receive ECMP paths and it should program the FIB with ECMP paths.
Suite Setup       Start Suite
Suite Teardown    Stop Suite
Resource          ../../../libraries/VpnOperations.robot
Resource          ../../../libraries/OpenStackOperations.robot
Resource          ../../../libraries/OVSDB.robot
Resource          ../../../libraries/Utils.robot
Resource          ../../../variables/Variables.robot
Resource          ../../../variables/netvirt/Variables.robot

*** Variables ***
@{FILES_PATH}     /tmp/${BUNDLEFOLDER}/etc/opendaylight/datastore/initial/config/netvirt-vpnmanager-config.xml    /tmp/${BUNDLEFOLDER}/etc/opendaylight/datastore/initial/config/netvirt-natservice-config.xml    /tmp/${BUNDLEFOLDER}/etc/opendaylight/datastore/initial/config/netvirt-elanmanager-config.xml
${SNAT_DEFAULT_HARD_TIMEOUT}    5
${L3_DEFAULT_HARD_TIMEOUT}    10
${ARP_DEFAULT_HARD_TIMEOUT}    5
@{DEFAULT_HARD_TIMEOUT}    ${L3_DEFAULT_HARD_TIMEOUT}    ${SNAT_DEFAULT_HARD_TIMEOUT}    ${ARP_DEFAULT_HARD_TIMEOUT}
${HARD_TIMEOUT_180}    20
${HARD_TIMEOUT_10}    10
${SNAT_PUNT_TABLE}    46
${L3_PUNT_TABLE}    22
${ARP_PUNT_TABLE_1}    195
${ARP_PUNT_TABLE_2}    196
@{OF_PUNT_TABLES}    ${L3_PUNT_TABLE}    ${SNAT_PUNT_TABLE}    ${ARP_PUNT_TABLE_1}    ${ARP_PUNT_TABLE_2}
${HARD_TIMEOUT_VALUE_ZERO}    0
@{HARD_TIMEOUT_VALUES}    20    30    100    1000    10000

*** Test Cases ***
Verify default hard timeout in XML file in ODL Controller and default flow in OVS for Subnet Route, SNAT and ARP
    [Documentation]    To verify the default value for punt path Subnet Route, SNAT and ARP in the xml file in ODL Controller and default
    ...    flow in OVS for the table 22
    ${snat_napt_switch_ip} =    Get Compute IP From DPIN ID
    : FOR    ${index}    IN RANGE    0    3
    \    BuiltIn.Wait Until Keyword Succeeds    120s    20s    OVSDB.Verify Dump Flows For Specific Table    ${snat_napt_switch_ip}    @{OF_PUNT_TABLES}[${index}]
    \    ...    True    ${EMPTY}    learn(table=@{OF_PUNT_TABLES}[${index}],hard_timeout=@{DEFAULT_HARD_TIMEOUT}[${index}]

Verify No default flow for Subnet Route, SNAT and ARP after hard timeout is set to zero in XML file in ODL Controller
    [Documentation]    To verify the default flow in ovs for Subnet Route, SNAT and ARP after the changing the default value to zero. by change the the value to zero, punt path default flow is deleted.
    : FOR    ${index}    IN RANGE    0    3
    \    Change Hard Timeout Value In XML File    @{FILES_PATH}[${index}]    @{DEFAULT_HARD_TIMEOUT}[${index}]    ${HARD_TIMEOUT_VALUE_ZERO}
    \    Verify Punt Values In XML File    @{FILES_PATH}[${index}]    ${HARD_TIMEOUT_VALUE_ZERO}
    Restart Karaf Using Karaf Shell File
    ${snat_napt_switch_ip} =    Get Compute IP From DPIN ID
    BuiltIn.Wait Until Keyword Succeeds    120s    20s    OVSDB.Check OVS OpenFlow Connections    ${OS_CMP1_IP}    2
    : FOR    ${index}    IN RANGE    0    3
    \    OVSDB.Verify Dump Flows For Specific Table    ${snat_napt_switch_ip}    @{OF_PUNT_TABLES}[${index}]    False    ${EMPTY}    learn(table=@{OF_PUNT_TABLES}[${index}],hard_timeout=@{DEFAULT_HARD_TIMEOUT}[${index}]
    : FOR    ${index}    IN RANGE    0    3
    \    Change Hard Timeout Value In XML File    @{FILES_PATH}[${index}]    ${HARD_TIMEOUT_VALUE_ZERO}    @{DEFAULT_HARD_TIMEOUT}[${index}]
    \    Verify Punt Values In XML File    @{FILES_PATH}[${index}]    @{DEFAULT_HARD_TIMEOUT}[${index}]
    Restart Karaf Using Karaf Shell File
    BuiltIn.Wait Until Keyword Succeeds    120s    20s    OVSDB.Check OVS OpenFlow Connections    ${OS_CMP1_IP}    2
    ${snat_napt_switch_ip} =    Get Compute IP From DPIN ID
    : FOR    ${index}    IN RANGE    0    3
    \    BuiltIn.Wait Until Keyword Succeeds    120s    20s    OVSDB.Verify Dump Flows For Specific Table    ${snat_napt_switch_ip}    @{OF_PUNT_TABLES}[${index}]
    \    ...    True    ${EMPTY}    learn(table=@{OF_PUNT_TABLES}[${index}],hard_timeout=@{DEFAULT_HARD_TIMEOUT}[${index}]

Verify default flow for Subnet Route and ARP after changing hard timeout to different valus in XML file in ODL Controller
    [Documentation]    To verify the default flow in ovs for Subnet Route, SNAT and ARP after the changing the default value to zero. by change the the value to zero, punt path default flow is deleted.
    : FOR    ${index}    IN RANGE    0    3
    \    Change Hard Timeout Value In XML File    @{FILES_PATH}[${index}]    @{DEFAULT_HARD_TIMEOUT}[${index}]    @{HARD_TIMEOUT_VALUES}[0]
    \    Verify Punt Values In XML File    @{FILES_PATH}[${index}]    @{HARD_TIMEOUT_VALUES}[0]
    Restart Karaf Using Karaf Shell File
    BuiltIn.Wait Until Keyword Succeeds    120s    20s    OVSDB.Check OVS OpenFlow Connections    ${OS_CMP1_IP}    2
    ${snat_napt_switch_ip} =    Get Compute IP From DPIN ID
    : FOR    ${index}    IN RANGE    0    3
    \    OVSDB.Verify Dump Flows For Specific Table    ${snat_napt_switch_ip}    @{OF_PUNT_TABLES}[${index}]    True    ${EMPTY}    learn(table=@{OF_PUNT_TABLES}[${index}],hard_timeout=@{HARD_TIMEOUT_VALUES}[0]
    ${cnt}=    Get length    ${HARD_TIMEOUT_VALUES}
    : FOR    ${index}    IN RANGE    1    ${cnt}
    \    Change Hard Timeout Value In XML File    @{FILES_PATH}[0]    @{HARD_TIMEOUT_VALUES}[${index - 1}]    @{HARD_TIMEOUT_VALUES}[${index}]
    \    Verify Punt Values In XML File    @{FILES_PATH}[0]    @{HARD_TIMEOUT_VALUES}[${index}]
    \    Change Hard Timeout Value In XML File    @{FILES_PATH}[2]    @{HARD_TIMEOUT_VALUES}[${index - 1}]    @{HARD_TIMEOUT_VALUES}[${index}]
    \    Verify Punt Values In XML File    @{FILES_PATH}[2]    @{HARD_TIMEOUT_VALUES}[${index}]
    \    Change Hard Timeout Value In XML File    @{FILES_PATH}[1]    @{HARD_TIMEOUT_VALUES}[${index - 1}]    @{HARD_TIMEOUT_VALUES}[${index}]
    \    Verify Punt Values In XML File    @{FILES_PATH}[1]    @{HARD_TIMEOUT_VALUES}[${index}]
    \    Restart Karaf Using Karaf Shell File
    \    BuiltIn.Wait Until Keyword Succeeds    120s    20s    OVSDB.Check OVS OpenFlow Connections    ${OS_CMP1_IP}    2
    \    ${snat_napt_switch_ip} =    Get Compute IP From DPIN ID
    \    BuiltIn.Wait Until Keyword Succeeds    120s    5s    OVSDB.Verify Dump Flows For Specific Table    ${OS_COMPUTE_1_IP}    ${L3_PUNT_TABLE}
    \    ...    True    ${EMPTY}    learn(table=${L3_PUNT_TABLE},hard_timeout=@{HARD_TIMEOUT_VALUES}[${index}]
    \    BuiltIn.Wait Until Keyword Succeeds    120s    5s    OVSDB.Verify Dump Flows For Specific Table    ${OS_COMPUTE_1_IP}    ${ARP_PUNT_TABLE_1}
    \    ...    True    ${EMPTY}    learn(table=${ARP_PUNT_TABLE_1},hard_timeout=@{HARD_TIMEOUT_VALUES}[${index}]
    \    BuiltIn.Wait Until Keyword Succeeds    180s    5s    OVSDB.Verify Dump Flows For Specific Table    ${snat_napt_switch_ip}    ${SNAT_PUNT_TABLE}
    \    ...    True    ${EMPTY}    learn(table=${SNAT_PUNT_TABLE},hard_timeout=@{HARD_TIMEOUT_VALUES}[${index}]
    : FOR    ${index}    IN RANGE    0    3
    \    Change Hard Timeout Value In XML File    @{FILES_PATH}[${index}]    @{HARD_TIMEOUT_VALUES}[4]    @{DEFAULT_HARD_TIMEOUT}[${index}]
    \    Verify Punt Values In XML File    @{FILES_PATH}[${index}]    @{DEFAULT_HARD_TIMEOUT}[${index}]
    Restart Karaf Using Karaf Shell File
    BuiltIn.Wait Until Keyword Succeeds    120s    20s    OVSDB.Check OVS OpenFlow Connections    ${OS_CMP1_IP}    2
    ${snat_napt_switch_ip} =    Get Compute IP From DPIN ID
    : FOR    ${index}    IN RANGE    0    3
    \    BuiltIn.Wait Until Keyword Succeeds    120s    20s    OVSDB.Verify Dump Flows For Specific Table    ${snat_napt_switch_ip}    @{OF_PUNT_TABLES}[${index}]
    \    ...    True    ${EMPTY}    learn(table=@{OF_PUNT_TABLES}[${index}],hard_timeout=@{DEFAULT_HARD_TIMEOUT}[${index}]

*** Keywords ***
Start Suite
    [Documentation]    Start suite to create common setup related SF441 openflow punt path
    VpnOperations.Basic Suite Setup
    Create Dictionary For DPN ID And Compute IP Mapping For All DPNS

Stop Suite
    [Documentation]    Setup start suite
    OpenStackOperations.OpenStack Cleanup All

Restart Karaf Using Karaf Shell File
    [Documentation]    Restarts Karaf and polls log to detect when Karaf is up and running again
    Utils.Run Command On Remote System    ${ODL_SYSTEM_IP}    /tmp/${BUNDLEFOLDER}/bin/stop
    ${status} =    Utils.Run Command On Remote System    ${ODL_SYSTEM_IP}    /tmp/${BUNDLEFOLDER}/bin/status
    BuiltIn.Wait Until Keyword Succeeds    60s    15s    BuiltIn.Should Contain    ${status}    Not Running
    Utils.Run Command On Remote System    ${ODL_SYSTEM_IP}    /tmp/${BUNDLEFOLDER}/bin/start
    ${status} =    Utils.Run Command On Remote System    ${ODL_SYSTEM_IP}    /tmp/${BUNDLEFOLDER}/bin/status
    BuiltIn.Wait Until Keyword Succeeds    60s    15s    BuiltIn.Should Contain    ${status}    Running

Verify Punt Values In XML File
    [Arguments]    ${file_path}    ${value}
    [Documentation]    To verify the default value for SNAT, ARP in ELAN, Subnet Routing in the xml file in ODL Controller
    SSHKeywords.Open_Connection_To_ODL_System
    ${output} =    Utils.Write Commands Until Expected Prompt    cat ${file_path} | grep punt-timeout    ${DEFAULT_LINUX_PROMPT_STRICT}
    @{matches}    BuiltIn.Should Match Regexp    ${output}    punt.timeout.*?([0-9]+)
    BuiltIn.Should be true    @{matches}[1] == ${value}
    SSHLibrary.Close_Connection

Change Hard Timeout Value In XML File
    [Arguments]    ${file_path}    ${value_1}    ${value_2}
    [Documentation]    To change the default value in xml in the ODL controller for subnet route, SNAT and ARP
    SSHKeywords.Open_Connection_To_ODL_System
    Utils.Write Commands Until Expected Prompt    sed -i -e 's/punt-timeout\>${value_1}/punt-timeout\>${value_2}/' ${file_path}    ${DEFAULT_LINUX_PROMPT_STRICT}
    SSHLibrary.Close_Connection

Create Dictionary For DPN ID And Compute IP Mapping For All DPNS
    [Documentation]    Creating dictionary for DPN ID and compute IP mapping
    ${COMPUTE_1_DPNID} =    OVSDB.Get DPID    ${OS_CMP1_IP}
    BuiltIn.Set Suite Variable    ${COMPUTE_1_DPNID}
    ${COMPUTE_2_DPNID} =    OVSDB.Get DPID    ${OS_CMP2_IP}
    BuiltIn.Set Suite Variable    ${COMPUTE_2_DPNID}
    ${CNTL_DPNID} =    OVSDB.Get DPID    ${OS_CNTL_IP}
    BuiltIn.Set Suite Variable    ${CNTL_DPNID}
    ${DPN_TO_COMPUTE_IP} =    BuiltIn.Create Dictionary
    Collections.Set To Dictionary    ${DPN_TO_COMPUTE_IP}    ${COMPUTE_1_DPNID}    ${OS_CMP1_IP}
    Collections.Set To Dictionary    ${DPN_TO_COMPUTE_IP}    ${COMPUTE_2_DPNID}    ${OS_CMP2_IP}
    Collections.Set To Dictionary    ${DPN_TO_COMPUTE_IP}    ${CNTL_DPNID}    ${OS_CNTL_IP}
    Collections.Dictionary Should Contain Key    ${DPN_TO_COMPUTE_IP}    ${COMPUTE_1_DPNID}
    Collections.Dictionary Should Contain Key    ${DPN_TO_COMPUTE_IP}    ${COMPUTE_2_DPNID}
    Collections.Dictionary Should Contain Key    ${DPN_TO_COMPUTE_IP}    ${CNTL_DPNID}
    BuiltIn.Set Suite Variable    ${DPN_TO_COMPUTE_IP}

Get SNAT NAPT Switch DPIN ID
    [Documentation]    Returns the SNAT NAPT Switc dpnid from odl rest call.
    ${output} =    Utils.Run Command On Remote System    ${OS_CMP1_IP}    curl -v -u admin:admin GET http://${ODL_SYSTEM_1_IP}:${RESTCONFPORT}${CONFIG_API}/odl-nat:napt-switches
    @{matches}    BuiltIn.Should Match Regexp    ${output}    switch.id.*?([0-9]+)
    ${dpnid} =    BuiltIn.Convert To Integer    @{matches}[1]
    [Return]    ${dpnid}

Get Compute IP From DPIN ID
    [Documentation]    Returns the SNAT NAPT Switc dpnid from odl rest call.
    ${dpnid} =    Get SNAT NAPT Switch DPIN ID
    ${compute_ip}    Collections.Get From Dictionary    ${DPN_TO_COMPUTE_IP}    ${dpnid}
    [Return]    ${compute_ip}
