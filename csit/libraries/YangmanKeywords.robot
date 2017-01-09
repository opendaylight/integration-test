*** Settings ***
Documentation     A resource file containing all global keyword to help
...               Yangman GUI and functional testing.
Library           OperatingSystem
Library           Collections
Library           HttpLibrary.HTTP
Library           Selenium2Library    timeout=15    implicit_wait=15    run_on_failure=Selenium2Library.Capture Page Screenshot
Variables         ../variables/Variables.py
Resource          GUIKeywords.robot
Resource          ../variables/YangmanGUIVariables.robot

*** Keywords ***
Open DLUX And Login And Navigate To Yangman URL
    GUIKeywords.Launch Or Open DLUX Page And Login DLUX
    GUIKeywords.Navigate To URL    ${Yangman_Submenu_URL}

Return List Of Operation IDs
    ${list}=    BuiltIn.Create List    ${Get_Option}    ${Put_Option}    ${Post_Option}    ${Delete_Option}
    [Return]    ${list}

Return List Of Operation Names
    ${list}=    BuiltIn.Create List    ${Get_Operation_Name}    ${Put_Operation_Name}    ${Post_Operation_Name}    ${Delete_Operation_Name}
    [Return]    ${list}

Modules Tab Is Selected
    Selenium2Library.Page Should Contain Element    ${Modules_Tab_Selected}
    Selenium2Library.Page Should Contain Element    ${Module_Search_Input}
    Selenium2Library.Page Should Contain Element    ${History_Tab_Unselected}
    Selenium2Library.Page Should Contain Element    ${Collections_Tab_Unselected}

Expand Operation Select Menu
    Selenium2Library.Focus    ${Operation_Select_Input}
    Selenium2Library.Click Element    ${Operation_Select_Input}
    BuiltIn.Wait Until Keyword Succeeds    1 min    5 sec    Selenium2Library.Page Should Contain Element    ${Operation_Select_Menu_Expanded}

Close Select Box
    Click Element    ${Select_Backdrop}

Select Operation
    [Arguments]    ${operation_id}
    Selenium2Library.Page Should Contain Element    ${Operation_Select_Menu_Expanded}
    Selenium2Library.Focus    ${operation_id}
    Selenium2Library.Click Element    ${operation_id}

Verify Selected Operation Is Displayed
    [Arguments]    ${selected_operation_name}
    ${Selected_Operation_Xpath}=    Set Variable    ${Operation_Select_Input}//span/div[contains(text(), "${selected_operation_name}")]
    GUIKeywords.Page Should Contain Element With Wait    ${Selected_Operation_Xpath}

Choose Operation
    [Arguments]    ${operation_id}
    Expand Operation Select Menu
    Select Operation    ${operation_id}

Verify Yangman Home Page Elements
    BuiltIn.Wait Until Keyword Succeeds    30 sec    5 sec    Selenium2Library.Page Should Contain Element    ${Yangman_Logo}
    Selenium2Library.Log Location
    Modules Tab Is Selected
    Selenium2Library.Page Should Contain Element    ${Toggle_Menu_Button}
    Selenium2Library.Page Should Contain Element    ${Logout_Button}
    Verify Selected Operation Is Displayed    ${Get_Operation_Name}
    Selenium2Library.Page Should Contain Element    ${Request_URL_Input}
    Selenium2Library.Page Should Contain Element    ${Send_Button}
    Selenium2Library.Page Should Contain Element    ${Save_Button}
    Selenium2Library.Page Should Contain Element    ${Parameters_Button}
    Selenium2Library.Page Should Contain Element    ${Form_Radiobutton_Unselected}
    Selenium2Library.Page Should Contain Element    ${Json_Radiobutton_Selected}
    Selenium2Library.Page Should Contain Element    ${Received_Data_Code_Mirror_Displayed}
    Selenium2Library.Page Should Contain Element    ${Received_Data_Enlarge_Font_Size_Button}
    Selenium2Library.Page Should Contain Element    ${Received_Data_Reduce_Font_Size_Button}
    Selenium2Library.Page Should Not Contain Element    ${Sent_Data_Code_Mirror_Displayed}

Select Form View
    ${status}=    BuiltIn.Run Keyword And Return Status    Selenium2Library.Page Should Contain Element    ${Form_Radiobutton_Selected}
    BuiltIn.Run Keyword If    "${status}"=="False"    Selenium2Library.Click Element    ${Form_Radiobutton_Unselected}

Select Json View
    ${status}=    BuiltIn.Run Keyword And Return Status    Selenium2Library.Page Should Contain Element    ${Json_Radiobutton_Selected}
    BuiltIn.Run Keyword If    "${status}"=="False"    Selenium2Library.Click Element    ${Json_Radiobutton_Unselected}

Return Number Of Modules Loaded
    [Arguments]    ${module_xpath}
    ${number_of_modules}=    Selenium2Library.Get Matching Xpath Count    ${module_xpath}
    [Return]    ${number_of_modules}

Verify Any Module Is Loaded
    ${numberof__modules_loaded}=    Return Number Of Modules Loaded    ${Module_List_Item}
    Should Be True    ${number_of_modules_loaded}>0

Return Module List Indexed Module
    [Arguments]    ${index}
    ${Module_Index}=    BuiltIn.Catenate    SEPARATOR=    ${Module_ID_Label}    ${index}
    ${Module_List_Item_Indexed}=    BuiltIn.Set Variable    ${Module_Tab_Content}//md-list-item[@id="${Module_Index}"]//div[@class="pointer title layout-align-center-center layout-row"]
    [Return]    ${Module_List_Item_Indexed}

Return Indexed Module Operations Label
    [Arguments]    ${index}
    ${Module_List_Item_Indexed}=    Return Module List Indexed Module    ${index}
    ${Indexed_Module_Operations_Label}=    BuiltIn.Set Variable    ${Module_List_Item_Indexed}//following-sibling::md-list[@aria-hidden="false"]//p[contains(., "${Module_List_Operations_Label}")]
    [Return]    ${Indexed_Module_Operations_Label}

Return Indexed Module Operational Label
    [Arguments]    ${index}
    ${Module_List_Item_Indexed}=    Return Module List Indexed Module    ${index}
    ${Indexed_Module_Operational_Label}=    BuiltIn.Set Variable    ${Module_List_Item_Indexed}//following-sibling::md-list[@aria-hidden="false"]//p[contains(., "${Module_List_Operational_Label}")]
    [Return]    ${Indexed_Module_Operational_Label}

Return Indexed Module Config Label
    [Arguments]    ${index}
    ${Module_List_Item_Indexed}=    Return Module List Indexed Module    ${index}
    ${Indexed_Module_Config_Label}=    BuiltIn.Set Variable    ${Module_List_Item_Indexed}//following-sibling::md-list[@aria-hidden="false"]//p[contains(., "${Module_List_Config_Label}")]
    [Return]    ${Indexed_Module_Config_Label}

Compare Operations Tab Label
    ${operations_label}    Selenium2Library.Get Text    ${Module_Detail_Operations_Tab_Selected}
    ${operations_label_lowercase}=    String.Convert To Lowercase    ${operations_label}
    BuiltIn.Should Be Equal As Strings    ${operations_label_lowercase}    ${Module_List_Operations_Label}

Compare Operational Tab Label
    ${operational_label}    Selenium2Library.Get Text    ${Module_Detail_Operational_Tab_Selected}
    ${operational_label_lowercase}=    String.Convert To Lowercase    ${operational_label}
    BuiltIn.Should Be Equal As Strings    ${operational_label_lowercase}    ${Module_List_Operational_Label}

Compare Config Tab Label
    ${config_label}    Selenium2Library.Get Text    ${Module_Detail_Config_Tab_Selected}
    ${config_label_lowercase}=    String.Convert To Lowercase    ${config_label}
    BuiltIn.Should Be Equal As Strings    ${config_label_lowercase}    ${Module_List_Config_Label}

Click Indexed Module Operations To Load Modules Detail Operations Tab
    [Arguments]    ${index}
    ${indexed_module_operations}=    Return Indexed Module Operations Label    ${index}
    GUIKeywords.Page Should Contain Element With Wait    ${indexed_module_operations}
    GUIKeywords.Focus And Click Element    ${indexed_module_operations}
    Selenium2Library.Wait Until Page Contains Element    ${Module_Detail_Operations_Tab_Selected}

Click Indexed Module Operational To Load Modules Detail Operational Tab
    [Arguments]    ${index}
    ${indexed_module_operational}=    Return Indexed Module Operational Label    ${index}
    GUIKeywords.Page Should Contain Element With Wait    ${indexed_module_operational}
    GUIKeywords.Focus And Click Element    ${indexed_module_operational}
    Selenium2Library.Wait Until Page Contains Element    ${Module_Detail_Operational_Tab_Selected}

Click Indexed Module Config To Load Modules Detail Config Tab
    [Arguments]    ${index}
    ${indexed_module_config}=    Return Indexed Module Config Label    ${index}
    GUIKeywords.Page Should Contain Element With Wait    ${indexed_module_config}
    GUIKeywords.Focus And Click Element    ${indexed_module_config}
    Selenium2Library.Wait Until Page Contains Element    ${Module_Detail_Config_Tab_Selected}

Toggle Module Detail
    Selenium2Library.Wait Until Element Is Visible    ${Arrow_Switcher_Button}
    GUIKeywords.Focus And Click Element    ${Arrow_Switcher_Button}

Return Module ID Index From Module Name
    [Arguments]    ${module_name}
    ${testing_module_xpath}=    BuiltIn.Set Variable    ${Module_Tab_Content}//p[contains(., "${Testing_Module_Name}")]//ancestor::md-list-item[contains(@id, "${Module_ID_Label}")]
    ${module_id}=    Selenium2Library.Get Element Attribute    ${testing_module_xpath}@id
    ${module_id_index}=    String.Fetch From Right    ${module_id}    ${Module_ID_Label}
    [Return]    ${module_id_index}

Return Indexed Module From Module Name
    [Arguments]    ${module_name}
    ${module_id_index}=    Return Module ID Index From Module Name    ${module_name}
    BuiltIn.Set Suite Variable    ${index}
    ${module_list_item_indexed}=    Return Module List Indexed Module    ${index}
    [Return]    ${module_list_item_indexed}

Expand Module
    [Arguments]    ${module_name}    ${module_id_index}
    ${module_list_item_indexed}=    BuiltIn.Run Keyword If    "${module_name}"!= "${EMPTY}"    Return Indexed Module From Module Name    ${module_name}
    ${module_list_item_indexed}=    BuiltIn.Run Keyword If    "${module_id_index}"!= "${EMPTY}"    Return Module List Indexed Module    ${module_id_index}
    Selenium2Library.Click Element    ${module_list_item_indexed}
    ${module_list_item_collapsed_indexed}=    BuiltIn.Set Variable    ${module_list_item_indexed}//following-sibling::md-list[@aria-hidden="true"]
    Selenium2Library.Page Should Not Contain Element    ${module_list_item_collapsed_indexed}

Click Module Operational Tab
    [Arguments]    ${module_name}    ${module_id_index}
    Expand Module    ${module_name}    ${module_id_index}
    Click Indexed Module Operational To Load Modules Detail Operational Tab    ${module_id_index}
    Selenium2Library.Click Element    ${Module_Detail_Operational_Tab_Selected}

Navigate To Testing Module Operational Tab
    [Arguments]    ${Testing_Module_Name}
    ${module_id_index}=    YangmanKeywords.Return Module ID Index From Module Name    ${Testing_Module_Name}
    Selenium2Library.Wait Until Page Does Not Contain Element    ${Modules_Were_Loaded_Alert}
    YangmanKeywords.Click Module Operational Tab    ${EMPTY}    ${module_id_index}

Click Module Config Tab
    [Arguments]    ${module_name}    ${module_id_index}
    Expand Module    ${module_name}    ${module_id_index}
    Click Indexed Module Config To Load Modules Detail Config Tab    ${module_id_index}
    Selenium2Library.Click Element    ${Module_Detail_Config_Tab_Selected}

Navigate To Testing Module Config Tab
    [Arguments]    ${Testing_Module_Name}
    ${module_id_index}=    YangmanKeywords.Return Module ID Index From Module Name    ${Testing_Module_Name}
    Selenium2Library.Wait Until Page Does Not Contain Element    ${Modules_Were_Loaded_Alert}
    YangmanKeywords.Click Module Config Tab    ${EMPTY}    ${module_id_index}

Select Module Detail Operational Tab
    ${status}=    BuiltIn.Run Keyword And Return Status    Selenium2Library.Page Should Contain Element    ${Module_Detail_Operational_Tab_Selected}
    BuiltIn.Run Keyword If    "${status}"=="False"    Selenium2Library.Click Element    ${Module_Detail_Operational_Tab_Deselected}

Select Module Detail Config Tab
    ${status}=    BuiltIn.Run Keyword And Return Status    Selenium2Library.Page Should Contain Element    ${Module_Detail_Config_Tab_Selected}
    BuiltIn.Run Keyword If    "${status}"=="False"    Selenium2Library.Click Element    ${Module_Detail_Config_Tab_Deselected}

Expand All Branches In Module Detail Content Active Tab
    Selenium2Library.Wait Until Element Is Visible    ${Module_Detail_Expand_Branch_Button}
    : FOR    ${i}    IN RANGE    1    1000
    \    ${count}=    Selenium2Library.Get Matching Xpath Count    ${Module_Detail_Expand_Branch_Button}
    \    BuiltIn.Exit For Loop If    ${count}==0
    \    Selenium2Library.Click Element    ${Module_Detail_Expand_Branch_Button}
    Selenium2Library.Page Should Not Contain Element    ${Module_Detail_Expand_Branch_Button}

Collapse All Branches In Module Detail Content Active Tab
    Selenium2Library.Wait Until Element Is Visible    ${Module_Detail_Collapse_Branch_Button}
    : FOR    ${i}    IN RANGE    1    1000
    \    ${count}=    Selenium2Library.Get Matching Xpath Count    ${Module_Detail_Collapse_Branch_Button}
    \    BuiltIn.Exit For Loop If    ${count}==0
    \    Selenium2Library.Click Element    ${Module_Detail_Collapse_Branch_Button}
    Selenium2Library.Page Should Not Contain Element    ${Module_Detail_Collapse_Branch_Button}

Catenate Branch Id
    [Arguments]    ${index}
    ${branch_id}=    BuiltIn.Catenate    SEPARATOR=    ${Branch_ID_Label}    ${index}
    [Return]    ${branch_id}

Return Branch ID From Branch Label
    [Arguments]    ${branch_label}
    ${labelled_branch_xpath}=    Return Labelled Branch Xpath    ${branch_label}
    ${branch_id}=    Selenium2Library.Get Element Attribute    ${labelled_branch_xpath}//ancestor::md-list-item[contains(@id, "${Branch_ID_Label}")]@id
    [Return]    ${branch_id}

Return Module Detail Branch Indexed
    [Arguments]    ${branch_id}
    ${module_detail_branch_indexed}=    BuiltIn.Set Variable    ${Module_Detail_Active_Tab_Content}//md-list-item[contains(@id, "${branch_id}")]
    [Return]    ${module_detail_branch_indexed}

Return Indexed Branch Label
    [Arguments]    ${module_detail_branch_indexed}
    ${branch_label}=    Selenium2Library.Get Text    ${module_detail_branch_indexed}//span[@class="indented tree-label ng-binding flex"]
    [Return]    ${branch_label}

Return Branch Label Without Curly Braces Part
    [Arguments]    ${branch_label}
    ${branch_label_without_curly_braces_part}=    String.Fetch From Left    ${branch_label}    ${SPACE}
    [Return]    ${branch_label_without_curly_braces_part}

Return Labelled Branch Xpath
    [Arguments]    ${branch_label}
    ${labelled_branch_xpath}=    BuiltIn.Set Variable    ${Module_Detail_Branch}//span[contains(@class, "indented tree-label ng-binding flex") and contains(text(), "${branch_label}")]
    [Return]    ${labelled_branch_xpath}

Return Labelled Branch Toggle Button
    [Arguments]    ${labelled_branch_xpath}
    ${labelled_branch_toggle_button}=    BuiltIn.Set Variable    ${labelled_branch_xpath}//preceding-sibling::md-icon[contains(@id, "toggle-branch-")]
    [Return]    ${labelled_branch_toggle_button}

Return Branch Toggle Button From Branch Label And Click
    [Arguments]    ${branch_label}
    ${labelled_branch_xpath}=    Return Labelled Branch Xpath    ${branch_label}
    ${labelled_branch_toggle_button}=    Return Labelled Branch Toggle Button    ${labelled_branch_xpath}
    Selenium2Library.Page Should Contain Element    ${labelled_branch_toggle_button}
    Selenium2Library.Click Element    ${labelled_branch_toggle_button}

Click Module Detail Branch Indexed
    [Arguments]    ${module_detail_branch_indexed}
    Selenium2Library.Page Should Contain Element    ${module_detail_branch_indexed}
    Selenium2Library.Click Element    ${module_detail_branch_indexed}

Return Form Top Element Label
    ${form_top_element_label}=    Selenium2Library.Get Text    ${Form_Top_Element_Label}
    [Return]    ${form_top_element_label}

Compare Module Detail Branch Label And Form Top Element Label
    [Arguments]    ${branch_label}
    ${branch_label_without_curly_braces_part}=    Return Branch Label Without Curly Braces Part    ${branch_label}
    ${form_top_element_label}=    Return Form Top Element Label
    ${form_top_element_label_stripped}=    String.Strip String    ${form_top_element_label}
    BuiltIn.Should Be Equal As Strings    ${branch_label_without_curly_braces_part}    ${form_top_element_label_stripped}

Verify Module Detail Branch Is List Branch
    [Arguments]    ${module_detail_branch_indexed}
    ${branch_label}=    Return Indexed Branch Label    ${module_detail_branch_indexed}
    ${branch_is_list_evaluation}=    BuiltIn.Run Keyword And Return Status    BuiltIn.Should Contain    ${branch_label}    {
    [Return]    ${branch_is_list_evaluation}

Return List Item With Index []
    [Arguments]    ${branch_label}    ${index}
    ${branch_label_without_curly_braces_part}=    Return Branch Label Without Curly Braces Part    ${branch_label}
    ${list_item_with_index}=    BuiltIn.Catenate    ${branch_label_without_curly_braces_part}    [${index}]
    [Return]    ${list_item_with_index}

Verify Form Top Element Contains List Item With Index []
    [Arguments]    ${branch_label}    ${index}
    ${list_item_with_index}=    Return List Item With Index []    ${branch_label}    ${index}
    ${form_top_list_item_label}=    Selenium2Library.Get Text    ${Form_Top_Element_List_Item_Label}
    ${form_top_list_item_label_lowercase}=    String.Convert To Lowercase    ${form_top_list_item_label}
    BuiltIn.Should Be Equal As Strings    ${list_item_with_index}    ${form_top_list_item_label_lowercase}

Expand Network-Topology Branch
    ${labelled_branch_xpath}=    Return Labelled Branch Xpath    ${Network_Topology_Label}
    ${labelled_branch_toggle_button}=    Return Labelled Branch Toggle Button    ${labelled_branch_xpath}

Load Topology Topology Id Node In Form
    ${topology_topology_id_branch}=    Return Labelled Branch Xpath    ${Topology_Topology_Id_Label}
    ${status}=    BuiltIn.Run Keyword And Return Status    Selenium2Library.Element Should Be Visible    ${topology_topology_id_branch}
    Select Form View
    BuiltIn.Run Keyword If    "${status}"=="False"    YangmanKeywords.Return Branch Toggle Button From Branch Label And Click    ${Network_Topology_Label}
    YangmanKeywords.Return Branch Toggle Button From Branch Label And Click    ${Topology_Topology_Id_Label}

Verify Sent Data CM Is Displayed
    GUIKeywords.Page Should Contain Element With Wait    ${Show_Sent_Data_Checkbox_Selected}
    Selenium2Library.Element Should Be Visible    ${Sent_Data_Code_Mirror_Displayed}

Verify Sent Data CM Is Not Displayed
    GUIKeywords.Page Should Contain Element With Wait    ${Show_Sent_Data_Checkbox_Unselected}
    Selenium2Library.Element Should Not Be Visible    ${Sent_Data_Code_Mirror_Displayed}

Verify Received Data CM Is Displayed
    GUIKeywords.Page Should Contain Element With Wait    ${Show_Received_Data_Checkbox_Selected}
    Selenium2Library.Element Should Be Visible    ${Received_Data_Code_Mirror_Displayed}

Verify Received Data CM Is Not Displayed
    GUIKeywords.Page Should Contain Element With Wait    ${Show_Received_Data_Checkbox_Unselected}
    Selenium2Library.Element Should Not Be Visible    ${Received_Data_Code_Mirror_Displayed}
