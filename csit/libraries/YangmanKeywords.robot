*** Settings ***
Documentation     A resource file containing all global keyword to help
...               Yangman GUI and functional testing.
Library           OperatingSystem
Library           Collections
Library           HttpLibrary.HTTP
Library           Selenium2Library    timeout=30    implicit_wait=30    run_on_failure=Selenium2Library.Capture Page Screenshot
Resource          ../variables/Variables.robot
Resource          GUIKeywords.robot
Resource          ../variables/YangmanGUIVariables.robot

*** Keywords ***
Open DLUX And Login And Navigate To Yangman URL
    [Documentation]    Launches DLUX page using PhantomJS, or Xvfb, or real browser and navigates to yangman url.
    GUIKeywords.Open Or Launch DLUX Page And Log In To DLUX
    GUIKeywords.Navigate To URL    ${YANGMAN_SUBMENU_URL}

Return List Of Operation IDs
    [Documentation]    Returns list of IDs of Get, Put, Post and Delete options in expanded operation select menu.
    ${list}=    BuiltIn.Create List    ${GET_OPTION}    ${PUT_OPTION}    ${POST_OPTION}    ${DELETE_OPTION}
    [Return]    ${list}

Return List Of Operation Names
    [Documentation]    Returns list of operations names.
    ${list}=    BuiltIn.Create List    ${GET_OPERATION_NAME}    ${PUT_OPERATION_NAME}    ${POST_OPERATION_NAME}    ${DELETE_OPERATION_NAME}
    [Return]    ${list}

Modules Tab Is Selected
    [Documentation]    Verifies that module tab is selected and history and collection tabs are unselected.
    Selenium2Library.Page Should Contain Element    ${MODULES_TAB_SELECTED}
    Selenium2Library.Page Should Contain Element    ${MODULE_SEARCH_INPUT}
    Selenium2Library.Page Should Contain Element    ${HISTORY_TAB_UNSELECTED}
    Selenium2Library.Page Should Contain Element    ${COLLECTIONS_TAB_UNSELECTED}

Expand Operation Select Menu
    [Documentation]    Clicks operation select menu to expand it.
    Selenium2Library.Focus    ${OPERATION_SELECT_INPUT}
    Selenium2Library.Click Element    ${OPERATION_SELECT_INPUT}
    BuiltIn.Wait Until Keyword Succeeds    1 min    5 sec    Selenium2Library.Page Should Contain Element    ${OPERATION_SELECT_MENU_EXPANDED}

Exit Opened Application Dialog
    [Documentation]    Closes opened/ expanded dialogs/ menus by clicking the backdrop.
    Click Element    ${SELECT_BACKDROP}

Select Operation
    [Arguments]    ${operation_id}
    [Documentation]    Selects chosen operation from expanded operation select menu.
    Selenium2Library.Page Should Contain Element    ${OPERATION_SELECT_MENU_EXPANDED}
    Selenium2Library.Focus    ${operation_id}
    Selenium2Library.Click Element    ${operation_id}

Verify Selected Operation Is Displayed
    [Arguments]    ${selected_operation_name}
    [Documentation]    Verifies that the selected operation is now displayed in collapsed operation select menu.
    ${selected_operation_xpath}=    BuiltIn.Set Variable    ${OPERATION_SELECT_INPUT}//span/div[contains(text(), "${selected_operation_name}")]
    Selenium2Library.Wait Until Page Contains Element    ${selected_operation_xpath}

Expand Operation Select Menu And Select Operation
    [Arguments]    ${operation_id}
    [Documentation]    Expands operation select menu and select operation provided as an argument.
    Expand Operation Select Menu
    Select Operation    ${operation_id}

Verify Yangman Home Page Elements
    [Documentation]    Verifies presence of Yangman home page elements.
    Selenium2Library.Wait Until Page Contains Element    ${YANGMAN_LOGO}
    Selenium2Library.Log Location
    Modules Tab Is Selected
    Selenium2Library.Page Should Contain Element    ${TOGGLE_MENU_BUTTON}
    Selenium2Library.Page Should Contain Element    ${LOGOUT_BUTTON}
    Verify Selected Operation Is Displayed    ${GET_OPERATION_NAME}
    Selenium2Library.Page Should Contain Element    ${REQUEST_URL_INPUT}
    Selenium2Library.Page Should Contain Element    ${SEND_BUTTON}
    Selenium2Library.Page Should Contain Element    ${SAVE_BUTTON}
    Selenium2Library.Page Should Contain Element    ${PARAMETERS_BUTTON}
    Selenium2Library.Page Should Contain Element    ${FORM_RADIOBUTTON_UNSELECTED}
    Selenium2Library.Page Should Contain Element    ${JSON_RADIOBUTTON_SELECTED}
    Selenium2Library.Page Should Contain Element    ${SHOW_SENT_DATA_CHECKBOX_UNSELECTED}
    Selenium2Library.Page Should Contain Element    ${SHOW_RECEIVED_DATA_CHECKBOX_SELECTED}
    Selenium2Library.Page Should Contain Element    ${Received_Data_Code_Mirror_Displayed}
    Selenium2Library.Page Should Contain Element    ${RECEIVED_DATA_ENLARGE_FONT_SIZE_BUTTON}
    Selenium2Library.Page Should Contain Element    ${RECEIVED_DATA_REDUCE_FONT_SIZE_BUTTON}
    Selenium2Library.Page Should Not Contain Element    ${SENT_DATA_CODE_MIRROR_DISPLAYED}

Select Form View
    [Documentation]    Click Form radiobutton to display form view.
    ${status}=    BuiltIn.Run Keyword And Return Status    Selenium2Library.Page Should Contain Element    ${FORM_RADIOBUTTON_SELECTED}
    BuiltIn.Run Keyword If    "${status}"=="False"    Selenium2Library.Click Element    ${FORM_RADIOBUTTON_UNSELECTED}

Select Json View
    [Documentation]    Click Json radiobutton to display json view.
    ${status}=    BuiltIn.Run Keyword And Return Status    Selenium2Library.Page Should Contain Element    ${JSON_RADIOBUTTON_SELECTED}
    BuiltIn.Run Keyword If    "${status}"=="False"    Selenium2Library.Click Element    ${JSON_RADIOBUTTON_UNSELECTED}

Return Number Of Modules Loaded
    [Arguments]    ${module_xpath}
    [Documentation]    Returns number of modules loaded in Modules tab.
    ${number_of_modules}=    Selenium2Library.Get Matching Xpath Count    ${module_xpath}
    [Return]    ${number_of_modules}

Verify Any Module Is Loaded
    [Documentation]    Verifies that at least one module has been loaded in Modules tab.
    ${number_of__modules_loaded}=    Return Number Of Modules Loaded    ${MODULE_LIST_ITEM}
    BuiltIn.Should Be True    ${number_of_modules_loaded}>0

Return Module List Indexed Module
    [Arguments]    ${index}
    [Documentation]    Returns indexed Xpath of the module. ${index} is a number.
    ${module_index}=    BuiltIn.Catenate    SEPARATOR=    ${MODULE_ID_LABEL}    ${index}
    ${module_list_item_indexed}=    BuiltIn.Set Variable    ${MODULE_TAB_CONTENT}//md-list-item[@id="${module_index}"]//div[@class="pointer title layout-align-center-center layout-row"]
    [Return]    ${module_list_item_indexed}

Return Indexed Module Operations Label
    [Arguments]    ${index}
    [Documentation]    Returns Xpath of the indexed module's operations item in Modules tab.
    ${module_list_item_indexed}=    Return Module List Indexed Module    ${index}
    ${indexed_module_operations_label}=    BuiltIn.Set Variable    ${module_list_item_indexed}//following-sibling::md-list[@aria-hidden="false"]//p[contains(., "${OPERATIONS_LABEL}")]
    [Return]    ${indexed_module_operations_label}

Return Indexed Module Operational Label
    [Arguments]    ${index}
    [Documentation]    Returns Xpath of the indexed module`s operational in Modules tab.
    ${module_list_item_indexed}=    Return Module List Indexed Module    ${index}
    ${indexed_module_operational_label}=    BuiltIn.Set Variable    ${module_list_item_indexed}//following-sibling::md-list[@aria-hidden="false"]//p[contains(., "${OPERATIONAL_LABEL}")]
    [Return]    ${indexed_module_operational_label}

Return Indexed Module Config Label
    [Arguments]    ${index}
    [Documentation]    Returns Xpath of the indexed module`s config in Modules tab.
    ${module_list_item_indexed}=    Return Module List Indexed Module    ${index}
    ${indexed_module_config_label}=    BuiltIn.Set Variable    ${module_list_item_indexed}//following-sibling::md-list[@aria-hidden="false"]//p[contains(., "${CONFIG_LABEL}")]
    [Return]    ${indexed_module_config_label}

Click Indexed Module Operations To Load Module Detail Operations Tab
    [Arguments]    ${index}
    [Documentation]    Clicks indexed module`s operations to load module detail operations tab.
    ${indexed_module_operations}=    Return Indexed Module Operations Label    ${index}
    Selenium2Library.Wait Until Page Contains Element    ${indexed_module_operations}
    GUIKeywords.Focus And Click Element    ${indexed_module_operations}
    Selenium2Library.Wait Until Page Contains Element    ${MODULE_DETAIL_OPERATIONS_TAB_SELECTED}

Click Indexed Module Operational To Load Module Detail Operational Tab
    [Arguments]    ${index}
    [Documentation]    Clicks indexed module`s operational to load module detail operational tab.
    ${indexed_module_operational}=    Return Indexed Module Operational Label    ${index}
    Selenium2Library.Wait Until Page Contains Element    ${indexed_module_operational}
    GUIKeywords.Focus And Click Element    ${indexed_module_operational}
    Selenium2Library.Wait Until Page Contains Element    ${MODULE_DETAIL_OPERATIONAL_TAB_SELECTED}

Click Indexed Module Config To Load Module Detail Config Tab
    [Arguments]    ${index}
    [Documentation]    Clicks indexed module`s config to load module detail config tab.
    ${indexed_module_config}=    Return Indexed Module Config Label    ${index}
    Selenium2Library.Wait Until Page Contains Element    ${indexed_module_config}
    GUIKeywords.Focus And Click Element    ${indexed_module_config}
    Selenium2Library.Wait Until Page Contains Element    ${MODULE_DETAIL_CONFIG_TAB_SELECTED}

Toggle Module Detail To Module Detail To Modules Or History Or Collections Tab
    [Documentation]    Click toggle module detail button to toggle from module detail to modules or history or collections tab.
    Selenium2Library.Wait Until Element Is Visible    ${TOGGLE_MODULE_DETAIL_BUTTON_LEFT}
    GUIKeywords.Focus And Click Element    ${TOGGLE_MODULE_DETAIL_BUTTON_LEFT}

Return Module ID Index From Module Name
    [Arguments]    ${module_name}
    [Documentation]    Returns number - module id index from module name.
    ${testing_module_xpath}=    BuiltIn.Set Variable    ${MODULE_TAB_CONTENT}//p[contains(., "${module_name}")]//ancestor::md-list-item[contains(@id, "${MODULE_ID_LABEL}")]
    ${module_id}=    Selenium2Library.Get Element Attribute    ${testing_module_xpath}@id
    ${module_id_index}=    String.Fetch From Right    ${module_id}    ${MODULE_ID_LABEL}
    [Return]    ${module_id_index}

Return Indexed Module From Module Name
    [Arguments]    ${module_name}
    [Documentation]    Returns indexed Xpath of the module from the module`s name.
    ${module_id_index}=    Return Module ID Index From Module Name    ${module_name}
    ${module_list_item_indexed}=    Return Module List Indexed Module    ${module_id_index}
    [Return]    ${module_list_item_indexed}

Expand Module
    [Arguments]    ${module_name}    ${module_id_index}
    [Documentation]    Clicks module list item in modules tab to expand the item and display its operations/ operational/ config items.
    ...    Arguments are either module name, or module id index, that is a number, or ${EMPTY}, if the option is not used.
    ${module_list_item_indexed}=    BuiltIn.Run Keyword If    "${module_name}"!= "${EMPTY}"    Return Indexed Module From Module Name    ${module_name}
    ${module_list_item_indexed}=    BuiltIn.Run Keyword If    "${module_id_index}"!= "${EMPTY}"    Return Module List Indexed Module    ${module_id_index}
    Selenium2Library.Click Element    ${module_list_item_indexed}
    ${module_list_item_collapsed_indexed}=    BuiltIn.Set Variable    ${module_list_item_indexed}//following-sibling::md-list[@aria-hidden="true"]
    Selenium2Library.Page Should Not Contain Element    ${module_list_item_collapsed_indexed}

Expand Module And Click Module Operational Item
    [Arguments]    ${module_name}    ${module_id_index}
    [Documentation]    Clicks module list item in modules tab and then clicks its operational item to load operational tab in module detail.
    ...    Arguments are either module name, or module id index, that is a number, or ${EMPTY}, if the option is not used.
    Expand Module    ${module_name}    ${module_id_index}
    Click Indexed Module Operational To Load Module Detail Operational Tab    ${module_id_index}

Expand Module And Click Module Config Item
    [Arguments]    ${module_name}    ${module_id_index}
    [Documentation]    Clicks module list item in modules tab and then clicks its config item to load operational tab in module detail.
    ...    Arguments are either module name, or module id index, that is a number, or ${EMPTY}, if the option is not used.
    Expand Module    ${module_name}    ${module_id_index}
    Click Indexed Module Config To Load Module Detail Config Tab    ${module_id_index}

Navigate From Yangman Submenu To Testing Module Operational Tab
    [Arguments]    ${testing_module_name}
    [Documentation]    Navigates from loaded Yangman URL to testing module detail operational tab.
    ${module_id_index}=    YangmanKeywords.Return Module ID Index From Module Name    ${testing_module_name}
    Selenium2Library.Wait Until Page Does Not Contain Element    ${testing_module_name}
    Expand Module And Click Module Operational Item    ${EMPTY}    ${module_id_index}

Navigate From Yangman Submenu To Testing Module Config Tab
    [Arguments]    ${testing_module_name}
    [Documentation]    Navigates from loaded Yangman URL to testing module detail config tab.
    ${module_id_index}=    YangmanKeywords.Return Module ID Index From Module Name    ${testing_module_name}
    Selenium2Library.Wait Until Page Does Not Contain Element    ${MODULES_WERE_LOADED_ALERT}
    Expand Module And Click Module Config Item    ${EMPTY}    ${module_id_index}

Select Module Detail Operational Tab
    [Documentation]    Selects operational tab in module detail.
    ${status}=    BuiltIn.Run Keyword And Return Status    Selenium2Library.Page Should Contain Element    ${MODULE_DETAIL_OPERATIONAL_TAB_SELECTED}
    BuiltIn.Run Keyword If    "${status}"=="False"    Selenium2Library.Click Element    ${MODULE_DETAIL_OPERATIONAL_TAB_DESELECTED}
    Selenium2Library.Wait Until Page Contains Element    ${MODULE_DETAIL_OPERATIONAL_TAB_SELECTED}

Select Module Detail Config Tab
    [Documentation]    Selects config tab in module detail.
    ${status}=    BuiltIn.Run Keyword And Return Status    Selenium2Library.Page Should Contain Element    ${MODULE_DETAIL_CONFIG_TAB_SELECTED}
    BuiltIn.Run Keyword If    "${status}"=="False"    Selenium2Library.Click Element    ${MODULE_DETAIL_CONFIG_TAB_DESELECTED}
    Selenium2Library.Wait Until Page Contains Element    ${MODULE_DETAIL_CONFIG_TAB_SELECTED}

Expand All Branches In Module Detail Content Active Tab
    [Documentation]    Expands all branches in module detail active operations or operational or config tab.
    Selenium2Library.Wait Until Element Is Visible    ${MODULE_DETAIL_EXPAND_BRANCH_BUTTON}
    : FOR    ${i}    IN RANGE    1    1000
    \    ${count}=    Selenium2Library.Get Matching Xpath Count    ${MODULE_DETAIL_EXPAND_BRANCH_BUTTON}
    \    BuiltIn.Exit For Loop If    ${count}==0
    \    BuiltIn.Wait Until Keyword Succeeds    30 s    5 s    GUIKeywords.Focus And Click Element    ${MODULE_DETAIL_EXPAND_BRANCH_BUTTON}
    Selenium2Library.Wait Until Page Does Not Contain Element    ${MODULE_DETAIL_EXPAND_BRANCH_BUTTON}

Collapse All Branches In Module Detail Content Active Tab
    [Documentation]    Collapses all branches in module detail active operations or operational or config tab.
    Selenium2Library.Wait Until Element Is Visible    ${MODULE_DETAIL_COLLAPSE_BRANCH_BUTTON}
    : FOR    ${i}    IN RANGE    1    1000
    \    ${count}=    Selenium2Library.Get Matching Xpath Count    ${MODULE_DETAIL_COLLAPSE_BRANCH_BUTTON}
    \    BuiltIn.Exit For Loop If    ${count}==0
    \    BuiltIn.Wait Until Keyword Succeeds    30 s    5 s    GUIKeywords.Focus And Click Element    ${MODULE_DETAIL_COLLAPSE_BRANCH_BUTTON}
    Selenium2Library.Wait Until Page Does Not Contain Element    ${MODULE_DETAIL_COLLAPSE_BRANCH_BUTTON}

Catenate Branch Id
    [Arguments]    ${index}
    [Documentation]    Catenates and returns string - branch id in the format "branch-"${index}""
    ${branch_id}=    BuiltIn.Catenate    SEPARATOR=    ${BRANCH_ID_LABEL}    ${index}
    [Return]    ${branch_id}

Return Module Detail Labelled Branch Xpath
    [Arguments]    ${branch_label}
    [Documentation]    Returns xpath of module detail labelled branch.
    ${labelled_branch_xpath}=    BuiltIn.Set Variable    ${MODULE_DETAIL_BRANCH}//span[contains(@class, "indented tree-label ng-binding flex") and contains(text(), "${branch_label}")]
    [Return]    ${labelled_branch_xpath}

Return Module Detail Branch ID From Branch Label
    [Arguments]    ${branch_label}
    [Documentation]    Catenates and returns string - module detail branch id in the format "branch-"${index}"".
    ${labelled_branch_xpath}=    Return Module Detail Labelled Branch Xpath    ${branch_label}
    ${branch_id}=    Selenium2Library.Get Element Attribute    ${labelled_branch_xpath}//ancestor::md-list-item[contains(@id, "${BRANCH_ID_LABEL}")]@id
    [Return]    ${branch_id}

Return Module Detail Branch Indexed
    [Arguments]    ${branch_id}
    [Documentation]    Returns indexed Xpath of the module detail branch. Argument is ${branch_id} in the form "branch-"${index}"".
    ${module_detail_branch_indexed}=    BuiltIn.Set Variable    ${MODULE_DETAIL_ACTIVE_TAB_CONTENT}//md-list-item[contains(@id, "${branch_id}")]
    [Return]    ${module_detail_branch_indexed}

Return Indexed Branch Label
    [Arguments]    ${module_detail_branch_indexed}
    [Documentation]    Returns string - label of indexed branch in module detail.
    ${branch_label}=    Selenium2Library.Get Text    ${module_detail_branch_indexed}//span[@class="indented tree-label ng-binding flex"]
    [Return]    ${branch_label}

Return Branch Label Without Curly Braces Part
    [Arguments]    ${branch_label}
    [Documentation]    Returns string - part of label of indexed branch in module detail without curly braces part.
    ${branch_label_without_curly_braces_part}=    String.Fetch From Left    ${branch_label}    ${SPACE}
    [Return]    ${branch_label_without_curly_braces_part}

Return Labelled Branch Toggle Button
    [Arguments]    ${labelled_branch_xpath}
    [Documentation]    Returns xpath of toggle button of labelled branch in module detail.
    ${labelled_branch_toggle_button}=    BuiltIn.Set Variable    ${labelled_branch_xpath}//preceding-sibling::md-icon[contains(@id, "toggle-branch-")]
    [Return]    ${labelled_branch_toggle_button}

Return Branch Toggle Button From Branch Label And Click
    [Arguments]    ${branch_label}
    [Documentation]    Returns xpath toggle button of labelled branch in module detail and clicks it.
    ${labelled_branch_xpath}=    Return Module Detail Labelled Branch Xpath    ${branch_label}
    ${labelled_branch_toggle_button}=    Return Labelled Branch Toggle Button    ${labelled_branch_xpath}
    Selenium2Library.Page Should Contain Element    ${labelled_branch_toggle_button}
    Selenium2Library.Click Element    ${labelled_branch_toggle_button}

Click Module Detail Branch Indexed
    [Arguments]    ${module_detail_branch_indexed}
    [Documentation]    Click indexed branch in module detail.
    Selenium2Library.Page Should Contain Element    ${module_detail_branch_indexed}
    GUIKeywords.Mouse Down And Mouse Up Click Element    ${module_detail_branch_indexed}

Return Form Top Element Label
    [Documentation]    Returns string - form top element label.
    ${form_top_element_label}=    Selenium2Library.Get Text    ${FORM_TOP_ELEMENT_LABEL_XPATH}
    [Return]    ${form_top_element_label}

Return Form Top Element Labelled
    [Arguments]    ${label}
    [Documentation]    Returns xpath of form top element with label.
    ${form_top_element_labelled}=    BuiltIn.Set Variable    ${FORM_TOP_ELEMENT_POINTER}//span[contains(@class, "ng-binding ng-scope") and contains(text(), "${label}")]
    [Return]    ${form_top_element_labelled}

Verify Module Detail Branch Is List Branch
    [Arguments]    ${module_detail_branch_indexed}
    [Documentation]    Returns status "True" if module detail branch is a list branch and "False" if module detail branch is not a list brnach.
    ${branch_label}=    Return Indexed Branch Label    ${module_detail_branch_indexed}
    ${branch_is_list_evaluation}=    BuiltIn.Run Keyword And Return Status    BuiltIn.Should Contain    ${branch_label}    {
    [Return]    ${branch_is_list_evaluation}

Return Form List Item With Index Or Key
    [Arguments]    ${branch_label}    ${branch_label_curly_braces_part}    ${index_or_key}
    [Documentation]    Returns string - catenated branch label and index, in the form "label [${index_or_key}]" or "label <${branch_label_curly_braces_part}:${index_or_key}>".
    ${branch_label_without_curly_braces_part}=    Return Branch Label Without Curly Braces Part    ${branch_label}
    ${key_part}=    BuiltIn.Set Variable    <${branch_label_curly_braces_part}:${index_or_key}>
    ${list_item_with_index_or_key}=    BuiltIn.Set Variable If    "${branch_label_curly_braces_part}"=="${EMPTY}"    ${FORM_TOP_ELEMENT_LIST_ITEM_LABEL}[contains(text(), "${branch_label_without_curly_braces_part}") and contains(text(), "[${index_or_key}]")]    ${FORM_TOP_ELEMENT_LIST_ITEM_LABEL}[contains(text(), "${branch_label_without_curly_braces_part}") and contains(text(), "${key_part}")]
    [Return]    ${list_item_with_index_or_key}

Verify List Item With Index Or Key Is Visible
    [Arguments]    ${branch_label}    ${branch_label_curly_braces_part}    ${index_or_key}
    [Documentation]    Verifies that form list item with given index or key is visible.
    ${list_item_with_index_or_key}=    Return Form List Item With Index Or Key    ${branch_label}    ${branch_label_curly_braces_part}    ${index_or_key}
    Selenium2Library.Wait Until Element Is Visible    ${list_item_with_index_or_key}

Load Topology Topology Id Node In Form
    [Documentation]    Expands network-topology branch in testing module detail and clicks topology {topology-id} branch to load topology list node in form.
    Select Form View
    ${topology_topology_id_branch}=    Return Module Detail Labelled Branch Xpath    ${TOPOLOGY_TOPOLOGY_ID_LABEL}
    ${status}=    BuiltIn.Run Keyword And Return Status    Selenium2Library.Element Should Be Visible    ${topology_topology_id_branch}
    BuiltIn.Run Keyword If    "${status}"=="False"    YangmanKeywords.Return Branch Toggle Button From Branch Label And Click    ${NETWORK_TOPOLOGY_LABEL}
    YangmanKeywords.Return Branch Toggle Button From Branch Label And Click    ${TOPOLOGY_TOPOLOGY_ID_LABEL}
    Verify List Item With Index Or Key Is Visible    ${TOPOLOGY_TOPOLOGY_ID_LABEL}    ${EMPTY}    0

Verify Sent Data CM Is Displayed
    [Arguments]    ${true_or_false_option}
    [Documentation]    Verifies that sent data code mirror is displayed if ${true_or_false_option} has ${TRUE_OPTION} value, or is not displayed if ${true_or_false_option} is ${FALSE_OPTION}.
    BuiltIn.Run keyword If    "${true_or_false_option}"=="${TRUE_OPTION}"    BuiltIn.Run Keywords    Selenium2Library.Wait Until Page Contains Element    ${SHOW_SENT_DATA_CHECKBOX_SELECTED}
    ...    AND    Selenium2Library.Element Should Be Visible    ${SENT_DATA_CODE_MIRROR_DISPLAYED}
    BuiltIn.Run keyword If    "${true_or_false_option}"=="${FALSE_OPTION}"    BuiltIn.Run Keywords    Selenium2Library.Wait Until Page Contains Element    ${SHOW_SENT_DATA_CHECKBOX_UNSELECTED}
    ...    AND    Selenium2Library.Element Should Not Be Visible    ${SENT_DATA_CODE_MIRROR_DISPLAYED}

Verify Received Data CM Is Displayed
    [Arguments]    ${true_or_false_option}
    [Documentation]    Verifies that received data code mirror is displayed if ${true_or_false_option} has ${TRUE_OPTION} value, or is not displayed if ${true_or_false_option} is ${FALSE_OPTION}.
    BuiltIn.Run keyword If    "${true_or_false_option}"=="${TRUE_OPTION}"    BuiltIn.Run Keywords    Selenium2Library.Wait Until Page Contains Element    ${SHOW_RECEIVED_DATA_CHECKBOX_SELECTED}
    ...    AND    Selenium2Library.Element Should Be Visible    ${Received_Data_Code_Mirror_Displayed}
    BuiltIn.Run keyword If    "${true_or_false_option}"=="${FALSE_OPTION}"    BuiltIn.Run Keywords    Selenium2Library.Wait Until Page Contains Element    ${SHOW_RECEIVED_DATA_CHECKBOX_UNSELECTED}
    ...    AND    Selenium2Library.Element Should Not Be Visible    ${Received_Data_Code_Mirror_Displayed}
