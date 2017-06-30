*** Settings ***
Documentation     Verification that when chain of 5 successful PUT/ GET/ DELETE requests is executed with
...               Fill form with received data after execution checkbox [selected, selected, unselected, unselected, selected],
...               then relevant data are displayed in the form.
Suite Setup       YangmanKeywords.Open DLUX And Login And Navigate To Yangman URL And Verify Modules Tab Name Translation
Suite Teardown    Selenium2Library.Close Browser
Test Teardown     BuiltIn.Run Keyword If Test Failed    GUIKeywords.Return Webdriver Instance And Log Browser Console Content
Resource          ${CURDIR}/../../../libraries/YangmanKeywords.robot

*** Variables ***

*** Test Cases ***
Execute Chain Of Successful Put Requests From Form And Verify Data In Form
    YangmanKeywords.Navigate From Yangman Submenu To Testing Module Config And Load Topology Topology Id Node In Form    ${NETWORK_TOPOLOGY_TESTING_MODULE_NAME}
    ${topology_label_without_curly_braces_part}=    YangmanKeywords.Return Branch Label Without Curly Braces Part    ${TOPOLOGY_TOPOLOGY_ID_LABEL}
    ${topology_id_label_curly_braces_part}=    YangmanKeywords.Return Branch Label Curly Braces Part Without Braces    ${TOPOLOGY_TOPOLOGY_ID_LABEL}
    BuiltIn.Set Suite Variable    ${topology_label_without_curly_braces_part}
    BuiltIn.Set Suite Variable    ${topology_id_label_curly_braces_part}
    @{keys}=    BuiltIn.Create List    ${Topology_ID_0}    ${Topology_ID_1}    ${Topology_ID_2}    ${Topology_ID_3}    ${Topology_ID_4}
    BuiltIn.Set Suite Variable    @{keys}
    @{fill_form_selected_checkbox}=    BuiltIn.Create List    selected    selected    unselected    unselected    selected
    BuiltIn.Set Suite Variable    @{fill_form_selected_checkbox}
    : FOR    ${index}    IN RANGE    0    len(@{keys})
    \    ${topology_key}=    Collections.Get From List    ${keys}    ${index}
    \    ${fill_form_option}=    Collections.Get From List    ${fill_form_selected_checkbox}    ${index}
    \    YangmanKeywords.Input Text To Labelled Form Input Field    ${topology_id_label_curly_braces_part}    ${topology_key}
    \    YangmanKeywords.Execute Chosen Operation From Form    ${PUT_OPTION}    PUT    ${fill_form_option}
    \    BuiltIn.Run Keyword If    "${fill_form_option}"=="selected"    BuiltIn.Run Keywords    YangmanKeywords.Verify Labelled Form Input Field Does Not Contain Any Data    ${topology_id_label_curly_braces_part}
    \    ...    AND    YangmanKeywords.Verify Labelled Api Path Input Does Not Contain Any Data    ${topology_label_without_curly_braces_part}
    \    BuiltIn.Run Keyword If    "${fill_form_option}"=="unselected"    BuiltIn.Run Keywords    YangmanKeywords.Verify Labelled Form Input Field Contains Data    ${topology_id_label_curly_braces_part}    ${topology_key}
    \    ...    AND    YangmanKeywords.Verify Labelled Api Path Input Contains Data    ${topology_label_without_curly_braces_part}    ${topology_key}

Execute Chain Of Successful Get Requests From Form And Verify Data In Form
    : FOR    ${index}    IN RANGE    0    len(@{keys})
    \    ${topology_key}=    Collections.Get From List    ${keys}    ${index}
    \    ${fill_form_option}=    Collections.Get From List    ${fill_form_selected_checkbox}    ${index}
    \    YangmanKeywords.Input Text To Labelled Form Input Field    ${topology_id_label_curly_braces_part}    ${topology_key}
    \    YangmanKeywords.Execute Chosen Operation From Form    ${GET_OPTION}    GET    ${fill_form_option}
    \    YangmanKeywords.Verify Labelled Api Path Input Contains Data    ${topology_label_without_curly_braces_part}    ${topology_key}
    \    YangmanKeywords.Verify Labelled Form Input Field Contains Data    ${topology_id_label_curly_braces_part}    ${topology_key}

Execute Chain Of Successful Delete Requests From Form And Verify Data In Form
    : FOR    ${index}    IN RANGE    0    len(@{keys})
    \    ${topology_key}=    Collections.Get From List    ${keys}    ${index}
    \    ${fill_form_option}=    Collections.Get From List    ${fill_form_selected_checkbox}    ${index}
    \    YangmanKeywords.Input Text To Labelled Form Input Field    ${topology_id_label_curly_braces_part}    ${topology_key}
    \    YangmanKeywords.Execute Chosen Operation From Form    ${DELETE_OPTION}    DELETE    ${fill_form_option}
    \    ${topology_id_labelled_input}=    YangmanKeywords.Return Labelled Form Input Field    ${topology_id_label_curly_braces_part}
    \    BuiltIn.Run Keyword If    "${fill_form_option}"=="selected"    BuiltIn.Run Keywords    Selenium2Library.Element Should Not Be Visible    ${topology_id_labelled_input}
    \    ...    AND    YangmanKeywords.Load Topology Topology Id Node In Form
    \    BuiltIn.Run Keyword If    "${fill_form_option}"=="unselected"    BuiltIn.Run Keywords    YangmanKeywords.Verify Labelled Form Input Field Contains Data    ${topology_id_label_curly_braces_part}    ${topology_key}
    \    ...    AND    YangmanKeywords.Verify Labelled Api Path Input Contains Data    ${topology_label_without_curly_braces_part}    ${topology_key}

*** Keywords ***
