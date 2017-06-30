*** Settings ***
Documentation     Verification that when successful PUT, GET and DELETE requests are executed successively from form with
...               Fill form with received data after execution checkbox selected/ unselected, then relevant data are displayed in
...               the form and relevant code mirrors are displayed and correct data are displayed in the code mirrors in json.
...               Verification that when unsuccessful PUT, GET and DELETE requests are executed successively from form with
...               Fill form with received data after execution checkbox selected/ unselected, then relevant data are displayed in
...               the form and relevant code mirrors are displayed and correct data are displayed in the code mirrors in json.
Suite Setup       YangmanKeywords.Open DLUX And Login And Navigate To Yangman URL And Verify Modules Tab Name Translation
Suite Teardown    Selenium2Library.Close Browser
Test Teardown     BuiltIn.Run Keyword If Test Failed    GUIKeywords.Return Webdriver Instance And Log Browser Console Content
Resource          ${CURDIR}/../../../libraries/YangmanKeywords.robot

*** Variables ***

*** Test Cases ***
Execute Successful Put And Get And Delete Requests From Form With Fill Form Checkbox Selected And Verify Data Presence In Form And Json
    [Documentation]    Executes successful PUT, GET and DELETE requests from form view with Fill form with received data after execution checkbox selected and verifies data presence in form and json view.
    YangmanKeywords.Navigate From Yangman Submenu To Testing Module Config And Load Topology Topology Id Node In Form    ${NETWORK_TOPOLOGY_TESTING_MODULE_NAME}
    ${topology_label_without_curly_braces_part}=    YangmanKeywords.Return Branch Label Without Curly Braces Part    ${TOPOLOGY_TOPOLOGY_ID_LABEL}
    ${topology_id_label_curly_braces_part}=    YangmanKeywords.Return Branch Label Curly Braces Part Without Braces    ${TOPOLOGY_TOPOLOGY_ID_LABEL}
    BuiltIn.Set Suite Variable    ${topology_label_without_curly_braces_part}
    BuiltIn.Set Suite Variable    ${topology_id_label_curly_braces_part}
    ${topology_id_labelled_input}=    YangmanKeywords.Return Labelled Form Input Field    ${topology_id_label_curly_braces_part}
    BuiltIn.Set Suite Variable    ${topology_id_labelled_input}
    @{keys}=    BuiltIn.Create List    ${TOPOLOGY_ID_0}    ${TOPOLOGY_ID_1}    ${TOPOLOGY_ID_2}
    @{operations}=    BuiltIn.Create List    ${PUT_OPTION}    ${GET_OPTION}    ${DELETE_OPTION}
    @{operation_names}=    BuiltIn.Create List    PUT    GET    DELETE
    BuiltIn.Set Suite Variable    @{keys}
    BuiltIn.Set Suite Variable    @{operations}
    BuiltIn.Set Suite Variable    @{operation_names}
    : FOR    ${index}    IN RANGE    0    len(@{keys})
    \    ${topology_key}=    Collections.Get From List    ${keys}    ${index}
    \    YangmanKeywords.Input Text To Labelled Form Input Field    ${topology_id_label_curly_braces_part}    ${topology_key}
    \    YangmanKeywords.Execute Chosen Operation From Form    ${PUT_OPTION}    PUT    unselected
    : FOR    ${index}    IN RANGE    0    len(@{keys})
    \    ${topology_key}=    Collections.Get From List    ${keys}    ${index}
    \    ${operation}=    Collections.Get From List    ${operations}    ${index}
    \    ${operation_name}=    Collections.Get From List    ${operation_names}    ${index}
    \    YangmanKeywords.Select Form View
    \    YangmanKeywords.Input Text To Labelled Form Input Field    ${topology_id_label_curly_braces_part}    ${topology_key}
    \    YangmanKeywords.Execute Chosen Operation From Form And Check Status Code    ${operation}    ${operation_name}    selected    ${20X_REQUEST_CODE_REGEX}
    \    BuiltIn.Run Keyword If    "${operation_name}"=="PUT"    BuiltIn.Run Keywords    YangmanKeywords.Verify Labelled Form Input Field Does Not Contain Any Data    ${topology_id_label_curly_braces_part}
    \    ...    AND    YangmanKeywords.Verify Labelled Api Path Input Does Not Contain Any Data    ${topology_label_without_curly_braces_part}
    \    BuiltIn.Run Keyword If    "${operation_name}"=="GET"    BuiltIn.Run Keywords    YangmanKeywords.Verify Labelled Form Input Field Contains Data    ${topology_id_label_curly_braces_part}    ${topology_key}
    \    ...    AND    YangmanKeywords.Verify Labelled Api Path Input Contains Data    ${topology_label_without_curly_braces_part}    ${topology_key}
    \    BuiltIn.Run Keyword If    "${operation_name}"=="DELETE"    BuiltIn.Run Keywords    Selenium2Library.Wait Until Element Is Not Visible    ${topology_id_labelled_input}
    \    ...    AND    YangmanKeywords.Verify Labelled Api Path Input Contains Data    ${topology_label_without_curly_braces_part}    ${topology_key}
    \    YangmanKeywords.Select Json View
    \    BuiltIn.Run Keyword If    "${operation_name}"=="PUT"    BuiltIn.Run Keywords    YangmanKeywords.Verify Sent Data CM Is Displayed
    \    ...    AND    YangmanKeywords.Verify Received Data CM Is Displayed
    \    ...    AND    YangmanKeywords.Verify Code Mirror Code Does Not Contain Data    ${SENT_DATA_CODE_MIRROR_CODE}    ${topology_id_label_curly_braces_part}
    \    BuiltIn.Run Keyword If    "${operation_name}"=="GET"    BuiltIn.Run Keywords    YangmanKeywords.Verify Sent Data CM Is Not Displayed
    \    ...    AND    YangmanKeywords.Verify Received Data CM Is Displayed
    \    ...    AND    YangmanKeywords.Verify Code Mirror Code Contains Data    ${RECEIVED_DATA_CODE_MIRROR_CODE}    ${topology_key}
    \    BuiltIn.Run Keyword If    "${operation_name}"=="DELETE"    BuiltIn.Run Keywords    YangmanKeywords.Verify Sent Data CM Is Not Displayed
    \    ...    AND    YangmanKeywords.Verify Received Data CM Is Displayed
    \    ...    AND    YangmanKeywords.Verify Code Mirror Code Does Not Contain Data    ${RECEIVED_DATA_CODE_MIRROR_CODE}    ${topology_key}

Execute Successful Put And Get And Delete Requests From Form With Fill Form Checkbox Unselected And Verify Data Presence In Form And Json
    [Documentation]    Executes successful PUT, GET and DELETE requests from form view with Fill form with received data after execution checkbox unselected and verifies data presence in form and json view.
    YangmanKeywords.Select Form View
    : FOR    ${index}    IN RANGE    0    len(@{keys})
    \    ${topology_key}=    Collections.Get From List    ${keys}    ${index}
    \    YangmanKeywords.Input Text To Labelled Form Input Field    ${topology_id_label_curly_braces_part}    ${topology_key}
    \    YangmanKeywords.Execute Chosen Operation From Form    ${PUT_OPTION}    PUT    unselected
    : FOR    ${index}    IN RANGE    0    len(@{keys})
    \    ${topology_key}=    Collections.Get From List    ${keys}    ${index}
    \    ${operation}=    Collections.Get From List    ${operations}    ${index}
    \    ${operation_name}=    Collections.Get From List    ${operation_names}    ${index}
    \    YangmanKeywords.Select Form View
    \    YangmanKeywords.Input Text To Labelled Form Input Field    ${topology_id_label_curly_braces_part}    ${topology_key}
    \    YangmanKeywords.Execute Chosen Operation From Form And Check Status Code    ${operation}    ${operation_name}    unselected    ${20X_REQUEST_CODE_REGEX}
    \    BuiltIn.Run Keywords    YangmanKeywords.Verify Labelled Form Input Field Contains Data    ${topology_id_label_curly_braces_part}    ${topology_key}
    \    ...    AND    YangmanKeywords.Verify Labelled Api Path Input Contains Data    ${topology_label_without_curly_braces_part}    ${topology_key}
    \    YangmanKeywords.Select Json View
    \    BuiltIn.Run Keyword If    "${operation_name}"=="PUT"    BuiltIn.Run Keywords    YangmanKeywords.Verify Sent Data CM Is Displayed
    \    ...    AND    YangmanKeywords.Verify Received Data CM Is Displayed
    \    ...    AND    YangmanKeywords.Verify Code Mirror Code Contains Data    ${SENT_DATA_CODE_MIRROR_CODE}    ${topology_key}
    \    BuiltIn.Run Keyword If    "${operation_name}"=="GET"    BuiltIn.Run Keywords    YangmanKeywords.Verify Sent Data CM Is Not Displayed
    \    ...    AND    YangmanKeywords.Verify Received Data CM Is Displayed
    \    ...    AND    YangmanKeywords.Verify Code Mirror Code Contains Data    ${RECEIVED_DATA_CODE_MIRROR_CODE}    ${topology_key}
    \    BuiltIn.Run Keyword If    "${operation_name}"=="DELETE"    BuiltIn.Run Keywords    YangmanKeywords.Verify Sent Data CM Is Not Displayed
    \    ...    AND    YangmanKeywords.Verify Received Data CM Is Displayed
    \    ...    AND    YangmanKeywords.Verify Code Mirror Code Does Not Contain Data    ${RECEIVED_DATA_CODE_MIRROR_CODE}    ${topology_key}

Execute Unsuccessful Put And Get And Delete Requests From Form With Fill Form Checkbox Selected And Verify Data Presence In Form And Json
    [Documentation]    Executes unsuccessful PUT, GET and DELETE requests from form view with Fill form with received data after execution checkbox selected and verifies data presence in form and json view.
    YangmanKeywords.Load Topology Topology Id Node In Form
    Execute Unsuccessful Put And Get And Delete Requests From Form And Verify Data Presence In Form And Json    selected

Execute Unsuccessful Put And Get And Delete Requests From Form With Fill Form Checkbox Unselected And Verify Data Presence In Form And Json
    [Documentation]    Executes unsuccessful PUT, GET and DELETE requests from form view with Fill form with received data after execution checkbox unselected and verifies data presence in form and json view.
    YangmanKeywords.Load Topology Topology Id Node In Form
    Execute Unsuccessful Put And Get And Delete Requests From Form And Verify Data Presence In Form And Json    unselected

*** Keywords ***
Execute Unsuccessful Put And Get And Delete Requests From Form And Verify Data Presence In Form And Json
    [Arguments]    ${fill_form_option}
    @{keys}=    BuiltIn.Create List    ${EMPTY}    ${TOPOLOGY_ID_2}    ${TOPOLOGY_ID_3}
    : FOR    ${index}    IN RANGE    0    len(@{keys})
    \    ${topology_key}=    Collections.Get From List    ${keys}    ${index}
    \    ${operation}=    Collections.Get From List    ${operations}    ${index}
    \    ${operation_name}=    Collections.Get From List    ${operation_names}    ${index}
    \    YangmanKeywords.Select Form View
    \    YangmanKeywords.Input Text To Labelled Form Input Field    ${topology_id_label_curly_braces_part}    ${topology_key}
    \    YangmanKeywords.Execute Chosen Operation From Form    ${operation}    ${operation_name}    ${fill_form_option}
    \    BuiltIn.Run Keyword If    "${operation_name}"=="PUT"    YangmanKeywords.Verify Form Contains Error Message    ${ERROR_MESSAGE_IDENTIFIERS_IN_PATH_REQUIRED}
    \    BuiltIn.Run Keyword If    "${operation_name}"=="GET"    BuiltIn.Run Keywords    YangmanKeywords.Verify Labelled Form Input Field Contains Data    ${topology_id_label_curly_braces_part}    ${topology_key}
    \    ...    AND    YangmanKeywords.Verify Labelled Api Path Input Contains Data    ${topology_label_without_curly_braces_part}    ${topology_key}
    \    ...    AND    YangmanKeywords.Verify Form Contains Error Message    ${JSON_ERROR_MESSAGE_CONTENT_DOES_NOT_EXIST}
    \    BuiltIn.Run Keyword If    "${operation_name}"=="DELETE"    BuiltIn.Run Keywords    YangmanKeywords.Verify Labelled Form Input Field Contains Data    ${topology_id_label_curly_braces_part}    ${topology_key}
    \    ...    AND    YangmanKeywords.Verify Labelled Api Path Input Contains Data    ${topology_label_without_curly_braces_part}    ${topology_key}
    \    ...    AND    YangmanKeywords.Verify Form Contains Error Message    ${JSON_ERROR_MESSAGE_DATA_DOES_NOT_EXIST_FOR_PATH}
    \    YangmanKeywords.Select Json View
    \    BuiltIn.Run Keyword If    "${operation_name}"=="PUT"    BuiltIn.Run Keywords    YangmanKeywords.Verify Sent Data CM Is Displayed
    \    ...    AND    YangmanKeywords.Verify Received Data CM Is Displayed
    \    ...    AND    YangmanKeywords.Verify Code Mirror Code Does Not Contain Data    ${SENT_DATA_CODE_MIRROR_CODE}    ${topology_id_label_curly_braces_part}
    \    BuiltIn.Run Keyword If    "${operation_name}"=="GET"    BuiltIn.Run Keywords    YangmanKeywords.Verify Sent Data CM Is Not Displayed
    \    ...    AND    YangmanKeywords.Verify Received Data CM Is Displayed
    \    ...    AND    YangmanKeywords.Verify Code Mirror Code Contains Data    ${RECEIVED_DATA_CODE_MIRROR_CODE}    ${JSON_ERROR_MESSAGE_CONTENT_DOES_NOT_EXIST}
    \    BuiltIn.Run Keyword If    "${operation_name}"=="DELETE"    BuiltIn.Run Keywords    YangmanKeywords.Verify Sent Data CM Is Not Displayed
    \    ...    AND    YangmanKeywords.Verify Received Data CM Is Displayed
    \    ...    AND    YangmanKeywords.Verify Code Mirror Code Contains Data    ${RECEIVED_DATA_CODE_MIRROR_CODE}    ${JSON_ERROR_MESSAGE_DATA_DOES_NOT_EXIST_FOR_PATH}
