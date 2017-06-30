*** Settings ***
Documentation     Verification that data DELETE from form with checkbox Fill form with received data after execution selected [unselected]
...               are erased from the form together with topology id input field and remain filled in API [remain filled in form and API].
...               The data are not displayed in Received data code mirror [are not displayed in Received data code mirror].
...               Verification that data DELETE from json with checkbox Fill form with received data after execution selected [unselected]
...               are not displayed in Received data code mirror and are displayed in the form and form API.
Suite Setup       YangmanKeywords.Open DLUX And Login And Navigate To Yangman URL And Verify Modules Tab Name Translation
Suite Teardown    Selenium2Library.Close Browser
Test Teardown     BuiltIn.Run Keyword If Test Failed    GUIKeywords.Return Webdriver Instance And Log Browser Console Content
Resource          ${CURDIR}/../../../libraries/YangmanKeywords.robot

*** Variables ***

*** Test Cases ***
Delete Topology Topology Id From Form With Fill Form Checkbox Selected/ Unselected And Verify Data Presence In Json
    YangmanKeywords.Navigate From Yangman Submenu To Testing Module Config And Load Topology Topology Id Node In Form    ${NETWORK_TOPOLOGY_TESTING_MODULE_NAME}
    ${topology_label_without_curly_braces_part}=    YangmanKeywords.Return Branch Label Without Curly Braces Part    ${TOPOLOGY_TOPOLOGY_ID_LABEL}
    ${topology_id_label_curly_braces_part}=    YangmanKeywords.Return Branch Label Curly Braces Part Without Braces    ${TOPOLOGY_TOPOLOGY_ID_LABEL}
    BuiltIn.Set Suite Variable    ${topology_label_without_curly_braces_part}
    BuiltIn.Set Suite Variable    ${topology_id_label_curly_braces_part}
    @{topology_keys}=    BuiltIn.Create List    ${TOPOLOGY_ID_0}    ${TOPOLOGY_ID_1}
    @{selected_or_unselected}=    BuiltIn.Create List    selected    unselected
    BuiltIn.Set Suite Variable    @{selected_or_unselected}
    YangmanKeywords.Input Key_1 And Key_2 To Topology Id Input Field And Execute Operation With Checkbox Fill Form Selected And Unselected    ${TOPOLOGY_ID_0}    ${TOPOLOGY_ID_1}    ${PUT_OPTION}    PUT
    : FOR    ${index}    IN RANGE    0    len(@{selected_or_unselected})
    \    ${difference}=    BuiltIn.Evaluate    ${index}+1
    \    YangmanKeywords.Select Form View
    \    ${key}=    Collections.Get From List    ${topology_keys}    ${index}
    \    ${fill_form_with_received_data_option}=    Collections.Get From List    ${selected_or_unselected}    ${index}
    \    YangmanKeywords.Input Text To Labelled Form Input Field    ${topology_id_label_curly_braces_part}    ${key}
    \    YangmanKeywords.Execute Chosen Operation From Form And Check Status Code    ${DELETE_OPTION}    DELETE    ${fill_form_with_received_data_option}    ${20X_REQUEST_CODE_REGEX}
    \    ${topology_id_labelled_input}=    YangmanKeywords.Return Labelled Form Input Field    ${topology_id_label_curly_braces_part}
    \    BuiltIn.Run Keyword If    ${index}==0    Selenium2Library.Element Should Not Be Visible    ${topology_id_labelled_input}
    \    ...    ELSE    YangmanKeywords.Verify Labelled Form Input Field Contains Data    ${topology_id_label_curly_braces_part}    ${key}
    \    YangmanKeywords.Verify Labelled Api Path Input Contains Data    ${topology_label_without_curly_braces_part}    ${key}
    \    YangmanKeywords.Select Json View
    \    YangmanKeywords.Verify Sent Data CM Is Not Displayed
    \    YangmanKeywords.Verify Received Data CM Is Displayed
    \    YangmanKeywords.Verify Code Mirror Code Does Not Contain Data    ${RECEIVED_DATA_CODE_MIRROR_CODE}    ${key}

Delete Topology Topology Id From Json With Fill Form Checkbox Selected/ Unselected And Verify Data Presence In Form
    YangmanKeywords.Select Form View
    YangmanKeywords.Input Key_1 And Key_2 To Topology Id Input Field And Execute Operation With Checkbox Fill Form Selected And Unselected    ${TOPOLOGY_ID_2}    ${TOPOLOGY_ID_3}    ${PUT_OPTION}    PUT
    @{topology_keys}=    BuiltIn.Create List    ${TOPOLOGY_ID_2}    ${TOPOLOGY_ID_3}
    : FOR    ${index}    IN RANGE    0    len(@{selected_or_unselected})
    \    ${key}=    Collections.Get From List    ${topology_keys}    ${index}
    \    ${fill_form_with_received_data_option}=    Collections.Get From List    ${selected_or_unselected}    ${index}
    \    YangmanKeywords.Select Form View
    \    YangmanKeywords.Input Text To Labelled Form Input Field    ${topology_id_label_curly_braces_part}    ${key}
    \    YangmanKeywords.Select Operation    ${DELETE_OPTION}
    \    YangmanKeywords.Select Fill Form With Received Data After Execution Checkbox    ${fill_form_with_received_data_option}
    \    YangmanKeywords.Select Json View
    \    YangmanKeywords.Send Request And Verify Request Status Code Matches Desired Code    ${20X_REQUEST_CODE_REGEX}
    \    YangmanKeywords.Verify Sent Data CM Is Not Displayed
    \    YangmanKeywords.Verify Received Data CM Is Displayed
    \    YangmanKeywords.Verify Code Mirror Code Does Not Contain Data    ${RECEIVED_DATA_CODE_MIRROR_CODE}    ${key}
    \    YangmanKeywords.Select Form View
    \    YangmanKeywords.Verify Labelled Form Input Field Contains Data    ${topology_id_label_curly_braces_part}    ${key}
    \    YangmanKeywords.Verify Labelled Api Path Input Contains Data    ${topology_label_without_curly_braces_part}    ${key}

Run Delete Request With No Data From Form And Verify Data Presence In Code Mirror
    YangmanKeywords.Delete All Topologies In Network Topology
    YangmanKeywords.Load Topology Topology Id Node In Form
    : FOR    ${index}    IN RANGE    0    len(@{selected_or_unselected})
    \    ${fill_form_with_received_data_option}=    Collections.Get From List    ${selected_or_unselected}    ${index}
    \    YangmanKeywords.Select Form View
    \    YangmanKeywords.Input Text To Labelled Form Input Field    ${topology_id_label_curly_braces_part}    ${EMPTY}
    \    YangmanKeywords.Execute Chosen Operation From Form And Check Status Code    ${DELETE_OPTION}    DELETE    ${fill_form_with_received_data_option}    ${THREE_DOTS_DEFAULT_STATUS_AND_TIME}
    \    YangmanKeywords.Verify Form Contains Error Message    ${ERROR_MESSAGE_IDENTIFIERS_IN_PATH_REQUIRED}
    \    YangmanKeywords.Verify Labelled Form Input Field Does Not Contain Any Data    ${topology_id_label_curly_braces_part}
    \    YangmanKeywords.Verify Labelled Api Path Input Does Not Contain Any Data    ${topology_label_without_curly_braces_part}
    \    YangmanKeywords.Select Json View
    \    YangmanKeywords.Verify Sent Data CM Is Not Displayed
    \    YangmanKeywords.Verify Received Data CM Is Displayed
    \    YangmanKeywords.Verify No Data Are Displayed In Code Mirror Code    ${RECEIVED_DATA_CODE_MIRROR_CODE}

Run Delete Request With No Data From Json And Verify Data Presence In Code Mirror
    YangmanKeywords.Load Topology Topology Id Node In Form
    : FOR    ${index}    IN RANGE    0    len(@{selected_or_unselected})
    \    ${fill_form_with_received_data_option}=    Collections.Get From List    ${selected_or_unselected}    ${index}
    \    YangmanKeywords.Select Form View
    \    YangmanKeywords.Input Text To Labelled Form Input Field    ${topology_id_label_curly_braces_part}    ${EMPTY}
    \    YangmanKeywords.Select Operation    ${DELETE_OPTION}
    \    YangmanKeywords.Select Fill Form With Received Data After Execution Checkbox    ${fill_form_with_received_data_option}
    \    YangmanKeywords.Select Json View
    \    YangmanKeywords.Send Request And Verify Request Status Code Matches Desired Code    ${40X_REQUEST_CODE_REGEX}
    \    YangmanKeywords.Verify Sent Data CM Is Not Displayed
    \    YangmanKeywords.Verify Received Data CM Is Displayed
    \    YangmanKeywords.Verify Code Mirror Code Contains Data    ${RECEIVED_DATA_CODE_MIRROR_CODE}    ${JSON_ERROR_MESSAGE_DATA_DOES_NOT_EXIST_FOR_PATH}
    \    YangmanKeywords.Select Form View
    \    YangmanKeywords.Verify Form Contains Error Message    ${JSON_ERROR_MESSAGE_DATA_DOES_NOT_EXIST_FOR_PATH}
    \    YangmanKeywords.Verify Labelled Form Input Field Does Not Contain Any Data    ${topology_id_label_curly_braces_part}
    \    YangmanKeywords.Verify Labelled Api Path Input Does Not Contain Any Data    ${topology_label_without_curly_braces_part}

*** Keywords ***
