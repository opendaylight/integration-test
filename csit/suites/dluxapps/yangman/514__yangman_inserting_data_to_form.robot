*** Settings ***
Documentation     Verification that list items keys inserted in the form are reflected in API path and vice versa.
...               Verification that it is possible to add multiple topology list items.
...               Verification that when multiple list items keys are inserted in the form, then these keys are reflected in list item label.
Suite Setup       YangmanKeywords.Open DLUX And Login And Navigate To Yangman URL And Verify Modules Tab Name Translation
Suite Teardown    Selenium2Library.Close Browser
Test Teardown     BuiltIn.Run Keyword If Test Failed    GUIKeywords.Return Webdriver Instance And Log Browser Console Content
Resource          ${CURDIR}/../../../libraries/YangmanKeywords.robot

*** Variables ***

*** Test Cases ***
Verify List Items Keys Inserted In Form Are Reflected In API Path And Vice Versa
    YangmanKeywords.Navigate From Yangman Submenu To Testing Module Config Tab    ${NETWORK_TOPOLOGY_TESTING_MODULE_NAME}
    YangmanKeywords.Expand All Branches In Module Detail Content Active Tab
    YangmanKeywords.Select Form View
    ${branches_number}=    Selenium2Library.Get Matching Xpath Count    ${MODULE_DETAIL_BRANCH}
    ${active_module_detail_tab_branches_number}=    BuiltIn.Evaluate    ${branches_number}/2
    : FOR    ${index}    IN RANGE    0    ${active_module_detail_tab_branches_number}
    \    ${module_detail_branch_indexed}=    YangmanKeywords.Compose Branch Id And Return Module Detail Branch Indexed    ${index}
    \    ${branch_label}=    YangmanKeywords.Return Indexed Branch Label    ${module_detail_branch_indexed}
    \    ${branch_label_without_curly_braces_part}=    YangmanKeywords.Return Branch Label Without Curly Braces Part    ${branch_label}
    \    ${branch_label_curly_braces_part}=    YangmanKeywords.Return Branch Label Curly Braces Part Without Braces    ${branch_label}
    \    ${item_key_1}=    BuiltIn.Set Variable    key1${index}
    \    ${item_key_2}=    BuiltIn.Set Variable    key2${index}
    \    If Module Detail Branch Is List Branch Then Click It Else Continue For Loop    ${module_detail_branch_indexed}
    \    YangmanKeywords.Verify List Item With Index Or Key Is Visible    ${branch_label}    ${EMPTY}    0
    \    If Key Input Is Select Menu Then Continue For Loop    ${module_detail_branch_indexed}
    \    YangmanKeywords.Compose Labelled Api Path Input Xpath And Verify It Is Visible    ${branch_label_without_curly_braces_part}
    \    YangmanKeywords.Compose Labelled Form Input Field Xpath And Verify It Is Visible    ${branch_label_curly_braces_part}
    \    Input Key To Input Field And Verify That Form Contains List Element With Key And Key Is Displayed In Api Path    ${item_key_1}    ${branch_label_curly_braces_part}    ${branch_label_without_curly_braces_part}
    \    Input Key To Api Path Input Field And Verify That Form Contains List Element With Key And Key Is Displayed In Api Path    ${item_key_2}    ${branch_label_curly_braces_part}    ${branch_label_without_curly_braces_part}

Verify It Is Possible To Add Multiple Topology List Items
    YangmanKeywords.Load And Expand Network Topology In Form
    ${topology_label_without_curly_braces_part}=    YangmanKeywords.Return Branch Label Without Curly Braces Part    ${TOPOLOGY_TOPOLOGY_ID_LABEL}
    BuiltIn.Set Suite Variable    ${topology_label_without_curly_braces_part}
    ${topology_id_label_curly_braces_part}=    YangmanKeywords.Return Branch Label Curly Braces Part Without Braces    ${TOPOLOGY_TOPOLOGY_ID_LABEL}
    BuiltIn.Set Suite Variable    ${topology_id_label_curly_braces_part}
    ${topology_show_next_item_arrow}=    YangmanKeywords.Return Labelled Element Show Next Item Arrow    ${topology_label_without_curly_braces_part}
    BuiltIn.Set Suite Variable    ${topology_show_next_item_arrow}
    ${topology_show_previous_item_arrow}=    YangmanKeywords.Return Labelled Element Show Previous Item Arrow    ${topology_label_without_curly_braces_part}
    BuiltIn.Set Suite Variable    ${topology_show_previous_item_arrow}
    : FOR    ${index}    IN RANGE    0    10
    \    Compose Topology Yangmenu And Click It And Click Add List Item Yangmenu Button
    \    ${next_item_arrow_is_visble}=    BuiltIn.Run Keyword And Return Status    Selenium2Library.Element Should Be Visible    ${topology_show_next_item_arrow}
    \    BuiltIn.Run Keyword If    ${next_item_arrow_is_visble}==True    BuiltIn.Run Keywords    GUIKeywords.Mouse Down And Mouse Up Click Element    ${topology_show_next_item_arrow}
    \    ...    AND    Selenium2Library.Element Should Be Visible    ${topology_show_previous_item_arrow}
    \    YangmanKeywords.Verify List Item With Index Or Key Is Visible    ${topology_label_without_curly_braces_part}    ${EMPTY}    ${index}
    \    BuiltIn.Run Keyword If    ${next_item_arrow_is_visble}==True    BuiltIn.Exit For Loop
    Selenium2Library.Click Element    ${topology_show_previous_item_arrow}
    YangmanKeywords.Click Form List Item With Index Or Key    ${topology_label_without_curly_braces_part}    ${EMPTY}    0

Verify Multiple List Items Keys Inserted In Form Are Displayed In Form And Reflected In List Item Label
    : FOR    ${index}    IN RANGE    0    10
    \    ${topology_key}=    BuiltIn.Catenate    SEPARATOR=    t    ${index}
    \    ${list_item_is_visible}=    BuiltIn.Run Keyword And Return Status    YangmanKeywords.Verify List Item With Index Or Key Is Visible    ${topology_label_without_curly_braces_part}    ${EMPTY}    ${index}
    \    BuiltIn.Run Keyword If    ${list_item_is_visible}==False    Selenium2Library.Click Element    ${topology_show_next_item_arrow}
    \    YangmanKeywords.Click Form List Item With Index Or Key    ${topology_label_without_curly_braces_part}    ${EMPTY}    ${index}
    \    YangmanKeywords.Input Text To Labelled Form Input Field    ${topology_id_label_curly_braces_part}    ${topology_key}
    \    ${previous_item_arrow_is_visible}=    BuiltIn.Run Keyword And Return Status    Selenium2Library.Element Should Be Visible    ${topology_show_previous_item_arrow}
    \    BuiltIn.Exit For Loop If    ${previous_item_arrow_is_visible}==True
    Selenium2Library.Click Element    ${topology_show_previous_item_arrow}
    : FOR    ${index}    IN RANGE    0    10
    \    ${topology_key}=    BuiltIn.Catenate    SEPARATOR=    t    ${index}
    \    ${list_item_is_visible}=    BuiltIn.Run Keyword And Return Status    YangmanKeywords.Verify List Item With Index Or Key Is Visible    ${topology_label_without_curly_braces_part}    ${topology_id_label_curly_braces_part}    ${topology_key}
    \    BuiltIn.Run Keyword If    ${list_item_is_visible}==False    Selenium2Library.Click Element    ${topology_show_next_item_arrow}
    \    YangmanKeywords.Click Form List Item With Index Or Key    ${topology_label_without_curly_braces_part}    ${topology_id_label_curly_braces_part}    ${topology_key}
    \    ${topology_id_input_field}=    YangmanKeywords.Return Labelled Form Input Field    ${topology_id_label_curly_braces_part}
    \    YangmanKeywords.Verify Labelled Form Input Field Contains Data    ${topology_id_label_curly_braces_part}    ${topology_key}
    \    ${previous_item_arrow_is_visble}=    BuiltIn.Run Keyword And Return Status    Selenium2Library.Element Should Be Visible    ${topology_show_previous_item_arrow}
    \    BuiltIn.Exit For Loop If    ${previous_item_arrow_is_visble}==True

*** Keywords ***
If Module Detail Branch Is List Branch Then Click It Else Continue For Loop
    [Arguments]    ${module_detail_branch_indexed}
    ${status}=    YangmanKeywords.Verify Module Detail Branch Is List Branch    ${module_detail_branch_indexed}
    BuiltIn.Run Keyword If    ${status}==True    YangmanKeywords.Click Module Detail Branch Indexed    ${module_detail_branch_indexed}
    ...    ELSE    BuiltIn.Continue For Loop If    ${status}==False

If Key Input Is Select Menu Then Continue For Loop
    [Arguments]    ${module_detail_branch_indexed}
    ${branch_label}=    YangmanKeywords.Return Indexed Branch Label    ${module_detail_branch_indexed}
    ${branch_label_curly_braces_part}=    YangmanKeywords.Return Branch Label Curly Braces Part Without Braces    ${branch_label}
    ${labelled_form_select}=    YangmanKeywords.Return Labelled Form Select    ${branch_label_curly_braces_part}
    ${status}=    BuiltIn.Run Keyword And Return Status    Selenium2Library.Element Should Be Visible    ${labelled_form_select}
    BuiltIn.Continue For Loop If    ${status}==True

Input Key To Input Field And Verify That Form Contains List Element With Key And Key Is Displayed In Api Path
    [Arguments]    ${item_key}    ${branch_label_curly_braces_part}    ${branch_label_without_curly_braces_part}
    ${labelled_form_input_field}=    YangmanKeywords.Return Labelled Form Input Field    ${branch_label_curly_braces_part}
    Selenium2Library.Input Text    ${labelled_form_input_field}    ${item_key}
    YangmanKeywords.Verify Labelled Api Path Input Contains Data    ${branch_label_without_curly_braces_part}    ${item_key}
    YangmanKeywords.Verify List Item With Index Or Key Is Visible    ${branch_label}    ${branch_label_curly_braces_part}    ${item_key}
    YangmanKeywords.Verify Labelled Form Input Field Contains Data    ${branch_label_curly_braces_part}    ${item_key}

Input Key To Api Path Input Field And Verify That Form Contains List Element With Key And Key Is Displayed In Api Path
    [Arguments]    ${item_key}    ${branch_label_curly_braces_part}    ${branch_label_without_curly_braces_part}
    ${labelled_api_path_input}=    YangmanKeywords.Return Labelled Api Path Input    ${branch_label_without_curly_braces_part}
    Selenium2Library.Input Text    ${labelled_api_path_input}    ${item_key}
    YangmanKeywords.Verify List Item With Index Or Key Is Visible    ${branch_label}    ${branch_label_curly_braces_part}    ${item_key}
    YangmanKeywords.Verify Labelled Form Input Field Contains Data    ${branch_label_curly_braces_part}    ${item_key}
    YangmanKeywords.Verify Labelled Api Path Input Contains Data    ${branch_label_without_curly_braces_part}    ${item_key}

Compose Topology Yangmenu And Click It And Click Add List Item Yangmenu Button
    ${topology_yangmenu}=    YangmanKeywords.Return Labelled Element Yangmenu    ${topology_label_without_curly_braces_part}
    GUIKeywords.Mouse Down And Mouse Up Click Element    ${topology_yangmenu}[2]
    GUIKeywords.Focus And Click Element    ${YANGMENU_ADD_LIST_ITEM_BUTTON}
