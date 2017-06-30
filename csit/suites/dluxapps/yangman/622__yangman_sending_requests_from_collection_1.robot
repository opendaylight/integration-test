*** Settings ***
Documentation     Verification that PUT requests that were saved from history to collection are present in collections list.
...               Verification that sending put requests from collections tab using send button with all checkboxes
...               in history settings selected results in correct displaying of API and form content and status and time values of
...               put requests in history.
...               Verification that unselecting fill form with received data on history select checkbox in history list
...               settings results in correct displaying of API and form content and status and time values of put requests in history.
...               Verification that sending put requests from collections tab using send button with save received data
...               checkbox in history settings unselected results in correct displaying of API and form content and status
...               and time values of put requests in history.
...               Verification that sending put requests from collections tab using send button with save base response
...               data checkbox in history settings unselected results in correct displaying of API and form content and status
...               and time values of put requests in history.
Suite Setup       YangmanKeywords.Open DLUX And Login And Navigate To Yangman URL And Verify Modules Tab Name Translation
Suite Teardown    Selenium2Library.Close Browser
Test Teardown     BuiltIn.Run Keyword If Test Failed    GUIKeywords.Return Webdriver Instance And Log Browser Console Content
Resource          ${CURDIR}/../../../libraries/YangmanKeywords.robot

*** Variables ***
${group_id}       0
${collection_id_0}    0
${collection_id_1}    1
${collection_id_2}    2

*** Test Cases ***
Delete all history requests and collections and select all checkboxes in history and collections settings
    YangmanKeywords.Delete All History Requests And Collections And Select All Checkboxes In History And Collections Settings

Put t0 and t1 topologies and save requests from history to a new collection and verify requests are present in collectins tab
    @{keys}=    BuiltIn.Create List    ${TOPOLOGY_ID_1}    ${TOPOLOGY_ID_0}
    BuiltIn.Set Suite Variable    @{keys}
    ${reversed_keys}=    GUIKeywords.Return Reversed List    ${keys}
    BuiltIn.Set Suite Variable    @{reversed_keys}
    YangmanKeywords.Navigate To Testing Module Config And Load Topology Topology Id Node In Form And Send Key_1 And Key_2 And Navigate To History    ${TOPOLOGY_ID_0}    ${TOPOLOGY_ID_1}    ${PUT_OPTION}    PUT
    YangmanKeywords.Verify Number Of History Requests Displayed Equals To Number Given    2
    YangmanKeywords.Save History Requests With Given Indeces To Collection And Verify Number Of Collections And Number Of Requests In Indexed Collection    0    1    ${COLLECTION_NAME_0}    1

Run requests from collections using send button and verify these requests are present in history and verify API and form content and status and time values 1
    Open Collections Settings Dialog And Unselect Fill Form View With Received Data On History Request Select Checkbox
    YangmanKeywords.Click Collections Settings Dialog Save Button
    : FOR    ${index}    IN RANGE    0    2
    \    YangmanKeywords.Select And Send Collection Indexed Request From Form    ${collection_id_0}    ${index}
    YangmanKeywords.Navigate To History Tab
    YangmanKeywords.Verify Number Of History Requests Displayed Equals To Number Given    4
    YangmanKeywords.Compare Indexed History Request Operation Label And Verify Url Label Contains Given Key    PUT    ${reversed_keys}
    YangmanKeywords.Verify History Requests With Given Indeces Contain Data In Api And No Data In Form And Contain Status And Time Data    ${reversed_keys}    ${group_id}    0    1
    YangmanKeywords.Open History Requests Settings Dialog And Unselect Fill Form View With Received Data On History Request Select Checkbox
    YangmanKeywords.Click History Requests Settings Dialog Save Button
    YangmanKeywords.Verify History Requests With Given Indeces Contain Data In Api And Form And Contain Status And Time Data    ${reversed_keys}    ${group_id}    0    1
    YangmanKeywords.Open History Requests Settings Dialog And Unselect Save Received Data Select Checkbox
    YangmanKeywords.Click History Requests Settings Dialog Save Button
    YangmanKeywords.Navigate To Collections Tab

Run requests from collections using send button and verify these requests are present in history and verify API and form content and status and time values 2
    : FOR    ${index}    IN RANGE    0    2
    \    YangmanKeywords.Select And Send Collection Indexed Request From Form    ${collection_id_0}    ${index}
    YangmanKeywords.Navigate To History Tab
    YangmanKeywords.Verify Number Of History Requests Displayed Equals To Number Given    6
    YangmanKeywords.Compare Indexed History Request Operation Label And Verify Url Label Contains Given Key    PUT    ${reversed_keys}
    YangmanKeywords.Verify History Requests With Given Indeces Contain Data In Api And Form And Contain Status And Time Data    ${reversed_keys}    ${group_id}    0    1
    YangmanKeywords.Open History Requests Settings Dialog And Unselect Save Base Response Data Select Checkbox
    YangmanKeywords.Click History Requests Settings Dialog Save Button
    YangmanKeywords.Navigate To Collections Tab

Run requests from collections using send button and verify these requests are present in history and verify API and form content and status and time values 3
    : FOR    ${index}    IN RANGE    0    2
    \    YangmanKeywords.Select And Send Collection Indexed Request From Form    ${collection_id_0}    ${index}
    YangmanKeywords.Navigate To History Tab
    YangmanKeywords.Verify Number Of History Requests Displayed Equals To Number Given    8
    YangmanKeywords.Compare Indexed History Request Operation Label And Verify Url Label Contains Given Key    PUT    ${reversed_keys}
    YangmanKeywords.Verify History Requests With Given Indeces Contain Data In Api And Form And Do Not Contain Status And Time Data    ${reversed_keys}    ${group_id}    0    1
    YangmanKeywords.Select Save Base Response Data And Save Received Data And Fill Form With Received Data On Request Select Checkboxes In History Settings And Save Changes

*** Keywords ***
