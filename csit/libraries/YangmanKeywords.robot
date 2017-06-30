*** Settings ***
Documentation     A resource file containing all global keywords to help
...               Yangman GUI and functional testing.
Library           Collections
Library           Selenium2Library    timeout=30    implicit_wait=30    run_on_failure=Selenium2Library.Capture Page Screenshot
Resource          ../variables/Variables.robot
Resource          GUIKeywords.robot
Resource          ../variables/YangmanGUIVariables.robot

*** Variables ***

*** Keywords ***
Open DLUX And Login And Navigate To Yangman URL
    [Documentation]    Launches DLUX page using PhantomJS, or Xvfb, or real browser and navigates to yangman url.
    GUIKeywords.Open Or Launch DLUX Page And Log In To DLUX
    GUIKeywords.Navigate To URL    ${YANGMAN_SUBMENU_URL}

Verify Modules Tab Name Is Translated
    [Documentation]    Verifies that Modules tab name is translated from YANGMAN_MODULES to Modules.
    ${modules_tab_name}=    Selenium2Library.Get Text    ${LEFT_TAB_AREA}//md-tab-item[@aria-selected="true"]/span
    BuiltIn.Should Be Equal    ${modules_tab_name}    ${MODULES_TAB_NAME}

Open DLUX And Login And Navigate To Yangman URL And Verify Modules Tab Name Translation
    [Documentation]    Launches DLUX page and navigates to yangman url and verifies translation of modules tab name.
    Open DLUX And Login And Navigate To Yangman URL
    Selenium2Library.Wait Until Page Contains Element    ${YANGMAN_LOGO}
    Selenium2Library.Wait Until Page Contains Element    ${MODULES_WERE_LOADED_ALERT}
    Selenium2Library.Wait Until Page Does Not Contain Element    ${MODULES_WERE_LOADED_ALERT}
    Verify Modules Tab Name Is Translated

Reload Yangman
    [Documentation]    Reloads Yangman application.
    Selenium2Library.Reload Page
    GUIKeywords.Navigate To URL    ${YANGMAN_SUBMENU_URL}
    Selenium2Library.Wait Until Page Does Not Contain Element    ${MODULES_WERE_LOADED_ALERT}

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

Return List Of Operation IDs
    [Documentation]    Returns list of IDs of Get, Put, Post and Delete options in expanded operation select menu.
    ${list}=    BuiltIn.Create List    ${GET_OPTION}    ${PUT_OPTION}    ${POST_OPTION}    ${DELETE_OPTION}
    [Return]    ${list}

Return List Of Operation Names
    [Documentation]    Returns list of operations names.
    ${list}=    BuiltIn.Create List    GET    PUT    POST    DELETE
    [Return]    ${list}

Expand Operation Select Menu
    [Documentation]    Clicks operation select menu to expand it.
    GUIKeywords.Patient Click    ${OPERATION_SELECT_INPUT}    ${OPERATION_SELECT_MENU_EXPANDED}

Exit Opened Application Dialog
    [Documentation]    Closes opened/ expanded dialogs/ menus by clicking the backdrop.
    Selenium2Library.Click Element    ${SELECT_BACKDROP}

Select Operation
    [Arguments]    ${operation_id}
    [Documentation]    Selects chosen operation from expanded operation select menu.
    ${status}=    BuiltIn.Run Keyword And Return Status    GUIKeywords.Page Should Contain Element With Wait    ${OPERATION_SELECT_MENU_EXPANDED}
    BuiltIn.Run Keyword If    "${status}"=="False"    Expand Operation Select Menu
    GUIKeywords.Focus And Click Element    ${operation_id}

Verify Selected Operation Is Displayed
    [Arguments]    ${selected_operation_name}
    [Documentation]    Verifies that the selected operation is now displayed in collapsed operation select menu.
    ${selected_operation_xpath}=    BuiltIn.Set Variable    ${OPERATION_SELECT_INPUT}//span/div[contains(text(), "${selected_operation_name}")]
    GUIKeywords.Page Should Contain Element With Wait    ${selected_operation_xpath}

Select Operation And Verify Operation Has Been Selected
    [Arguments]    ${operation_id}    ${selected_operation_name}
    [Documentation]    Selects chosen operation from expanded operation select menu and verifies the operation has been selected.
    ${status}=    BuiltIn.Run Keyword And Return Status    GUIKeywords.Page Should Contain Element With Wait    ${OPERATION_SELECT_MENU_EXPANDED}
    BuiltIn.Run Keyword If    "${status}"=="False"    Expand Operation Select Menu
    ${selected_operation_xpath}=    BuiltIn.Set Variable    ${OPERATION_SELECT_INPUT}//span/div[contains(., "${selected_operation_name}")]
    GUIKeywords.Helper Click    ${operation_id}    ${selected_operation_xpath}

Expand Operation Select Menu And Select Operation
    [Arguments]    ${operation_id}    ${selected_operation_name}
    [Documentation]    Expands operation select menu and select operation provided as an argument.
    Expand Operation Select Menu
    Select Operation And Verify Operation Has Been Selected    ${operation_id}    ${selected_operation_name}

Send Request
    [Documentation]    Clicks Send request button and waits until progression bar disappears.
    Selenium2Library.Click Element    ${SEND_BUTTON}
    Selenium2Library.Wait Until Page Contains Element    ${HEADER_LINEAR_PROGRESSION_BAR_HIDDEN}

Select Fill Form With Received Data After Execution Checkbox
    [Arguments]    ${selected_or_unselected}
    [Documentation]    Selects or unselects Fill form with received data after execution checkbox. ${selected_or_unselected} variable has two values,
    ...    selected or unselected.
    ${status}=    BuiltIn.Run Keyword And Return Status    Selenium2Library.Element Should Be Visible    ${FILL_FORM_WITH_RECEIVED_DATA_CHECKBOX_SELECTED}
    BuiltIn.Run Keyword If    "${status}"=="True" and "${selected_or_unselected}"=="selected"    BuiltIn.No Operation
    BuiltIn.Run Keyword If    "${status}"=="True" and "${selected_or_unselected}"=="unselected"    BuiltIn.Run Keywords    Selenium2Library.Click Element    ${FILL_FORM_WITH_RECEIVED_DATA_CHECKBOX_SELECTED}
    ...    AND    Selenium2Library.Wait Until Element Is Visible    ${FILL_FORM_WITH_RECEIVED_DATA_CHECKBOX_UNSELECTED}
    BuiltIn.Run Keyword If    "${status}"=="False" and "${selected_or_unselected}"=="selected"    BuiltIn.Run Keywords    Selenium2Library.Click Element    ${FILL_FORM_WITH_RECEIVED_DATA_CHECKBOX_UNSELECTED}
    ...    AND    Selenium2Library.Wait Until Element Is Visible    ${FILL_FORM_WITH_RECEIVED_DATA_CHECKBOX_SELECTED}
    BuiltIn.Run Keyword If    "${status}"=="False" and "${selected_or_unselected}"=="unselected"    BuiltIn.No Operation

Verify Request Status Code Matches Desired Code
    [Arguments]    ${desired_code_regexp}
    [Documentation]    Verifies that execution status code matches regexp provided as an argument.
    ${request_status}=    BuiltIn.Wait Until Keyword Succeeds    30 s    5 s    Selenium2Library.Get Text    ${STATUS_VALUE}
    BuiltIn.Should Match Regexp    ${request_status}    ${desired_code_regexp}

Verify Request Execution Time Is Present
    [Documentation]    Verifies that execution time value is present.
    ${time_value}=    BuiltIn.Wait Until Keyword Succeeds    30 s    5 s    Selenium2Library.Get Text    ${TIME_VALUE}
    BuiltIn.Should Contain    ${time_value}    ${MILLISECONDS_LABEL}

Verify Request Execution Time Is Threedots
    [Documentation]    Verifies that execution time value is threedots.
    ${time_value}=    BuiltIn.Wait Until Keyword Succeeds    30 s    5 s    Selenium2Library.Get Text    ${TIME_VALUE}
    BuiltIn.Should Contain    ${time_value}    ${THREE_DOTS_DEFAULT_STATUS_AND_TIME}

Verify Request Status Code Matches Desired Code And Request Execution Time Is Present
    [Arguments]    ${desired_code_regexp}
    [Documentation]    Verifies that execution status code matches regexp provided as an argument and execution time value is present.
    Verify Request Status Code Matches Desired Code    ${desired_code_regexp}
    Verify Request Execution Time Is Present

Verify Request Status Code Matches Desired Code And Request Execution Time Is Threedots
    [Arguments]    ${desired_code_regexp}
    [Documentation]    Verifies that execution status code matches regexp provided as an argument and execution time value is threedots.
    Verify Request Status Code Matches Desired Code    ${desired_code_regexp}
    Verify Request Execution Time Is Threedots

Send Request And Verify Request Status Code Matches Desired Code
    [Arguments]    ${desired_code_regexp}
    [Documentation]    Sends request and verifies that execution status code matches regexp provided as an argument.
    Send Request
    Verify Request Status Code Matches Desired Code    ${desired_code_regexp}
    Verify Request Execution Time Is Present

Execute Chosen Operation From Form
    [Arguments]    ${operation_id}    ${selected_operation_name}    ${selected_or_unselected}
    [Documentation]    Selects operation, selects or unselects fill form with received data after execution checkbox.
    Expand Operation Select Menu And Select Operation    ${operation_id}    ${selected_operation_name}
    Select Fill Form With Received Data After Execution Checkbox    ${selected_or_unselected}
    Send Request

Execute Chosen Operation From Form And Check Status Code
    [Arguments]    ${operation_id}    ${selected_operation_name}    ${selected_or_unselected}    ${desired_code_regexp}
    [Documentation]    Selects operation, selects or unselects fill form with received data after execution checkbox and
    ...    verifies that execution status matches regexp provided as an argument.
    Expand Operation Select Menu And Select Operation    ${operation_id}    ${selected_operation_name}
    Select Fill Form With Received Data After Execution Checkbox    ${selected_or_unselected}
    Send Request
    BuiltIn.Run Keyword If    "${desired_code_regexp}"=="${THREE_DOTS_DEFAULT_STATUS_AND_TIME}"    BuiltIn.Run Keywords    Verify Request Status Code Matches Desired Code    ${THREE_DOTS_DEFAULT_STATUS_AND_TIME}
    ...    AND    Verify Request Execution Time Is Threedots
    BuiltIn.Run Keyword If    "${desired_code_regexp}"!="${THREE_DOTS_DEFAULT_STATUS_AND_TIME}"    BuiltIn.Run Keywords    Verify Request Status Code Matches Desired Code    ${desired_code_regexp}
    ...    AND    Verify Request Execution Time Is Present

Return Labelled Api Path Input
    [Arguments]    ${branch_label_without_curly_braces_part}
    [Documentation]    Returns Xpath of labelled API path input field.
    ${labelled_api_path_input}=    BuiltIn.Set Variable    ${API_PATH}//span[contains(text(), "/${branch_label_without_curly_braces_part}")]//parent::md-input-container//following-sibling::md-input-container[last()]/input
    [Return]    ${labelled_api_path_input}

Compose Labelled Api Path Input Xpath And Verify It Is Visible
    [Arguments]    ${branch_label_without_curly_braces_part}
    [Documentation]    Composes Xpath of labelled API path input field and verifies th input field is visible.
    ${labelled_api_path_input}=    Return Labelled Api Path Input    ${branch_label_without_curly_braces_part}
    Selenium2Library.Element Should Be Visible    ${labelled_api_path_input}

Verify Labelled Api Path Input Contains Data
    [Arguments]    ${branch_label_without_curly_braces_part}    ${data}
    [Documentation]    Verifies that labelled API path input field contains data provided as an argument.
    ${labelled_api_path_input}=    YangmanKeywords.Return Labelled Api Path Input    ${branch_label_without_curly_braces_part}
    Selenium2Library.Wait Until Element Is Visible    ${labelled_api_path_input}[@aria-label="${data}"]

Verify Labelled Api Path Input Does Not Contain Any Data
    [Arguments]    ${branch_label_without_curly_braces_part}
    [Documentation]    Verifies that labelled API path input field is empty.
    ${labelled_api_path_input}=    YangmanKeywords.Return Labelled Api Path Input    ${branch_label_without_curly_braces_part}
    Selenium2Library.Textfield Value Should Be    ${labelled_api_path_input}    ${EMPTY}

Select Form View
    [Documentation]    Click Form radiobutton to display form view.
    ${status}=    BuiltIn.Run Keyword And Return Status    Selenium2Library.Page Should Contain Element    ${FORM_RADIOBUTTON_SELECTED}
    BuiltIn.Run Keyword If    "${status}"=="False"    GUIKeywords.Patient Click    ${FORM_RADIOBUTTON_UNSELECTED}    ${FORM_RADIOBUTTON_SELECTED}

Select Json View
    [Documentation]    Click Json radiobutton to display json view.
    ${status}=    BuiltIn.Run Keyword And Return Status    Selenium2Library.Page Should Contain Element    ${JSON_RADIOBUTTON_SELECTED}
    BuiltIn.Run Keyword If    "${status}"=="False"    GUIKeywords.Patient Click    ${JSON_RADIOBUTTON_UNSELECTED}    ${JSON_RADIOBUTTON_SELECTED}

Modules Tab Is Selected
    [Documentation]    Verifies that module tab is selected and history and collection tabs are unselected.
    Selenium2Library.Page Should Contain Element    ${MODULES_TAB_SELECTED}
    Selenium2Library.Page Should Contain Element    ${MODULE_SEARCH_INPUT}
    Selenium2Library.Page Should Contain Element    ${HISTORY_TAB_UNSELECTED}
    Selenium2Library.Page Should Contain Element    ${COLLECTIONS_TAB_UNSELECTED}

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
    ${module_index}=    BuiltIn.Set Variable    ${MODULE_ID_LABEL}${index}
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

Return Module List Item Collapsed Indexed
    [Arguments]    ${index}
    [Documentation]    Returns Xpath of collapsed indexed module.
    ${indexed_module}=    Return Module List Indexed Module    ${index}
    ${module_list_item_collapsed_indexed}=    BuiltIn.Set Variable    ${indexed_module}//following-sibling::md-list[@aria-hidden="true"]
    [Return]    ${module_list_item_collapsed_indexed}

Return Module List Item Expanded Indexed
    [Arguments]    ${index}
    [Documentation]    Returns Xpath of expanded indexed module.
    ${indexed_module}=    Return Module List Indexed Module    ${index}
    ${module_list_item_expanded_indexed}=    BuiltIn.Set Variable    ${indexed_module}//following-sibling::md-list[@aria-hidden="false"]
    [Return]    ${module_list_item_expanded_indexed}

Return Indexed Module Expander Icon
    [Arguments]    ${index}
    [Documentation]    Returns xpath of indexed module expander icon.
    ${indexed_module}=    Return Module List Indexed Module    ${index}
    ${indexed_module_expander_icon}=    BuiltIn.Set Variable    ${indexed_module}/md-icon
    [Return]    ${indexed_module_expander_icon}

Expand Module
    [Arguments]    ${module_name}    ${module_id_index}
    [Documentation]    Clicks module list item in modules tab to expand the item and display its operations/ operational/ config items.
    ...    Arguments are either module name, or module id index, that is a number, or ${EMPTY}, if the option is not used.
    ${module_list_item_indexed}=    BuiltIn.Run Keyword If    "${module_name}"!= "${EMPTY}"    Return Indexed Module From Module Name    ${module_name}
    ${module_list_item_indexed}=    BuiltIn.Run Keyword If    "${module_id_index}"!= "${EMPTY}"    Return Module List Indexed Module    ${module_id_index}
    ${module_list_item_expanded_indexed}=    BuiltIn.Set Variable    ${module_list_item_indexed}//following-sibling::md-list[@aria-hidden="false"]
    ${module_list_item_indexed_is_expanded}=    BuiltIn.Run Keyword And Return Status    Selenium2Library.Wait Until Page Contains Element    ${module_list_item_expanded_indexed}
    BuiltIn.Run Keyword If    ${module_list_item_indexed_is_expanded}==False    GUIKeywords.Mouse Down And Mouse Up Click Element    ${module_list_item_indexed}
    Selenium2Library.Wait Until Page Contains Element    ${module_list_item_expanded_indexed}

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

Navigate To Modules Tab
    [Documentation]    Navigates to Modules tab.
    ${toggle_module_detail_button_left_is_visible}=    BuiltIn.Run Keyword And Return Status    Selenium2Library.Element Should Be Visible    ${TOGGLE_MODULE_DETAIL_BUTTON_LEFT}
    BuiltIn.Run Keyword If    ${toggle_module_detail_button_left_is_visible}==True    GUIKeywords.Patient Click    ${TOGGLE_MODULE_DETAIL_BUTTON_LEFT}    ${TOGGLE_MODULE_DETAIL_BUTTON_RIGHT}
    ${modules_tab_is_selected}=    BuiltIn.Run Keyword And Return Status    Selenium2Library.Element Should Be Visible    ${MODULES_TAB_SELECTED}
    BuiltIn.Run Keyword If    ${modules_tab_is_selected}==False    GUIKeywords.Patient Click    ${MODULES_TAB_UNSELECTED}    ${MODULES_TAB_SELECTED}

Navigate From Yangman Submenu To Testing Module Operational Tab
    [Arguments]    ${testing_module_name}
    [Documentation]    Navigates from loaded Yangman URL to testing module detail operational tab.
    Navigate To Modules Tab
    ${module_id_index}=    YangmanKeywords.Return Module ID Index From Module Name    ${testing_module_name}
    Selenium2Library.Wait Until Page Does Not Contain Element    ${MODULES_WERE_LOADED_ALERT}
    Expand Module And Click Module Operational Item    ${EMPTY}    ${module_id_index}

Navigate From Yangman Submenu To Testing Module Config Tab
    [Arguments]    ${testing_module_name}
    [Documentation]    Navigates from loaded Yangman URL to testing module detail config tab.
    Navigate To Modules Tab
    ${indexed_module_list_item}=    Return Indexed Module From Module Name    ${testing_module_name}
    Selenium2LIbrary.Wait Until Page Contains Element    ${indexed_module_list_item}
    Selenium2Library.Wait Until Page Does Not Contain Element    ${MODULES_WERE_LOADED_ALERT}
    ${module_id_index}=    YangmanKeywords.Return Module ID Index From Module Name    ${testing_module_name}
    Expand Module And Click Module Config Item    ${EMPTY}    ${module_id_index}

Compose Branch Id
    [Arguments]    ${index}
    [Documentation]    Composes and returns string - branch id in the format branch-${index}.
    BuiltIn.Return From Keyword    ${BRANCH_ID_LABEL}${index}

Toggle Module Detail To Modules Or History Or Collections Tab
    [Documentation]    Click toggle module detail button to toggle from module detail to modules or history or collections tab.
    Selenium2Library.Wait Until Element Is Visible    ${TOGGLE_MODULE_DETAIL_BUTTON_LEFT}
    GUIKeywords.Focus And Click Element    ${TOGGLE_MODULE_DETAIL_BUTTON_LEFT}

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

Return Module Detail Labelled Branch Xpath
    [Arguments]    ${branch_label}
    [Documentation]    Returns xpath of module detail labelled branch.
    ${labelled_branch_xpath}=    BuiltIn.Set Variable    ${MODULE_DETAIL_BRANCH}//span[contains(@class, "indented tree-label ng-binding flex") and contains(text(), "${branch_label}")]
    [Return]    ${labelled_branch_xpath}

Return Module Detail Branch ID From Branch Label
    [Arguments]    ${branch_label}
    [Documentation]    Returns string - module detail branch id in the format branch-${index}.
    ${labelled_branch_xpath}=    Return Module Detail Labelled Branch Xpath    ${branch_label}
    ${branch_id}=    Selenium2Library.Get Element Attribute    ${labelled_branch_xpath}//ancestor::md-list-item[contains(@id, "${BRANCH_ID_LABEL}")]@id
    [Return]    ${branch_id}

Return Module Detail Branch Indexed
    [Arguments]    ${branch_id}
    [Documentation]    Returns indexed Xpath of the module detail branch. Argument is ${branch_id} in the form branch-${index}.
    ${module_detail_branch_indexed}=    BuiltIn.Set Variable    ${MODULE_DETAIL_ACTIVE_TAB_CONTENT}//md-list-item[contains(@id, "${branch_id}")]
    [Return]    ${module_detail_branch_indexed}

Compose Branch Id And Return Module Detail Branch Indexed
    [Arguments]    ${index}
    [Documentation]    Composes branch id in the format branch-${index} and returns indexed Xpath of the module detail branch.
    ${branch_id}=    YangmanKeywords.Compose Branch Id    ${index}
    ${module_detail_branch_indexed}=    YangmanKeywords.Return Module Detail Branch Indexed    ${branch_id}
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

Return Branch Label Curly Braces Part Without Braces
    [Arguments]    ${branch_label}
    [Documentation]    Returns string - curly braces part of label of indexed branch in module detail without curly braces.
    ${branch_label_curly_braces_part}=    String.Fetch From Right    ${branch_label}    ${SPACE}
    ${branch_label_curly_braces_part}=    String.Strip String    ${branch_label_curly_braces_part}    characters={}
    [Return]    ${branch_label_curly_braces_part}

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
    GUIKeywords.Focus And Click Element    ${labelled_branch_toggle_button}

Click Module Detail Branch Indexed
    [Arguments]    ${module_detail_branch_indexed}
    [Documentation]    Click indexed branch in module detail.
    Selenium2Library.Page Should Contain Element    ${module_detail_branch_indexed}
    GUIKeywords.Mouse Down And Mouse Up Click Element    ${module_detail_branch_indexed}

Return And Click Module Detail Branch Indexed
    [Arguments]    ${branch_label}
    [Documentation]    Returns and click Click indexed branch in module detail.
    ${branch_id}=    Return Module Detail Branch ID From Branch Label    ${branch_label}
    ${module_detail_branch_indexed}=    Return Module Detail Branch Indexed    ${branch_id}
    Click Module Detail Branch Indexed    ${module_detail_branch_indexed}

Verify Module Detail Branch Is List Branch
    [Arguments]    ${module_detail_branch_indexed}
    [Documentation]    Returns status "True" if module detail branch is a list branch and "False" if module detail branch is not a list brnach.
    ${branch_label}=    Return Indexed Branch Label    ${module_detail_branch_indexed}
    ${branch_is_list_evaluation}=    BuiltIn.Run Keyword And Return Status    BuiltIn.Should Contain    ${branch_label}    {
    [Return]    ${branch_is_list_evaluation}

Return Form Top Element Label
    [Documentation]    Returns string - form top element label.
    ${form_top_element_label}=    Selenium2Library.Get Text    ${FORM_TOP_ELEMENT_LABEL_XPATH}
    [Return]    ${form_top_element_label}

Return Form Top Element Labelled
    [Arguments]    ${label}
    [Documentation]    Returns xpath of form top element with label.
    ${form_top_element_labelled}=    BuiltIn.Set Variable    ${FORM_TOP_ELEMENT_POINTER}//span[contains(@class, "ng-binding ng-scope") and contains(text(), "${label}")]
    [Return]    ${form_top_element_labelled}

Return Form List Item With Index Or Key
    [Arguments]    ${branch_label}    ${branch_label_curly_braces_part}    ${index_or_key}
    [Documentation]    Returns string - catenated branch label and index, in the form "label [${index_or_key}]" or "label <${branch_label_curly_braces_part}:${index_or_key}>".
    ${branch_label_without_curly_braces_part}=    Return Branch Label Without Curly Braces Part    ${branch_label}
    ${key_part}=    BuiltIn.Set Variable    <${branch_label_curly_braces_part}:${index_or_key}>
    ${list_item_with_index_or_key}=    BuiltIn.Set Variable If    "${branch_label_curly_braces_part}"=="${EMPTY}"    ${FORM_TOP_ELEMENT_LIST_ITEM_LABEL}[contains(text(), "${branch_label_without_curly_braces_part}") and contains(text(), "[${index_or_key}]")]    ${FORM_TOP_ELEMENT_LIST_ITEM_LABEL}[contains(text(), "${branch_label_without_curly_braces_part}") and contains(text(), "${key_part}")]
    [Return]    ${list_item_with_index_or_key}

Click Form List Item With Index Or Key
    [Arguments]    ${branch_label}    ${id/ref/prefix_part}    ${index/key}
    [Documentation]    Clicks form list item with given index or key is visible.
    ${list_item_with_index_or_key}=    Return Form List Item With Index Or Key    ${branch_label}    ${id/ref/prefix_part}    ${index/key}
    Selenium2Library.Click Element    ${list_item_with_index_or_key}

Verify List Item With Index Or Key Is Visible
    [Arguments]    ${branch_label}    ${branch_label_curly_braces_part}    ${index_or_key}
    [Documentation]    Verifies that form list item with given index or key is visible.
    ${list_item_with_index_or_key}=    Return Form List Item With Index Or Key    ${branch_label}    ${branch_label_curly_braces_part}    ${index_or_key}
    Selenium2Library.Wait Until Element Is Visible    ${list_item_with_index_or_key}

Load And Expand Network Topology In Form
    [Documentation]    Loads and expands network-topology top element container.
    Select Form View
    YangmanKeywords.Return And Click Module Detail Branch Indexed    ${NETWORK_TOPOLOGY_LABEL}
    Selenium2Library.Page Should Contain Element    ${FORM_TOP_ELEMENT_CONTAINER}
    Selenium2Library.Click Element    ${FORM_TOP_ELEMENT_POINTER}

Load Topology Topology Id Node In Form
    [Documentation]    Expands network-topology branch in testing module detail and clicks topology {topology-id} branch to load topology list node in form.
    Select Form View
    ${topology_topology_id_branch}=    Return Module Detail Labelled Branch Xpath    ${TOPOLOGY_TOPOLOGY_ID_LABEL}
    ${status}=    BuiltIn.Run Keyword And Return Status    Selenium2Library.Element Should Be Visible    ${topology_topology_id_branch}
    BuiltIn.Run Keyword If    "${status}"=="False"    Return Branch Toggle Button From Branch Label And Click    ${NETWORK_TOPOLOGY_LABEL}
    Return And Click Module Detail Branch Indexed    ${TOPOLOGY_TOPOLOGY_ID_LABEL}
    Verify List Item With Index Or Key Is Visible    ${TOPOLOGY_TOPOLOGY_ID_LABEL}    ${EMPTY}    0

Navigate From Yangman Submenu To Testing Module Config And Load Topology Topology Id Node In Form
    [Arguments]    ${testing_module_name}
    [Documentation]    Navigates from yangman submenu to testing module config tab and loads tpology topology id node in the form view.
    YangmanKeywords.Navigate From Yangman Submenu To Testing Module Config Tab    ${testing_module_name}
    YangmanKeywords.Expand All Branches In Module Detail Content Active Tab
    YangmanKeywords.Load Topology Topology Id Node In Form

Load Node Node Id Node In Form
    [Documentation]    Expands network-topology branch in testing module detail and clicks topology {topology-id} branch to load topology list node in form.
    Select Form View
    ${node_node_id_branch}=    Return Module Detail Labelled Branch Xpath    ${NODE_NODE_ID_LABEL}
    ${node_branch_is_visible}=    BuiltIn.Run Keyword And Return Status    Selenium2Library.Element Should Be Visible    ${node_node_id_branch}
    BuiltIn.Run Keyword If    "${node_branch_is_visible}"=="False"    Run Keywords    Load Topology Topology Id Node In Form
    ...    AND    Return Branch Toggle Button From Branch Label And Click    ${TOPOLOGY_TOPOLOGY_ID_LABEL}
    Return And Click Module Detail Branch Indexed    ${NODE_NODE_ID_LABEL}
    Verify List Item With Index Or Key Is Visible    ${NODE_NODE_ID_LABEL}    ${EMPTY}    0

Return Labelled Element Yangmenu
    [Arguments]    ${label}
    [Documentation]    Returns xpath of labelled element yangmenu in form.
    ${form_top_element_labelled}=    Return Form Top Element Labelled    ${label}
    ${form_labelled_element_yangmenu}=    BuiltIn.Set Variable    ${form_top_element_labelled}//following::yang-form-menu
    [Return]    ${form_labelled_element_yangmenu}

Return And Click Labelled Element Yangmenu
    [Arguments]    ${label}
    [Documentation]    Returns xpath of labelled element yangmenu in form and clicks the yangmenu.
    ${form_labelled_element_yangmenu}=    Return Labelled Element Yangmenu    ${label}
    Selenium2Library.Element Should Be Visible    ${form_labelled_element_yangmenu}
    GUIKeywords.Mouse Down And Mouse Up Click Element    ${form_labelled_element_yangmenu}

Return Labelled Element Show Previous Item Arrow
    [Arguments]    ${label}
    [Documentation]    Returns xpath of labelled element show previous list item icon in form.
    ${form_top_element_labelled}=    Return Form Top Element Labelled    ${label}
    ${labelled_show_previous_item_arrow}=    BuiltIn.Set Variable    ${form_top_element_labelled}//following::md-prev-button[@aria-label="Previous Page"]
    [Return]    ${labelled_show_previous_item_arrow}

Return Labelled Element Show Next Item Arrow
    [Arguments]    ${label}
    [Documentation]    Returns xpath of labelled element show next list item icon.
    ${form_top_element_labelled}=    Return Form Top Element Labelled    ${label}
    ${labelled_show_next_item_arrow}=    BuiltIn.Set Variable    ${form_top_element_labelled}//following::md-next-button[@aria-label="Next Page"]
    [Return]    ${labelled_show_next_item_arrow}

Return Labelled Form Input Field
    [Arguments]    ${branch_label_curly_braces_part}
    [Documentation]    Returns xpath of labelled form input field.
    ${labelled_form_input_field}=    BuiltIn.Set Variable    ${FORM_CONTENT}//span[contains(@class, "ng-binding ng-scope") and contains(text(), "${branch_label_curly_braces_part}")]//following::input
    [Return]    ${labelled_form_input_field}

Compose Labelled Form Input Field Xpath And Verify It Is Visible
    [Arguments]    ${branch_label_curly_braces_part}
    [Documentation]    Composes Xpath of labelled form input field and verifies the input field is visible.
    ${labelled_form_input_field}=    Return Labelled Form Input Field    ${branch_label_curly_braces_part}
    Selenium2Library.Element Should Be Visible    ${labelled_form_input_field}

Verify Labelled Form Input Field Contains Data
    [Arguments]    ${branch_label_curly_braces_part}    ${data}
    [Documentation]    Verifies that labelled form input field contains data provided as an argument.
    ${labelled_form_input_field}=    YangmanKeywords.Return Labelled Form Input Field    ${branch_label_curly_braces_part}
    Selenium2Library.Element Should Be Visible    ${labelled_form_input_field}[@aria-label="${data}"]

Verify Labelled Form Input Field Does Not Contain Any Data
    [Arguments]    ${branch_label_curly_braces_part}
    [Documentation]    Verifies that labelled form input field contains data provided as an argument.
    ${labelled_form_input_field}=    YangmanKeywords.Return Labelled Form Input Field    ${branch_label_curly_braces_part}
    Selenium2Library.Textfield Value Should Be    ${labelled_form_input_field}    ${EMPTY}

Return Labelled Form Select
    [Arguments]    ${branch_label_curly_braces_part}
    [Documentation]    Returns labelled form select.
    ${labelled_select}=    BuiltIn.Set Variable    ${FORM_CONTENT}//span[contains(@class, "ng-binding ng-scope") and contains(text(), "${branch_label_curly_braces_part}")]//following::md-select
    [Return]    ${labelled_select}

Input Text To Labelled Form Input Field
    [Arguments]    ${branch_label_curly_braces_part}    ${text}
    [Documentation]    Returns labelled form input field and inputs the text provided as an argument into it.
    ${labelled_input_field}=    Return Labelled Form Input Field    ${branch_label_curly_braces_part}
    Selenium2Library.Input Text    ${labelled_input_field}    ${text}

Input Key To Topology Id Input Field And Execute Operation With Checkbox Fill Form Selected
    [Arguments]    ${key}    ${operation}    ${operation_name}
    [Documentation]    Inputs ${key} as topology key in form and executes operation provided as an argument with fill form checkbox selected
    Return And Click Module Detail Branch Indexed    ${TOPOLOGY_TOPOLOGY_ID_LABEL}
    ${topology_id_label_curly_braces_part}=    YangmanKeywords.Return Branch Label Curly Braces Part Without Braces    ${TOPOLOGY_TOPOLOGY_ID_LABEL}
    YangmanKeywords.Input Text To Labelled Form Input Field    ${topology_id_label_curly_braces_part}    ${key}
    YangmanKeywords.Execute Chosen Operation From Form    ${operation}    ${operation_name}    selected

Input Key To Topology Id Input Field And Execute Operation With Checkbox Fill Form Unselected
    [Arguments]    ${key}    ${operation}    ${operation_name}
    [Documentation]    Inputs ${key} as topology key in form and executes operation provided as an argument with fill form checkbox unselected
    Return And Click Module Detail Branch Indexed    ${TOPOLOGY_TOPOLOGY_ID_LABEL}
    ${topology_id_label_curly_braces_part}=    YangmanKeywords.Return Branch Label Curly Braces Part Without Braces    ${TOPOLOGY_TOPOLOGY_ID_LABEL}
    YangmanKeywords.Input Text To Labelled Form Input Field    ${topology_id_label_curly_braces_part}    ${key}
    YangmanKeywords.Execute Chosen Operation From Form    ${operation}    ${operation_name}    unselected

Input Key_1 And Key_2 To Topology Id Input Field And Execute Operation With Checkbox Fill Form Selected And Unselected
    [Arguments]    ${key_1}    ${key_2}    ${operation}    ${operation_name}
    [Documentation]    Inputs ${key_1} and ${key_2} as topology keys in form and executes operation provided as an argument with fill form checkbox selected and unselected.
    Input Key To Topology Id Input Field And Execute Operation With Checkbox Fill Form Selected    ${key_1}    ${operation}    ${operation_name}
    Input Key To Topology Id Input Field And Execute Operation With Checkbox Fill Form Unselected    ${key_2}    ${operation}    ${operation_name}

Navigate To Testing Module Config And Load Topology Topology Id Node In Form And Put T1 And T0 Topologies
    [Documentation]    Navigate to testing module config and put t1 and t0 topologies.
    YangmanKeywords.Navigate From Yangman Submenu To Testing Module Config And Load Topology Topology Id Node In Form    ${NETWORK_TOPOLOGY_TESTING_MODULE_NAME}
    YangmanKeywords.Input Key_1 And Key_2 To Topology Id Input Field And Execute Operation With Checkbox Fill Form Selected And Unselected    ${TOPOLOGY_ID_0}    ${TOPOLOGY_ID_1}    ${PUT_OPTION}    PUT

Navigate To Testing Module Config And Load Topology Topology Id Node In Form And Put T1 And T0 Topologies And Get T0 And T1 Topologies And Navigate To History Tab
    [Documentation]    Navigate to testing module config and put t1 and t0 topologies and get t0 and t1 topologies and navigate to history tab.
    YangmanKeywords.Navigate From Yangman Submenu To Testing Module Config And Load Topology Topology Id Node In Form    ${NETWORK_TOPOLOGY_TESTING_MODULE_NAME}
    YangmanKeywords.Input Key_1 And Key_2 To Topology Id Input Field And Execute Operation With Checkbox Fill Form Selected And Unselected    ${TOPOLOGY_ID_0}    ${TOPOLOGY_ID_1}    ${PUT_OPTION}    PUT
    YangmanKeywords.Input Key_1 And Key_2 To Topology Id Input Field And Execute Operation With Checkbox Fill Form Selected And Unselected    ${TOPOLOGY_ID_0}    ${TOPOLOGY_ID_1}    ${GET_OPTION}    GET
    YangmanKeywords.Navigate To History Tab

Navigate To Testing Module Config And Load Topology Topology Id Node In Form And Put T0 And T1 Topologies And Delete T0 And T1 Topologies And Navigate To History Tab
    [Documentation]    Navigate to testing module config and put t1 and t0 topologies and delete t0 and t1 topologies and navigate to history tab.
    YangmanKeywords.Navigate From Yangman Submenu To Testing Module Config And Load Topology Topology Id Node In Form    ${NETWORK_TOPOLOGY_TESTING_MODULE_NAME}
    YangmanKeywords.Input Key_1 And Key_2 To Topology Id Input Field And Execute Operation With Checkbox Fill Form Selected And Unselected    ${TOPOLOGY_ID_0}    ${TOPOLOGY_ID_1}    ${PUT_OPTION}    PUT
    YangmanKeywords.Input Key_1 And Key_2 To Topology Id Input Field And Execute Operation With Checkbox Fill Form Selected And Unselected    ${TOPOLOGY_ID_0}    ${TOPOLOGY_ID_1}    ${DELETE_OPTION}    DELETE
    YangmanKeywords.Navigate To History Tab

Verify Form Contains Error Message
    [Arguments]    ${error_message}
    [Documentation]    Verifies that the form contains error message that is provided as an argument.
    ${form_error_message}=    BuiltIn.Set Variable    //p[contains(@id, "form-error-message") and contains (text(), "${error_message}")]
    Selenium2Library.Page Should Contain Element    ${form_error_message}

Verify Code Mirror Code Contains Data
    [Arguments]    ${code_mirror_code}    ${data}
    [Documentation]    Verifies that either sent or received data code mirror contains data provided as an argument.
    ...    ${code_mirror_code} is either ${SENT_DATA_CODE_MIRROR_CODE} or ${RECEIVED_DATA_CODE_MIRROR_CODE}.
    Selenium2Library.Wait Until Page Contains Element    ${code_mirror_code}/div/pre/span[contains(., "${data}")]

Verify Code Mirror Code Does Not Contain Data
    [Arguments]    ${code_mirror_code}    ${data}
    [Documentation]    Verifies that either sent or received data code mirror does not contain data provided as an argument.
    ...    ${code_mirror_code} is either ${SENT_DATA_CODE_MIRROR_CODE} or ${RECEIVED_DATA_CODE_MIRROR_CODE}.
    Selenium2Library.Wait Until Page Does Not Contain Element    ${code_mirror_code}/div/pre/span[contains(., "${data}")]

Verify No Data Are Displayed In Code Mirror Code
    [Arguments]    ${code_mirror_code}
    [Documentation]    Verifies that there are no data displayed in either sent or received data code mirror.
    ...    Value for ${code_mirror_code} is either ${SENT_DATA_CODE_MIRROR_CODE} or ${RECEIVED_DATA_CODE_MIRROR_CODE}.
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

Delete All Topologies In Network Topology
    [Documentation]    Loads network-topology in the form and deletes all topologies.
    Load And Expand Network Topology In Form
    ${status}=    BuiltIn.Run Keyword And Return Status    Execute Chosen Operation From Form And Check Status Code    ${DELETE_OPTION}    DELETE    selected    ${20X_OR_40X_REQUEST_CODE_REGEX}
    BuiltIn.Should Be Equal    "${status}"    "True"

Navigate To History Tab
    [Documentation]    Navigates to History tab.
    ${toggle_module_detail_button_left_is_visible}=    BuiltIn.Run Keyword And Return Status    Selenium2Library.Element Should Be Visible    ${TOGGLE_MODULE_DETAIL_BUTTON_LEFT}
    BuiltIn.Run Keyword If    ${toggle_module_detail_button_left_is_visible}==True    GUIKeywords.Patient Click    ${TOGGLE_MODULE_DETAIL_BUTTON_LEFT}    ${TOGGLE_MODULE_DETAIL_BUTTON_RIGHT}
    ${history_tab_is_selected}=    BuiltIn.Run Keyword And Return Status    Selenium2Library.Element Should Be Visible    ${HISTORY_TAB_SELECTED}
    BuiltIn.Run Keyword If    ${history_tab_is_selected}==False    GUIKeywords.Patient Click    ${HISTORY_TAB_UNSELECTED}    ${HISTORY_TAB_SELECTED}
    Selenium2Library.Wait Until Element Is Visible    ${HISTORY_TAB_SELECTED}    1 min

Return Number Of History Requests Displayed
    [Documentation]    Returns number of history requests displayed in History list.
    ${number_of_history_requests}=    Selenium2Library.Get Matching Xpath Count    ${HISTORY_LIST_ITEM}
    [Return]    ${number_of_history_requests}

Verify Number Of History Requests Displayed Equals To Number Given
    [Arguments]    ${number_provided}
    [Documentation]    Verifies that number of history requests displayed in History list equals to the number provided as an argument.
    ${number_of_history_requests}=    Return Number Of History Requests Displayed
    BuiltIn.Should Be Equal    ${number_of_history_requests}    ${number_provided}

Verify Any History Request Is Displayed
    [Documentation]    Verifies that there is at least on history request displayed in History list.
    ${number_of_history_requests}=    Return Number Of History Requests Displayed
    BuiltIn.Should Be True    ${number_of_history_requests}>0

Return Indexed History Requests Group
    [Arguments]    ${group_index}
    [Documentation]    Returns xpath of indexed history requests group.
    ${history_requests_group_indexed}=    BuiltIn.Set Variable    ${HISTORY_TAB_CONTENT}//md-list-item[@id="history-requests-group-${group_index}"]
    [Return]    ${history_requests_group_indexed}

Return Indexed History Request
    [Arguments]    ${group_index}    ${request_index}
    [Documentation]    Returns xpath of indexed history request.
    ${history_request_indexed}=    BuiltIn.Set Variable    ${HISTORY_TAB_CONTENT}//md-list-item[@id="history-request-${group_index}-${request_index}"]
    [Return]    ${history_request_indexed}

Return Indexed Selected History Request
    [Arguments]    ${group_index}    ${request_index}
    [Documentation]    Returns xpath of indexed selected history request.
    ${history_request_indexed_selected}=    BuiltIn.Set Variable    ${HISTORY_TAB_CONTENT}//md-list-item[contains(@id, "history-request-${group_index}-${request_index}") and contains(@class, "selected")]
    [Return]    ${history_request_indexed_selected}

Verify History Request Is Selected
    [Arguments]    ${group_index}    ${request_index}
    [Documentation]    Composes xpath of indexed history request and verifies the request is selected.
    ${history_request_indexed_selected}=    Return Indexed Selected History Request    ${group_index}    ${request_index}
    Selenium2Library.Wait Until Page Contains Element    ${history_request_indexed_selected}

Return Indexed Deselected History Request
    [Arguments]    ${group_index}    ${request_index}
    [Documentation]    Returns xpath of indexed deselected history request.
    ${history_request_indexed_deselected}=    BuiltIn.Set Variable    ${HISTORY_TAB_CONTENT}//md-list-item[contains(@id, "history-request-${group_index}-${request_index}") and not(contains(@class, "selected"))]
    [Return]    ${history_request_indexed_deselected}

Select Indexed History Request
    [Arguments]    ${group_index}    ${request_index}
    [Documentation]    Selects indexed history request and verifies the request is selected.
    ${history_request_indexed}=    Return Indexed History Request    ${group_index}    ${request_index}
    GUIKeywords.Mouse Down And Mouse Up Click Element    ${history_request_indexed}

Select Indexed History Request And Verify Request Is Selected
    [Arguments]    ${group_index}    ${request_index}
    [Documentation]    Selects indexed history request and verifies the request is selected.
    ${history_request_indexed}=    Return Indexed History Request    ${group_index}    ${request_index}
    GUIKeywords.Mouse Down And Mouse Up Click Element    ${history_request_indexed}
    Verify History Request Is Selected    ${group_index}    ${request_index}

Verify History Request Is Not Selected
    [Arguments]    ${group_index}    ${request_index}
    [Documentation]    Composes xpath of indexed history request and verifies the request is not selected.
    ${history_request_indexed_not_selected}=    Return Indexed Deselected History Request    ${group_index}    ${request_index}
    Selenium2Library.Wait Until Page Contains Element    ${history_request_indexed_not_selected}

Return Indexed History Request Operation Label
    [Arguments]    ${group_index}    ${request_index}
    [Documentation]    Returns label of indexed history request operation.
    ${history_request_indexed}=    Return Indexed History Request    ${group_index}    ${request_index}
    ${history_request_indexed_operation_xpath}=    BuiltIn.Set Variable    ${history_request_indexed}//p[contains(@id, "operation")]
    ${history_request_indexed_operation_label}=    Selenium2Library.Get Text    ${history_request_indexed_operation_xpath}
    ${history_request_indexed_operation_label_stripped}=    String.Strip String    ${history_request_indexed_operation_label}
    [Return]    ${history_request_indexed_operation_label_stripped}

Compare Indexed History Request Operation Label With Given Operation Name
    [Arguments]    ${group_index}    ${request_index}    ${operation_name}
    [Documentation]    Compares indexed history request operation label with operation name provided as an argument.
    ${history_request_indexed_operation_label}=    Return Indexed History Request Operation Label    ${group_index}    ${request_index}
    BuiltIn.Should Be Equal    ${history_request_indexed_operation_label}    ${operation_name}

Return Indexed History Request Url Label
    [Arguments]    ${group_index}    ${request_index}
    [Documentation]    Returns label of indexed history request url.
    ${history_request_indexed}=    Return Indexed History Request    ${group_index}    ${request_index}
    ${history_request_indexed_url_xpath}=    BuiltIn.Set Variable    ${history_request_indexed}//p[contains(@id, "url")]
    ${history_request_indexed_url_label}=    Selenium2Library.Get Text    ${history_request_indexed_url_xpath}
    [Return]    ${history_request_indexed_url_label}

Verify Indexed History Request Url Label Contains Given Key
    [Arguments]    ${group_index}    ${request_index}    ${key}
    [Documentation]    Verifies that indexed history request url label contains key.
    ${history_request_indexed_url_label}=    Return Indexed History Request Url Label    ${group_index}    ${request_index}
    BuiltIn.Should Contain    ${history_request_indexed_url_label}    ${key}

Select All History Requests
    [Documentation]    Select all history requests by clicking select all button.
    GUIKeywords.Patient Click    ${SELECT_HISTORY_REQUEST_MENU}    ${SELECT_ALL_HISTORY_REQUESTS_BUTTON}
    GUIKeywords.Patient Click With Wait Until Element Is Not Visible Check    ${SELECT_ALL_HISTORY_REQUESTS_BUTTON}    ${SELECT_ALL_HISTORY_REQUESTS_BUTTON}

Unselect All History Requests
    [Documentation]    Deselect all history requests by clicking deselect all button.
    GUIKeywords.Patient Click    ${SELECT_HISTORY_REQUEST_MENU}    ${DESELECT_ALL_HISTORY_REQUESTS_BUTTON}
    GUIKeywords.Patient Click With Wait Until Element Is Not Visible Check    ${DESELECT_ALL_HISTORY_REQUESTS_BUTTON}    ${DESELECT_ALL_HISTORY_REQUESTS_BUTTON}

Verify All History Requests In Request Group Are Selected
    [Arguments]    ${group_id}    ${number_of_requests_in_request_group}
    [Documentation]    Verifies that all history requests of an indexed history requests group are selected.
    : FOR    ${index}    IN RANGE    ${number_of_requests_in_request_group}
    \    YangmanKeywords.Verify History Request Is Selected    ${group_id}    ${index}

Verify All History Requests In Request Group Are Unselected
    [Arguments]    ${group_id}    ${number_of_requests_in_request_group}
    [Documentation]    Verifies that all history requests of an indexed history requests group are unselected.
    : FOR    ${index}    IN RANGE    ${number_of_requests_in_request_group}
    \    YangmanKeywords.Verify History Request Is Not Selected    ${group_id}    ${index}

Click Select All Button And Verify All Requests Have Been Selected
    [Arguments]    ${group_id}    ${number_of_requests_in_request_group}
    [Documentation]    Clicks Select all button to select all history requests and verifies that all requests have been selected.
    YangmanKeywords.Select All History Requests
    Verify All History Requests In Request Group Are Selected    ${group_id}    ${number_of_requests_in_request_group}

Click Deselect All Button And Verify All Requests Have Been Unselected
    [Arguments]    ${group_id}    ${number_of_requests_in_request_group}
    [Documentation]    Clicks Deselect all button to deselect all history requests and verifies that all requests have been deselected.
    YangmanKeywords.Unselect All History Requests
    Verify All History Requests In Request Group Are Unselected    ${group_id}    ${number_of_requests_in_request_group}

Open History Requests Settings Dialog
    [Documentation]    Click history requests setting button to open history requests settings dialog if it is not opened.
    ${histroy_requests_settings_dialog_is_opened}=    BuiltIn.Run Keyword And Return Status    Selenium2Library.Wait Until Page Contains Element    ${HISTORY_REQUESTS_SETTINGS_DIALOG}
    BuiltIn.Run Keyword If    ${histroy_requests_settings_dialog_is_opened}==False    GUIKeywords.Patient Click    ${HISTORY_REQUESTS_SETTINGS_BUTTON}    ${HISTORY_REQUESTS_SETTINGS_DIALOG}

Click History Requests Settings Dialog Save Button
    [Documentation]    Click history requests setting save button to save changes.
    GUIKeywords.Patient Click With Wait Until Page Does Not Contain Element Check    ${HISTORY_REQUESTS_SETTINGS_SAVE_BUTTON}    ${HISTORY_REQUESTS_SETTINGS_SAVE_BUTTON}

Open History Requests Settings Dialog And Select Save Base Response Data Select Checkbox
    [Documentation]    Selects save base response data select checkbox in History settings.
    Open History Requests Settings Dialog
    ${save_base_response_data_checkbox_is_selected}=    BuiltIn.Run Keyword And Return Status    Selenium2Library.Page Should Contain Element    ${HISTORY_REQUESTS_SAVE_BASE_RESPONSE_DATA_CHECKBOX_SELECTED}
    BuiltIn.Run Keyword If    ${save_base_response_data_checkbox_is_selected}==False    GUIKeywords.Patient Click    ${HISTORY_REQUESTS_SAVE_BASE_RESPONSE_DATA_CHECKBOX}    ${HISTORY_REQUESTS_SAVE_BASE_RESPONSE_DATA_CHECKBOX_SELECTED}

Open History Requests Settings Dialog And Unselect Save Base Response Data Select Checkbox
    [Documentation]    Unselects save base response data select checkbox in History settings.
    Open History Requests Settings Dialog
    ${save_base_response_data_checkbox_is_unselected}=    BuiltIn.Run Keyword And Return Status    Selenium2Library.Page Should Contain Element    ${HISTORY_REQUESTS_SAVE_BASE_RESPONSE_DATA_CHECKBOX_UNSELECTED}
    BuiltIn.Run Keyword If    ${save_base_response_data_checkbox_is_unselected}==False    GUIKeywords.Patient Click    ${HISTORY_REQUESTS_SAVE_BASE_RESPONSE_DATA_CHECKBOX}    ${HISTORY_REQUESTS_SAVE_BASE_RESPONSE_DATA_CHECKBOX_UNSELECTED}

Open History Requests Settings Dialog And Select Save Received Data Select Checkbox
    [Documentation]    Selects save received data select checkbox in History settings.
    Open History Requests Settings Dialog
    ${save_received_data_checkbox_is_selected}=    BuiltIn.Run Keyword And Return Status    Selenium2Library.Page Should Contain Element    ${HISTORY_REQUESTS_SAVE_RECEIVED_DATA_CHECKBOX_SELECTED}
    BuiltIn.Run Keyword If    ${save_received_data_checkbox_is_selected}==False    GUIKeywords.Patient Click    ${HISTORY_REQUESTS_SAVE_RECEIVED_DATA_CHECKBOX}    ${HISTORY_REQUESTS_SAVE_RECEIVED_DATA_CHECKBOX_SELECTED}

Open History Requests Settings Dialog And Unselect Save Received Data Select Checkbox
    [Documentation]    Unselects save received data select checkbox in History settings.
    Open History Requests Settings Dialog
    ${save_received_data_checkbox_is_unselected}=    BuiltIn.Run Keyword And Return Status    Selenium2Library.Page Should Contain Element    ${HISTORY_REQUESTS_SAVE_RECEIVED_DATA_CHECKBOX_UNSELECTED}
    BuiltIn.Run Keyword If    ${save_received_data_checkbox_is_unselected}==False    GUIKeywords.Patient Click    ${HISTORY_REQUESTS_SAVE_RECEIVED_DATA_CHECKBOX}    ${HISTORY_REQUESTS_SAVE_RECEIVED_DATA_CHECKBOX_UNSELECTED}

Open History Requests Settings Dialog And Select Fill Form View With Received Data On History Request Select Checkbox
    [Documentation]    Selects Fill form view with received data on history request select checkbox in History settings.
    Open History Requests Settings Dialog
    ${fill_form_view_checkbox_is_selected}=    BuiltIn.Run Keyword And Return Status    Selenium2Library.Page Should Contain Element    ${HISTORY_REQUESTS_FILL_FORM_WITH_RECEIVED_DATA_ON_REQUEST_SELECT_CHECKBOX_SELECTED}
    BuiltIn.Run Keyword If    ${fill_form_view_checkbox_is_selected}==False    GUIKeywords.Patient Click    ${HISTORY_REQUESTS_FILL_FORM_WITH_RECEIVED_DATA_ON_REQUEST_SELECT_CHECKBOX}    ${HISTORY_REQUESTS_FILL_FORM_WITH_RECEIVED_DATA_ON_REQUEST_SELECT_CHECKBOX_SELECTED}

Open History Requests Settings Dialog And Unselect Fill Form View With Received Data On History Request Select Checkbox
    [Documentation]    Unselects Fill form view with received data on history request select checkbox in History settings.
    Open History Requests Settings Dialog
    ${fill_form_view_checkbox_is_unselected}=    BuiltIn.Run Keyword And Return Status    Selenium2Library.Page Should Contain Element    ${HISTORY_REQUESTS_FILL_FORM_WITH_RECEIVED_DATA_ON_REQUEST_SELECT_CHECKBOX_UNSELECTED}
    BuiltIn.Run Keyword If    ${fill_form_view_checkbox_is_unselected}==False    GUIKeywords.Patient Click    ${HISTORY_REQUESTS_FILL_FORM_WITH_RECEIVED_DATA_ON_REQUEST_SELECT_CHECKBOX}    ${HISTORY_REQUESTS_FILL_FORM_WITH_RECEIVED_DATA_ON_REQUEST_SELECT_CHECKBOX_UNSELECTED}

Navigate To History Tab And Delete All History Requests
    [Documentation]    Navigates to history tab and deletes all history requests and verify they have been deleted.
    YangmanKeywords.Navigate To History Tab
    YangmanKeywords.Delete All History Requests And Verify They Have Been Deleted

Click Delete All History Requests Button
    [Documentation]    Clicks delete all button to delete all history requests.
    Patient Click    ${DELETE_ALL_HISTORY_REQUESTS_BUTTON}    ${DELETE_ALL_HISTORY_REQUESTS_DIALOG_ACTION_OK}

Click Delete All History Requests Dialog Button OK
    [Documentation]    Clicks dialog action button ok.
    GUIKeywords.Patient Click With Wait Until Page Does Not Contain Element Check    ${DELETE_ALL_HISTORY_REQUESTS_DIALOG_ACTION_OK}    ${DELETE_ALL_HISTORY_REQUESTS_DIALOG_ACTION_OK}

Delete All History Requests
    [Documentation]    Deletes all history requests using delete all button.
    ${history_requests_are_displayed}=    BuiltIn.Run Keyword And Return Status    Verify Any History Request Is Displayed
    BuiltIn.Run Keyword If    ${history_requests_are_displayed}==True    BuiltIn.Run Keywords    GUIKeywords.Focus And Click Element    ${DELETE_HISTORY_REQUEST_MENU_BUTTON}
    ...    AND    Click Delete All History Requests Button
    ...    AND    Click Delete All History Requests Dialog Button OK

Delete All History Requests And Verify They Have Been Deleted
    [Documentation]    Deletes all history requests using delete all button.
    Delete All History Requests
    Verify Number Of History Requests Displayed Equals To Number Given    0

Select Save Base Response Data And Save Received Data And Fill Form With Received Data On Request Select Checkboxes In History Settings And Save Changes
    [Documentation]    Opens history requests settings dialog and selects save base response data, save received data and fill form view with received data on history request select checkboxes.
    Open History Requests Settings Dialog And Select Save Base Response Data Select Checkbox
    Open History Requests Settings Dialog And Select Save Received Data Select Checkbox
    Open History Requests Settings Dialog And Select Fill Form View With Received Data On History Request Select Checkbox
    Click History Requests Settings Dialog Save Button

Navigate To History Tab And Delete All History Requests And Select All History Settings Checkboxes
    [Documentation]    Deletes all history requests using delete all button and select all checkboxes and save changes
    Navigate To History Tab And Delete All History Requests
    Select Save Base Response Data And Save Received Data And Fill Form With Received Data On Request Select Checkboxes In History Settings And Save Changes

Navigate To Testing Module Config And Load Topology Topology Id Node In Form And Send Key_1 And Key_2 And Navigate To History
    [Arguments]    ${key_1}    ${key_2}    ${operation}    ${operation_name}
    [Documentation]    Navigates to config tab of testing module and executes chosen operation with key_1 and key_2 and fill form with checbox selected and unselected and navigates to history.
    Navigate From Yangman Submenu To Testing Module Config And Load Topology Topology Id Node In Form    ${NETWORK_TOPOLOGY_TESTING_MODULE_NAME}
    Input Key_1 And Key_2 To Topology Id Input Field And Execute Operation With Checkbox Fill Form Selected And Unselected    ${key_1}    ${key_2}    ${operation}    ${operation_name}
    Navigate To History Tab

Navigate To Testing Module Config And Load Topology Topology Id Node In Form And Send Key With Checkbox Fill Form Selected And Navigate To History
    [Arguments]    ${key}    ${operation}    ${operation_name}
    [Documentation]    Navigates to config tab of testing module and executes chosen operation with key_1 and fill form with checbox selected and navigates to history.
    Navigate From Yangman Submenu To Testing Module Config And Load Topology Topology Id Node In Form    ${NETWORK_TOPOLOGY_TESTING_MODULE_NAME}
    Input Key To Topology Id Input Field And Execute Operation With Checkbox Fill Form Selected    ${key}    ${operation}    ${operation_name}
    Navigate To History Tab

Navigate To Testing Module Config And Load Topology Topology Id Node In Form And Send Key With Checkbox Fill Form Unselected And Navigate To History
    [Arguments]    ${key}    ${operation}    ${operation_name}
    [Documentation]    Navigates to config tab of testing module and executes chosen operation with key_1 and fill form with checbox unselected and navigates to history.
    Navigate From Yangman Submenu To Testing Module Config And Load Topology Topology Id Node In Form    ${NETWORK_TOPOLOGY_TESTING_MODULE_NAME}
    Input Key To Topology Id Input Field And Execute Operation With Checkbox Fill Form Unselected    ${key}    ${operation}    ${operation_name}
    Navigate To History Tab

Verify History Requests With Given Indeces Contain Data In Api And No Data In Form And Contain Status And Time Data
    [Arguments]    ${keys}    ${group_id}    ${first_index}    ${last_index}
    [Documentation]    Verifies that indexed history requests with given indeces contain data in api and no data in form and contain status and time data.
    ${key_index}=    BuiltIn.Evaluate    -1
    : FOR    ${index}    IN RANGE    ${first_index}    ${last_index}+1
    \    ${key_index}=    BuiltIn.Evaluate    ${key_index}+1
    \    ${key}=    Collections.Get From List    ${keys}    ${key_index}
    \    YangmanKeywords.Select Indexed History Request    ${group_id}    ${index}
    \    YangmanKeywords.Verify Labelled Api Path Input Contains Data    ${TOPOLOGY_LABEL}    ${key}
    \    YangmanKeywords.Verify Labelled Form Input Field Does Not Contain Any Data    ${TOPOLOGY_ID_LABEL}
    \    YangmanKeywords.Verify Request Status Code Matches Desired Code And Request Execution Time Is Present    ${20X_REQUEST_CODE_REGEX}
    \    BuiltIn.Run Keyword If    ${first_index}==${last_index}    BuiltIn.Exit For Loop

Verify History Requests With Given Indeces Contain Data In Api And Form And Contain Status And Time Data
    [Arguments]    ${keys}    ${group_id}    ${first_index}    ${last_index}
    [Documentation]    Verifies that indexed history requests with given indeces contain data in api and form and contain status and time data.
    ${key_index}=    BuiltIn.Evaluate    -1
    : FOR    ${index}    IN RANGE    ${first_index}    ${last_index}+1
    \    ${key_index}=    BuiltIn.Evaluate    ${key_index}+1
    \    ${key}=    Collections.Get From List    ${keys}    ${key_index}
    \    YangmanKeywords.Select Indexed History Request    ${group_id}    ${index}
    \    YangmanKeywords.Verify Labelled Api Path Input Contains Data    ${TOPOLOGY_LABEL}    ${key}
    \    YangmanKeywords.Verify Labelled Form Input Field Contains Data    ${TOPOLOGY_ID_LABEL}    ${key}
    \    YangmanKeywords.Verify Request Status Code Matches Desired Code And Request Execution Time Is Present    ${20X_REQUEST_CODE_REGEX}
    \    BuiltIn.Run Keyword If    ${first_index}==${last_index}    BuiltIn.Exit For Loop

Verify History Requests With Given Indeces Contain Data In Api And Form And Do Not Contain Status And Time Data
    [Arguments]    ${keys}    ${group_id}    ${first_index}    ${last_index}
    [Documentation]    Verifies that indexed history requests with given indeces contain data in api and form and do not contain status and time data.
    ${key_index}=    BuiltIn.Evaluate    -1
    : FOR    ${index}    IN RANGE    ${first_index}    ${last_index}+1
    \    ${key_index}=    BuiltIn.Evaluate    ${key_index}+1
    \    ${key}=    Collections.Get From List    ${keys}    ${key_index}
    \    YangmanKeywords.Select Indexed History Request    ${group_id}    ${index}
    \    YangmanKeywords.Verify Labelled Api Path Input Contains Data    ${TOPOLOGY_LABEL}    ${key}
    \    YangmanKeywords.Verify Labelled Form Input Field Contains Data    ${TOPOLOGY_ID_LABEL}    ${key}
    \    YangmanKeywords.Verify Request Status Code Matches Desired Code And Request Execution Time Is Threedots    ${THREE_DOTS_DEFAULT_STATUS_AND_TIME}
    \    BuiltIn.Run Keyword If    ${first_index}==${last_index}    BuiltIn.Exit For Loop

Verify History Requests With Given Indeces Contain Data In Api And No Data In Form And Do Not Contain Status And Time Data
    [Arguments]    ${keys}    ${group_id}    ${first_index}    ${last_index}
    [Documentation]    Verifies that indexed history requests with given indeces contain data in api and no data in form and do not contain status and time data.
    ${key_index}=    BuiltIn.Evaluate    -1
    : FOR    ${index}    IN RANGE    ${first_index}    ${last_index}+1
    \    ${key_index}=    BuiltIn.Evaluate    ${key_index}+1
    \    ${key}=    Collections.Get From List    ${keys}    ${key_index}
    \    YangmanKeywords.Select Indexed History Request    ${group_id}    ${index}
    \    YangmanKeywords.Verify Labelled Api Path Input Contains Data    ${TOPOLOGY_LABEL}    ${key}
    \    YangmanKeywords.Verify Labelled Form Input Field Does Not Contain Any Data    ${TOPOLOGY_ID_LABEL}
    \    YangmanKeywords.Verify Request Status Code Matches Desired Code And Request Execution Time Is Threedots    ${THREE_DOTS_DEFAULT_STATUS_AND_TIME}
    \    BuiltIn.Run Keyword If    ${first_index}==${last_index}    BuiltIn.Exit For Loop

Verify History Requests With Given Indeces Contain Data In Api And Error Message In Form And Contain 400 Status And Time Data
    [Arguments]    ${key}    ${group_id}    ${first_index}    ${last_index}    ${error_message}
    [Documentation]    Verifies that indexed history requests with given indeces contain data in api and given error message in form and contains 400 status data and time data.
    ${key_index}=    BuiltIn.Evaluate    -1
    : FOR    ${index}    IN RANGE    ${first_index}    ${last_index}+1
    \    ${key_index}=    BuiltIn.Evaluate    ${key_index}+1
    \    ${key}=    Collections.Get From List    ${keys}    ${key_index}
    \    YangmanKeywords.Select Indexed History Request    ${group_id}    ${index}
    \    YangmanKeywords.Verify Labelled Api Path Input Contains Data    ${TOPOLOGY_LABEL}    ${key}
    \    YangmanKeywords.Verify Labelled Form Input Field Does Not Contain Any Data    ${TOPOLOGY_ID_LABEL}
    \    YangmanKeywords.Verify Form Contains Error Message    ${error_message}
    \    YangmanKeywords.Verify Request Status Code Matches Desired Code And Request Execution Time Is Present    ${40X_REQUEST_CODE_REGEX}
    \    BuiltIn.Run Keyword If    ${first_index}==${last_index}    BuiltIn.Exit For Loop

Compare Indexed History Request Operation Label And Verify Url Label Contains Given Key
    [Arguments]    ${operation_name}    ${keys}
    [Documentation]    Compares indexed history request operation label with operation name provided as an argument and verifies url label contains the key provided as an argument.
    : FOR    ${index}    IN RANGE    0    len(@{keys})
    \    ${key}=    Collections.Get From List    ${keys}    ${index}
    \    YangmanKeywords.Compare Indexed History Request Operation Label With Given Operation Name    0    ${index}    ${operation_name}
    \    YangmanKeywords.Verify Indexed History Request Url Label Contains Given Key    0    ${index}    ${key}

Return History Indexed Request Yangmenu
    [Arguments]    ${group_index}    ${request_index}
    [Documentation]    Returns xpath of indexed history request yangmenu.
    ${history_indexed_request_yangmenu}=    BuiltIn.Set Variable    ${HISTORY_TAB_CONTENT}//md-menu/button[@id="history-request-${group_index}-${request_index}-submenu"]
    [Return]    ${history_indexed_request_yangmenu}

Return And Click History Indexed Request Yangmenu
    [Arguments]    ${group_index}    ${request_index}
    [Documentation]    Returns and clicks indexed history request yangmenu.
    ${history_indexed_request_yangmenu}=    Return History Indexed Request Yangmenu    0    ${request_index}
    GUIKeywords.Mouse Down And Mouse Up Click Element    ${history_indexed_request_yangmenu}

Return History Indexed Request Run Request Button
    [Arguments]    ${group_index}    ${request_index}
    [Documentation]    Returns xpath of indexed history request run request button.
    ${history_indexed_request_run_request_button}=    BuiltIn.Set Variable    //button[@id="history-request-${group_index}-${request_index}-execute"]
    [Return]    ${history_indexed_request_run_request_button}

Return And Click History Indexed Request Run Request Button
    [Arguments]    ${group_index}    ${request_index}
    [Documentation]    Returns and clicks indexed history run request button.
    ${history_indexed_request_run_request_button}=    Return History Indexed Request Run Request Button    0    ${request_index}
    GUIKeywords.Patient Click With Wait Until Element Is Not Visible Check    ${history_indexed_request_run_request_button}    ${history_indexed_request_run_request_button}

Run History Indexed Request Via Run Request Button
    [Arguments]    ${group_index}    ${request_index}
    [Documentation]    Clicks indexed request yangmenu and clicks run request button.
    Return And Click History Indexed Request Yangmenu    ${group_index}    ${request_index}
    Return And Click History Indexed Request Run Request Button    ${group_index}    ${request_index}

Return And Check History Contains Last Indexed Request
    [Arguments]    ${group_index}    ${last_request_index}
    [Documentation]    Returns xpath of indexed history request yangmenu and checks history list contains indexed request with index provided as an argument.
    ${history_last_indexed_request}=    Return History Indexed Request Yangmenu    0    ${last_request_index}
    Selenium2Library.Wait Until Page Contains Element    ${history_last_indexed_request}

Return History Indexed Request Delete Request Button
    [Arguments]    ${group_index}    ${request_index}
    [Documentation]    Returns xpath of indexed history request delete request button.
    ${history_indexed_request_delete_request_button}=    BuiltIn.Set Variable    //button[@id="history-request-${group_index}-${request_index}-delete"]
    [Return]    ${history_indexed_request_delete_request_button}

Return And Click History Indexed Request Delete Request Button
    [Arguments]    ${group_index}    ${request_index}
    [Documentation]    Returns and clicks indexed history delete request button.
    ${history_indexed_request_delete_request_button}=    Return History Indexed Request Delete Request Button    0    ${request_index}
    GUIKeywords.Patient Click With Wait Until Element Is Not Visible Check    ${history_indexed_request_delete_request_button}    ${history_indexed_request_delete_request_button}

Click Delete History Request Dialog Button OK
    [Documentation]    Clicks delete request dialog action button ok.
    GUIKeywords.Patient Click With Wait Until Page Does Not Contain Element Check    ${DELETE_SELECTED_HISTORY_REQUEST_DIALOG_ACTION_OK}    ${DELETE_SELECTED_HISTORY_REQUEST_DIALOG_ACTION_OK}

Delete History Indexed Request Via Delete Request Button
    [Arguments]    ${group_index}    ${request_index}
    [Documentation]    Clicks indexed request yangmenu and clicks delete request button.
    Return And Click History Indexed Request Yangmenu    ${group_index}    ${request_index}
    Return And Click History Indexed Request Delete Request Button    ${group_index}    ${request_index}
    Click Delete History Request Dialog Button OK

Select And Send Indexed History Request From Form
    [Arguments]    ${group_index}    ${request_index}
    [Documentation]    Selects indexed history request and sends it from form using send button.
    Select Indexed History Request    ${group_index}    ${request_index}
    Send Request

Navigate To Collections Tab
    [Documentation]    Navigates to Collections tab.
    ${toggle_module_detail_button_left_is_visible}=    BuiltIn.Run Keyword And Return Status    Selenium2Library.Element Should Be Visible    ${TOGGLE_MODULE_DETAIL_BUTTON_LEFT}
    BuiltIn.Run Keyword If    ${toggle_module_detail_button_left_is_visible}==True    GUIKeywords.Patient Click    ${TOGGLE_MODULE_DETAIL_BUTTON_LEFT}    ${TOGGLE_MODULE_DETAIL_BUTTON_RIGHT}
    ${collections_tab_is_selected}=    BuiltIn.Run Keyword And Return Status    Selenium2Library.Element Should Be Visible    ${COLLECTIONS_TAB_SELECTED}
    BuiltIn.Run Keyword If    ${collections_tab_is_selected}==False    GUIKeywords.Patient Click    ${COLLECTIONS_TAB_UNSELECTED}    ${COLLECTIONS_TAB_SELECTED}
    Selenium2Library.Wait Until Element Is Visible    ${COLLECTIONS_TAB_SELECTED}    1 min

Click Save To Collection Button
    [Documentation]    Clicks save history request to collection.
    GUIKeywords.Patient Click    ${SAVE_HISTORY_REQUEST_TO_COLLECTION_BUTTON}    ${SAVE_TO_COLLECTION_DIALOG}

Insert Collection Name To Save To Collection Dialog Input Field
    [Arguments]    ${collection_name}
    [Documentation]    Insert collection name given as argument to save to colection dialog input field.
    Selenium2Library.Focus    ${SAVE_TO_COLLECTION_DIALOG_INPUT_FIELD}
    Selenium2Library.Press Key    ${SAVE_TO_COLLECTION_DIALOG_INPUT_FIELD}    ${collection_name}

Click Save To Collection Dialog Save Button
    [Documentation]    Clicks save to collection dialog save button.
    Patient Click With Wait Until Page Does Not Contain Element Check    ${SAVE_TO_COLLECTION_DIALOG_ACTION_SAVE}    ${SAVE_TO_COLLECTION_DIALOG_ACTION_SAVE}

Insert Collection Name To Save To Collection Dialog Input Field And Save
    [Arguments]    ${collection_name}
    [Documentation]    Inserts collection name given as argument to save to colection dialog input field and save.
    Insert Collection Name To Save To Collection Dialog Input Field    ${collection_name}
    Click Save To Collection Dialog Save Button

Click Save To Collection Button And Fill The Collection Name And Click Save
    [Arguments]    ${collection_name}
    [Documentation]    Clicks save to collection button and fills the collection name in input field and clicks save dialog button.
    Click Save To Collection Button
    Insert Collection Name To Save To Collection Dialog Input Field And Save    ${collection_name}

Select History Request And Save It To Collection
    [Arguments]    ${group_id}    ${index}    ${collection_name}
    [Documentation]    Selects indexed history request and saves it to collection the name of which is provided as an argument, using Save to collection button.
    YangmanKeywords.Select Indexed History Request    ${group_id}    ${index}
    Click Save To Collection Button And Fill The Collection Name And Click Save    ${collection_name}

Click Save Button
    [Documentation]    Clicks save button to save history request to collection.
    GUIKeywords.Patient Click    ${SAVE_BUTTON}    ${SAVE_TO_COLLECTION_DIALOG}

Click Save Button And Fill The Collection Name And Click Save
    [Arguments]    ${collection_name}
    [Documentation]    Clicks save button and fills the collection name in input field and clicks save dialog button.
    Click Save Button
    Insert Collection Name To Save To Collection Dialog Input Field And Save    ${collection_name}

Select History Request And Save It To Collection Using Save Button
    [Arguments]    ${group_id}    ${index}    ${collection_name}
    [Documentation]    Selects indexed history request and saves it to collection the name of which is provided as an argument, using Save button.
    YangmanKeywords.Select Indexed History Request    ${group_id}    ${index}
    Click Save Button And Fill The Collection Name And Click Save    ${collection_name}

Return Number Of Collections Displayed
    [Documentation]    Returns number of collections displayed in Collections list.
    ${number_of_collections}=    Selenium2Library.Get Matching Xpath Count    ${COLLECTIONS_LIST_ITEM}
    [Return]    ${number_of_collections}

Verify Number Of Collections Displayed Equals To Number Given
    [Arguments]    ${number_provided}
    [Documentation]    Verifies that number of collections in Collections list equals to the number provided as an argument.
    ${number_of_collections}=    Return Number Of Collections Displayed
    BuiltIn.Should Be Equal As Integers    ${number_of_collections}    ${number_provided}

Return Indexed Collection
    [Arguments]    ${collection_index}
    [Documentation]    Returns xpath of indexed collection.
    ${collection_indexed}=    BuiltIn.Set Variable    ${COLLECTIONS_TAB_CONTENT}//md-list-item[@id="collection-${collection_index}"]
    [Return]    ${collection_indexed}

Return Indexed Collection Name
    [Arguments]    ${collection_index}
    [Documentation]    Returns string - label of indexed collection.
    ${indexed_collection_label_xpath}=    BuiltIn.Set Variable    ${COLLECTIONS_TAB_CONTENT}//span[@id="collection-${collection_index}-name"]
    ${indexed_collection_name}=    Selenium2Library.Get Text    ${indexed_collection_label_xpath}
    [Return]    ${indexed_collection_name}

Verify Indexed Collection Name Equals To Name Given
    [Arguments]    ${collection_index}    ${collection_name}
    [Documentation]    Verifies that indexed collection name equals to the name provided as an argument.
    ${indexed_collection_name}=    Return Indexed Collection Name    ${collection_index}
    BuiltIn.Should Contain    ${indexed_collection_name}    ${collection_name}

Select And Expand Collection
    [Arguments]    ${collection_index}
    [Documentation]    Selects and at the same time expands indexed collection.
    ${collection_indexed}=    Return Indexed Collection    ${collection_index}
    ${collection_indexed_expanded_and_selected}=    BuiltIn.Set Variable    ${COLLECTIONS_TAB_CONTENT}//md-list-item[contains(@class, "expanded selected") and contains(@id,"collection-${collection_index}")]
    ${status}=    BuiltIn.Run Keyword And Return Status    Selenium2Library.Page Should Contain Element    ${collection_indexed_expanded_and_selected}
    BuiltIn.Run Keyword If    ${status}==False    GUIKeywords.Mouse Down And Mouse Up Click Element    ${collection_indexed}

Return Collection Indexed Request
    [Arguments]    ${collection_index}    ${request_index}
    [Documentation]    Returns xpath of collection indexed request yangmenu.
    ${collection_indexed_request}=    BuiltIn.Set Variable    ${COLLECTIONS_TAB_CONTENT}//md-list-item[@id="collection-request-${collection_index}-${request_index}"]
    [Return]    ${collection_indexed_request}

Select Collection Indexed Request
    [Arguments]    ${collection_index}    ${request_index}
    [Documentation]    Selects collection indexed request and verifies the request is selected.
    ${collection_indexed_request}=    Return Collection Indexed Request    ${collection_index}    ${request_index}
    GUIKeywords.Mouse Down And Mouse Up Click Element    ${collection_indexed_request}

Return Number Of Requests Displayed In Indexed Collection
    [Arguments]    ${collection_index}
    [Documentation]    Returns number of indexed collection requests displayed in Collections list.
    ${indexed_collection_request}=    BuiltIn.Set Variable    ${COLLECTIONS_TAB_CONTENT}//md-list-item[contains(@id, "collection-request-${collection_index}")]
    ${number_of_indexed_collection_requests}=    Selenium2Library.Get Matching Xpath Count    ${indexed_collection_request}
    [Return]    ${number_of_indexed_collection_requests}

Verify Number Of Requests Displayed In Indexed Collection Equals To Number Given
    [Arguments]    ${collection_index}    ${number_provided}
    [Documentation]    Verifies that number of indexed collection requests displayed in Collections list equals to the number provided as an argument.
    ${number_of_indexed_collection_requests}=    Return Number Of Requests Displayed In Indexed Collection    ${collection_index}
    BuiltIn.Should Be Equal As Integers    ${number_of_indexed_collection_requests}    ${number_provided}

Expand Collection And Verify Number Of Requests In Indexed Collection Equals To Number Given
    [Arguments]    ${collection_index}    ${number_provided}
    [Documentation]    Expands collection with given index and verifies that number of indexed collection requests equals to the number provided as an argument.
    Select And Expand Collection    ${collection_index}
    Verify Number Of Requests Displayed In Indexed Collection Equals To Number Given    ${collection_index}    ${number_provided}

Return Collection Indexed Request Operation Label
    [Arguments]    ${collection_index}    ${request_index}
    [Documentation]    Returns label of collection indexed request operation.
    ${collection_indexed_request}=    Return Collection Indexed Request    ${collection_index}    ${request_index}
    ${collection_indexed_request_operation_xpath}=    BuiltIn.Set Variable    ${collection_indexed_request}//p[contains(@id, "operation")]
    ${collection_indexed_request_operation_label}=    Selenium2Library.Get Text    ${collection_indexed_request_operation_xpath}
    ${collection_indexed_request_operation_label_stripped}=    String.Strip String    ${collection_indexed_request_operation_label}
    [Return]    ${collection_indexed_request_operation_label_stripped}

Compare Collection Indexed Request Operation Label With Given Operation Name
    [Arguments]    ${collection_index}    ${request_index}    ${operation_name}
    [Documentation]    Compares collection indexed request operation label with operation name provided as an argument.
    ${collection_indexed_request_operation_label}=    Return Collection Indexed Request Operation Label    ${collection_index}    ${request_index}
    BuiltIn.Should Be Equal    ${collection_indexed_request_operation_label}    ${operation_name}

Return Collection Indexed Request Url Label
    [Arguments]    ${collection_index}    ${request_index}
    [Documentation]    Returns label of collection indexed request url.
    ${collection_indexed_request}=    Return Collection Indexed Request    ${collection_index}    ${request_index}
    ${collection_indexed_request_url_xpath}=    BuiltIn.Set Variable    ${collection_indexed_request}//p[contains(@id, "url")]
    ${collection_indexed_request_url_label}=    Selenium2Library.Get Text    ${collection_indexed_request_url_xpath}
    [Return]    ${collection_indexed_request_url_label}

Verify Collection Indexed Request Url Label Contains Given Key
    [Arguments]    ${collection_index}    ${request_index}    ${key}
    [Documentation]    Verifies that collection indexed request url label contains key.
    ${collection_indexed_request_url_label}=    Return Collection Indexed Request Url Label    ${collection_index}    ${request_index}
    BuiltIn.Should Contain    ${collection_indexed_request_url_label}    ${key}

Navigate To Collections Tab And Delete All Collections
    [Documentation]    Navigates to history tab and deletes all collections and verify they have been deleted.
    YangmanKeywords.Navigate To Collections Tab
    YangmanKeywords.Delete All Collections And Verify They Have Been Deleted

Click Delete All Collections Button
    [Documentation]    Clicks delete all button to delete all collections.
    Patient Click    ${DELETE_ALL_COLLECTIONS_BUTTON}    ${DELETE_ALL_COLLECTIONS_DIALOG_ACTION_OK}

Click Delete All Collections Dialog Button OK
    [Documentation]    Clicks dialog action button ok.
    GUIKeywords.Patient Click With Wait Until Page Does Not Contain Element Check    ${DELETE_ALL_COLLECTIONS_DIALOG_ACTION_OK}    ${DELETE_ALL_COLLECTIONS_DIALOG_ACTION_OK}

Verify Any Collection Is Displayed
    [Documentation]    Verifies that there is at least one collection displayed in Collections list.
    ${number_of_collections}=    Return Number Of Collections Displayed
    BuiltIn.Should Be True    ${number_of_collections}>0

Delete All Collections
    [Documentation]    Deletes all collections using Delete all collections button.
    ${collections_are_displayed}=    BuiltIn.Run Keyword And Return Status    Verify Any Collection Is Displayed
    BuiltIn.Run Keyword If    ${collections_are_displayed}==True    BuiltIn.Run Keywords    GUIKeywords.Focus And Click Element    ${DELETE_COLLECTIONS_MENU_BUTTON}
    ...    AND    Click Delete All Collections Button
    ...    AND    Click Delete All Collections Dialog Button OK

Delete All Collections And Verify They Have Been Deleted
    [Documentation]    Deletes all collections using Delete all collections button and verifies these collections have been deleted.
    Delete All Collections
    Verify Number Of Collections Displayed Equals To Number Given    0

Open Collections Settings Dialog
    [Documentation]    Click collections setting button to open collections settings dialog if it is not opened.
    ${collections_settings_dialog_is_opened}=    BuiltIn.Run Keyword And Return Status    Selenium2Library.Wait Until Page Contains Element    ${COLLECTIONS_SETTINGS_DIALOG}
    BuiltIn.Run Keyword If    ${collections_settings_dialog_is_opened}==False    GUIKeywords.Patient Click    ${COLLECTIONS_SETTINGS_BUTTON}    ${COLLECTIONS_SETTINGS_DIALOG}

Click Collections Settings Dialog Save Button
    [Documentation]    Click collections setting save button to save changes.
    GUIKeywords.Patient Click With Wait Until Page Does Not Contain Element Check    ${COLLECTIONS_SETTINGS_SAVE_BUTTON}    ${COLLECTIONS_SETTINGS_SAVE_BUTTON}

Open Collections Settings Dialog And Select Save Base Response Data Select Checkbox
    [Documentation]    Selects save base response data select checkbox in collections settings.
    Open Collections Settings Dialog
    ${save_base_response_data_checkbox_is_selected}=    BuiltIn.Run Keyword And Return Status    Selenium2Library.Page Should Contain Element    ${COLLECTIONS_SETTINGS_SAVE_BASE_RESPONSE_DATA_CHECKBOX_SELECTED}
    BuiltIn.Run Keyword If    ${save_base_response_data_checkbox_is_selected}==False    GUIKeywords.Patient Click    ${COLLECTIONS_SETTINGS_SAVE_BASE_RESPONSE_DATA_CHECKBOX}    ${COLLECTIONS_SETTINGS_SAVE_BASE_RESPONSE_DATA_CHECKBOX_SELECTED}

Open Collections Settings Dialog And Unselect Save Base Response Data Select Checkbox
    [Documentation]    Unselects save base response data select checkbox in collections settings.
    Open Collections Settings Dialog
    ${save_base_response_data_checkbox_is_unselected}=    BuiltIn.Run Keyword And Return Status    Selenium2Library.Page Should Contain Element    ${COLLECTIONS_SETTINGS_SAVE_BASE_RESPONSE_DATA_CHECKBOX_UNSELECTED}
    BuiltIn.Run Keyword If    ${save_base_response_data_checkbox_is_unselected}==False    GUIKeywords.Patient Click    ${COLLECTIONS_SETTINGS_SAVE_BASE_RESPONSE_DATA_CHECKBOX}    ${COLLECTIONS_SETTINGS_SAVE_BASE_RESPONSE_DATA_CHECKBOX_UNSELECTED}

Open Collections Settings Dialog And Select Save Received Data Select Checkbox
    [Documentation]    Selects save received data select checkbox in collection settings.
    Open Collections Settings Dialog
    ${save_received_data_checkbox_is_selected}=    BuiltIn.Run Keyword And Return Status    Selenium2Library.Page Should Contain Element    ${COLLECTIONS_SETTINGS_SAVE_RECEIVED_DATA_CHECKBOX_SELECTED}
    BuiltIn.Run Keyword If    ${save_received_data_checkbox_is_selected}==False    GUIKeywords.Patient Click    ${COLLECTIONS_SETTINGS_SAVE_RECEIVED_DATA_CHECKBOX}    ${COLLECTIONS_SETTINGS_SAVE_RECEIVED_DATA_CHECKBOX_SELECTED}

Open Collections Settings Dialog And Unselect Save Received Data Select Checkbox
    [Documentation]    Unselects save received data select checkbox in collections settings.
    Open Collections Settings Dialog
    ${save_received_data_checkbox_is_unselected}=    BuiltIn.Run Keyword And Return Status    Selenium2Library.Page Should Contain Element    ${COLLECTIONS_SETTINGS_SAVE_RECEIVED_DATA_CHECKBOX_UNSELECTED}
    BuiltIn.Run Keyword If    ${save_received_data_checkbox_is_unselected}==False    GUIKeywords.Patient Click    ${COLLECTIONS_SETTINGS_SAVE_RECEIVED_DATA_CHECKBOX}    ${COLLECTIONS_SETTINGS_SAVE_RECEIVED_DATA_CHECKBOX_UNSELECTED}

Open Collections Settings Dialog And Select Fill Form View With Received Data On History Request Select Checkbox
    [Documentation]    Selects Fill form view with received data on collections request select checkbox in collections settings.
    Open Collections Settings Dialog
    ${fill_form_view_checkbox_is_selected}=    BuiltIn.Run Keyword And Return Status    Selenium2Library.Page Should Contain Element    ${COLLECTIONS_SETTINGS_FILL_FORM_WITH_RECEIVED_DATA_ON_REQUEST_SELECT_CHECKBOX_SELECTED}
    BuiltIn.Run Keyword If    ${fill_form_view_checkbox_is_selected}==False    GUIKeywords.Patient Click    ${COLLECTIONS_SETTINGS_FILL_FORM_WITH_RECEIVED_DATA_ON_REQUEST_SELECT_CHECKBOX}    ${COLLECTIONS_SETTINGS_FILL_FORM_WITH_RECEIVED_DATA_ON_REQUEST_SELECT_CHECKBOX_SELECTED}

Open Collections Settings Dialog And Unselect Fill Form View With Received Data On History Request Select Checkbox
    [Documentation]    Unselects Fill form view with received data on history request select checkbox in collections settings.
    Open Collections Settings Dialog
    ${fill_form_view_checkbox_is_unselected}=    BuiltIn.Run Keyword And Return Status    Selenium2Library.Page Should Contain Element    ${COLLECTIONS_SETTINGS_FILL_FORM_WITH_RECEIVED_DATA_ON_REQUEST_SELECT_CHECKBOX_UNSELECTED}
    BuiltIn.Run Keyword If    ${fill_form_view_checkbox_is_unselected}==False    GUIKeywords.Patient Click    ${COLLECTIONS_SETTINGS_FILL_FORM_WITH_RECEIVED_DATA_ON_REQUEST_SELECT_CHECKBOX}    ${COLLECTIONS_SETTINGS_FILL_FORM_WITH_RECEIVED_DATA_ON_REQUEST_SELECT_CHECKBOX_UNSELECTED}

Select Save Base Response Data And Save Received Data And Fill Form With Received Data On Request Select Checkboxes In Collections Settings And Save Changes
    [Documentation]    Opens collections settings dialog and selects save base response data, save received data and fill form view with received data on history request select checkboxes.
    Open Collections Settings Dialog And Select Save Base Response Data Select Checkbox
    Open Collections Settings Dialog And Select Save Received Data Select Checkbox
    Open Collections Settings Dialog And Select Fill Form View With Received Data On History Request Select Checkbox
    Click Collections Settings Dialog Save Button

Navigate To Collections Tab And Delete All Collections And Select All Collections Settings Checkboxes
    [Documentation]    Deletes all collections using delete all button and select all checkboxes and save changes
    Navigate To Collections Tab And Delete All Collections
    Select Save Base Response Data And Save Received Data And Fill Form With Received Data On Request Select Checkboxes In Collections Settings And Save Changes

Delete All History Requests And Collections And Select All Checkboxes In History And Collections Settings
    [Documentation]    Deletes all history requests and deletes all collections and selects all checkboxes in history and collections settings.
    YangmanKeywords.Navigate To History Tab And Delete All History Requests And Select All History Settings Checkboxes
    YangmanKeywords.Navigate To Collections Tab And Delete All Collections And Select All Collections Settings Checkboxes

Verify Collections Requests With Given Indeces Contain Data In Api And No Data In Form And Contain Status And Time Data
    [Arguments]    ${keys}    ${collection_id}    ${first_index}    ${last_index}
    [Documentation]    Verify collections requests with given indeces contain data in api and no data in form and contain status and time data.
    ${key_index}=    BuiltIn.Evaluate    -1
    : FOR    ${index}    IN RANGE    ${first_index}    ${last_index}+1
    \    ${key_index}=    BuiltIn.Evaluate    ${key_index}+1
    \    ${key}=    Collections.Get From List    ${keys}    ${key_index}
    \    YangmanKeywords.Select Collection Indexed Request    ${collection_id}    ${index}
    \    YangmanKeywords.Verify Labelled Api Path Input Contains Data    ${TOPOLOGY_LABEL}    ${key}
    \    YangmanKeywords.Verify Labelled Form Input Field Does Not Contain Any Data    ${TOPOLOGY_ID_LABEL}
    \    YangmanKeywords.Verify Request Status Code Matches Desired Code And Request Execution Time Is Present    ${20X_REQUEST_CODE_REGEX}
    \    BuiltIn.Run Keyword If    ${first_index}==${last_index}    BuiltIn.Exit For Loop

Verify Collections Requests With Given Indeces Contain Data In Api And Form And Contain Status And Time Data
    [Arguments]    ${keys}    ${collection_id}    ${first_index}    ${last_index}
    [Documentation]    Verify collections requests with given indeces contain data in api and form and contain status and time data.
    ${key_index}=    BuiltIn.Evaluate    -1
    : FOR    ${index}    IN RANGE    ${first_index}    ${last_index}+1
    \    ${key_index}=    BuiltIn.Evaluate    ${key_index}+1
    \    ${key}=    Collections.Get From List    ${keys}    ${key_index}
    \    YangmanKeywords.Select Collection Indexed Request    ${collection_id}    ${index}
    \    YangmanKeywords.Verify Labelled Api Path Input Contains Data    ${TOPOLOGY_LABEL}    ${key}
    \    YangmanKeywords.Verify Labelled Form Input Field Contains Data    ${TOPOLOGY_ID_LABEL}    ${key}
    \    YangmanKeywords.Verify Request Status Code Matches Desired Code And Request Execution Time Is Present    ${20X_REQUEST_CODE_REGEX}
    \    BuiltIn.Run Keyword If    ${first_index}==${last_index}    BuiltIn.Exit For Loop

Verify Collections Requests With Given Indeces Contain Data In Api And Form And Do Not Contain Status And Time Data
    [Arguments]    ${keys}    ${collection_id}    ${first_index}    ${last_index}
    [Documentation]    Verify collections requests with given indeces contain data in api and form and do not contain status and time data.
    ${key_index}=    BuiltIn.Evaluate    -1
    : FOR    ${index}    IN RANGE    ${first_index}    ${last_index}+1
    \    ${key_index}=    BuiltIn.Evaluate    ${key_index}+1
    \    ${key}=    Collections.Get From List    ${keys}    ${key_index}
    \    YangmanKeywords.Select Collection Indexed Request    ${collection_id}    ${index}
    \    YangmanKeywords.Verify Labelled Api Path Input Contains Data    ${TOPOLOGY_LABEL}    ${key}
    \    YangmanKeywords.Verify Labelled Form Input Field Contains Data    ${TOPOLOGY_ID_LABEL}    ${key}
    \    YangmanKeywords.Verify Request Status Code Matches Desired Code And Request Execution Time Is Threedots    ${THREE_DOTS_DEFAULT_STATUS_AND_TIME}
    \    BuiltIn.Run Keyword If    ${first_index}==${last_index}    BuiltIn.Exit For Loop

Verify Collections Requests With Given Indeces Contain Data In Api And No Data In Form And Do Not Contain Status And Time Data
    [Arguments]    ${keys}    ${collection_id}    ${first_index}    ${last_index}
    [Documentation]    Verify collections requests with given indeces contain data in api and no data in form and do not contain status and time data.
    ${key_index}=    BuiltIn.Evaluate    -1
    : FOR    ${index}    IN RANGE    ${first_index}    ${last_index}+1
    \    ${key_index}=    BuiltIn.Evaluate    ${key_index}+1
    \    ${key}=    Collections.Get From List    ${keys}    ${key_index}
    \    YangmanKeywords.Select Collection Indexed Request    ${collection_id}    ${index}
    \    YangmanKeywords.Verify Labelled Api Path Input Contains Data    ${TOPOLOGY_LABEL}    ${key}
    \    YangmanKeywords.Verify Labelled Form Input Field Does Not Contain Any Data    ${TOPOLOGY_ID_LABEL}
    \    YangmanKeywords.Verify Request Status Code Matches Desired Code And Request Execution Time Is Threedots    ${THREE_DOTS_DEFAULT_STATUS_AND_TIME}
    \    BuiltIn.Run Keyword If    ${first_index}==${last_index}    BuiltIn.Exit For Loop

Verify Collections Requests With Given Indeces Contain Data In Api And Error Message In Form And Contain 400 Status And Time Data
    [Arguments]    ${keys}    ${collection_id}    ${first_index}    ${last_index}
    [Documentation]    Verify collections requests with given indeces contain data in api and error message in form and contain 400 status and contain time data.
    ${key_index}=    BuiltIn.Evaluate    -1
    : FOR    ${index}    IN RANGE    ${first_index}    ${last_index}+1
    \    ${key_index}=    BuiltIn.Evaluate    ${key_index}+1
    \    ${key}=    Collections.Get From List    ${keys}    ${key_index}
    \    YangmanKeywords.Select Collection Indexed Request    ${collection_id}    ${index}
    \    YangmanKeywords.Verify Labelled Api Path Input Contains Data    ${TOPOLOGY_LABEL}    ${key}
    \    YangmanKeywords.Verify Labelled Form Input Field Does Not Contain Any Data    ${TOPOLOGY_ID_LABEL}
    \    YangmanKeywords.Verify Form Contains Error Message    ${error_message}
    \    YangmanKeywords.Verify Request Status Code Matches Desired Code And Request Execution Time Is Present    ${40X_REQUEST_CODE_REGEX}
    \    BuiltIn.Run Keyword If    ${first_index}==${last_index}    BuiltIn.Exit For Loop

Compare Collection Indexed Request Operation Label And Verify Url Label Contains Given Key
    [Arguments]    ${collection_id}    ${operation_name}    ${keys}
    [Documentation]    Compares collection indexed request operation label with operation name provided as an argument and verifies url label contains key provided as an argument.
    : FOR    ${index}    IN RANGE    0    len(@{keys})
    \    ${key}=    Collections.Get From List    ${keys}    ${index}
    \    YangmanKeywords.Compare Collection Indexed Request Operation Label With Given Operation Name    ${collection_id}    ${index}    ${operation_name}
    \    YangmanKeywords.Verify Collection Indexed Request Url Label Contains Given Key    ${collection_id}    ${index}    ${key}

Return Collection Indexed Request Yangmenu
    [Arguments]    ${collection_index}    ${request_index}
    [Documentation]    Returns xpath of collection indexed request yangmenu.
    ${collection_request_indexed_yangmenu}=    BuiltIn.Set Variable    //button[@id="collection-request-${collection_index}-${request_index}-submenu"]
    [Return]    ${collection_request_indexed_yangmenu}

Return And Click Collection Indexed Request Yangmenu
    [Arguments]    ${collection_index}    ${request_index}
    [Documentation]    Returns and clicks collection indexed request yangmenu.
    ${collection_request_indexed_yangmenu}=    Return Collection Indexed Request Yangmenu    ${collection_index}    ${request_index}
    GUIKeywords.Mouse Down And Mouse Up Click Element    ${collection_request_indexed_yangmenu}

Return Collection Indexed Request Run Request Button
    [Arguments]    ${collection_index}    ${request_index}
    [Documentation]    Returns xpath of collection indexed request run request button.
    ${collection_indexed_request_run_request_button}=    BuiltIn.Set Variable    //button[@id="collection-request-${collection_index}-${request_index}-execute"]
    [Return]    ${collection_indexed_request_run_request_button}

Return And Click Collection Indexed Request Run Request Button
    [Arguments]    ${collection_index}    ${request_index}
    [Documentation]    Returns and clicks collection indexed request run request button.
    ${collection_indexed_request_run_request_button}=    Return Collection Indexed Request Run Request Button    ${collection_index}    ${request_index}
    GUIKeywords.Patient Click With Wait Until Element Is Not Visible Check    ${collection_indexed_request_run_request_button}    ${collection_indexed_request_run_request_button}

Run Collection Indexed Request Via Run Request Button
    [Arguments]    ${collection_index}    ${request_index}
    [Documentation]    Clicks collection indexed request yangmenu and clicks run request button.
    Return And Click Collection Indexed Request Yangmenu    ${collection_index}    ${request_index}
    Return And Click Collection Indexed Request Run Request Button    ${collection_index}    ${request_index}

Select And Send Collection Indexed Request From Form
    [Arguments]    ${collection_index}    ${request_index}
    [Documentation]    Selects collection indexed request and sends it from form using send button.
    Select Collection Indexed Request    ${collection_index}    ${request_index}
    Send Request

Return Collection Indexed Request Selected
    [Arguments]    ${collection_index}    ${request_index}
    [Documentation]    Returns xpath of collection indexed request selected.
    ${collection_indexed_request_selected}=    BuiltIn.Set Variable    //md-list-item[contains(@id,"collection-request-${collection_index}-${request_index}) and contains(@class, "selected")]
    [Return]    ${collection_indexed_request_selected}

Return Collection Indexed Request Delete Request Button
    [Arguments]    ${collection_index}    ${request_index}
    [Documentation]    Returns xpath of collection indexed request delete request button.
    ${collection_indexed_request_delete_request_button}=    BuiltIn.Set Variable    //button[@id="collection-request-${collection_index}-${request_index}-delete"]
    [Return]    ${collection_indexed_request_delete_request_button}

Return And Click Collection Indexed Request Delete Request Button
    [Arguments]    ${collection_index}    ${request_index}
    [Documentation]    Returns and clicks collection indexed request delete request button.
    ${collection_indexed_request_delete_request_button}=    Return Collection Indexed Request Delete Request Button    0    ${request_index}
    GUIKeywords.Patient Click With Wait Until Element Is Not Visible Check    ${collection_indexed_request_delete_request_button}    ${collection_indexed_request_delete_request_button}

Delete Collection Indexed Request Via Delete Request Button
    [Arguments]    ${collection_index}    ${request_index}
    [Documentation]    Clicks collection indexed request yangmenu and clicks delete request button.
    Return And Click Collection Indexed Request Yangmenu    ${collection_index}    ${request_index}
    Return And Click Collection Indexed Request Delete Request Button    ${collection_index}    ${request_index}
    Click Delete History Request Dialog Button OK

Click Delete Selected Collection Request Button
    [Documentation]    Clicks delete selected button to delete selected collection indexed request.
    Patient Click    ${DELETE_SELECTED_COLLECTIONS_REQUEST_BUTTON}    ${DELETE_SELECTED_HISTORY_REQUEST_DIALOG}

Select Collection Indexed Request And Delete The Request Via Delete Selected Button
    [Arguments]    ${collection_index}    ${request_index}
    [Documentation]    Deletes selected collection indexed request using delete selected button.
    Select Collection Indexed Request    ${collection_index}    ${request_index}
    GUIKeywords.Focus And Click Element    ${DELETE_COLLECTIONS_MENU_BUTTON}
    Click Delete Selected Collection Request Button
    Click Delete History Request Dialog Button OK

Return Indexed Collection Yangmenu
    [Arguments]    ${collection_index}
    [Documentation]    Returns xpath of indexed collection yangmenu.
    ${indexed_collection_yangmenu}=    BuiltIn.Set Variable    //md-menu[@id="collection-menu-${collection_index}"]/button
    [Return]    ${indexed_collection_yangmenu}

Return And Click Indexed Collection Yangmenu
    [Arguments]    ${collection_index}
    [Documentation]    Returns xpath of indexed collection yangmenu and clicks the indexed collection yangmenu.
    ${indexed_collection_yangmenu}=    Return Indexed Collection Yangmenu    ${collection_index}
    GUIKeywords.Mouse Down And Mouse Up Click Element    ${indexed_collection_yangmenu}

Return Indexed Collection Delete Collection Button
    [Arguments]    ${collection_index}
    [Documentation]    Returns xpath of indexed collection delete button.
    ${indexed_collection_delete_button}=    BuiltIn.Set Variable    //button[@id="collection-menu-${collection_index}-delete"]
    [Return]    ${indexed_collection_delete_button}

Return And Click Indexed Collection Delete Collection Button
    [Arguments]    ${collection_index}
    [Documentation]    Returns and clicks indexed collection delete button.
    ${indexed_collection_delete_button}=    Return Indexed Collection Delete Collection Button    ${collection_index}
    GUIKeywords.Patient Click With Wait Until Element Is Not Visible Check    ${indexed_collection_delete_button}    ${indexed_collection_delete_button}

Click Delete Collection Dialog Button Ok
    [Documentation]    Click delete collection dialog ok button.
    GUIKeywords.Patient Click With Wait Until Page Does Not Contain Element Check    ${DELETE_COLLECTION_DIALOG_OK_BUTTON}    ${DELETE_COLLECTION_DIALOG_OK_BUTTON}

Delete Collection Using Delete Collection Button
    [Arguments]    ${collection_index}
    [Documentation]    Deletes indexed collection via delete collection button
    Return And Click Indexed Collection Yangmenu    ${collection_index}
    Return And Click Indexed Collection Delete Collection Button    ${collection_index}
    Click Delete Collection Dialog Button Ok
