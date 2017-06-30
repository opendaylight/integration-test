*** Settings ***
Documentation     Verification that DELETE requests that were run are present in history list with correct operation label
...               and API content and status and time values. Verification that unselecting fill form with received data
...               on request select checkbox results in correct displaying of API and form content and status and time values of DELETE requests.
...               Verification that unselecting save base response data checkbox and deleting t0 and t1 topologies results in
...               correct displaying of API and form content and status and time values of DELETE requests.
...               Verification that unselecting save received data checkbox and deleting t0 and t1 topologies results in
...               correct displaying of API and form content and status and time values, in this case threedots, of DELETE requests.
...               Verification that unselecting save received data checkbox and deleting t0 and t1 topologies results in
...               correct displaying of API and form content and status and time values, in this case threedots, of DELETE requests.
Suite Setup       YangmanKeywords.Open DLUX And Login And Navigate To Yangman URL And Verify Modules Tab Name Translation
Suite Teardown    Selenium2Library.Close Browser
Test Teardown     BuiltIn.Run Keyword If Test Failed    GUIKeywords.Return Webdriver Instance And Log Browser Console Content
Resource          ${CURDIR}/../../../libraries/YangmanKeywords.robot

*** Variables ***
${group_id}       0

*** Test Cases ***
Navigate from Yangman submenu to history tab and delete all history requests and select all checkboxes in history settings
    YangmanKeywords.Navigate To History Tab And Delete All History Requests And Select All History Settings Checkboxes

Put t0 and t1 topologies and delete t0 and t0 topologies and navigate to history
    YangmanKeywords.Navigate To Testing Module Config And Load Topology Topology Id Node In Form And Put T0 And T1 Topologies And Delete T0 And T1 Topologies And Navigate To History Tab

Verify requests that were run are present in history with correct operation label and API content
    YangmanKeywords.Verify Number Of History Requests Displayed Equals To Number Given    4
    @{keys}=    BuiltIn.Create List    ${TOPOLOGY_ID_1}    ${TOPOLOGY_ID_0}
    BuiltIn.Set Suite Variable    @{keys}
    : FOR    ${index}    IN RANGE    0    len(@{keys})
    \    ${key}=    Collections.Get From List    ${keys}    ${index}
    \    YangmanKeywords.Compare Indexed History Request Operation Label With Given Operation Name    ${group_id}    ${index}    DELETE
    \    YangmanKeywords.Verify Indexed History Request Url Label Contains Given Key    ${group_id}    ${index}    ${key}
    YangmanKeywords.Verify History Requests With Given Indeces Contain Data In Api And No Data In Form And Contain Status And Time Data    ${keys}    ${group_id}    0    1

Unselect fill form with received data on request select checkbox and verify API and form content and status and time values
    YangmanKeywords.Open History Requests Settings Dialog And Unselect Fill Form View With Received Data On History Request Select Checkbox
    YangmanKeywords.Click History Requests Settings Dialog Save Button
    YangmanKeywords.Verify History Requests With Given Indeces Contain Data In Api And Form And Contain Status And Time Data    ${keys}    ${group_id}    0    1

Unselect save base response data checkbox and delete t0 and t1 topologies and navigate to history and verify status and time values of new requests are threedots
    YangmanKeywords.Open History Requests Settings Dialog And Unselect Save Base Response Data Select Checkbox
    YangmanKeywords.Click History Requests Settings Dialog Save Button
    YangmanKeywords.Navigate To Testing Module Config And Load Topology Topology Id Node In Form And Put T0 And T1 Topologies And Delete T0 And T1 Topologies And Navigate To History Tab
    @{keys}=    BuiltIn.Create List    ${TOPOLOGY_ID_1}    ${TOPOLOGY_ID_0}    ${TOPOLOGY_ID_1}    ${TOPOLOGY_ID_0}
    YangmanKeywords.Verify History Requests With Given Indeces Contain Data In Api And Form And Do Not Contain Status And Time Data    ${keys}    ${group_id}    0    1
    YangmanKeywords.Verify History Requests With Given Indeces Contain Data In Api And Form And Contain Status And Time Data    ${keys}    ${group_id}    4    5

Unselect save received data checkbox and delete t0 and t1 topologies and navigate to history and verify status and time values of new requests are threedots
    YangmanKeywords.Open History Requests Settings Dialog And Unselect Save Received Data Select Checkbox
    YangmanKeywords.Click History Requests Settings Dialog Save Button
    YangmanKeywords.Navigate To Testing Module Config And Load Topology Topology Id Node In Form And Put T0 And T1 Topologies And Delete T0 And T1 Topologies And Navigate To History Tab
    @{keys}=    BuiltIn.Create List    ${TOPOLOGY_ID_1}    ${TOPOLOGY_ID_0}    ${TOPOLOGY_ID_1}    ${TOPOLOGY_ID_0}    ${TOPOLOGY_ID_1}
    ...    ${TOPOLOGY_ID_0}
    YangmanKeywords.Verify History Requests With Given Indeces Contain Data In Api And Form And Do Not Contain Status And Time Data    ${keys}    ${group_id}    0    1
    YangmanKeywords.Verify History Requests With Given Indeces Contain Data In Api And Form And Do Not Contain Status And Time Data    ${keys}    ${group_id}    4    5
    YangmanKeywords.Verify History Requests With Given Indeces Contain Data In Api And Form And Contain Status And Time Data    ${keys}    ${group_id}    8    9

*** Keywords ***
