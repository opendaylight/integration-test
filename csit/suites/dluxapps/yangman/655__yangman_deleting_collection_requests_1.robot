*** Settings ***
Documentation     Verification that requests saved in one collection can be deleted from collection one by one using
...               delete selected button. Verification that requests saved in one collection can be deleted from collection
...               one by one using delete request button.
Suite Setup       YangmanKeywords.Open DLUX And Login And Navigate To Yangman URL And Verify Modules Tab Name Translation
Suite Teardown    Selenium2Library.Close Browser
Test Teardown     BuiltIn.Run Keyword If Test Failed    GUIKeywords.Return Webdriver Instance And Log Browser Console Content
Resource          ${CURDIR}/../../../libraries/YangmanKeywords.robot

*** Variables ***
${group_id}       0

*** Test Cases ***
Navigate from Yangman submenu to history tab and delete all history requests and naviaget to collections tab and delete all collections
    YangmanKeywords.Delete All History Requests And Collections And Select All Checkboxes In History And Collections Settings

Execute successful Put and Get and Delete operations and save each request to a single one collection using save to collection button and verify requests presence in the collection
    Execute Successful Put And Get And Delete Operations And Navigate To History And Verify Correct Requests Are Displayed
    : FOR    ${index}    IN RANGE    0    ${number_of_history_requests}
    \    Select History Request And Save It To Collection    0    ${index}    0
    YangmanKeywords.Navigate To Collections Tab
    YangmanKeywords.Verify Number Of Collections Displayed Equals To Number Given    1
    YangmanKeywords.Select And Expand Collection    0
    YangmanKeywords.Verify Number Of Requests Displayed In Indexed Collection Equals To Number Given    0    ${number_of_history_requests}

Delete requests in the collection one by one using delete selected button and verify no requests are displayed in collections tab
    : FOR    ${index}    IN RANGE    0    ${number_of_history_requests}
    \    ${number_of_collection_requests}=    BuiltIn.Evaluate    ${number_of_history_requests}-${index}
    \    YangmanKeywords.Verify Number Of Requests Displayed In Indexed Collection Equals To Number Given    0    ${number_of_collection_requests}
    \    YangmanKeywords.Select Collection Indexed Request And Delete The Request Via Delete Selected Button    0    0
    YangmanKeywords.Verify Number Of Collections Displayed Equals To Number Given    0

Navigate to history and save each request to a single one collection using save to collection button and delete these requests from collection using delete request button
    YangmanKeywords.Navigate To History Tab
    : FOR    ${index}    IN RANGE    0    ${number_of_history_requests}
    \    Select History Request And Save It To Collection    0    ${index}    ${COLLECTION_NAME_0}
    YangmanKeywords.Navigate To Collections Tab
    YangmanKeywords.Verify Number Of Collections Displayed Equals To Number Given    1
    YangmanKeywords.Select And Expand Collection    0
    YangmanKeywords.Verify Number Of Requests Displayed In Indexed Collection Equals To Number Given    0    ${number_of_history_requests}
    : FOR    ${index}    IN RANGE    0    ${number_of_history_requests}
    \    ${number_of_collection_requests}=    BuiltIn.Evaluate    ${number_of_history_requests}-${index}
    \    YangmanKeywords.Verify Number Of Requests Displayed In Indexed Collection Equals To Number Given    0    ${number_of_collection_requests}
    \    YangmanKeywords.Delete Collection Indexed Request Via Delete Request Button    0    0
    YangmanKeywords.Verify Number Of Collections Displayed Equals To Number Given    0

*** Keywords ***
Execute Successful Put And Get And Delete Operations And Navigate To History And Verify Correct Requests Are Displayed
    Put And Get And Delete T0 And T1 Topology IDs With Fill Form Selected And Unselected And Navigate To History
    ${number_of_history_requests}=    BuiltIn.Set Variable    6
    BuiltIn.Set Suite Variable    ${number_of_history_requests}
    YangmanKeywords.Verify Number Of History Requests Displayed Equals To Number Given    ${number_of_history_requests}
    @{operation_names}=    BuiltIn.Create List    DELETE    DELETE    GET    GET    PUT
    ...    PUT
    BuiltIn.Set Suite Variable    @{operation_names}
    : FOR    ${index}    IN RANGE    0    ${number_of_history_requests}
    \    ${operation_name}=    Collections.Get From List    ${operation_names}    ${index}
    \    YangmanKeywords.Compare Indexed History Request Operation Label With Given Operation Name    0    ${index}    ${operation_name}

Put And Get And Delete T0 And T1 Topology IDs With Fill Form Selected And Unselected And Navigate To History
    YangmanKeywords.Navigate From Yangman Submenu To Testing Module Config And Load Topology Topology Id Node In Form    ${NETWORK_TOPOLOGY_TESTING_MODULE_NAME}
    @{operations}=    BuiltIn.Create List    ${PUT_OPTION}    ${GET_OPTION}    ${DELETE_OPTION}
    @{operation_names}=    BuiltIn.Create List    PUT    GET    DELETE
    BuiltIn.Set Suite Variable    @{operations}
    : FOR    ${index}    IN RANGE    0    len(@{operations})
    \    ${operation}=    Collections.Get From List    ${operations}    ${index}
    \    ${operation_name}=    Collections.Get From List    ${operation_names}    ${index}
    \    YangmanKeywords.Input Key_1 And Key_2 To Topology Id Input Field And Execute Operation With Checkbox Fill Form Selected And Unselected    ${TOPOLOGY_ID_0}    ${TOPOLOGY_ID_1}    ${operation}    ${operation_name}
    YangmanKeywords.Navigate To History Tab
