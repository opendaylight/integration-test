*** Settings ***
Documentation     Verification that collections can be deleted all at once using delete all collections button.
...               Verification that collections can be deleted one by one using delete collection.
Suite Setup       YangmanKeywords.Open DLUX And Login And Navigate To Yangman URL And Verify Modules Tab Name Translation
Suite Teardown    Selenium2Library.Close Browser
Test Teardown     BuiltIn.Run Keyword If Test Failed    GUIKeywords.Return Webdriver Instance And Log Browser Console Content
Resource          ${CURDIR}/../../../libraries/YangmanKeywords.robot

*** Variables ***
${group_id}       0

*** Test Cases ***
Navigate from Yangman submenu to history tab and delete all history requests and naviaget to collections tab and delete all collections
    YangmanKeywords.Delete All History Requests And Collections And Select All Checkboxes In History And Collections Settings

Execute successful Put and Get and Delete operations and save each request to a new collection using save to collection button and verify requests presence in the collection
    Execute Successful Put And Get And Delete Operations And Navigate To History And Verify Correct Requests Are Displayed
    : FOR    ${index}    IN RANGE    0    ${number_of_history_requests}
    \    ${collection_name}=    BuiltIn.Evaluate    str(${index})
    \    YangmanKeywords.Select History Request And Save It To Collection    0    ${index}    ${collection_name}
    YangmanKeywords.Navigate To Collections Tab
    YangmanKeywords.Verify Number Of Collections Displayed Equals To Number Given    ${number_of_history_requests}
    : FOR    ${index}    IN RANGE    0    ${number_of_history_requests}
    \    YangmanKeywords.Select And Expand Collection    ${index}
    \    YangmanKeywords.Verify Number Of Requests Displayed In Indexed Collection Equals To Number Given    ${index}    1

Delete all collections using delete all collections button
    YangmanKeywords.Delete All Collections And Verify They Have Been Deleted

Navigate to history and save each request to a new collection and delete collections one by one using delete collection button
    YangmanKeywords.Navigate To History Tab
    : FOR    ${index}    IN RANGE    0    ${number_of_history_requests}
    \    ${collection_name}=    BuiltIn.Evaluate    str(${index})
    \    YangmanKeywords.Select History Request And Save It To Collection    0    ${index}    ${collection_name}
    YangmanKeywords.Navigate To Collections Tab
    YangmanKeywords.Verify Number Of Collections Displayed Equals To Number Given    ${number_of_history_requests}
    : FOR    ${index}    IN RANGE    0    ${number_of_history_requests}
    \    ${number_of_collections}=    BuiltIn.Evaluate    ${number_of_history_requests}-${index}
    \    YangmanKeywords.Verify Number Of Collections Displayed Equals To Number Given    ${number_of_collections}
    \    YangmanKeywords.Delete Collection Using Delete Collection Button    0

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
