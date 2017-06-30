*** Settings ***
Documentation     Verification that PUT requests that were run are present in history list.
...               Verification that running put requests from history using send button with all checkboxes in history
...               settings selected results in correct displaying of API and form content and status and time values of put requests.
...               Verification that running put requests from history using send button with fill form view with received data on history
...               request checkbox unselected results in correct displaying of API and form content and status and time values of put requests.
...               Verification that running put requests from history using send button with save base response data checkbox
...               unselected results in correct displaying of API and form content and status and time values of put requests.
...               Verification that running put requests from history using send button with save received data checkbox
...               unselected results in correct displaying of API and form content and status and time values of put requests.
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

Put t0 and t1 topologies and navigate to history and verify requests are present in history table
    YangmanKeywords.Navigate To Testing Module Config And Load Topology Topology Id Node In Form And Send Key_1 And Key_2 And Navigate To History    ${TOPOLOGY_ID_0}    ${TOPOLOGY_ID_1}    ${PUT_OPTION}    PUT
    YangmanKeywords.Verify Number Of History Requests Displayed Equals To Number Given    2
    @{keys}=    BuiltIn.Create List    ${TOPOLOGY_ID_1}    ${TOPOLOGY_ID_0}
    BuiltIn.Set Suite Variable    @{keys}
    : FOR    ${index}    IN RANGE    0    len(@{keys})
    \    ${key}=    Collections.Get From List    ${keys}    ${index}
    \    YangmanKeywords.Compare Indexed History Request Operation Label With Given Operation Name    0    ${index}    PUT
    \    YangmanKeywords.Verify Indexed History Request Url Label Contains Given Key    0    ${index}    ${key}
    YangmanKeywords.Verify History Requests With Given Indeces Contain Data In Api And No Data In Form And Contain Status And Time Data    ${keys}    ${group_id}    0    1

Send put requests from history using send button and verify requests are displayed in history
    : FOR    ${index}    IN RANGE    0    2
    \    ${number_of_history_requests_displayed}=    YangmanKeywords.Return Number Of History Requests Displayed
    \    YangmanKeywords.Select And Send Indexed History Request From Form    0    1
    \    YangmanKeywords.Return And Check History Contains Last Indexed Request    0    ${number_of_history_requests_displayed}
    : FOR    ${index}    IN RANGE    0    len(@{keys})
    \    ${key}=    Collections.Get From List    ${keys}    ${index}
    \    YangmanKeywords.Compare Indexed History Request Operation Label With Given Operation Name    0    ${index}    PUT
    \    YangmanKeywords.Verify Indexed History Request Url Label Contains Given Key    0    ${index}    ${key}
    YangmanKeywords.Verify History Requests With Given Indeces Contain Data In Api And Error Message In Form And Contain 400 Status And Time Data    ${keys}    ${group_id}    0    1    ${JSON_ERROR_MESSAGE_INPUT_IS_MISSING}
    YangmanKeywords.Verify History Requests With Given Indeces Contain Data In Api And No Data In Form And Contain Status And Time Data    ${keys}    ${group_id}    2    3

Unselect fill form with received data on request select checkbox and send put requests from history using send button and verify API and form content and status and time values
    YangmanKeywords.Open History Requests Settings Dialog And Unselect Fill Form View With Received Data On History Request Select Checkbox
    YangmanKeywords.Click History Requests Settings Dialog Save Button
    : FOR    ${index}    IN RANGE    0    2
    \    ${number_of_history_requests_displayed}=    YangmanKeywords.Return Number Of History Requests Displayed
    \    YangmanKeywords.Select And Send Indexed History Request From Form    0    3
    \    YangmanKeywords.Return And Check History Contains Last Indexed Request    0    ${number_of_history_requests_displayed}
    : FOR    ${index}    IN RANGE    0    len(@{keys})
    \    ${key}=    Collections.Get From List    ${keys}    ${index}
    \    YangmanKeywords.Compare Indexed History Request Operation Label With Given Operation Name    0    ${index}    PUT
    \    YangmanKeywords.Verify Indexed History Request Url Label Contains Given Key    0    ${index}    ${key}
    YangmanKeywords.Verify History Requests With Given Indeces Contain Data In Api And Form And Contain Status And Time Data    ${keys}    ${group_id}    0    1
    YangmanKeywords.Verify History Requests With Given Indeces Contain Data In Api And Error Message In Form And Contain 400 Status And Time Data    ${keys}    ${group_id}    2    3    ${JSON_ERROR_MESSAGE_INPUT_IS_MISSING}
    YangmanKeywords.Verify History Requests With Given Indeces Contain Data In Api And Form And Contain Status And Time Data    ${keys}    ${group_id}    4    5

Unselect save base response data checkbox and send put requests from history using send button and verify status and time values of new requests are threedots
    YangmanKeywords.Open History Requests Settings Dialog And Unselect Save Base Response Data Select Checkbox
    YangmanKeywords.Click History Requests Settings Dialog Save Button
    : FOR    ${index}    IN RANGE    0    2
    \    ${number_of_history_requests_displayed}=    YangmanKeywords.Return Number Of History Requests Displayed
    \    YangmanKeywords.Select And Send Indexed History Request From Form    0    5
    \    YangmanKeywords.Return And Check History Contains Last Indexed Request    0    ${number_of_history_requests_displayed}
    : FOR    ${index}    IN RANGE    0    len(@{keys})
    \    ${key}=    Collections.Get From List    ${keys}    ${index}
    \    YangmanKeywords.Compare Indexed History Request Operation Label With Given Operation Name    ${group_id}    ${index}    PUT
    \    YangmanKeywords.Verify Indexed History Request Url Label Contains Given Key    ${group_id}    ${index}    ${key}
    YangmanKeywords.Verify History Requests With Given Indeces Contain Data In Api And Form And Do Not Contain Status And Time Data    ${keys}    ${group_id}    0    1
    YangmanKeywords.Verify History Requests With Given Indeces Contain Data In Api And Form And Contain Status And Time Data    ${keys}    ${group_id}    2    3
    YangmanKeywords.Verify History Requests With Given Indeces Contain Data In Api And Error Message In Form And Contain 400 Status And Time Data    ${keys}    ${group_id}    4    5    ${JSON_ERROR_MESSAGE_INPUT_IS_MISSING}
    YangmanKeywords.Verify History Requests With Given Indeces Contain Data In Api And Form And Contain Status And Time Data    ${keys}    ${group_id}    6    7

Unselect save received data checkbox and send put requests from history using send button and verify status and time values of new requests are threedots
    YangmanKeywords.Open History Requests Settings Dialog And Unselect Save Received Data Select Checkbox
    YangmanKeywords.Click History Requests Settings Dialog Save Button
    : FOR    ${index}    IN RANGE    0    2
    \    ${number_of_history_requests_displayed}=    YangmanKeywords.Return Number Of History Requests Displayed
    \    YangmanKeywords.Select And Send Indexed History Request From Form    0    7
    \    YangmanKeywords.Return And Check History Contains Last Indexed Request    0    ${number_of_history_requests_displayed}
    : FOR    ${index}    IN RANGE    0    len(@{keys})
    \    ${key}=    Collections.Get From List    ${keys}    ${index}
    \    YangmanKeywords.Compare Indexed History Request Operation Label With Given Operation Name    ${group_id}    ${index}    PUT
    \    YangmanKeywords.Verify Indexed History Request Url Label Contains Given Key    ${group_id}    ${index}    ${key}
    YangmanKeywords.Verify History Requests With Given Indeces Contain Data In Api And Form And Do Not Contain Status And Time Data    ${keys}    ${group_id}    0    1
    YangmanKeywords.Verify History Requests With Given Indeces Contain Data In Api And Form And Do Not Contain Status And Time Data    ${keys}    ${group_id}    2    3
    YangmanKeywords.Verify History Requests With Given Indeces Contain Data In Api And Form And Contain Status And Time Data    ${keys}    ${group_id}    4    5
    YangmanKeywords.Verify History Requests With Given Indeces Contain Data In Api And Error Message In Form And Contain 400 Status And Time Data    ${keys}    ${group_id}    6    7    ${JSON_ERROR_MESSAGE_INPUT_IS_MISSING}
    YangmanKeywords.Verify History Requests With Given Indeces Contain Data In Api And Form And Contain Status And Time Data    ${keys}    ${group_id}    8    9

*** Keywords ***
