*** Settings ***
Documentation     Verification that executed requests are present in History list.
...               Verification that operations and urls of requests displayed in History tab correspond with operations and urls of requests that have been run.
...               Verification that clicking select all button results in selecting all requests in History list.
...               Verification that clicking deselect all button results in deselecting all requests in History list.
...               Verification that selecting one of history requests and then clicking select all results in all requests being selected,
...               and then clicking deselect all button results in all requests being deselected.
...               Verification that selecting one of history requests and then clicking deselect all results in all requests being deselected,
...               and then clicking select all button results in all requests being selected.
...               Verify that clicking delete all results in deleting all requests in History list.
Suite Setup       YangmanKeywords.Open DLUX And Login And Navigate To Yangman URL And Verify Modules Tab Name Translation
Suite Teardown    Selenium2Library.Close Browser
Test Teardown     BuiltIn.Run Keyword If Test Failed    GUIKeywords.Return Webdriver Instance And Log Browser Console Content
Resource          ${CURDIR}/../../../libraries/YangmanKeywords.robot

*** Variables ***
${group_id}       0

*** Test Cases ***
Navigate from Yangman submenu to history tab and delete all history requests
    YangmanKeywords.Navigate To History Tab And Delete All History Requests

Execute successful Put and Get and Delete operations and navigate to history
    YangmanKeywords.Navigate From Yangman Submenu To Testing Module Config And Load Topology Topology Id Node In Form    ${NETWORK_TOPOLOGY_TESTING_MODULE_NAME}
    @{operations}=    BuiltIn.Create List    ${PUT_OPTION}    ${GET_OPTION}    ${DELETE_OPTION}
    @{operation_names}=    BuiltIn.Create List    PUT    GET    DELETE
    BuiltIn.Set Suite Variable    @{operations}
    : FOR    ${index}    IN RANGE    0    len(@{operations})
    \    ${operation}=    Collections.Get From List    ${operations}    ${index}
    \    ${operation_name}=    Collections.Get From List    ${operation_names}    ${index}
    \    YangmanKeywords.Input Key_1 And Key_2 To Topology Id Input Field And Execute Operation With Checkbox Fill Form Selected And Unselected    ${TOPOLOGY_ID_0}    ${TOPOLOGY_ID_1}    ${operation}    ${operation_name}
    YangmanKeywords.Navigate To History Tab

Verify requests are present in history
    ${number_of_history_requests}=    Return Number Of History Requests Displayed
    BuiltIn.Set Suite Variable    ${number_of_history_requests}
    YangmanKeywords.Verify Number Of History Requests Displayed Equals To Number Given    6

Verify that operations and urls of requests correspond with requests that have been run
    @{operation_names}=    BuiltIn.Create List    DELETE    DELETE    GET    GET    PUT
    ...    PUT
    @{keys}=    BuiltIn.Create List    ${TOPOLOGY_ID_1}    ${TOPOLOGY_ID_0}    ${TOPOLOGY_ID_1}    ${TOPOLOGY_ID_0}    ${TOPOLOGY_ID_1}
    ...    ${TOPOLOGY_ID_0}
    : FOR    ${index}    IN RANGE    0    ${number_of_history_requests}
    \    ${operation_name}=    Collections.Get From List    ${operation_names}    ${index}
    \    ${key}=    Collections.Get From List    ${keys}    ${index}
    \    YangmanKeywords.Compare Indexed History Request Operation Label With Given Operation Name    ${group_id}    ${index}    ${operation_name}
    \    YangmanKeywords.Verify Indexed History Request Url Label Contains Given Key    ${group_id}    ${index}    ${key}

Select all history requests by clicking select all button and verify all requests have been selectd
    YangmanKeywords.Click Select All Button And Verify All Requests Have Been Selected    ${group_id}    ${number_of_history_requests}

Unselect all history requests by clicking deselect all button and verify all requests have been unselectd
    YangmanKeywords.Click Deselect All Button And Verify All Requests Have Been Unselected    ${group_id}    ${number_of_history_requests}

Select one history request then click select all and verify all have been selected and then click deselect all and verify all have been deselected
    : FOR    ${index}    IN RANGE    ${number_of_history_requests}
    \    YangmanKeywords.Select Indexed History Request And Verify Request Is Selected    ${group_id}    ${index}
    \    YangmanKeywords.Click Select All Button And Verify All Requests Have Been Selected    ${group_id}    ${number_of_history_requests}
    \    YangmanKeywords.Click Deselect All Button And Verify All Requests Have Been Unselected    ${group_id}    ${number_of_history_requests}

Select one history request then click deselect all and verify all have been unselected and then click select all and verify all have been selected
    : FOR    ${index}    IN RANGE    ${number_of_history_requests}
    \    YangmanKeywords.Select Indexed History Request And Verify Request Is Selected    ${group_id}    ${index}
    \    YangmanKeywords.Click Select All Button And Verify All Requests Have Been Selected    ${group_id}    ${number_of_history_requests}
    \    YangmanKeywords.Click Deselect All Button And Verify All Requests Have Been Unselected    ${group_id}    ${number_of_history_requests}

Delete all history requests by clicking delete all history requests button
    YangmanKeywords.Delete All History Requests And Verify They Have Been Deleted

*** Keywords ***
