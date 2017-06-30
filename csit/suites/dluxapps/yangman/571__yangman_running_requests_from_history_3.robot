*** Settings ***
Documentation     Verification that DELETE requests that were run are present in history list.
...               Verification that running delete requests from history using run request button with all checkboxes in history
...               settings selected results in correct displaying of API and form content and status and time values of delete requests.
...               Verification that running delete requests from history using run request button with fill form view with received data on history
...               request checkbox unselected results in correct displaying of API and form content and status and time values of delete requests.
...               Verification that running delete requests from history using run request button with save base response data checkbox
...               unselected results in correct displaying of API and form content and status and time values of delete requests.
...               Verification that running delete requests from history using run request button with save received data checkbox
...               unselected results in correct displaying of API and form content and status and time values of delete requests.
Suite Setup       YangmanKeywords.Open DLUX And Login And Navigate To Yangman URL And Verify Modules Tab Name Translation
Suite Teardown    Selenium2Library.Close Browser
Test Teardown     BuiltIn.Run Keyword If Test Failed    GUIKeywords.Return Webdriver Instance And Log Browser Console Content
Resource          ${CURDIR}/../../../libraries/YangmanKeywords.robot

*** Variables ***
${group_id}       0

*** Test Cases ***
Navigate from Yangman submenu to history tab and delete all history requests and select all checkboxes in history settings
    YangmanKeywords.Navigate To History Tab And Delete All History Requests
    YangmanKeywords.Select Save Base Response Data And Save Received Data And Fill Form With Received Data On Request Select Checkboxes In History Settings And Save Changes

Delete t0 and t1 topologies and navigate to history and verify requests are present in history table
    YangmanKeywords.Navigate To Testing Module Config And Load Topology Topology Id Node In Form And Send Key_1 And Key_2 And Navigate To History    ${TOPOLOGY_ID_0}    ${TOPOLOGY_ID_1}    ${PUT_OPTION}    PUT
    YangmanKeywords.Delete All History Requests And Verify They Have Been Deleted
    YangmanKeywords.Navigate To Testing Module Config And Load Topology Topology Id Node In Form And Send Key_1 And Key_2 And Navigate To History    ${TOPOLOGY_ID_0}    ${TOPOLOGY_ID_1}    ${DELETE_OPTION}    DELETE
    YangmanKeywords.Verify Number Of History Requests Displayed Equals To Number Given    2
    @{keys}=    BuiltIn.Create List    ${TOPOLOGY_ID_1}    ${TOPOLOGY_ID_0}
    BuiltIn.Set Suite Variable    @{keys}
    : FOR    ${index}    IN RANGE    0    len(@{keys})
    \    ${key}=    Collections.Get From List    ${keys}    ${index}
    \    YangmanKeywords.Compare Indexed History Request Operation Label With Given Operation Name    0    ${index}    DELETE
    \    YangmanKeywords.Verify Indexed History Request Url Label Contains Given Key    0    ${index}    ${key}
    YangmanKeywords.Verify History Requests With Given Indeces Contain Data In Api And No Data In Form And Contain Status And Time Data    ${keys}    ${group_id}    0    1

Run delete requests from history using yangmenu run request button and verify requests are displayed in history
    YangmanKeywords.Navigate To Testing Module Config And Load Topology Topology Id Node In Form And Send Key_1 And Key_2 And Navigate To History    ${TOPOLOGY_ID_0}    ${TOPOLOGY_ID_1}    ${PUT_OPTION}    PUT
    BuiltIn.Repeat Keyword    2 times    YangmanKeywords.Delete History Indexed Request Via Delete Request Button    0    0
    : FOR    ${index}    IN RANGE    0    2
    \    ${number_of_history_requests_displayed}=    YangmanKeywords.Return Number Of History Requests Displayed
    \    YangmanKeywords.Run History Indexed Request Via Run Request Button    0    1
    \    YangmanKeywords.Return And Check History Contains Last Indexed Request    0    ${number_of_history_requests_displayed}
    : FOR    ${index}    IN RANGE    0    len(@{keys})
    \    ${key}=    Collections.Get From List    ${keys}    ${index}
    \    YangmanKeywords.Compare Indexed History Request Operation Label With Given Operation Name    0    ${index}    DELETE
    \    YangmanKeywords.Verify Indexed History Request Url Label Contains Given Key    0    ${index}    ${key}
    YangmanKeywords.Verify History Requests With Given Indeces Contain Data In Api And No Data In Form And Contain Status And Time Data    ${keys}    ${group_id}    0    1
    YangmanKeywords.Verify History Requests With Given Indeces Contain Data In Api And No Data In Form And Contain Status And Time Data    ${keys}    ${group_id}    2    3

Unselect fill form with received data on request select checkbox and verify API and form content and status and time values
    YangmanKeywords.Open History Requests Settings Dialog And Unselect Fill Form View With Received Data On History Request Select Checkbox
    YangmanKeywords.Click History Requests Settings Dialog Save Button
    YangmanKeywords.Verify History Requests With Given Indeces Contain Data In Api And Form And Contain Status And Time Data    ${keys}    ${group_id}    0    1
    YangmanKeywords.Verify History Requests With Given Indeces Contain Data In Api And Form And Contain Status And Time Data    ${keys}    ${group_id}    2    3

Unselect save base response data checkbox and run delete requests from history using yangmenu run request button and verify status and time values of new requests are threedots
    YangmanKeywords.Open History Requests Settings Dialog And Unselect Save Base Response Data Select Checkbox
    YangmanKeywords.Click History Requests Settings Dialog Save Button
    YangmanKeywords.Navigate To Testing Module Config And Load Topology Topology Id Node In Form And Send Key_1 And Key_2 And Navigate To History    ${TOPOLOGY_ID_0}    ${TOPOLOGY_ID_1}    ${PUT_OPTION}    PUT
    BuiltIn.Repeat Keyword    2 times    YangmanKeywords.Delete History Indexed Request Via Delete Request Button    0    0
    : FOR    ${index}    IN RANGE    0    2
    \    ${number_of_history_requests_displayed}=    YangmanKeywords.Return Number Of History Requests Displayed
    \    YangmanKeywords.Run History Indexed Request Via Run Request Button    0    3
    \    YangmanKeywords.Return And Check History Contains Last Indexed Request    0    ${number_of_history_requests_displayed}
    : FOR    ${index}    IN RANGE    0    len(@{keys})
    \    ${key}=    Collections.Get From List    ${keys}    ${index}
    \    YangmanKeywords.Compare Indexed History Request Operation Label With Given Operation Name    ${group_id}    ${index}    DELETE
    \    YangmanKeywords.Verify Indexed History Request Url Label Contains Given Key    ${group_id}    ${index}    ${key}
    YangmanKeywords.Verify History Requests With Given Indeces Contain Data In Api And Form And Do Not Contain Status And Time Data    ${keys}    ${group_id}    0    1
    YangmanKeywords.Verify History Requests With Given Indeces Contain Data In Api And Form And Contain Status And Time Data    ${keys}    ${group_id}    2    3
    YangmanKeywords.Verify History Requests With Given Indeces Contain Data In Api And Form And Contain Status And Time Data    ${keys}    ${group_id}    4    5

Unselect save received data checkbox and delete t0 and t1 topologies and navigate to history and verify status and time values of new requests are threedots
    YangmanKeywords.Open History Requests Settings Dialog And Unselect Save Received Data Select Checkbox
    YangmanKeywords.Click History Requests Settings Dialog Save Button
    YangmanKeywords.Navigate To Testing Module Config And Load Topology Topology Id Node In Form And Send Key_1 And Key_2 And Navigate To History    ${TOPOLOGY_ID_0}    ${TOPOLOGY_ID_1}    ${PUT_OPTION}    PUT
    BuiltIn.Repeat Keyword    2 times    YangmanKeywords.Delete History Indexed Request Via Delete Request Button    0    0
    : FOR    ${index}    IN RANGE    0    2
    \    ${number_of_history_requests_displayed}=    YangmanKeywords.Return Number Of History Requests Displayed
    \    YangmanKeywords.Run History Indexed Request Via Run Request Button    0    5
    \    YangmanKeywords.Return And Check History Contains Last Indexed Request    0    ${number_of_history_requests_displayed}
    : FOR    ${index}    IN RANGE    0    len(@{keys})
    \    ${key}=    Collections.Get From List    ${keys}    ${index}
    \    YangmanKeywords.Compare Indexed History Request Operation Label With Given Operation Name    ${group_id}    ${index}    DELETE
    \    YangmanKeywords.Verify Indexed History Request Url Label Contains Given Key    ${group_id}    ${index}    ${key}
    YangmanKeywords.Verify History Requests With Given Indeces Contain Data In Api And Form And Do Not Contain Status And Time Data    ${keys}    ${group_id}    0    1
    YangmanKeywords.Verify History Requests With Given Indeces Contain Data In Api And Form And Do Not Contain Status And Time Data    ${keys}    ${group_id}    2    3
    YangmanKeywords.Verify History Requests With Given Indeces Contain Data In Api And Form And Contain Status And Time Data    ${keys}    ${group_id}    4    5
    YangmanKeywords.Verify History Requests With Given Indeces Contain Data In Api And Form And Contain Status And Time Data    ${keys}    ${group_id}    6    7

*** Keywords ***
