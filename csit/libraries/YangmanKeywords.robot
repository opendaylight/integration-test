*** Settings ***
Documentation       A resource file containing all global keywords to help
...                 Yangman GUI and functional testing.

Library             Collections
Library             Selenium2Library    timeout=30    implicit_wait=30    run_on_failure=Selenium2Library.Log Source
Resource            ../variables/Variables.robot
Resource            GUIKeywords.robot
Resource            ../variables/YangmanGUIVariables.robot


*** Keywords ***
Return List Of Operation IDs
    [Documentation]    Returns list of IDs of Get, Put, Post and Delete options in expanded operation select menu.
    ${list}=    BuiltIn.Create List    ${GET_OPTION}    ${PUT_OPTION}    ${POST_OPTION}    ${DELETE_OPTION}
    RETURN    ${list}

Return List Of Operation Names
    [Documentation]    Returns list of operations names.
    ${list}=    BuiltIn.Create List    GET    PUT    POST    DELETE
    RETURN    ${list}

Expand Operation Select Menu
    [Documentation]    Clicks operation select menu to expand it.
    GUIKeywords.Patient Click    ${OPERATION_SELECT_INPUT}    ${OPERATION_SELECT_MENU_EXPANDED}

Exit Opened Application Dialog
    [Documentation]    Closes opened/ expanded dialogs/ menus by clicking the backdrop.
    Selenium2Library.Click Element    ${SELECT_BACKDROP}

Select Operation
    [Documentation]    Selects chosen operation from expanded operation select menu.
    [Arguments]    ${operation_id}
    ${status}=    BuiltIn.Run Keyword And Return Status
    ...    GUIKeywords.Page Should Contain Element With Wait
    ...    ${OPERATION_SELECT_MENU_EXPANDED}
    IF    "${status}"=="False"
        Expand Operation Select Menu    ${OPERATION_SELECT_INPUT}
    END
    GUIKeywords.Focus And Click Element    ${operation_id}

Verify Selected Operation Is Displayed
    [Documentation]    Verifies that the selected operation is now displayed in collapsed operation select menu.
    [Arguments]    ${selected_operation_name}
    ${selected_operation_xpath}=    BuiltIn.Set Variable
    ...    ${OPERATION_SELECT_INPUT}//span/div[contains(text(), "${selected_operation_name}")]
    GUIKeywords.Page Should Contain Element With Wait    ${selected_operation_xpath}

Select Operation And Verify Operation Has Been Selected
    [Documentation]    Selects chosen operation from expanded operation select menu and verifies the operation has been selected.
    [Arguments]    ${operation_id}    ${selected_operation_name}
    ${status}=    BuiltIn.Run Keyword And Return Status
    ...    GUIKeywords.Page Should Contain Element With Wait
    ...    ${OPERATION_SELECT_MENU_EXPANDED}
    IF    "${status}"=="False"
        Expand Operation Select Menu    ${OPERATION_SELECT_INPUT}
    END
    ${selected_operation_xpath}=    BuiltIn.Set Variable
    ...    ${OPERATION_SELECT_INPUT}//span/div[contains(text(), "${selected_operation_name}")]
    GUIKeywords.Patient Click    ${operation_id}    ${selected_operation_xpath}

Expand Operation Select Menu And Select Operation
    [Documentation]    Expands operation select menu and select operation provided as an argument.
    [Arguments]    ${operation_id}    ${selected_operation_name}
    Expand Operation Select Menu
    Select Operation And Verify Operation Has Been Selected    ${operation_id}    ${selected_operation_name}

Send Request
    [Documentation]    Clicks Send request button and waits until progression bar disappears.
    Selenium2Library.Click Element    ${SEND_BUTTON}
    Selenium2Library.Wait Until Page Contains Element    ${HEADER_LINEAR_PROGRESSION_BAR_HIDDEN}

Verify Request Status Code Matches Desired Code
    [Documentation]    Verifies that execution status code matches regexp provided as an argument.
    [Arguments]    ${desired_code_regexp}
    ${request_status}=    BuiltIn.Wait Until Keyword Succeeds
    ...    30 s
    ...    5 s
    ...    Selenium2Library.Get Text
    ...    ${STATUS_VALUE}
    BuiltIn.Should Match Regexp    ${request_status}    ${desired_code_regexp}

Verify Request Execution Time Is Present
    [Documentation]    Verifies that execution time value is present.
    ${time_value}=    BuiltIn.Wait Until Keyword Succeeds    30 s    5 s    Selenium2Library.Get Text    ${TIME_VALUE}
    BuiltIn.Should Contain    ${time_value}    ${MILLISECONDS_LABEL}

Verify Request Execution Time Is Threedots
    [Documentation]    Verifies that execution time value is threedots.
    ${time_value}=    BuiltIn.Wait Until Keyword Succeeds    30 s    5 s    Selenium2Library.Get Text    ${TIME_VALUE}
    BuiltIn.Should Contain    ${time_value}    ${THREE_DOTS_DEFAULT_STATUS_AND_TIME}

Send Request And Verify Request Status Code Matches Desired Code
    [Documentation]    Sends request and verifies that execution status code matches regexp provided as an argument.
    [Arguments]    ${desired_code_regexp}
    Send Request
    Verify Request Status Code Matches Desired Code    ${desired_code_regexp}
    Verify Request Execution Time Is Present

Execute Chosen Operation From Form
    [Documentation]    Selects operation, selects or unselects fill form with received data after execution checkbox.
    [Arguments]    ${operation_id}    ${selected_operation_name}    ${selected_true_false}
    Expand Operation Select Menu And Select Operation    ${operation_id}    ${selected_operation_name}
    Select Fill Form With Received Data After Execution Checkbox    ${selected_true_false}
    Send Request

Execute Chosen Operation From Form And Check Status Code
    [Documentation]    Selects operation, selects or unselects fill form with received data after execution checkbox and
    ...    verifies that execution status matches regexp provided as an argument.
    [Arguments]    ${operation_id}    ${selected_operation_name}    ${selected_true_false}    ${desired_code_regexp}
    Expand Operation Select Menu And Select Operation    ${operation_id}    ${selected_operation_name}
    Select Fill Form With Received Data After Execution Checkbox    ${selected_true_false}
    Send Request
    IF    "${desired_code_regexp}"=="${THREE_DOTS_DEFAULT_STATUS_AND_TIME}"
        BuiltIn.Run Keywords
        ...    Verify Request Status Code Matches Desired Code
        ...    ${THREE_DOTS_DEFAULT_STATUS_AND_TIME}
        ...    AND
        ...    Verify Request Execution Time Is Threedots
    END
    IF    "${desired_code_regexp}"!="${THREE_DOTS_DEFAULT_STATUS_AND_TIME}"
        BuiltIn.Run Keywords
        ...    Verify Request Status Code Matches Desired Code
        ...    ${desired_code_regexp}
        ...    AND
        ...    Verify Request Execution Time Is Present
    END

Return Labelled Api Path Input
    [Documentation]    Returns Xpath of labelled API path input field.
    [Arguments]    ${branch_label_without_curly_braces_part}
    ${labelled_api_path_input}=    BuiltIn.Set Variable
    ...    ${API_PATH}//span[contains(text(), "/${branch_label_without_curly_braces_part}")]//parent::md-input-container//following-sibling::md-input-container[last()]/input
    RETURN    ${labelled_api_path_input}

Verify Yangman Home Page Elements
    [Documentation]    Verifies presence of Yangman home page elements.
    Selenium2Library.Wait Until Page Contains Element    ${YANGMAN_LOGO}
    Selenium2Library.Log Location
    Modules Tab Is Selected
    Selenium2Library.Page Should Contain Element    ${TOGGLE_MENU_BUTTON}
    Selenium2Library.Page Should Contain Element    ${LOGOUT_BUTTON}
    Verify Selected Operation Is Displayed    GET
    Selenium2Library.Page Should Contain Element    ${REQUEST_URL_INPUT}
    Selenium2Library.Page Should Contain Element    ${SEND_BUTTON}
    Selenium2Library.Page Should Contain Element    ${SAVE_BUTTON}
    Selenium2Library.Page Should Contain Element    ${PARAMETERS_BUTTON}
    Selenium2Library.Page Should Contain Element    ${FORM_RADIOBUTTON_UNSELECTED}
    Selenium2Library.Page Should Contain Element    ${JSON_RADIOBUTTON_SELECTED}
    Selenium2Library.Page Should Contain Element    ${SHOW_SENT_DATA_CHECKBOX_UNSELECTED}
    Selenium2Library.Page Should Contain Element    ${SHOW_RECEIVED_DATA_CHECKBOX_SELECTED}
    Selenium2Library.Page Should Contain Element    ${RECEIVED_DATA_CODE_MIRROR_DISPLAYED}
    Selenium2Library.Page Should Contain Element    ${RECEIVED_DATA_ENLARGE_FONT_SIZE_BUTTON}
    Selenium2Library.Page Should Contain Element    ${RECEIVED_DATA_REDUCE_FONT_SIZE_BUTTON}
    Selenium2Library.Page Should Not Contain Element    ${SENT_DATA_CODE_MIRROR_DISPLAYED}

Select Form View
    [Documentation]    Click Form radiobutton to display form view.
    ${status}=    BuiltIn.Run Keyword And Return Status
    ...    Selenium2Library.Page Should Contain Element
    ...    ${FORM_RADIOBUTTON_SELECTED}
    IF    "${status}"=="False"
        GUIKeywords.Patient Click    ${FORM_RADIOBUTTON_UNSELECTED}    ${FORM_RADIOBUTTON_SELECTED}
    END

Select Json View
    [Documentation]    Click Json radiobutton to display json view.
    ${status}=    BuiltIn.Run Keyword And Return Status
    ...    Selenium2Library.Page Should Contain Element
    ...    ${JSON_RADIOBUTTON_SELECTED}
    IF    "${status}"=="False"
        GUIKeywords.Patient Click    ${JSON_RADIOBUTTON_UNSELECTED}    ${JSON_RADIOBUTTON_SELECTED}
    END

Modules Tab Is Selected
    [Documentation]    Verifies that module tab is selected and history and collection tabs are unselected.
    Selenium2Library.Page Should Contain Element    ${MODULES_TAB_SELECTED}
    Selenium2Library.Page Should Contain Element    ${MODULE_SEARCH_INPUT}
    Selenium2Library.Page Should Contain Element    ${HISTORY_TAB_UNSELECTED}
    Selenium2Library.Page Should Contain Element    ${COLLECTIONS_TAB_UNSELECTED}

Return Number Of Modules Loaded
    [Documentation]    Returns number of modules loaded in Modules tab.
    [Arguments]    ${module_xpath}
    ${number_of_modules}=    Selenium2Library.Get Matching Xpath Count    ${module_xpath}
    RETURN    ${number_of_modules}

Verify Any Module Is Loaded
    [Documentation]    Verifies that at least one module has been loaded in Modules tab.
    ${number_of__modules_loaded}=    Return Number Of Modules Loaded    ${MODULE_LIST_ITEM}
    BuiltIn.Should Be True    ${number_of_modules_loaded}>0

Return Module List Indexed Module
    [Documentation]    Returns indexed Xpath of the module. ${index} is a number.
    [Arguments]    ${index}
    ${module_index}=    BuiltIn.Set Variable    ${MODULE_ID_LABEL}${index}
    ${module_list_item_indexed}=    BuiltIn.Set Variable
    ...    ${MODULE_TAB_CONTENT}//md-list-item[@id="${module_index}"]//div[@class="pointer title layout-align-center-center layout-row"]
    RETURN    ${module_list_item_indexed}

Return Indexed Module Operations Label
    [Documentation]    Returns Xpath of the indexed module's operations item in Modules tab.
    [Arguments]    ${index}
    ${module_list_item_indexed}=    Return Module List Indexed Module    ${index}
    ${indexed_module_operations_label}=    BuiltIn.Set Variable
    ...    ${module_list_item_indexed}//following-sibling::md-list[@aria-hidden="false"]//p[contains(., "${OPERATIONS_LABEL}")]
    RETURN    ${indexed_module_operations_label}

Return Indexed Module Operational Label
    [Documentation]    Returns Xpath of the indexed module`s operational in Modules tab.
    [Arguments]    ${index}
    ${module_list_item_indexed}=    Return Module List Indexed Module    ${index}
    ${indexed_module_operational_label}=    BuiltIn.Set Variable
    ...    ${module_list_item_indexed}//following-sibling::md-list[@aria-hidden="false"]//p[contains(., "${OPERATIONAL_LABEL}")]
    RETURN    ${indexed_module_operational_label}

Return Indexed Module Config Label
    [Documentation]    Returns Xpath of the indexed module`s config in Modules tab.
    [Arguments]    ${index}
    ${module_list_item_indexed}=    Return Module List Indexed Module    ${index}
    ${indexed_module_config_label}=    BuiltIn.Set Variable
    ...    ${module_list_item_indexed}//following-sibling::md-list[@aria-hidden="false"]//p[contains(., "${CONFIG_LABEL}")]
    RETURN    ${indexed_module_config_label}

Click Indexed Module Operations To Load Module Detail Operations Tab
    [Documentation]    Clicks indexed module`s operations to load module detail operations tab.
    [Arguments]    ${index}
    ${indexed_module_operations}=    Return Indexed Module Operations Label    ${index}
    Selenium2Library.Wait Until Page Contains Element    ${indexed_module_operations}
    GUIKeywords.Focus And Click Element    ${indexed_module_operations}
    Selenium2Library.Wait Until Page Contains Element    ${MODULE_DETAIL_OPERATIONS_TAB_SELECTED}

Click Indexed Module Operational To Load Module Detail Operational Tab
    [Documentation]    Clicks indexed module`s operational to load module detail operational tab.
    [Arguments]    ${index}
    ${indexed_module_operational}=    Return Indexed Module Operational Label    ${index}
    Selenium2Library.Wait Until Page Contains Element    ${indexed_module_operational}
    GUIKeywords.Focus And Click Element    ${indexed_module_operational}
    Selenium2Library.Wait Until Page Contains Element    ${MODULE_DETAIL_OPERATIONAL_TAB_SELECTED}

Click Indexed Module Config To Load Module Detail Config Tab
    [Documentation]    Clicks indexed module`s config to load module detail config tab.
    [Arguments]    ${index}
    ${indexed_module_config}=    Return Indexed Module Config Label    ${index}
    Selenium2Library.Wait Until Page Contains Element    ${indexed_module_config}
    GUIKeywords.Focus And Click Element    ${indexed_module_config}
    Selenium2Library.Wait Until Page Contains Element    ${MODULE_DETAIL_CONFIG_TAB_SELECTED}

Return Module ID Index From Module Name
    [Documentation]    Returns number - module id index from module name.
    [Arguments]    ${module_name}
    ${testing_module_xpath}=    BuiltIn.Set Variable
    ...    ${MODULE_TAB_CONTENT}//p[contains(., "${module_name}")]//ancestor::md-list-item[contains(@id, "${MODULE_ID_LABEL}")]
    ${module_id}=    Selenium2Library.Get Element Attribute    ${testing_module_xpath}@id
    ${module_id_index}=    String.Fetch From Right    ${module_id}    ${MODULE_ID_LABEL}
    RETURN    ${module_id_index}

Return Indexed Module From Module Name
    [Documentation]    Returns indexed Xpath of the module from the module`s name.
    [Arguments]    ${module_name}
    ${module_id_index}=    Return Module ID Index From Module Name    ${module_name}
    ${module_list_item_indexed}=    Return Module List Indexed Module    ${module_id_index}
    RETURN    ${module_list_item_indexed}

Return Module List Item Collapsed Indexed
    [Documentation]    Returns Xpath of collapsed indexed module.
    [Arguments]    ${index}
    ${indexed_module}=    Return Module List Indexed Module    ${index}
    ${module_list_item_collapsed_indexed}=    BuiltIn.Set Variable
    ...    ${indexed_module}//following-sibling::md-list[@aria-hidden="true"]
    RETURN    ${module_list_item_collapsed_indexed}

Return Module List Item Expanded Indexed
    [Documentation]    Returns Xpath of expanded indexed module.
    [Arguments]    ${index}
    ${indexed_module}=    Return Module List Indexed Module    ${index}
    ${module_list_item_expanded_indexed}=    BuiltIn.Set Variable
    ...    ${indexed_module}//following-sibling::md-list[@aria-hidden="false"]
    RETURN    ${module_list_item_expanded_indexed}

Return Indexed Module Expander Icon
    [Documentation]    Returns xpath of indexed module expander icon.
    [Arguments]    ${index}
    ${indexed_module}=    Return Module List Indexed Module    ${index}
    ${indexed_module_expander_icon}=    BuiltIn.Set Variable    ${indexed_module}/md-icon
    RETURN    ${indexed_module_expander_icon}

Expand Module
    [Documentation]    Clicks module list item in modules tab to expand the item and display its operations/ operational/ config items.
    ...    Arguments are either module name, or module id index, that is a number, or ${EMPTY}, if the option is not used.
    [Arguments]    ${module_name}    ${module_id_index}
    IF    "${module_name}"!= "${EMPTY}"
        ${module_list_item_indexed}=    Return Indexed Module From Module Name    ${module_name}
    ELSE
        ${module_list_item_indexed}=    Set Variable    ${None}
    END
    IF    "${module_id_index}"!= "${EMPTY}"
        ${module_list_item_indexed}=    Return Module List Indexed Module    ${module_id_index}
    ELSE
        ${module_list_item_indexed}=    Set Variable    ${None}
    END
    ${module_list_item_expanded_indexed}=    BuiltIn.Set Variable
    ...    ${module_list_item_indexed}//following-sibling::md-list[@aria-hidden="false"]
    GUIKeywords.Mouse Down And Mouse Up Click Element    ${module_list_item_indexed}
    Selenium2Library.Wait Until Page Contains Element    ${module_list_item_expanded_indexed}

Expand Module And Click Module Operational Item
    [Documentation]    Clicks module list item in modules tab and then clicks its operational item to load operational tab in module detail.
    ...    Arguments are either module name, or module id index, that is a number, or ${EMPTY}, if the option is not used.
    [Arguments]    ${module_name}    ${module_id_index}
    Expand Module    ${module_name}    ${module_id_index}
    Click Indexed Module Operational To Load Module Detail Operational Tab    ${module_id_index}

Expand Module And Click Module Config Item
    [Documentation]    Clicks module list item in modules tab and then clicks its config item to load operational tab in module detail.
    ...    Arguments are either module name, or module id index, that is a number, or ${EMPTY}, if the option is not used.
    [Arguments]    ${module_name}    ${module_id_index}
    Expand Module    ${module_name}    ${module_id_index}
    Click Indexed Module Config To Load Module Detail Config Tab    ${module_id_index}

Navigate From Yangman Submenu To Testing Module Operational Tab
    [Documentation]    Navigates from loaded Yangman URL to testing module detail operational tab.
    [Arguments]    ${testing_module_name}
    ${module_id_index}=    YangmanKeywords.Return Module ID Index From Module Name    ${testing_module_name}
    Selenium2Library.Wait Until Page Does Not Contain Element    ${MODULES_WERE_LOADED_ALERT}
    Expand Module And Click Module Operational Item    ${EMPTY}    ${module_id_index}

Navigate From Yangman Submenu To Testing Module Config Tab
    [Documentation]    Navigates from loaded Yangman URL to testing module detail config tab.
    [Arguments]    ${testing_module_name}
    ${module_id_index}=    YangmanKeywords.Return Module ID Index From Module Name    ${testing_module_name}
    Selenium2Library.Wait Until Page Does Not Contain Element    ${MODULES_WERE_LOADED_ALERT}
    Expand Module And Click Module Config Item    ${EMPTY}    ${module_id_index}

Compose Branch Id
    [Documentation]    Composes and returns string - branch id in the format branch-${index}.
    [Arguments]    ${index}
    RETURN    ${BRANCH_ID_LABEL}${index}

Toggle Module Detail To Modules Or History Or Collections Tab
    [Documentation]    Click toggle module detail button to toggle from module detail to modules or history or collections tab.
    Selenium2Library.Wait Until Element Is Visible    ${TOGGLE_MODULE_DETAIL_BUTTON_LEFT}
    GUIKeywords.Focus And Click Element    ${TOGGLE_MODULE_DETAIL_BUTTON_LEFT}

Select Module Detail Operational Tab
    [Documentation]    Selects operational tab in module detail.
    ${status}=    BuiltIn.Run Keyword And Return Status
    ...    Selenium2Library.Page Should Contain Element
    ...    ${MODULE_DETAIL_OPERATIONAL_TAB_SELECTED}
    IF    "${status}"=="False"
        Selenium2Library.Click Element    ${MODULE_DETAIL_OPERATIONAL_TAB_DESELECTED}
    END
    Selenium2Library.Wait Until Page Contains Element    ${MODULE_DETAIL_OPERATIONAL_TAB_SELECTED}

Select Module Detail Config Tab
    [Documentation]    Selects config tab in module detail.
    ${status}=    BuiltIn.Run Keyword And Return Status
    ...    Selenium2Library.Page Should Contain Element
    ...    ${MODULE_DETAIL_CONFIG_TAB_SELECTED}
    IF    "${status}"=="False"
        Selenium2Library.Click Element    ${MODULE_DETAIL_CONFIG_TAB_DESELECTED}
    END
    Selenium2Library.Wait Until Page Contains Element    ${MODULE_DETAIL_CONFIG_TAB_SELECTED}

Expand All Branches In Module Detail Content Active Tab
    [Documentation]    Expands all branches in module detail active operations or operational or config tab.
    Selenium2Library.Wait Until Element Is Visible    ${MODULE_DETAIL_EXPAND_BRANCH_BUTTON}
    FOR    ${i}    IN RANGE    1    1000
        ${count}=    Selenium2Library.Get Matching Xpath Count    ${MODULE_DETAIL_EXPAND_BRANCH_BUTTON}
        IF    ${count}==0            BREAK
        BuiltIn.Wait Until Keyword Succeeds
        ...    30 s
        ...    5 s
        ...    GUIKeywords.Focus And Click Element
        ...    ${MODULE_DETAIL_EXPAND_BRANCH_BUTTON}
    END
    Selenium2Library.Wait Until Page Does Not Contain Element    ${MODULE_DETAIL_EXPAND_BRANCH_BUTTON}

Collapse All Branches In Module Detail Content Active Tab
    [Documentation]    Collapses all branches in module detail active operations or operational or config tab.
    Selenium2Library.Wait Until Element Is Visible    ${MODULE_DETAIL_COLLAPSE_BRANCH_BUTTON}
    FOR    ${i}    IN RANGE    1    1000
        ${count}=    Selenium2Library.Get Matching Xpath Count    ${MODULE_DETAIL_COLLAPSE_BRANCH_BUTTON}
        IF    ${count}==0            BREAK
        BuiltIn.Wait Until Keyword Succeeds
        ...    30 s
        ...    5 s
        ...    GUIKeywords.Focus And Click Element
        ...    ${MODULE_DETAIL_COLLAPSE_BRANCH_BUTTON}
    END
    Selenium2Library.Wait Until Page Does Not Contain Element    ${MODULE_DETAIL_COLLAPSE_BRANCH_BUTTON}

Return Module Detail Labelled Branch Xpath
    [Documentation]    Returns xpath of module detail labelled branch.
    [Arguments]    ${branch_label}
    ${labelled_branch_xpath}=    BuiltIn.Set Variable
    ...    ${MODULE_DETAIL_BRANCH}//span[contains(@class, "indented tree-label ng-binding flex") and contains(text(), "${branch_label}")]
    RETURN    ${labelled_branch_xpath}

Return Module Detail Branch ID From Branch Label
    [Documentation]    Returns string - module detail branch id in the format branch-${index}.
    [Arguments]    ${branch_label}
    ${labelled_branch_xpath}=    Return Module Detail Labelled Branch Xpath    ${branch_label}
    ${branch_id}=    Selenium2Library.Get Element Attribute
    ...    ${labelled_branch_xpath}//ancestor::md-list-item[contains(@id, "${BRANCH_ID_LABEL}")]@id
    RETURN    ${branch_id}

Return Module Detail Branch Indexed
    [Documentation]    Returns indexed Xpath of the module detail branch. Argument is ${branch_id} in the form "branch-"${index}"".
    [Arguments]    ${branch_id}
    ${module_detail_branch_indexed}=    BuiltIn.Set Variable
    ...    ${MODULE_DETAIL_ACTIVE_TAB_CONTENT}//md-list-item[contains(@id, "${branch_id}")]
    RETURN    ${module_detail_branch_indexed}

Return Indexed Branch Label
    [Documentation]    Returns string - label of indexed branch in module detail.
    [Arguments]    ${module_detail_branch_indexed}
    ${branch_label}=    Selenium2Library.Get Text
    ...    ${module_detail_branch_indexed}//span[@class="indented tree-label ng-binding flex"]
    RETURN    ${branch_label}

Return Branch Label Without Curly Braces Part
    [Documentation]    Returns string - part of label of indexed branch in module detail without curly braces part.
    [Arguments]    ${branch_label}
    ${branch_label_without_curly_braces_part}=    String.Fetch From Left    ${branch_label}    ${SPACE}
    RETURN    ${branch_label_without_curly_braces_part}

Return Branch Label Curly Braces Part Without Braces
    [Documentation]    Returns string - curly braces part of label of indexed branch in module detail without curly braces.
    [Arguments]    ${branch_label}
    ${branch_label_curly_braces_part}=    String.Fetch From Right    ${branch_label}    ${SPACE}
    ${branch_label_curly_braces_part}=    String.Strip String    ${branch_label_curly_braces_part}    characters={}
    RETURN    ${branch_label_curly_braces_part}

Return Labelled Branch Toggle Button
    [Documentation]    Returns xpath of toggle button of labelled branch in module detail.
    [Arguments]    ${labelled_branch_xpath}
    ${labelled_branch_toggle_button}=    BuiltIn.Set Variable
    ...    ${labelled_branch_xpath}//preceding-sibling::md-icon[contains(@id, "toggle-branch-")]
    RETURN    ${labelled_branch_toggle_button}

Return Branch Toggle Button From Branch Label And Click
    [Documentation]    Returns xpath toggle button of labelled branch in module detail and clicks it.
    [Arguments]    ${branch_label}
    ${labelled_branch_xpath}=    Return Module Detail Labelled Branch Xpath    ${branch_label}
    ${labelled_branch_toggle_button}=    Return Labelled Branch Toggle Button    ${labelled_branch_xpath}
    Selenium2Library.Page Should Contain Element    ${labelled_branch_toggle_button}
    Selenium2Library.Click Element    ${labelled_branch_toggle_button}

Click Module Detail Branch Indexed
    [Documentation]    Click indexed branch in module detail.
    [Arguments]    ${module_detail_branch_indexed}
    Selenium2Library.Page Should Contain Element    ${module_detail_branch_indexed}
    GUIKeywords.Mouse Down And Mouse Up Click Element    ${module_detail_branch_indexed}

Return And Click Module Detail Branch Indexed
    [Documentation]    Returns and click Click indexed branch in module detail.
    [Arguments]    ${branch_label}
    ${branch_id}=    Return Module Detail Branch ID From Branch Label    ${branch_label}
    ${module_detail_branch_indexed}=    Return Module Detail Branch Indexed    ${branch_id}
    Click Module Detail Branch Indexed    ${module_detail_branch_indexed}

Verify Module Detail Branch Is List Branch
    [Documentation]    Returns status "True" if module detail branch is a list branch and "False" if module detail branch is not a list brnach.
    [Arguments]    ${module_detail_branch_indexed}
    ${branch_label}=    Return Indexed Branch Label    ${module_detail_branch_indexed}
    ${branch_is_list_evaluation}=    BuiltIn.Run Keyword And Return Status
    ...    BuiltIn.Should Contain
    ...    ${branch_label}
    ...    {
    RETURN    ${branch_is_list_evaluation}

Return Form Top Element Label
    [Documentation]    Returns string - form top element label.
    ${form_top_element_label}=    Selenium2Library.Get Text    ${FORM_TOP_ELEMENT_LABEL_XPATH}
    RETURN    ${form_top_element_label}

Return Form Top Element Labelled
    [Documentation]    Returns xpath of form top element with label.
    [Arguments]    ${label}
    ${form_top_element_labelled}=    BuiltIn.Set Variable
    ...    ${FORM_TOP_ELEMENT_POINTER}//span[contains(@class, "ng-binding ng-scope") and contains(text(), "${label}")]
    RETURN    ${form_top_element_labelled}

Return Form List Item With Index Or Key
    [Documentation]    Returns string - catenated branch label and index, in the form "label [${index_or_key}]" or "label <${branch_label_curly_braces_part}:${index_or_key}>".
    [Arguments]    ${branch_label}    ${branch_label_curly_braces_part}    ${index_or_key}
    ${branch_label_without_curly_braces_part}=    Return Branch Label Without Curly Braces Part    ${branch_label}
    ${key_part}=    BuiltIn.Set Variable    <${branch_label_curly_braces_part}:${index_or_key}>
    ${list_item_with_index_or_key}=    BuiltIn.Set Variable If
    ...    "${branch_label_curly_braces_part}"=="${EMPTY}"
    ...    ${FORM_TOP_ELEMENT_LIST_ITEM_LABEL}[contains(text(), "${branch_label_without_curly_braces_part}") and contains(text(), "[${index_or_key}]")]
    ...    ${FORM_TOP_ELEMENT_LIST_ITEM_LABEL}[contains(text(), "${branch_label_without_curly_braces_part}") and contains(text(), "${key_part}")]
    RETURN    ${list_item_with_index_or_key}

Click Form List Item With Index Or Key
    [Documentation]    Clicks form list item with given index or key is visible.
    [Arguments]    ${branch_label}    ${id/ref/prefix_part}    ${index/key}
    ${list_item_with_index_or_key}=    Return Form List Item With Index Or Key
    ...    ${branch_label}
    ...    ${id/ref/prefix_part}
    ...    ${index/key}
    Selenium2Library.Click Element    ${list_item_with_index_or_key}

Verify List Item With Index Or Key Is Visible
    [Documentation]    Verifies that form list item with given index or key is visible.
    [Arguments]    ${branch_label}    ${branch_label_curly_braces_part}    ${index_or_key}
    ${list_item_with_index_or_key}=    Return Form List Item With Index Or Key
    ...    ${branch_label}
    ...    ${branch_label_curly_braces_part}
    ...    ${index_or_key}
    Selenium2Library.Wait Until Element Is Visible    ${list_item_with_index_or_key}

Load And Expand Network Topology In Form
    [Documentation]    Loads and expands network-topology top element container.
    Select Form View
    YangmanKeywords.Return And Click Module Detail Branch Indexed    ${Network_Topology_Branch_Label}
    Selenium2Library.Page Should Contain Element    ${FORM_TOP_ELEMENT_CONTAINER}
    Selenium2Library.Click Element    ${FORM_TOP_ELEMENT_POINTER}

Load Topology Topology Id Node In Form
    [Documentation]    Expands network-topology branch in testing module detail and clicks topology {topology-id} branch to load topology list node in form.
    Select Form View
    ${topology_topology_id_branch}=    Return Module Detail Labelled Branch Xpath    ${TOPOLOGY_TOPOLOGY_ID_LABEL}
    ${status}=    BuiltIn.Run Keyword And Return Status
    ...    Selenium2Library.Element Should Be Visible
    ...    ${topology_topology_id_branch}
    IF    "${status}"=="False"
        Return Branch Toggle Button From Branch Label And Click    ${NETWORK_TOPOLOGY_LABEL}
    END
    YangmanKeywords.Return Branch Toggle Button From Branch Label And Click    ${TOPOLOGY_TOPOLOGY_ID_LABEL}
    Verify List Item With Index Or Key Is Visible    ${TOPOLOGY_TOPOLOGY_ID_LABEL}    ${EMPTY}    0

Load Node Node Id Node In Form
    [Documentation]    Expands network-topology branch in testing module detail and clicks topology {topology-id} branch to load topology list node in form.
    Select Form View
    ${node_node_id_branch}=    Return Module Detail Labelled Branch Xpath    ${NODE_NODE_ID_LABEL}
    ${node_branch_is_visible}=    BuiltIn.Run Keyword And Return Status
    ...    Selenium2Library.Element Should Be Visible
    ...    ${node_node_id_branch}
    IF    "${node_branch_is_visible}"=="False"
        Load Topology Topology Id Node In Form
        Return Branch Toggle Button From Branch Label And Click    ${TOPOLOGY_TOPOLOGY_ID_LABEL}
    END
    YangmanKeywords.Return And Click Module Detail Branch Indexed    ${NODE_NODE_ID_LABEL}
    Verify List Item With Index Or Key Is Visible    ${NODE_NODE_ID_LABEL}    ${EMPTY}    0

Return Labelled Element Yangmenu
    [Documentation]    Returns xpath of labelled element yangmenu in form.
    [Arguments]    ${label}
    ${form_top_element_labelled}=    Return Form Top Element Labelled    ${label}
    ${form_labelled_element_yangmenu}=    BuiltIn.Set Variable
    ...    ${form_top_element_labelled}//following::yang-form-menu
    RETURN    ${form_labelled_element_yangmenu}

Return And Click Labelled Element Yangmenu
    [Documentation]    Returns xpath of labelled element yangmenu in form and clicks the yangmenu.
    [Arguments]    ${label}
    ${form_labelled_element_yangmenu}=    Return Labelled Element Yangmenu    ${label}
    Selenium2Library.Element Should Be Visible    ${form_labelled_element_yangmenu}
    GUIKeywords.Mouse Down And Mouse Up Click Element    ${form_labelled_element_yangmenu}

Return Labelled Element Show Previous Item Arrow
    [Documentation]    Returns xpath of labelled element show previous list item icon in form.
    [Arguments]    ${label}
    ${form_top_element_labelled}=    Return Form Top Element Labelled    ${label}
    ${labelled_show_previous_item_arrow}=    BuiltIn.Set Variable
    ...    ${form_top_element_labelled}//following::md-prev-button[@aria-label="Previous Page"]
    RETURN    ${labelled_show_previous_item_arrow}

Return Labelled Element Show Next Item Arrow
    [Documentation]    Returns xpath of labelled element show next list item icon.
    [Arguments]    ${label}
    ${form_top_element_labelled}=    Return Form Top Element Labelled    ${label}
    ${labelled_show_next_item_arrow}=    BuiltIn.Set Variable
    ...    ${form_top_element_labelled}//following::md-next-button[@aria-label="Next Page"]
    RETURN    ${labelled_show_next_item_arrow}

Return Labelled Form Input Field
    [Documentation]    Returns xpath of labelled form input field.
    [Arguments]    ${branch_label_curly_braces_part}
    ${labelled_input_field}=    BuiltIn.Set Variable
    ...    ${FORM_CONTENT}//span[contains(@class, "ng-binding ng-scope") and contains(text(), "${branch_label_curly_braces_part}")]//following::input
    RETURN    ${labelled_input_field}

Return Labelled Form Select
    [Documentation]    Returns labelled form input field.
    [Arguments]    ${branch_label_curly_braces_part}
    ${labelled_select}=    BuiltIn.Set Variable
    ...    ${FORM_CONTENT}//span[contains(@class, "ng-binding ng-scope") and contains(text(), "${branch_label_curly_braces_part}")]//following::md-select
    RETURN    ${labelled_select}

Input Text To Labelled Form Input Field
    [Documentation]    Returns labelled form input field and inputs the text provided as an argument into it.
    [Arguments]    ${branch_label_curly_braces_part}    ${text}
    ${labelled_input_field}=    Return Labelled Form Input Field    ${branch_label_curly_braces_part}
    Selenium2Library.Input Text    ${labelled_input_field}    ${text}

Verify Form Contains Error Message
    [Documentation]    Verifies that the form contains error message that is provided as an argument.
    [Arguments]    ${error_message}
    ${form_error_message}=    BuiltIn.Set Variable
    ...    //p[contains(@id, "form-error-message") and contains (text(), "${error_message}")]
    Selenium2Library.Page Should Contain Element    ${form_error_message}

Verify No Data Are Displayed In Code Mirror Code
    [Documentation]    Verifies that there are no data displayed in either sent or received data code mirror.
    ...    Value for ${code_mirror_code} is either ${SENT_DATA_CODE_MIRROR_CODE} or ${RECEIVED_DATA_CODE_MIRROR_CODE}.
    [Arguments]    ${code_mirror_code}
    ${number_of_lines_in_code_mirror}=    Selenium2Library.Get Matching Xpath Count    ${code_mirror_code}/div
    BuiltIn.Should Be Equal    ${number_of_lines_in_code_mirror}    1

Verify Sent Data CM Is Displayed
    [Documentation]    Verifies that sent data code mirror is displayed.
    Selenium2Library.Wait Until Element Is Visible    ${SENT_DATA_CODE_MIRROR_DISPLAYED}

Verify Sent Data CM Is Not Displayed
    [Documentation]    Verifies that sent data code mirror is not displayed.
    Selenium2Library.Wait Until Element Is Not Visible    ${SENT_DATA_CODE_MIRROR_DISPLAYED}

Verify Received Data CM Is Displayed
    [Documentation]    Verifies that received data code mirror is displayed.
    Selenium2Library.Wait Until Element Is Visible    ${RECEIVED_DATA_CODE_MIRROR_DISPLAYED}

Verify Received Data CM Is Not Displayed
    [Documentation]    Verifies that received data code mirror is not displayed.
    Selenium2Library.Wait Until Element Is Not Visible    ${RECEIVED_DATA_CODE_MIRROR_DISPLAYED}
