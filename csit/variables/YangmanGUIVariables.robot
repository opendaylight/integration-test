*** Settings ***
Documentation     A resource file containing all global Yangman GUI variables
...               to help Yangman GUI and functional testing.
Resource          Variables.robot

*** Variables ***
${t}              true
${f}              false
${Yangman_Logo}    //img[contains(@ng-src, "assets/images/logo_yangman.png") and contains(@id, "page_logo")]
${Toggle_Menu_Button}    //a[@id="toggleMenu"]
${Logout_Button}    //a[@id="logout-button"]
# Left Panel
${Modules_Tab_Name}    Modules
${History_Tab_Name}    History
${Collections_Tab_Name}    Collections
${Left_Tab_Area}    //md-tab-content[@id="tab-content-0"]
${Modules_Tab_Selected}    ${Left_Tab_Area}//md-tab-item[@aria-selected="true"]/span[contains(text(), "${Modules_Tab_Name}")]
${Modules_Tab_Unselected}    ${Left_Tab_Area}//md-tab-item[@aria-selected="false"]/span[contains(text(), "${Modules_Tab_Name}")]
${History_Tab_Selected}    ${Left_Tab_Area}//md-tab-item[@aria-selected="true"]/span[contains(text(), "${History_Tab_Name}")]
${History_Tab_Unselected}    ${Left_Tab_Area}//md-tab-item[@aria-selected="false"]/span[contains(text(), "${History_Tab_Name}")]
${Collections_Tab_Selected}    ${Left_Tab_Area}//md-tab-item[@aria-selected="true"]/span[contains(text(), "${Collections_Tab_Name}")]
${Collections_Tab_Unselected}    ${Left_Tab_Area}//md-tab-item[@aria-selected="false"]/span[contains(text(), "${Collections_Tab_Name}")]
${Modules_Were_Loaded_Alert}    //span[contains(text(), "Modules were loaded.")]
${Toggle_Module_Detail_Button_Left}    //md-icon[@class="arrow-switcher material-icons" and @id="toggle-module-detail"]
${Toggle_Module_Detail_Button_Right}    //md-icon[@class="arrow-switcher material-icons arrow-switcher__left"" and @id="toggle-module-detail"]
# Modules Tab Left Panel
${Module_Tab_Content}    //*[@id="tab-content-2"]
${Module_Search_Input}    //input[@id="search-modules"]
${Module_ID_Label}    module_
${Module_List_Item}    ${Module_Tab_Content}//md-list-item[contains(@id, "${Module_ID_Label}")]//div[@class="pointer title layout-align-center-center layout-row"]
${Module_List_Item_Collapsed}    ${Module_List_Item}//following-sibling::md-list[@aria-hidden="true"]
${Module_List_Item_Expanded}    ${Module_List_Item}//following-sibling::md-list[@aria-hidden="false"]
${Module_List_Module_Name_Xpath}    ${Module_List_Item}//p[@class="top-element flex"]
${Module_List_Operations_Label}    operations
${Module_List_Operational_Label}    operational
${Module_List_Config_Label}    config
${Testing_Module_Name}    ${EMPTY}
${Testing_Module_Xpath}    ${Module_Tab_Content}//p[contains(., "${Testing_Module_Name}")]//ancestor::md-list-item[contains(@id, "${Module_ID_Label}")]
# Module Detail
${Operations_Label}    operations
${Operational_Label}    operational
${Config_Label}    config
${Module_Detail_Content}    //*[@id="tab-content-1"]
${Module_Detail_Module_Name_Label}    ${Module_Detail_Content}//h4
${Module_Detail_Operations_Tab_Selected}    ${Module_Detail_Content}//md-tab-item[@aria-selected="true"]//span[contains(text(), "${Operations_Label}")]
${Module_Detail_Operations_Tab_Deselected}    ${Module_Detail_Content}//md-tab-item[@aria-selected="false"]//span[contains(text(), "${Operations_Label}")]
${Module_Detail_Operational_Tab_Selected}    ${Module_Detail_Content}//md-tab-item[@aria-selected="true"]//span[contains(text(), "${Operational_Label}")]
${Module_Detail_Operational_Tab_Deselected}    ${Module_Detail_Content}//md-tab-item[@aria-selected="false"]//span[contains(text(), "${Operational_Label}")]
${Module_Detail_Config_Tab_Selected}    ${Module_Detail_Content}//md-tab-item[@aria-selected="true"]//span[contains(text(), "${Config_Label}")]
${Module_Detail_Config_Tab_Deselected}    ${Module_Detail_Content}//md-tab-item[@aria-selected="false"]//span[contains(text(), "${Config_Label}")]
${Module_Detail_Tab_Content_Label}    tab-content-
${Module_Detail_Active_Tab_Content}    ${Module_Detail_Content}//md-tab-content[contains(@class, "md-active")]
${Module_Detail_Expand_Branch_Button}    ${Module_Detail_Active_Tab_Content}//md-icon[contains(., "add")]
${Module_Detail_Collapse_Branch_Button}    ${Module_Detail_Active_Tab_Content}//md-list-item//md-icon[contains(., "remove")]
${Branch_Label}    ${EMPTY}
${Network_Topology_Label}    network-topology
${Topology_Topology_Id_Label}    topology {topology-id}
${Node_Node_Id_Label}    node {node-id}
${Link_Link_Id_Label}    link {link-id}
${Branch_ID_Label}    branch-
${Module_Detail_Branch}    ${Module_Detail_Active_Tab_Content}//md-list-item[contains(@id, "${Branch_ID_Label}")]
${Module_Detail_Branch_Label}    ${Module_Detail_Branch}//span[contains(@class, "indented tree-label ng-binding flex") and contains(text(), "${Branch_Label}")]
#History Tab Left Panel
#Collections Tab Left Panel
#Right Panel Header
${Get_Operation_Name}    GET
${Put_Operation_Name}    PUT
${Post_Operation_Name}    POST
${Delete_Operation_Name}    DELETE
${Operation_Name}    EMPTY
${Operation_Select_Input}    //md-select[@id="request-selected-operation"]
${Operation_Select_Input_Clickable}    ${Operation_Select_Input}//parent::md-input-container
${Select_Backdrop}    //md-backdrop[@class="md-select-backdrop md-click-catcher ng-scope"]
${Operation_Select_Menu_Expanded}    //div[contains(@aria-hidden, "false") and contains(@id,"select_container_10")]
${Get_Option}     //*[@id="select_option_12"]
${Post_Option}    //*[@id="select_option_13"]
${Put_Option}     //*[@id="select_option_14"]
${Delete_Option}    //*[@id="select_option_15"]
${Selected_Operation_Xpath}    ${Operation_Select_Input}//span/div[contains(text(), "${Operation_Name}")]
${Request_URL_Input}    //*[@id="request-url"]
${Send_Button}    //*[@id="send-request"]
${Save_Button}    //*[@id="save-request"]
${Parameters_Button}    //*[@id="show-parameters"]
${Form_Radiobutton_Selected}    //md-radio-button[contains(@id, "shown-data-type-form") and contains(@aria-checked, "true")]
${Form_Radiobutton_Unselected}    //md-radio-button[contains(@id, "shown-data-type-form") and contains(@aria-checked, "false")]
${Json_Radiobutton_Selected}    //md-radio-button[contains(@id, "shown-data-type-json") and contains(@aria-checked, "true")]
${Json_Radiobutton_Unselected}    //md-radio-button[contains(@id, "shown-data-type-json") and contains(@aria-checked, "false")]
${Fill_Form_With_Received_Data_Checkbox_Selected}    //span[contains(text(), "Fill form with received data after execution")]//ancestor::md-checkbox[@aria-checked="true"]
${Fill_Form_With_Received_Data_Checkbox_Unselected}    //span[contains(text(), "Fill form with received data after execution")]//ancestor::md-checkbox[@aria-checked="false"]
${Show_Sent_Data_Checkbox_Selected}    //md-checkbox[@id="show-sent-data-checkbox" and @aria-checked="true"]
${Show_Sent_Data_Checkbox_Unselected}    //md-checkbox[@id="show-sent-data-checkbox" and @aria-checked="false"]
${Show_Received_Data_Checkbox_Selected}    //md-checkbox[@id="show-received-data-checkbox" and @aria-checked="true"]
${Show_Received_Data_Checkbox_Unselected}    //md-checkbox[@id="show-received-data-checkbox" and @aria-checked="false"]
${Miliseconds_Label}    ms
${Status_Label}    //span[contains(text(), "Status:")]
${Status_Value}    //span[@id="info-request-status"]
${Time_Label}     //span[contains(text(), "Time:")]
${Time_Value}     //span[@id="info-request-execution-time"]
#Right Panel Json Content
${Sent_Data_Code_Mirror_Displayed}    //div[@id="sentData" and @aria-hidden="false"]
${Sent_Data_Label}    ${Sent_Data_Code_Mirror_Displayed}//h5[contains(text(), Sent data)]
${Sent_Data_Enlarge_Font_Size_Button}    ${Sent_Data_Code_Mirror_Displayed}//button[contains(@aria-label, arrow_drop_up)]
${Sent_Data_Reduce_Font_Size_Button}    ${Sent_Data_Code_Mirror_Displayed}//button[contains(@aria-label, arrow_drop_down)]
${Received_Data_Code_Mirror_Displayed}    //div[@id="ReceiveData" and @aria-hidden="false"]
${Received_Data_Label}    ${Received_Data_Code_Mirror_Displayed}//h5[contains(text(), Received data)]
${Received_Data_Enlarge_Font_Size_Button}    ${Received_Data_Code_Mirror_Displayed}//button[contains(@aria-label, arrow_drop_up)]
${Received_Data_Reduce_Font_Size_Button}    ${Received_Data_Code_Mirror_Displayed}//button[contains(@aria-label, arrow_drop_down)]
# Right Panel Form Content
${Form_Content}    //section[contains(@class, "yangmanModule__right-panel__form bottom-content ng-scope") and contains(@aria-hidden, "false")]
${Form_Top_Element_Container}    ${Form_Content}//div[contains(@class, "yangmanModule__right-panel__form__element-container ng-scope")]
${Form_Top_Element_Pointer}    ${Form_Top_Element_Container}//p[contains(@class, "top-element pointer")]
${Form_Top_Element_Label}    ${Form_Top_Element_Pointer}//span[contains(@class, "ng-binding ng-scope")]
${Form_Top_Element_Yangmenu}    ${Form_Top_Element_Container}//yang-form-menu
${Form_Top_Element_List_Item_Row}    ${Form_Top_Element_Container}//section[@class="yangmanModule__right-panel__form__list__paginator ng-scope layout-column flex"]
${Form_Top_Element_List_Item}    ${Form_Top_Element_List_Item_Row}//md-tab-item[contains(@class, "md-tab ng-scope ng-isolate-scope md-ink-ripple"]
${Form_Top_Element_List_Item_Label}    ${Form_Top_Element_List_Item}/span
