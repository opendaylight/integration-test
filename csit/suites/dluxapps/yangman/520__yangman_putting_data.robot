*** Settings ***
Documentation     Verification that data PUT from form with checkbox Fill form with received data after execution selected [unselected]
...               are erased from form and form API [remain filled in form and form API] and are not displayed in Sent data code mirror
...               [are displayed in Sent data code mirror].
...               Verification that data PUT from json with checkbox Fill form with received data after execution selected [unselected]
...               are displayed in Sent data code mirror and are displayed in the form and form API.
...               Verification that when no data are PUT from form with checkbox Fill form with received data after execution selected [unselected]
...               then the request is not executed and error message "Identifiers in path are required..." is displayed in the form. No data are in Sent data and Received data code mirror.
...               Verification that when no data are PUT from json with checkbox Fill form with received data after execution selected [unselected] in form
...               then the request is executed with 400 http code. No data are displayed in Sent data code mirror and error message "Input is required." is displayed in Received data code mirror.
...               No data are displayed in the form.
Suite Setup       YangmanKeywords.Open DLUX And Login And Navigate To Yangman URL And Verify Modules Tab Name Translation
Suite Teardown    Selenium2Library.Close Browser
Test Teardown     BuiltIn.Run Keyword If Test Failed    GUIKeywords.Return Webdriver Instance And Log Browser Console Content
Resource          ${CURDIR}/../../../libraries/YangmanKeywords.robot

*** Variables ***

*** Test Cases ***
Put topology topology id from form with fill form checkbox selected/ unselected and verify data presence in json
    YangmanKeywords.Navigate From Yangman Submenu To Testing Module Config And Load Topology Topology Id Node In Form    ${NETWORK_TOPOLOGY_TESTING_MODULE_NAME}
    ${topology_label_without_curly_braces_part}=    YangmanKeywords.Return Branch Label Without Curly Braces Part    ${TOPOLOGY_TOPOLOGY_ID_LABEL}
    ${topology_id_label_curly_braces_part}=    YangmanKeywords.Return Branch Label Curly Braces Part Without Braces    ${TOPOLOGY_TOPOLOGY_ID_LABEL}
    ${node_label_without_curly_braces_part}=    YangmanKeywords.Return Branch Label Without Curly Braces Part    ${NODE_NODE_ID_LABEL}
    ${node_id_label_curly_braces_part}=    YangmanKeywords.Return Branch Label Curly Braces Part Without Braces    ${NODE_NODE_ID_LABEL}
    BuiltIn.Set Suite Variable    ${topology_label_without_curly_braces_part}
    BuiltIn.Set Suite Variable    ${topology_id_label_curly_braces_part}
    BuiltIn.Set Suite Variable    ${node_label_without_curly_braces_part}
    BuiltIn.Set Suite Variable    ${node_id_label_curly_braces_part}
    @{topology_keys}=    BuiltIn.Create List    ${TOPOLOGY_ID_0}    ${TOPOLOGY_ID_1}
    @{selected_or_unselected}=    BuiltIn.Create List    selected    unselected
    BuiltIn.Set Suite Variable    @{selected_or_unselected}
    : FOR    ${index}    IN RANGE    0    len(@{topology_keys})
    \    YangmanKeywords.Select Form View
    \    ${key}=    Collections.Get From List    ${topology_keys}    ${index}
    \    ${fill_form_with_received_data_option}=    Collections.Get From List    ${selected_or_unselected}    ${index}
    \    YangmanKeywords.Input Text To Labelled Form Input Field    ${topology_id_label_curly_braces_part}    ${key}
    \    YangmanKeywords.Execute Chosen Operation From Form And Check Status Code    ${PUT_OPTION}    PUT    ${fill_form_with_received_data_option}    ${20X_REQUEST_CODE_REGEX}
    \    BuiltIn.Run Keyword If    ${index}==0    BuiltIn.Run Keywords    YangmanKeywords.Verify Labelled Api Path Input Does Not Contain Any Data    ${topology_label_without_curly_braces_part}
    \    ...    AND    YangmanKeywords.Verify Labelled Form Input Field Does Not Contain Any Data    ${topology_label_without_curly_braces_part}
    \    BuiltIn.Run Keyword If    ${index}==1    BuiltIn.Run Keywords    YangmanKeywords.Verify Labelled Api Path Input Contains Data    ${topology_label_without_curly_braces_part}    ${key}
    \    ...    AND    YangmanKeywords.Verify Labelled Form Input Field Contains Data    ${topology_id_label_curly_braces_part}    ${key}
    \    YangmanKeywords.Select Json View
    \    YangmanKeywords.Verify Sent Data CM Is Displayed
    \    YangmanKeywords.Verify Received Data CM Is Displayed
    \    BuiltIn.Run Keyword If    ${index}==0    YangmanKeywords.Verify Code Mirror Code Does Not Contain Data    ${SENT_DATA_CODE_MIRROR_CODE}    ${key}
    \    BuiltIn.Run Keyword If    ${index}==1    YangmanKeywords.Verify Code Mirror Code Contains Data    ${SENT_DATA_CODE_MIRROR_CODE}    ${key}

Put topology topology id from json with fill form checkbox selected/ unselected and verify data presence in form
    @{topology_keys}=    BuiltIn.Create List    ${TOPOLOGY_ID_2}    ${TOPOLOGY_ID_3}
    : FOR    ${index}    IN RANGE    0    len(@{topology_keys})
    \    ${key}=    Collections.Get From List    ${topology_keys}    ${index}
    \    ${fill_form_with_received_data_option}=    Collections.Get From List    ${selected_or_unselected}    ${index}
    \    YangmanKeywords.Select Form View
    \    YangmanKeywords.Input Text To Labelled Form Input Field    ${topology_id_label_curly_braces_part}    ${key}
    \    YangmanKeywords.Expand Operation Select Menu And Select Operation    ${PUT_OPTION}    PUT
    \    YangmanKeywords.Select Fill Form With Received Data After Execution Checkbox    ${fill_form_with_received_data_option}
    \    YangmanKeywords.Select Json View
    \    YangmanKeywords.Send Request And Verify Request Status Code Matches Desired Code    ${20X_REQUEST_CODE_REGEX}
    \    YangmanKeywords.Verify Sent Data CM Is Displayed
    \    YangmanKeywords.Verify Received Data CM Is Displayed
    \    YangmanKeywords.Verify Code Mirror Code Contains Data    ${SENT_DATA_CODE_MIRROR_CODE}    ${key}
    \    YangmanKeywords.Select Form View
    \    YangmanKeywords.Verify Labelled Form Input Field Contains Data    ${topology_id_label_curly_braces_part}    ${key}
    \    YangmanKeywords.Verify Labelled Api Path Input Contains Data    ${topology_label_without_curly_braces_part}    ${key}

Run put request with no data from form
    YangmanKeywords.Load Node Node Id Node In Form
    : FOR    ${index}    IN RANGE    0    len(@{selected_or_unselected})
    \    ${fill_form_with_received_data_option}=    Collections.Get From List    ${selected_or_unselected}    ${index}
    \    YangmanKeywords.Select Form View
    \    YangmanKeywords.Input Text To Labelled Form Input Field    ${node_id_label_curly_braces_part}    ${EMPTY}
    \    YangmanKeywords.Execute Chosen Operation From Form And Check Status Code    ${PUT_OPTION}    PUT    ${fill_form_with_received_data_option}    ${THREE_DOTS_DEFAULT_STATUS_AND_TIME}
    \    YangmanKeywords.Verify Form Contains Error Message    ${ERROR_MESSAGE_IDENTIFIERS_IN_PATH_REQUIRED}
    \    YangmanKeywords.Verify Labelled Form Input Field Does Not Contain Any Data    ${node_id_label_curly_braces_part}
    \    YangmanKeywords.Verify Labelled Api Path Input Does Not Contain Any Data    ${node_label_without_curly_braces_part}
    \    YangmanKeywords.Select Json View
    \    YangmanKeywords.Verify Sent Data CM Is Displayed
    \    YangmanKeywords.Verify Received Data CM Is Displayed
    \    YangmanKeywords.Verify No Data Are Displayed In Code Mirror Code    ${SENT_DATA_CODE_MIRROR_CODE}
    \    YangmanKeywords.Verify No Data Are Displayed In Code Mirror Code    ${RECEIVED_DATA_CODE_MIRROR_CODE}

Run put request with no data from json
    : FOR    ${index}    IN RANGE    0    len(@{selected_or_unselected})
    \    ${fill_form_with_received_data_option}=    Collections.Get From List    ${selected_or_unselected}    ${index}
    \    YangmanKeywords.Select Form View
    \    YangmanKeywords.Input Text To Labelled Form Input Field    ${node_id_label_curly_braces_part}    ${EMPTY}
    \    YangmanKeywords.Expand Operation Select Menu And Select Operation    ${PUT_OPTION}    PUT
    \    YangmanKeywords.Select Fill Form With Received Data After Execution Checkbox    ${fill_form_with_received_data_option}
    \    YangmanKeywords.Select Json View
    \    YangmanKeywords.Send Request And Verify Request Status Code Matches Desired Code    ${40X_REQUEST_CODE_REGEX}
    \    YangmanKeywords.Verify Sent Data CM Is Displayed
    \    YangmanKeywords.Verify Received Data CM Is Displayed
    \    YangmanKeywords.Verify No Data Are Displayed In Code Mirror Code    ${SENT_DATA_CODE_MIRROR_CODE}
    \    YangmanKeywords.Verify Code Mirror Code Contains Data    ${RECEIVED_DATA_CODE_MIRROR_CODE}    ${JSON_ERROR_MESSAGE_INPUT_IS_REQUIRED}
    \    YangmanKeywords.Select Form View
    \    YangmanKeywords.Verify Form Contains Error Message    ${JSON_ERROR_MESSAGE_INPUT_IS_REQUIRED}
    \    YangmanKeywords.Verify Labelled Form Input Field Does Not Contain Any Data    ${node_id_label_curly_braces_part}
    \    YangmanKeywords.Verify Labelled Api Path Input Does Not Contain Any Data    ${node_label_without_curly_braces_part}

*** Keywords ***
