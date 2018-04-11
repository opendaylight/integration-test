*** Settings ***
Documentation     Test suite for Stats Manager flows collection
Suite Setup       Initialization Phase
Suite Teardown    Delete All Sessions
Test Template     Check Datastore Presence
Library           Collections
Library           OperatingSystem
Library           RequestsLibrary
Library           SSHLibrary
Library           XML
Library           ${CURDIR}/../../../../libraries/Common.py
Library           ${CURDIR}/../../../../libraries/XmlComparator.py
Resource          ${CURDIR}/../../../../libraries/CompareStream.robot
Resource          ${CURDIR}/../../../../libraries/FlowLib.robot
Resource          ${CURDIR}/../../../../variables/Variables.robot

*** Variables ***
${flow_update_time}    3s
${XmlsDir}        ${CURDIR}/../../../../variables/xmls
${switch_idx}     1
${switch_name}    s${switch_idx}
@{flowlist0}      f1.xml    f2.xml    f3.xml    f4.xml    f5.xml    f6.xml    f7.xml
...               f8.xml    f9.xml    f10.xml    f11.xml    f14.xml    f15.xml    f16.xml
...               f17.xml    f18.xml    f19.xml    f20.xml    f21.xml    f22.xml    f23.xml
...               f24.xml    f25.xml    f31.xml    f36.xml    f38.xml    f43.xml    f45.xml
...               f101.xml    f102.xml    f103.xml    f104.xml    f105.xml    f106.xml    f107.xml
...               f108.xml    f109.xml    f110.xml    f113.xml    f156.xml    f201.xml    f202.xml
...               f203.xml    f204.xml    f205.xml    f206.xml    f209.xml    f214.xml    f218.xml
...               f219.xml    f220.xml    f221.xml    f222.xml    f223.xml    f224.xml    f225.xml
...               f550.xml

*** Test Cases ***
Test Add Flows Group 0
    [Documentation]    Add all flows and waits for SM to collect data
    [Template]    NONE
    : FOR    ${flowfile}    IN    @{flowlist0}
    \    Log    ${flowfile}
    \    Create Flow Variables For Suite From XML File    ${XmlsDir}/${flowfile}
    \    Run Keyword And Continue On Failure    Add Flow Via Restconf    ${switch_idx}    ${table_id}    ${data}
    # Lets wait for ofp to collect stats
    ${flows}=    Get Length    ${flowlist0}
    Wait Until Keyword Succeeds    30s    2s    FlowLib.Check Flow Stats Are Available    openflow:1    ${flows}
    # Show switch content (for debug purposes if needed)
    Write    dpctl dump-flows -O OpenFlow13
    Read Until    mininet>

Test Is Flow 1 Added
    f1.xml    ${True}    ${True}    ${False}    ${True}

Test Is Flow 2 Added
    f2.xml    ${True}    ${True}    ${False}    ${True}

Test Is Flow 3 Added
    f3.xml    ${True}    ${True}    ${False}    ${True}

Test Is Flow 4 Added
    f4.xml    ${True}    ${True}    ${False}    ${True}

Test Is Flow 5 Added
    f5.xml    ${True}    ${True}    ${False}    ${True}

Test Is Flow 6 Added
    f6.xml    ${True}    ${True}    ${False}    ${True}

Test Is Flow 7 Added
    f7.xml    ${True}    ${True}    ${False}    ${True}

Test Is Flow 8 Added
    f8.xml    ${True}    ${True}    ${False}    ${True}

Test Is Flow 9 Added
    f9.xml    ${True}    ${True}    ${False}    ${True}

Test Is Flow 10 Added
    f10.xml    ${True}    ${True}    ${False}    ${True}

Test Is Flow 11 Added
    f11.xml    ${True}    ${True}    ${False}    ${True}

Test Is Flow 14 Added
    f14.xml    ${True}    ${True}    ${False}    ${True}

Test Is Flow 15 Added
    f15.xml    ${True}    ${True}    ${False}    ${True}

Test Is Flow 16 Added
    f16.xml    ${True}    ${True}    ${False}    ${True}

Test Is Flow 17 Added
    f17.xml    ${True}    ${True}    ${False}    ${True}

Test Is Flow 18 Added
    f18.xml    ${True}    ${True}    ${False}    ${True}

Test Is Flow 19 Added
    f19.xml    ${True}    ${True}    ${False}    ${True}

Test Is Flow 20 Added
    f20.xml    ${True}    ${True}    ${False}    ${True}

Test Is Flow 21 Added
    f21.xml    ${True}    ${True}    ${False}    ${True}

Test Is Flow 22 Added
    f22.xml    ${True}    ${True}    ${False}    ${True}

Test Is Flow 23 Added
    f23.xml    ${True}    ${True}    ${False}    ${True}

Test Is Flow 24 Added
    f24.xml    ${True}    ${True}    ${False}    ${True}

Test Is Flow 25 Added
    f25.xml    ${True}    ${True}    ${False}    ${True}

Test Is Flow 31 Added
    f31.xml    ${True}    ${True}    ${False}    ${True}

Test Is Flow 36 Added
    f36.xml    ${True}    ${True}    ${False}    ${True}

Test Is Flow 38 Added
    f38.xml    ${True}    ${True}    ${False}    ${True}

Test Is Flow 43 Added
    f43.xml    ${True}    ${True}    ${False}    ${True}

Test Is Flow 45 Added
    f45.xml    ${True}    ${True}    ${False}    ${True}

Test Is Flow 101 Added
    f101.xml    ${True}    ${True}    ${False}    ${True}

Test Is Flow 102 Added
    f102.xml    ${True}    ${True}    ${False}    ${True}

Test Is Flow 103 Added
    f103.xml    ${True}    ${True}    ${False}    ${True}

Test Is Flow 104 Added
    f104.xml    ${True}    ${True}    ${False}    ${True}

Test Is Flow 105 Added
    f105.xml    ${True}    ${True}    ${False}    ${True}

Test Is Flow 106 Added
    f106.xml    ${True}    ${True}    ${False}    ${True}

Test Is Flow 107 Added
    f107.xml    ${True}    ${True}    ${False}    ${True}

Test Is Flow 108 Added
    f108.xml    ${True}    ${True}    ${False}    ${True}

Test Is Flow 109 Added
    f109.xml    ${True}    ${True}    ${False}    ${True}

Test Is Flow 110 Added
    f110.xml    ${True}    ${True}    ${False}    ${True}

Test Is Flow 113 Added
    f113.xml    ${True}    ${True}    ${False}    ${True}

Test Is Flow 156 Added
    f156.xml    ${True}    ${True}    ${False}    ${True}

Test Is Flow 201 Added
    f201.xml    ${True}    ${True}    ${False}    ${True}

Test Is Flow 202 Added
    f202.xml    ${True}    ${True}    ${False}    ${True}

Test Is Flow 203 Added
    f203.xml    ${True}    ${True}    ${False}    ${True}

Test Is Flow 204 Added
    f204.xml    ${True}    ${True}    ${False}    ${True}

Test Is Flow 205 Added
    f205.xml    ${True}    ${True}    ${False}    ${True}

Test Is Flow 206 Added
    f206.xml    ${True}    ${True}    ${False}    ${True}

Test Is Flow 209 Added
    f209.xml    ${True}    ${True}    ${False}    ${True}

Test Is Flow 214 Added
    f214.xml    ${True}    ${True}    ${False}    ${True}

Test Is Flow 218 Added
    f218.xml    ${True}    ${True}    ${False}    ${True}

Test Is Flow 219 Added
    f219.xml    ${True}    ${True}    ${False}    ${True}

Test Is Flow 220 Added
    f220.xml    ${True}    ${True}    ${False}    ${True}

Test Is Flow 221 Added
    f221.xml    ${True}    ${True}    ${False}    ${True}

Test Is Flow 222 Added
    f222.xml    ${True}    ${True}    ${False}    ${True}

Test Is Flow 223 Added
    f223.xml    ${True}    ${True}    ${False}    ${True}

Test Is Flow 224 Added
    f224.xml    ${True}    ${True}    ${False}    ${True}

Test Is Flow 225 Added
    f225.xml    ${True}    ${True}    ${False}    ${True}

Test Is Flow 550 Added
    f550.xml    ${True}    ${True}    ${False}    ${True}

Test Update Flows Group 0
    [Documentation]    Update all flows and waits for SM to collect data
    [Template]    NONE
    : FOR    ${flowfile}    IN    @{flowlist0}
    \    Log    ${flowfile}
    \    Create Flow Variables For Suite From XML File    ${XmlsDir}/${flowfile}
    \    Run Keyword And Continue On Failure    Update Flow Via Restconf    ${switch_idx}    ${table_id}    ${flow_id}    ${upddata}
    # Lets wait for ofp to collect stats
    Sleep    ${flow_update_time}
    # Show switch content (for debug purposes if needed)
    Write    dpctl dump-flows -O OpenFlow13
    Read Until    mininet>

Test Is Flow 1 Updated
    f1.xml    ${True}    ${True}    ${True}    ${True}

Test Is Flow 2 Updated
    f2.xml    ${True}    ${True}    ${True}    ${True}

Test Is Flow 3 Updated
    f3.xml    ${True}    ${True}    ${True}    ${True}

Test Is Flow 4 Updated
    f4.xml    ${True}    ${True}    ${True}    ${True}

Test Is Flow 5 Updated
    f5.xml    ${True}    ${True}    ${True}    ${True}

Test Is Flow 6 Updated
    f6.xml    ${True}    ${True}    ${True}    ${True}

Test Is Flow 7 Updated
    f7.xml    ${True}    ${True}    ${True}    ${True}

Test Is Flow 8 Updated
    f8.xml    ${True}    ${True}    ${True}    ${True}

Test Is Flow 9 Updated
    f9.xml    ${True}    ${True}    ${True}    ${True}

Test Is Flow 10 Updated
    f10.xml    ${True}    ${True}    ${True}    ${True}

Test Is Flow 11 Updated
    f11.xml    ${True}    ${True}    ${True}    ${True}

Test Is Flow 14 Updated
    f14.xml    ${True}    ${True}    ${True}    ${True}

Test Is Flow 15 Updated
    f15.xml    ${True}    ${True}    ${True}    ${True}

Test Is Flow 16 Updated
    f16.xml    ${True}    ${True}    ${True}    ${True}

Test Is Flow 17 Updated
    f17.xml    ${True}    ${True}    ${True}    ${True}

Test Is Flow 18 Updated
    f18.xml    ${True}    ${True}    ${True}    ${True}

Test Is Flow 19 Updated
    f19.xml    ${True}    ${True}    ${True}    ${True}

Test Is Flow 20 Updated
    f20.xml    ${True}    ${True}    ${True}    ${True}

Test Is Flow 21 Updated
    f21.xml    ${True}    ${True}    ${True}    ${True}

Test Is Flow 22 Updated
    f22.xml    ${True}    ${True}    ${True}    ${True}

Test Is Flow 23 Updated
    f23.xml    ${True}    ${True}    ${True}    ${True}

Test Is Flow 24 Updated
    f24.xml    ${True}    ${True}    ${True}    ${True}

Test Is Flow 25 Updated
    f25.xml    ${True}    ${True}    ${True}    ${True}

Test Is Flow 31 Updated
    f31.xml    ${True}    ${True}    ${True}    ${True}

Test Is Flow 36 Updated
    f36.xml    ${True}    ${True}    ${True}    ${True}

Test Is Flow 38 Updated
    f38.xml    ${True}    ${True}    ${True}    ${True}

Test Is Flow 43 Updated
    f43.xml    ${True}    ${True}    ${True}    ${True}

Test Is Flow 45 Updated
    f45.xml    ${True}    ${True}    ${True}    ${True}

Test Is Flow 101 Updated
    f101.xml    ${True}    ${True}    ${True}    ${True}

Test Is Flow 102 Updated
    f102.xml    ${True}    ${True}    ${True}    ${True}

Test Is Flow 103 Updated
    f103.xml    ${True}    ${True}    ${True}    ${True}

Test Is Flow 104 Updated
    f104.xml    ${True}    ${True}    ${True}    ${True}

Test Is Flow 105 Updated
    f105.xml    ${True}    ${True}    ${True}    ${True}

Test Is Flow 106 Updated
    f106.xml    ${True}    ${True}    ${True}    ${True}

Test Is Flow 107 Updated
    f107.xml    ${True}    ${True}    ${True}    ${True}

Test Is Flow 108 Updated
    f108.xml    ${True}    ${True}    ${True}    ${True}

Test Is Flow 109 Updated
    f109.xml    ${True}    ${True}    ${True}    ${True}

Test Is Flow 110 Updated
    f110.xml    ${True}    ${True}    ${True}    ${True}

Test Is Flow 113 Updated
    f113.xml    ${True}    ${True}    ${True}    ${True}

Test Is Flow 156 Updated
    f156.xml    ${True}    ${True}    ${True}    ${True}

Test Is Flow 201 Updated
    f201.xml    ${True}    ${True}    ${True}    ${True}

Test Is Flow 202 Updated
    f202.xml    ${True}    ${True}    ${True}    ${True}

Test Is Flow 203 Updated
    f203.xml    ${True}    ${True}    ${True}    ${True}

Test Is Flow 204 Updated
    f204.xml    ${True}    ${True}    ${True}    ${True}

Test Is Flow 205 Updated
    f205.xml    ${True}    ${True}    ${True}    ${True}

Test Is Flow 206 Updated
    f206.xml    ${True}    ${True}    ${True}    ${True}

Test Is Flow 209 Updated
    f209.xml    ${True}    ${True}    ${True}    ${True}

Test Is Flow 214 Updated
    f214.xml    ${True}    ${True}    ${True}    ${True}

Test Is Flow 218 Updated
    f218.xml    ${True}    ${True}    ${True}    ${True}

Test Is Flow 219 Updated
    f219.xml    ${True}    ${True}    ${True}    ${True}

Test Is Flow 220 Updated
    f220.xml    ${True}    ${True}    ${True}    ${True}

Test Is Flow 221 Updated
    f221.xml    ${True}    ${True}    ${True}    ${True}

Test Is Flow 222 Updated
    f222.xml    ${True}    ${True}    ${True}    ${True}

Test Is Flow 223 Updated
    f223.xml    ${True}    ${True}    ${True}    ${True}

Test Is Flow 224 Updated
    f224.xml    ${True}    ${True}    ${True}    ${True}

Test Is Flow 225 Updated
    f225.xml    ${True}    ${True}    ${True}    ${True}

Test Is Flow 550 Updated
    f550.xml    ${True}    ${True}    ${True}    ${True}

Test Delete Flows Group 0
    [Documentation]    Delete all flows and waits for SM to collect data
    [Template]    NONE
    : FOR    ${flowfile}    IN    @{flowlist0}
    \    Log    ${flowfile}
    \    Create Flow Variables For Suite From XML File    ${XmlsDir}/${flowfile}
    \    Run Keyword And Continue On Failure    Delete Flow Via Restconf    ${switch_idx}    ${table_id}    ${flow_id}
    # Lets wait for ofp to collect stats
    Sleep    ${flow_update_time}
    # Show switch content (for debug purposes if needed)
    Write    dpctl dump-flows -O OpenFlow13
    Read Until    mininet>

Test Is Flow 1 Deleted
    f1.xml    ${False}    ${False}    ${True}

Test Is Flow 2 Deleted
    f2.xml    ${False}    ${False}    ${True}

Test Is Flow 3 Deleted
    f3.xml    ${False}    ${False}    ${True}

Test Is Flow 4 Deleted
    f4.xml    ${False}    ${False}    ${True}

Test Is Flow 5 Deleted
    f5.xml    ${False}    ${False}    ${True}

Test Is Flow 6 Deleted
    f6.xml    ${False}    ${False}    ${True}

Test Is Flow 7 Deleted
    f7.xml    ${False}    ${False}    ${True}

Test Is Flow 8 Deleted
    f8.xml    ${False}    ${False}    ${True}

Test Is Flow 9 Deleted
    f9.xml    ${False}    ${False}    ${True}

Test Is Flow 10 Deleted
    f10.xml    ${False}    ${False}    ${True}

Test Is Flow 11 Deleted
    f11.xml    ${False}    ${False}    ${True}

Test Is Flow 14 Deleted
    f14.xml    ${False}    ${False}    ${True}

Test Is Flow 15 Deleted
    f15.xml    ${False}    ${False}    ${True}

Test Is Flow 16 Deleted
    f16.xml    ${False}    ${False}    ${True}

Test Is Flow 17 Deleted
    f17.xml    ${False}    ${False}    ${True}

Test Is Flow 18 Deleted
    f18.xml    ${False}    ${False}    ${True}

Test Is Flow 19 Deleted
    f19.xml    ${False}    ${False}    ${True}

Test Is Flow 20 Deleted
    f20.xml    ${False}    ${False}    ${True}

Test Is Flow 21 Deleted
    f21.xml    ${False}    ${False}    ${True}

Test Is Flow 22 Deleted
    f22.xml    ${False}    ${False}    ${True}

Test Is Flow 23 Deleted
    f23.xml    ${False}    ${False}    ${True}

Test Is Flow 24 Deleted
    f24.xml    ${False}    ${False}    ${True}

Test Is Flow 25 Deleted
    f25.xml    ${False}    ${False}    ${True}

Test Is Flow 31 Deleted
    f31.xml    ${False}    ${False}    ${True}

Test Is Flow 36 Deleted
    f36.xml    ${False}    ${False}    ${True}

Test Is Flow 38 Deleted
    f38.xml    ${False}    ${False}    ${True}

Test Is Flow 43 Deleted
    f43.xml    ${False}    ${False}    ${True}

Test Is Flow 45 Deleted
    f45.xml    ${False}    ${False}    ${True}

Test Is Flow 101 Deleted
    f101.xml    ${False}    ${False}    ${True}

Test Is Flow 102 Deleted
    f102.xml    ${False}    ${False}    ${True}

Test Is Flow 103 Deleted
    f103.xml    ${False}    ${False}    ${True}

Test Is Flow 104 Deleted
    f104.xml    ${False}    ${False}    ${True}

Test Is Flow 105 Deleted
    f105.xml    ${False}    ${False}    ${True}

Test Is Flow 106 Deleted
    f106.xml    ${False}    ${False}    ${True}

Test Is Flow 107 Deleted
    f107.xml    ${False}    ${False}    ${True}

Test Is Flow 108 Deleted
    f108.xml    ${False}    ${False}    ${True}

Test Is Flow 109 Deleted
    f109.xml    ${False}    ${False}    ${True}

Test Is Flow 110 Deleted
    f110.xml    ${False}    ${False}    ${True}

Test Is Flow 113 Deleted
    f113.xml    ${False}    ${False}    ${True}

Test Is Flow 156 Deleted
    f156.xml    ${False}    ${False}    ${True}

Test Is Flow 201 Deleted
    f201.xml    ${False}    ${False}    ${True}

Test Is Flow 202 Deleted
    f202.xml    ${False}    ${False}    ${True}

Test Is Flow 203 Deleted
    f203.xml    ${False}    ${False}    ${True}

Test Is Flow 204 Deleted
    f204.xml    ${False}    ${False}    ${True}

Test Is Flow 205 Deleted
    f205.xml    ${False}    ${False}    ${True}

Test Is Flow 206 Deleted
    f206.xml    ${False}    ${False}    ${True}

Test Is Flow 209 Deleted
    f209.xml    ${False}    ${False}    ${True}

Test Is Flow 214 Deleted
    f214.xml    ${False}    ${False}    ${True}

Test Is Flow 218 Deleted
    f218.xml    ${False}    ${False}    ${True}

Test Is Flow 219 Deleted
    f219.xml    ${False}    ${False}    ${True}

Test Is Flow 220 Deleted
    f220.xml    ${False}    ${False}    ${True}

Test Is Flow 221 Deleted
    f221.xml    ${False}    ${False}    ${True}

Test Is Flow 222 Deleted
    f222.xml    ${False}    ${False}    ${True}

Test Is Flow 223 Deleted
    f223.xml    ${False}    ${False}    ${True}

Test Is Flow 224 Deleted
    f224.xml    ${False}    ${False}    ${True}

Test Is Flow 225 Deleted
    f225.xml    ${False}    ${False}    ${True}

Test Is Flow 550 Deleted
    f550.xml    ${False}    ${False}    ${True}

*** Keywords ***
Initialization Phase
    [Documentation]    Initiate tcp connection with controller
    BuiltIn.Wait Until Keyword Succeeds    5x    1s    FlowLib.Check Switches In Inventory    1
    Create Session    session    http://${ODL_SYSTEM_IP}:${RESTCONFPORT}    auth=${AUTH}    headers=${HEADERS_XML}
    Write    dpctl dump-flows -O OpenFlow13
    Read Until    mininet>
