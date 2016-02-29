*** Settings ***
Documentation     A resource file containing all global
...               elements (Variables, keywords) to help
...               Yang UI unit testing.
Library           OperatingSystem
Library           Collections
Library           Process
Library           Common.py
Variables         ../variables/Variables.py
Library           YangUILibrary.py 
Resource          GUIKeywords.robot

*** Variables ***

====================
# Yang UI Submenu
====================
${Yang_UI_Submenu_URL}    ${BASE_URL}#/yangui/index
${API_TAB}        //ul[@class="nav nav-tabs"]/li
${HISTORY_TAB}    //ul[@class="nav nav-tabs"]/li[2]
${COLLECTION_TAB}    //ul[@class="nav nav-tabs"]/li[3]
${PARAMETERS_TAB}    //ul[@class="nav nav-tabs"]/li[4]


===================
# API tab
===================
${ROOT_TEXT}      //span[@class="ng-scope"]
${Expand_all_BUTTON}    //button[@ng-click='expand_collapse_all_items()']
${Collapse_others_BUTTON}    //button[@ng-click='collapse_others()']
${List_NAME}      list
${Minimum_Loaded_Root_APIs_NUMBER}    12

${Tree_Level_1_NUMBER}    1
${Tree_Level_2_NUMBER}    2
${Tree_Level_3_NUMBER}    3
${Tree_Level_4_NUMBER}    4
${Tree_Level_5_NUMBER}    5
${Tree_Level_6_NUMBER}    6

${API_Tree_ROW_1st_Level_XPATH}    //li[contains(@class,"abn-tree-row ng-scope level-${Tree_Level_1_NUMBER}")]
${API_Tree_ROW_2nd_Level_XPATH}    //li[contains(@class,"abn-tree-row ng-scope level-${Tree_Level_2_NUMBER}")]
${API_Tree_ROW_3rd_Level_XPATH}    //li[contains(@class,"abn-tree-row ng-scope level-${Tree_Level_3_NUMBER}")]
${API_Tree_ROW_4th_Level_XPATH}    //li[contains(@class,"abn-tree-row ng-scope level-${Tree_Level_4_NUMBER}")]
${API_Tree_ROW_5th_Level_XPATH}    //li[contains(@class,"abn-tree-row ng-scope level-${Tree_Level_5_NUMBER}")]

${Testing_Root_API_NAME}    network-topology rev.2013-10-21
${Testing_Root_API_XPATH}    ${API_Tree_ROW_1st_Level_XPATH}/a/span[contains(text(),"${Testing_Root_API_NAME}")]
${Testing_Root_API_EXPANDER}    ${Testing_Root_API_XPATH}/preceding-sibling::i[@ng-class="row.tree_icon"]

${Testing_Root_API_Config_NAME}    config
${Testing_Root_API_Config_XPATH}    ${API_Tree_ROW_2nd_Level_XPATH}/a/span[contains(text(),"${Testing_Root_API_Config_NAME}")]
${Testing_Root_API_Config_EXPANDER}    ${Testing_Root_API_Config_XPATH}/preceding-sibling::i[@ng-class="row.tree_icon"]

${Testing_Root_API_Network_Topology_NAME}    network-topology
${Testing_Root_API_Network_Topology_XPATH}    ${API_Tree_ROW_3rd_Level_XPATH}/a/span[contains(text(),"${Testing_Root_API_Network_Topology_NAME}")]
${Testing_Root_API_Network_Topology_Plus_EXPANDER}    ${Testing_Root_API_Network_Topology_XPATH}/preceding-sibling::i[@ng-class="row.tree_icon"]

${Topology_ID}
${Testing_Root_API_Topology_NAME}    topology
${Testing_Root_API_Topology_Id_NAME}    topology-id
${Testing_Root_API_Topology_Topology_Id_NAME}    ${Testing_Root_API_Topology_NAME} {${Testing_Root_API_Topology_Id_NAME}}
${Testing_Root_API_Topology_Topology_Id_XPATH}    ${API_Tree_ROW_4th_Level_XPATH}/a/span[contains(text(),"${Testing_Root_API_Topology_Topology_Id_NAME}")]
${Testing_Root_API_Topology_Topology_Id_Plus_EXPANDER}    ${Testing_Root_API_Topology_Topology_Id_XPATH}/preceding-sibling::i[@ng-class="row.tree_icon"]
${Testing_Root_API_Topology_Types_NAME}    topology-types
${Testing_Root_API_Topology_Types_XPATH}    ${API_Tree_ROW_5th_Level_XPATH}/a/span[contains(text(),"${Testing_Root_API_Topology_Types_NAME}")]
${Testing_Root_API_Topology_Types_Plus_EXPANDER}    ${Testing_Root_API_Topology_Types_XPATH}/preceding-sibling::i[@ng-class="row.tree_icon"]

${Node_ID}
${Testing_Root_API_Node_NAME}    node
${Testing_Root_API_Node_Id_NAME}    node-id
${Testing_Root_API_Node_Node_Id_NAME}    ${Testing_Root_API_Node_NAME} {${Testing_Root_API_Node_Id_NAME}}
${Testing_Root_API_Node_Node_Id_XPATH}    ${API_Tree_ROW_5th_Level_XPATH}/a/span[contains(text(),"${Testing_Root_API_Node_Node_Id_NAME}")]
${Testing_Root_API_Node_Node_Id_Plus_EXPANDER}    ${Testing_Root_API_Node_Node_Id_XPATH}/preceding-sibling::i[@ng-class="row.tree_icon"]

${Link_ID}
${Testing_Root_API_Link_NAME}    link
${Testing_Root_API_Link_Id_NAME}    link-id
${Testing_Root_API_Link_Link_Id_NAME}    ${Testing_Root_API_Link_NAME} {${Testing_Root_API_Link_Id_NAME}}
${Testing_Root_API_Link_Link_Id_XPATH}    ${API_Tree_ROW_5th_Level_XPATH}/a/span[contains(text(),"${Testing_Root_API_Link_Link_Id_NAME}")]
${Testing_Root_API_Link_Link_Id_Plus_EXPANDER}    ${Testing_Root_API_Link_Link_Id_XPATH}/preceding-sibling::i[@ng-class="row.tree_icon"]


### ACTION BUTTONS CONTAINER ###

${Action_Buttons_DIV}    //div[@class="actionButtons"]
${Custom_API_request_BUTTON}    //button[@ng-click='show_add_data_popup()']
${Operation_Select_BOX}    ${Action_Buttons_DIV}/div/select[@ng-model="selectedOperation"]
${Get_OPERATION}    ${Operation_Select_BOX}/option[@label="GET"]
${Put_OPERATION}    ${Operation_Select_BOX}/option[@label="PUT"]
${Post_OPERATION}    ${Operation_Select_BOX}/option[@label="POST"]
${Delete_OPERATION}    ${Operation_Select_BOX}/option[@label="DELETE"]

${Path_Wrapper}    //span[@ng-show="pathElem.hasIdentifier()"]
${Topology_Id_Path_Wrapper_INPUT}    //div[@class="actionButtons"]//span[contains(.,"/${Testing_Root_API_Topology_NAME}")]//input       
${Node_Id_Path_Wrapper_INPUT}    //div[@class="actionButtons"]//span[contains(.,"/${Testing_Root_API_Node_NAME}")]//input
${Link_Id_Path_Wrapper_INPUT}    //div[@class="actionButtons"]//span[contains(.,"/${Testing_Root_API_Link_NAME}")]//input

${Copy_To_Clipboard_BUTTON}    //button[contains(@clip-copy, "copyReqPathToClipboard"]
${Send_BUTTON}    //button[@ng-click="executeOperation(selectedOperation)"]

${Previewed_API}
${Previewed_LIST}
${Show_Preview_BUTTON}    //button[@ng-click="showPreview()"]
${Preview_BOX}    //label[contains(text(), "Preview:")]/parent::div[contains(@class, "topologyContainer previewContainer draggablePopup")]
${Preview_Box_Close_BUTTON}    ${Preview_BOX}/button[contains(@class, "icon-remove close")]
${Preview_Box_Displayed_CONTENT}    ${Preview_BOX}/div/pre
${Preview_Box_Displayed_API}    ${Preview_BOX}/div/pre[contains(text(),"${Previewed_API}")]
${Preview_Box_Displayed_LIST}    ${Preview_BOX}/div/pre[${Previewed_LIST}]        

${CONFIG_TOPO_API}    /restconf/config/network-topology:network-topology
${CONFIG_TOPO_TOPOLOGY_ID_API}    :${RESTCONFPORT}${CONFIG_TOPO_API}/${Testing_Root_API_Topology_NAME}/${Topology_ID}
${CONFIG_TOPO_NODE_ID_API}    :${RESTCONFPORT}${CONFIG_TOPO_API}/${Testing_Root_API_Topology_NAME}/${Topology_ID}/${Testing_Root_API_Node_NAME}/${Node_ID}
${CONFIG_TOPO_LINK_ID_API}    :${RESTCONFPORT}${CONFIG_TOPO_API}/${Testing_Root_API_Topology_NAME}/${Topology_ID}/${Testing_Root_API_Link_NAME}/${Link_ID}    

${Network_Topology_Put_Preview_LIST}    contains(text(), "{}")
${Topology_Put_Preview_LIST}    contains(text(), "${Testing_Root_API_Topology_NAME}") and contains(text(), "${Testing_Root_API_Topology_Id_NAME}") and contains(text(), "${Topology_ID}")
${Node_Put_Preview_LIST}    contains(text(), "${Testing_Root_API_Node_NAME}") and contains(text(), "${Testing_Root_API_Node_Id_NAME}") and contains(text(), "${Node_ID}")
${Link_Put_Preview_LIST}    contains(text(), "${Testing_Root_API_Link_NAME}") and contains(text(), "${Testing_Root_API_Link_Id_NAME}") and contains(text(), "${Link_ID}")

${Custom_API_Request_BOX}    //label[contains(text(), "API path:")]/ancestor::div[contains(@class, "topologyContainer previewContainer dataPopup")]
${Custom_API_Request_Box_Close_BUTTON}    ${Custom_API_Request_BOX}/button[contains(@class, "icon-remove close")]    
${Custom_API_Request_API_Path_INPUT}    //label[contains(text(),"API path:")]/following-sibling::input[contains(@ng-model,"apiToFill")]
${Custom_API_Request_API_Data_INPUT}    ${Custom_API_Request_BOX}/textarea[@ng-model="dataToFill"]
${Custom_API_Request_Push_Config_BUTTON}    ${Custom_API_Request_BOX}/button[2]                


### CUSTOM CONTAINER AREA ###

${Alert_PANEL}    //div[contains(@class,"alert ng-isolate-scope alert-dismissible")]
${Alert_Close_BUTTON}    ${Alert_PANEL}/button[@class="close"]
${Loading_completed_successfully_MSG}    Loading completed successfully
${Loading_completed_successfully_ALERT}    ${Alert_PANEL}/div/b[contains(text(), "${Loading_completed_successfully_MSG}")]
${Request_sent_successfully_MSG}    Request sent successfully
${Request_sent_successfully_ALERT}    ${Alert_PANEL}/div/b[contains(text(), "${Request_sent_successfully_MSG}")]
${Error_sending_request_MSG}          Error sending request
${Data_already_exists_for_path_MSG}   - : Data already exists for path:
${Error_sendin_request_Data_already_exists_ALERT}    ${Alert_PANEL}/div/b[contains(text(), "${Error_sending_request_MSG}")]/following-sibling::b[contains(text(), "${Data_already_exists_for_path_MSG}")]
${Error_parsing_input_missing_keys_MSG}     - : Error parsing input: Input is missing some of the keys of                    
${Error_sending_request_Error_parsing_input_missing_keys_ALERT}    ${Alert_PANEL}/div/b[contains(text(), "${Error_sending_request_MSG}")]/following-sibling::b[contains(text(), "${Error_parsing_input_missing_keys_MSG}")]    
${Input_is_required_MSG}     - : Input is required.
${Error_sending_request_Input_is_required_ALERT}    ${Alert_PANEL}/div/b[contains(text(), "${Error_sending_request_MSG}")]/following-sibling::b[contains(text(), "${Input_is_required_MSG}")]
${Data_missing_Relevant_data_model_etc_MSG}     Data-missing : Request could not be completed because the relevant data model content does not exist.
${Relevant_data_model_content_not_existing_MSG}     - : Request could not be completed because the relevant data model content does not exist 
${Data_missing_Relevant_data_model_not_existing_ALERT}    ${Alert_PANEL}/div/b[contains(text(), "${Data_missing_Relevant_data_model_etc_MSG}")]/following-sibling::b[contains(text(), "${Relevant_data_model_content_not_existing_MSG}")]    
${Missing_key_for_list_MSG}     - : Missing key for list
${Data_missing_Missing_key_for_list_ALERT}    ${Alert_PANEL}/div/b[contains(text(), "${Data_missing_Relevant_data_model_etc_MSG}")]/following-sibling::b[contains(text(), "${Missing_key_for_list_MSG}")]
${Server_error_Server_encountered_unexpected_condition_MSG}    Server Error : The server encountered an unexpected condition which prevented it from fulfilling the request.
${Error_creating_data_MSG}     - : Error creating data 
${Server_error_Error_creating_data_ALERT}    ${Alert_PANEL}/div/b[contains(text(), "${Server_error_Server_encountered_unexpected_condition_MSG}")]/following-sibling::b[contains(text(), "${Error_creating_data_MSG}")]    
${Error_sending_request_Missing_key_for_list_ALERT}    ${Alert_PANEL}/div/b[contains(text(), "${Error_sending_request_MSG}")]/following-sibling::b[contains(text(), "${Missing_key_for_list_MSG}")]

${Default_ID}     [0]
${Arrow_EXPANDER}    button[@ng-click="toggleExpanded()"]
${Question_BUTTON}    button[contains(@class,"iconQuestion")]
${Augment_ICON}    span[contains(@class,"augmentIcon")]
${Plus_BUTTON}    button[@ng-click="addListElem()"]
${List_BUTTON}    div[@class="modalWrapper"]/button[@class="yangButton iconList"]
${Filter_BUTTON}    ng-include[@class="ng-scope"]/button[@ng-click="showListFilterWin()"]
${Delete_BUTTON}    button[@class="yangButton iconClose"]
${Key_ICON}       i[@class="icon-key ng-scope"]

${Testing_Root_API_Network_Topology_BUTTON}    //button[contains(.,'${Testing_Root_API_Network_Topology_NAME}')]
${Testing_Root_API_Network_Topology_Arrow_EXPANDER}    ${Testing_Root_API_Network_Topology_BUTTON}/preceding-sibling::button[@ng-click="toggleExpanded()"]

${Testing_Root_API_Topology_List_NAME}    ${Testing_Root_API_Topology_NAME}
${Testing_Root_API_Topology_List_BUTTON}    //div[@class="topContainerPart"]/button[contains(text(),"${Testing_Root_API_Topology_List_NAME}") and contains(text(),"${List_NAME}")]
${Testing_Root_API_Topology_List_Arrow_EXPANDER}    ${Testing_Root_API_Topology_List_BUTTON}/preceding-sibling::${Arrow_EXPANDER}
${Testing_Root_API_Topology_List_Question_BUTTON}    ${Testing_Root_API_Topology_List_BUTTON}/following::${Question_BUTTON}
${Testing_Root_API_Topology_List_Augment_ICON}    ${Testing_Root_API_Topology_List_BUTTON}/following::${Augment_ICON}
${Testing_Root_API_Topology_List_Plus_BUTTON}    ${Testing_Root_API_Topology_List_BUTTON}/following::${Plus_BUTTON}
${Testing_Root_API_Topology_List_List_BUTTON}    ${Testing_Root_API_Topology_List_BUTTON}/following::${List_BUTTON}
${Testing_Root_API_Topology_List_Filter_BUTTON}    ${Testing_Root_API_Topology_List_BUTTON}/following::${Filter_BUTTON}
${Testing_Root_API_Topology_List_Topology_Id_BUTTON}    //button[contains(text(), "${Testing_Root_API_Topology_List_NAME}") and contains(text(),"${Topology_ID}")]
${Testing_Root_API_Topology_List_Topology_Delete_BUTTON}    ${Testing_Root_API_Topology_List_Topology_Id_BUTTON}/following::${Delete_BUTTON}
${Testing_Root_API_Topology_List_Topology_Id_LABEL}    //div[@class="leaf ng-scope"]/span[contains(text(),"${Testing_Root_API_Topology_Id_NAME}")]
${Testing_Root_API_Topology_List_Topology_Id_Key_ICON}    ${Testing_Root_API_Topology_List_Topology_Id_LABEL}/${Key_ICON}
${Testing_Root_API_Topology_List_Topology_Id_INPUT}    ${Testing_Root_API_Topology_List_Topology_Id_LABEL}/following::input[@type="text"]

${Testing_Root_API_Topology_Types_NAME}    ${Testing_Root_API_Topology_Types_NAME}
${Testing_Root_API_Topology_Types_BUTTON}    //button[contains(.,'${Testing_Root_API_Topology_Types_NAME}')]
${Testing_Root_API_Topology_Types_Arrow_EXPANDER}    ${Testing_Root_API_Topology_Types_BUTTON}/preceding-sibling::${Arrow_EXPANDER}
${Testing_Root_API_Topology_Types_Question_BUTTON}    ${Testing_Root_API_Topology_Types_BUTTON}/following::${Question_BUTTON}
${Testing_Root_API_Topology_Types_Augment_ICON}    ${Testing_Root_API_Topology_Types_BUTTON}/following::${Augment_ICON}

${Testing_Root_API_Underlay-topology_List_NAME}    underlay-topology
${Testing_Root_API_Underlay-topology_List_BUTTON}    //div[@class="topContainerPart"]/button[contains(text(),"${Testing_Root_API_Underlay-topology_List_NAME}") and contains(text(),"${List_NAME}")]
${Testing_Root_API_Underlay-topology_List_Arrow_EXPANDER}    ${Testing_Root_API_Underlay-topology_List_BUTTON}/preceding-sibling::${Arrow_EXPANDER}
${Testing_Root_API_Underlay-topology_List_Question_BUTTON}    ${Testing_Root_API_Underlay-topology_List_BUTTON}/following::${Question_BUTTON}
${Testing_Root_API_Underlay-topology_List_Plus_BUTTON}    ${Testing_Root_API_Underlay-topology_List_BUTTON}/following::${Plus_BUTTON}

${Testing_Root_API_Node_List_NAME}    ${Testing_Root_API_Node_NAME}
${Testing_Root_API_Node_List_BUTTON}    //div[@class="topContainerPart"]/button[contains(text(),"${Testing_Root_API_Node_List_NAME}") and contains(text(),"${List_NAME}")]
${Testing_Root_API_Node_List_Arrow_EXPANDER}    ${Testing_Root_API_Node_List_BUTTON}/preceding-sibling::${Arrow_EXPANDER}
${Testing_Root_API_Node_List_Question_BUTTON}    ${Testing_Root_API_Node_List_BUTTON}/following::${Question_BUTTON}
${Testing_Root_API_Node_List_Augment_ICON}    ${Testing_Root_API_Node_List_BUTTON}/following::${Augment_ICON}
${Testing_Root_API_Node_List_Plus_BUTTON}    ${Testing_Root_API_Node_List_BUTTON}/following::${Plus_BUTTON}
${Testing_Root_API_Node_List_List_BUTTON}    ${Testing_Root_API_Node_List_BUTTON}/following::${List_BUTTON}
${Testing_Root_API_Node_List_Filter_BUTTON}    ${Testing_Root_API_Node_List_BUTTON}/following::${Filter_BUTTON}
${Testing_Root_API_Node_List_Node_Id_BUTTON}    //button[contains(text(), "${Testing_Root_API_Node_List_NAME}") and contains(text(),"${Node_ID}")]
${Testing_Root_API_Node_List_Node_Delete_BUTTON}    ${Testing_Root_API_Node_List_Node_Id_BUTTON}/following::${Delete_BUTTON}
${Testing_Root_API_Node_List_Node_Id_LABEL}    //div[@class="leaf ng-scope"]/span[contains(text(),"${Testing_Root_API_Node_Id_NAME}")]
${Testing_Root_API_Node_List_Node_Id_Key_ICON}    ${Testing_Root_API_Node_List_Node_Id_LABEL}/${Key_ICON}
${Testing_Root_API_Node_List_Node_Id_INPUT}    ${Testing_Root_API_Node_List_Node_Id_LABEL}/following::input[@type="text"]

${Testing_Root_API_Termination-point_List_NAME}    termination-point
${Testing_Root_API_Termination-point_List_BUTTON}    //div[@class="topContainerPart"]/button[contains(text(),"${Testing_Root_API_Termination-point_List_NAME}") and contains(text(),"${List_NAME}")]
${Testing_Root_API_Termination-point_List_Arrow_EXPANDER}    ${Testing_Root_API_Termination-point_List_BUTTON}/preceding-sibling::${Arrow_EXPANDER}
${Testing_Root_API_Termination-point_List_Question_BUTTON}    ${Testing_Root_API_Termination-point_List_BUTTON}/following::${Question_BUTTON}
${Testing_Root_API_Termination-point_List_Augment_ICON}    ${Testing_Root_API_Termination-point_List_BUTTON}/following::${Augment_ICON}
${Testing_Root_API_Termination-point_List_Plus_BUTTON}    ${Testing_Root_API_Termination-point_List_BUTTON}/following::${Plus_BUTTON}

${Testing_Root_API_Supporting-node_List_NAME}    supporting-node
${Testing_Root_API_Supporting-node_List_BUTTON}    //div[@class="topContainerPart"]/button[contains(text(),"${Testing_Root_API_Supporting-node_List_NAME}") and contains(text(),"${List_NAME}")]
${Testing_Root_API_Supporting-node_List_Arrow_EXPANDER}    ${Testing_Root_API_Supporting-node_List_BUTTON}/preceding-sibling::${Arrow_EXPANDER}
${Testing_Root_API_Supporting-node_List_Question_BUTTON}    ${Testing_Root_API_Supporting-node_List_BUTTON}/following::${Question_BUTTON}
${Testing_Root_API_Supporting-node_Plus_BUTTON}    ${Testing_Root_API_Supporting-node_List_BUTTON}/following::${Plus_BUTTON}

${Testing_Root_API_Link_List_NAME}    link
${Testing_Root_API_Link_List_BUTTON}    //div[@class="topContainerPart"]/button[contains(text(),"${Testing_Root_API_Link_List_NAME}") and contains(text(),"${List_NAME}")]
${Testing_Root_API_Link_List_Arrow_EXPANDER}    ${Testing_Root_API_Link_List_BUTTON}/preceding-sibling::${Arrow_EXPANDER}
${Testing_Root_API_Link_List_Question_BUTTON}    ${Testing_Root_API_Link_List_BUTTON}/following::${Question_BUTTON}
${Testing_Root_API_Link_List_Augment_ICON}    ${Testing_Root_API_Link_List_BUTTON}/following::${Augment_ICON}
${Testing_Root_API_Link_List_Plus_BUTTON}    ${Testing_Root_API_Link_List_BUTTON}/following::${Plus_BUTTON}
${Testing_Root_API_Link_List_List_BUTTON}    ${Testing_Root_API_Link_List_BUTTON}/following::${List_BUTTON}
${Testing_Root_API_Link_List_Filter_BUTTON}    ${Testing_Root_API_Link_List_BUTTON}/following::${Filter_BUTTON}
${Testing_Root_API_Link_List_Link_Id_BUTTON}    //button[contains(text(), "${Testing_Root_API_Link_List_NAME}") and contains(text(),"${Link_ID}")]
${Testing_Root_API_Link_List_Link_Delete_BUTTON}    ${Testing_Root_API_Link_List_Link_Id_BUTTON}/following::${Delete_BUTTON}
${Testing_Root_API_Link_List_Link_Id_LABEL}    //div[@class="leaf ng-scope"]/span[contains(text(),"${Testing_Root_API_Link_Id_NAME}")]
${Testing_Root_API_Link_List_Link_Id_Key_ICON}    ${Testing_Root_API_Link_List_Link_Id_LABEL}/${Key_ICON}
${Testing_Root_API_Link_List_Link_Id_INPUT}    ${Testing_Root_API_Link_List_Link_Id_LABEL}/following::input[@type="text"]

${Testing_Root_API_Source_NAME}    source
${Testing_Root_API_Source_BUTTON}    //div[@class="topContainerPart"]/button[contains(text(),"${Testing_Root_API_Source_NAME}")]
${Testing_Root_API_Source_Arrow_EXPANDER}    ${Testing_Root_API_Source_BUTTON}/preceding-sibling::${Arrow_EXPANDER}

${Testing_Root_API_Destination_NAME}    destination
${Testing_Root_API_Destination_BUTTON}    //div[@class="topContainerPart"]/button[contains(text(),"${Testing_Root_API_Destination_NAME}")]
${Testing_Root_API_Destination_Arrow_EXPANDER}    ${Testing_Root_API_Destination_BUTTON}/preceding-sibling::${Arrow_EXPANDER}
${Testing_Root_API_Supporting-link_List_NAME}    supporting-link
${Testing_Root_API_Supporting-link_List_BUTTON}    //div[@class="topContainerPart"]/button[contains(text(),"${Testing_Root_API_Supporting-link_List_NAME}") and contains(text(),"${List_NAME}")]
${Testing_Root_API_Supporting-link_List_Arrow_EXPANDER}    ${Testing_Root_API_Supporting-link_List_BUTTON}/preceding-sibling::${Arrow_EXPANDER}
${Testing_Root_API_Supporting-link_Plus_BUTTON}    ${Testing_Root_API_Supporting-link_List_BUTTON}/following::${Plus_BUTTON}

===================
# PARAMETERS tab
===================

${Parameters_TABLE}    //div[@class="table dataTable reqParams"]
${Parameters_Table_Name_Header_TEXT}    NAME
${Parameters_Table_Name_HEADER}    ${Parameters_TABLE}/div[@class="thdiv"]/div[text()="${Parameters_Table_Name_Header_TEXT}"]
${Parameters_Table_Value_Header_TEXT}    VALUE
${Parameters_Table_Value_HEADER}    ${Parameters_TABLE}/div[@class="thdiv"]/div[text()="${Parameters_Table_Value_Header_TEXT}"]
${Parameters_Table_Action_Header_TEXT}    ACTION
${Parameters_Table_Action_HEADER}    ${Parameters_TABLE}/div[@class="thdiv"]/div[text()="${Parameters_Table_Action_Header_TEXT}"]

${Add_New_Parameter_BUTTON}    //button[contains(text(), "Add new parameter")]
${Add_New_Parameter_Showed_BOX}    //div[@class= "paramBox popupContainer draggablePopup ng-scope ui-draggable ui-draggable-handle"]
${Add_New_Parameter_Hidden_BOX}    //div[@class= "paramBox popupContainer draggablePopup ng-scope ui-draggable ui-draggable-handle ng-hide"]
${Add_New_Parameter_Box_Close_BUTTON}    ${Add_New_Parameter_Showed_BOX}/button[contains(@class, "icon-remove close")]
${Add_New_Parameter_FORM}    ${Add_New_Parameter_Showed_BOX}/form[@name="paramForm"]
${Add_New_Parameter_Form_Name_TEXT}    Name    
${Add_New_Parameter_Form_Name_LABEL}    ${Add_New_Parameter_FORM}/label[contains(text(), "${Add_New_Parameter_Form_Name_TEXT}")]
${Add_New_Parameter_Form_Name_INPUT}    ${Add_New_Parameter_Form_Name_LABEL}/following-sibling::input[@ng-model="paramObj.name"]
${Add_New_Parameter_Form_Value_TEXT}    Value    
${Add_New_Parameter_Form_Value_LABEL}    ${Add_New_Parameter_FORM}/label[contains(text(), "${Add_New_Parameter_Form_Value_TEXT}")]
${Add_New_Parameter_Form_Value_INPUT}    ${Add_New_Parameter_Form_Value_LABEL}/following-sibling::input[@ng-model="paramObj.value"]
${Add_New_Parameter_Form_Save_BUTTON}    ${Add_New_Parameter_FORM}/button[@ng-click="saveParam()"]   
            
${Parameter_Name}
${Parameter_Value}
${Parameter_List_ROW}    //div[contains(@class, "trdiv ng-scope")]    
${Parameter_List_Parameter_Name_XPATH}    ${Parameter_List_ROW}//span[text()="<<${Parameter_Name}>>"]
${Parameter_List_Parameter_Value_XPATH}    ${Parameter_List_Parameter_Name_XPATH}/following::div[@class="tddiv rh-col3"]/span[text()="${Parameter_Value}"]
${Parameter_LIST_Edit_BUTTON}    ${Parameter_List_Parameter_Name_XPATH}/following::button[@class="yangButton iconEdit"]    
${Parameter_LIST_Delete_BUTTON}    ${Parameter_List_Parameter_Name_XPATH}/following::button[@class="yangButton iconClose"]            

${Clear_Parameters_BUTTON}    //button[contains(text(), "Clear parameters")]
${Import_Parameters_SECTION}    //span[contains(text(), "Import parameters")]
${Import_Parameters_INPUT}    //input[@id="upload-parameters"]
${Export_Parameters_BUTTON}    //button[contains(text(), "Export parameters")]

===================
# HISTORY tab
===================
${History_TABLE}    //div[@class="table dataTable reqHistory"]
${History_Table_Method_Header_TEXT}    Method
${History_Table_Method_HEADER}     ${History_TABLE}/div[@class="thdiv"]/div[text()="${Parameters_Table_Name_Header_TEXT}"]
${History_Table_Url_Header_TEXT}    URL
${History_Table_Url_HEADER}     ${History_TABLE}/div[@class="thdiv"]/div[text()="${History_Table_Url_Header_TEXT}"]
${History_Table_Status_Header_TEXT}     STATUS
${History_Table_Status_HEADER}    ${History_TABLE}/div[@class="thdiv"]/div[text()="${History_Table_Status_Header_TEXT}"]
${History_Table_Action_Header_TEXT}     ACTION
${History_Table_Action_HEADER}    ${History_TABLE}/div[@class="thdiv"]/div[text()="${History_Table_Action_Header_TEXT}"]     

${Method_Name}
${Row_NUMBER}
${Get_Method_NAME}    GET
${Put_Method_NAME}    PUT
${Post_Method_NAME}    POST    
${Remove_Method_NAME}    REMOVE
${Success_STATUS}    success
${Error_STATUS}    error
${History_Table_List_ROW}    //div[@ng-repeat="req in requestList.list track by $index"][${Row_NUMBER}]
${History_Table_List_Row_ENUM}    //div[@class="scroll"]/div[@ng-repeat="req in requestList.list track by $index"]
${History_Table_Row_Method_XPATH}     ${History_Table_List_ROW}//div[@class="tddiv rh-col2"]/span
${History_Table_Row_Method_Name_XPATH}    ${History_Table_List_ROW}//div[@class="tddiv rh-col2"]/span[text()="${Method_Name}"]
${History_Table_Row_Url_XPATH}    ${History_Table_List_ROW}//div[@class="tddiv rh-col3"]/span
${History_Table_Row_Status_XPATH}     ${History_Table_List_ROW}//div[@class="tddiv rh-col4"]/span                  
${History_Table_Row_Sent_Data_Disabled_BUTTON}    ${History_Table_List_ROW}//div[@class="tddiv rh-col5"]//button[@class="btn btn-primary ng-scope btn-slim disabled"]
${History_Table_Row_Sent_Data_Enabled_BUTTON}     ${History_Table_List_ROW}//div[@class="tddiv rh-col5"]//button[@class="btn btn-primary ng-scope btn-slim "]
${History_Table_Row_Received_Data_Disabled_BUTTON}    ${History_Table_List_ROW}//div[@class="tddiv rh-col6"]//button[@class="btn btn-primary ng-scope btn-slim disabled"]
${History_Table_Row_Received_Data_Enabled_BUTTON}     ${History_Table_List_ROW}//div[@class="tddiv rh-col6"]//button[@class="btn btn-primary ng-scope btn-slim "]
${History_Table_Row_Execute_Request_BUTTON}    ${History_Table_List_ROW}//div[@class="tddiv rh-col7"]//button[@ng-click="executeRequest()"]
${History_Table_Row_Add_To_Collection_BUTTON}    ${History_Table_List_ROW}//div[@class="tddiv rh-col7"]//div[@ng-click="showCollBox(req)"]
${History_Table_Row_Fill_Data_Disabled_BUTTON}    ${History_Table_List_ROW}//div[@class="tddiv rh-col7"]//button[@class="yangButton iconFillData disabled"]
${History_Table_Row_Fill_Data_Enabled_BUTTON}     ${History_Table_List_ROW}//div[@class="tddiv rh-col7"]//button[@class="yangButton iconFillData "]
${History_Table_Row_Delete_BUTTON}             ${History_Table_List_ROW}//div[@class="tddiv rh-col7"]//button[@class="yangButton iconClose"]

${History_Table_Sent_Data_BOX}    ${History_TABLE}//div[@ng-show="showData" and @class="trdiv pre-div ng-scope"]
${History_Table_Sent_Data_Box_Path_WRAPPER}     ${History_Table_Sent_Data_BOX}//div[@class="pathWrapper"]
${History_Table_Sent_Data_Box_Topology_Id_Path_Wrapper_INPUT}    ${History_Table_Sent_Data_Box_Path_WRAPPER}//span[contains(.,"/${Testing_Root_API_Topology_NAME}")]//input
${History_Table_Sent_Data_Box_Node_Id_Path_Wrapper_INPUT}    ${History_Table_Sent_Data_Box_Path_WRAPPER}//span[contains(.,"/${Testing_Root_API_Node_NAME}")]//input
${History_Table_Sent_Data_Box_Link_Id_Path_Wrapper_INPUT}    ${History_Table_Sent_Data_Box_Path_WRAPPER}//span[contains(.,"/${Testing_Root_API_Link_NAME}")]//input
${History_Table_Sent_Data_Box_Copy_To_Clipboard_BUTTON}    ${History_Table_Sent_Data_BOX}//button[contains(@clip-copy, "copyReqPathToClipboard")]
${History_Table_Sent_Data_Box_Reset_Parametrized_Data_BUTTON}    ${History_Table_Sent_Data_BOX}//button[@ng-click="clearParametrizedData()"]
${History_Table_Sent_Data_Box_Save_Parametrized_Data_BUTTON}    ${History_Table_Sent_Data_BOX}//button[contains(@ng-click, "saveParametrizedData")]
${History_Table_Sent_Data_Box_Close_BUTTON}    ${History_Table_Sent_Data_BOX}//button[contains(@class, "yangButton icon-remove")]
        


${Clear_History_Data_BUTTON}     //button[contains(text(), "Clear history data")]
    

*** Keywords ***
Load Network-topology Button In CustomContainer Area
    [Documentation]    Contains steps to navigate from loaded API tree to loaded
    ...    network-topology button in custom Container Area.  
    Click Element    ${Testing_Root_API_EXPANDER}
    Wait Until Page Contains Element    ${Testing_Root_API_Config_EXPANDER}
    Click Element    ${Testing_Root_API_Config_EXPANDER}
    Wait Until Page Contains Element    ${Testing_Root_API_Network_Topology_Plus_EXPANDER}
    Click Element    ${Testing_Root_API_Network_Topology_XPATH}
    Wait Until Page Contains Element    ${Testing_Root_API_Network_Topology_BUTTON}
    Page Should Contain Button    ${Testing_Root_API_Network_Topology_Arrow_EXPANDER}
   
    
Load Topology List Button In CustomContainer Area
    [Documentation]    Contains steps to navigate from loaded network-topology in API to loaded
    ...    topology list button in custom Container Area.  
    Page Should Contain Element    ${Testing_Root_API_Network_Topology_Plus_EXPANDER}    
    Click Element    ${Testing_Root_API_Network_Topology_Plus_EXPANDER}
    Wait Until Page Contains Element    ${Testing_Root_API_Topology_Topology_Id_Plus_EXPANDER}
    Click Element    ${Testing_Root_API_Topology_Topology_Id_XPATH}
    Wait Until Page Contains Element    ${Testing_Root_API_Topology_List_BUTTON}
    Page Should Contain Button    ${Testing_Root_API_Topology_List_Arrow_EXPANDER}
    Page Should Contain Button    ${Testing_Root_API_Topology_List_Plus_BUTTON}


Load Node List Button In CustomContainer Area
    [Documentation]    Contains steps to navigate from loaded topology {topology-id} 
    ...    in API to loaded node list button in custom Container Area.  
    Page Should Contain Element    ${Testing_Root_API_Topology_Topology_Id_Plus_EXPANDER}    
    Click Element    ${Testing_Root_API_Topology_Topology_Id_Plus_EXPANDER}
    Wait Until Page Contains Element    ${Testing_Root_API_Node_Node_Id_XPATH}
    Click Element    ${Testing_Root_API_Node_Node_Id_XPATH}
    Wait Until Page Contains Element    ${Testing_Root_API_Node_List_BUTTON}
    Page Should Contain Button    ${Testing_Root_API_Node_List_Arrow_EXPANDER}
    Page Should Contain Button    ${Testing_Root_API_Node_List_Plus_BUTTON}


Insert Text To Input Field
    [Arguments]    ${input_field}    ${text}
    [Documentation]    Will erase data from chosen input field and insert chosen data.
    Focus    ${input_field}
    Clear Element Text    ${input_field}    
    Press Key    ${input_field}    ${text}
    

PUT ID
    [Arguments]    ${input_field}    ${text}    ${Topology/Node/Link_ID}    ${topology/node/link_list_name}
    [Documentation]    Will insert topology, node or link id and execute PUT operation on it.
    ...    ${text} is id to be input; ${input_field} is locator of an INPUT field;
    ...    ${Topology/Node/Link_ID} has values of ${Topology_ID}, or ${Node_ID}, or ${Link_ID};
    ...    ${topology/node/link_list_name} is ${...Topology/Node/Link_List_NAME}.
    Insert Text To Input Field    ${input_field}    ${text}    
    Sleep    1
    Execute Chosen Operation    ${Put_OPERATION}    ${Request_sent_successfully_ALERT}    
    Verify Chosen_Id Presence On The Page    ${text}    ${Topology/Node/Link_ID}    ${topology/node/link_list_name}    

POST ID
    [Arguments]    ${input_field}    ${text}    ${Topology/Node/Link_ID}    ${topology/node/link_list_name}
    [Documentation]    Will insert topology, node or link id and execute POST operation on it.
    ...    ${text} is id to be input; ${input_field} is locator of an INPUT field;
    ...    ${Topology/Node/Link_ID} has values of ${Topology_ID}, or ${Node_ID}, or ${Link_ID};
    ...    ${topology/node/link_list_name} is ${...Topology/Node/Link_List_NAME}.
    Insert Text To Input Field    ${input_field}    ${text}
    Sleep    1
    Execute Chosen Operation    ${Post_OPERATION}    ${Request_sent_successfully_ALERT}    
    Verify Chosen_Id Presence On The Page    ${text}    ${Topology/Node/Link_ID}    ${topology/node/link_list_name}   

Select Chosen Operation
    [Arguments]    ${Chosen_Operation}    
    [Documentation]    Will select desired operation from operation selectbox.
    Click Element    ${Operation_Select_BOX}
    Wait Until Page Contains Element    ${Chosen_Operation}
    Click Element    ${Chosen_Operation}
    Click Element    ${Action_Buttons_DIV}


Execute Chosen Operation
    [Arguments]    ${Chosen_Operation}    ${Alert_Expected}
    [Documentation]    Will click desired operation and hit Send button to execute it
    ...    and check the alert message.
    Select Chosen Operation    ${Chosen_Operation}    
    Focus    ${Send_BUTTON}
    Click Element    ${Send_BUTTON}
    Wait Until Page Contains Element    ${Alert_Expected}
    Click Element    ${Alert_Close_BUTTON}
    Sleep    1
    
    
Verify Chosen_Id Presence On The Page
    [Arguments]    ${Chosen_Id}    ${Topology/Node/Link_ID}    ${topology/node/link_list_name}
    [Documentation]    This keyword verifies, that the page CONTAINS topology/ node/ link with
    ...    given id in customContainer Area.
    ...    ${Chosen_Id} is id to be input; ${Topology/Node/Link_ID} has values of ${Topology_ID},
    ...    or ${Node_ID}, or ${Link_ID};
    ...    ${topology/node/link_list_name} is ${...Topology/Node/Link_List_NAME}.
    ${Topology/Node/Link_ID}=    Set Variable    ${Chosen_Id}    
    Page Should Contain Element    //button[contains(text(), "${topology/node/link_list_name}") and contains(text(),"${Topology/Node/Link_ID}")]
    ${id_button}=    Set Variable    //button[contains(text(), "${topology/node/link_list_name}") and contains(text(),"${Topology/Node/Link_ID}")]
    Page Should Contain Element    ${id_button}/following::${Delete_BUTTON}

Verify Chosen_Id NON-Presence On The Page
    [Arguments]    ${Chosen_Id}    ${Topology/Node/Link_ID}    ${topology/node/link_list_name}
    [Documentation]    This keyword verifies, that the page DOES NOT CONTAIN topology/ node/ link with
    ...    given id in customContainer Area.
    ...    ${Chosen_Id} is id to be input; ${Topology/Node/Link_ID} has values of ${Topology_ID},
    ...    or ${Node_ID}, or ${Link_ID};
    ...    ${topology/node/link_list_name} is ${...Topology/Node/Link_List_NAME}.
    ${Topology/Node/Link_ID}=    Set Variable    ${Chosen_Id}    
    Page Should Not Contain Element    //button[contains(text(), "${topology/node/link_list_name}") and contains(text(),"${Topology/Node/Link_ID}")]
    ${id_button}=    Set Variable    //button[contains(text(), "${topology/node/link_list_name}") and contains(text(),"${Topology/Node/Link_ID}")]
    Page Should Not Contain Element    ${id_button}/following::${Delete_BUTTON}

Delete All Existing Topologies
    [Documentation]    This keyword deletes all existing topologies.
    Click Element    ${Testing_Root_API_Network_Topology_XPATH}
    Wait Until Page Contains Element    ${Testing_Root_API_Network_Topology_BUTTON}
    Click Element    ${Operation_Select_BOX}
    Wait Until Page Contains Element    ${Delete_OPERATION}
    Click Element    ${Delete_OPERATION}
    Click Element    ${Send_BUTTON}
    Wait Until Page Contains Element    ${Request_sent_successfully_ALERT}

Add New Parameter
    [Arguments]    ${Chosen_Name}    ${Chosen_Value}    ${Verification_Function}
    [Documentation]    This keyword inputs new parameter into parameters table. 
    ...    ${Chosen_Name} has a value of chosen parameter name, 
    ...    ${Chosen_Value} has a value of chosen parameter name,
    ...    ${Verification_Function} is either Verify Visibility of NONVisibility.
    Click Element    ${Add_New_Parameter_BUTTON}
    Wait Until Page Contains Element    ${Add_New_Parameter_Showed_BOX}
    Input Text    ${Add_New_Parameter_Form_Name_INPUT}    ${Chosen_Name}
    Input Text    ${Add_New_Parameter_Form_Value_INPUT}    ${Chosen_Value}
    Click Element    ${Add_New_Parameter_Form_Save_BUTTON}
    Sleep    1
    Run Keyword    ${Verification_Function}
    ${status}=    Run Keyword And Return Status    Page Should Contain Element    ${Add_New_Parameter_Showed_BOX}    
    Run Keyword If    "${status}"=="True"    Click Element    ${Add_New_Parameter_Box_Close_BUTTON}                   
    
Verify Add_New_Parameter_Box Visibility
    [Documentation]    This keyword verifies that Add_new_parameter Box is still open.
    Page Should Contain Element    ${Add_New_Parameter_Showed_BOX}

Verify Add_New_Parameter_Box NONVisibility    
    [Documentation]    This keyword verifies that Add_new_parameter Box is not open anymore.
    Page Should Contain Element    ${Add_New_Parameter_Hidden_BOX}
    
Verify Added Parameter Presence On The Page
    [Arguments]    ${Chosen_Name}    ${Chosen_Value}    
    [Documentation]    This keyword verifies that the page contains Chosen Parameter Name,
    ...    chosen Parameter value, Edit and Delete button.
    ${Parameter_Name}=    Set Variable    ${Chosen_Name}    
    ${Parameter_Value}=    Set Variable    ${Chosen_Value}
    ${Parameter_List_Parameter_Name_XPATH}=    Set Variable    ${Parameter_List_ROW}//span[text()="<<${Parameter_Name}>>"]        
    Page Should Contain Element    ${Parameter_List_Parameter_Name_XPATH}
    ${Parameter_List_Parameter_Value_XPATH}=    Set Variable    ${Parameter_List_Parameter_Name_XPATH}/following::div[@class="tddiv rh-col3"]/span[text()="${Parameter_Value}"]
    Page Should Contain Element    ${Parameter_List_Parameter_Value_XPATH}
    ${Parameter_LIST_Edit_BUTTON}=    Set Variable    ${Parameter_List_Parameter_Name_XPATH}/following::button[@class="yangButton iconEdit"]
    Page Should Contain Element    ${Parameter_LIST_Edit_BUTTON}    
    ${Parameter_LIST_Delete_BUTTON}=    Set Variable    ${Parameter_List_Parameter_Name_XPATH}/following::button[@class="yangButton iconClose"]
    Page Should Contain Element    ${Parameter_LIST_Delete_BUTTON}

Verify Deleted Parameter NONPresence On The Page
    [Arguments]    ${Chosen_Name}    ${Chosen_Value}    
    [Documentation]    This keyword verifies that the page does not contain Chosen Parameter Name,
    ...    chosen Parameter value, Edit and Delete button.
    ${Parameter_Name}=    Set Variable    ${Chosen_Name}    
    ${Parameter_Value}=    Set Variable    ${Chosen_Value}
    ${Parameter_List_Parameter_Name_XPATH}=    Set Variable    ${Parameter_List_ROW}//span[text()="<<${Parameter_Name}>>"]        
    Page Should Not Contain Element    ${Parameter_List_Parameter_Name_XPATH}
    ${Parameter_List_Parameter_Value_XPATH}=    Set Variable    ${Parameter_List_Parameter_Name_XPATH}/following::div[@class="tddiv rh-col3"]/span[text()="${Parameter_Value}"]
    Page Should Not Contain Element    ${Parameter_List_Parameter_Value_XPATH}
    ${Parameter_LIST_Edit_BUTTON}=    Set Variable    ${Parameter_List_Parameter_Name_XPATH}/following::button[@class="yangButton iconEdit"]
    Page Should Not Contain Element    ${Parameter_LIST_Edit_BUTTON}    
    ${Parameter_LIST_Delete_BUTTON}=    Set Variable    ${Parameter_List_Parameter_Name_XPATH}/following::button[@class="yangButton iconClose"]
    Page Should Not Contain Element    ${Parameter_LIST_Delete_BUTTON}


Verify History Table Row Content
    [Arguments]    ${Row_NUMBER}    ${Method_NAME}    ${Request_Status}        
    [Documentation]    This keyword verifies the occurence elements in History tab.
    ${History_Table_List_ROW}=    Set Variable    //div[@ng-repeat="req in requestList.list track by $index"][${Row_NUMBER}]
    
    ${History_Table_Row_Method_Name_XPATH}=    Set Variable    ${History_Table_List_ROW}//div[@class="tddiv rh-col2"]/span[text()="${Method_Name}"]
    Page Should Contain Element     ${History_Table_Row_Method_Name_XPATH}
    
    Click Element     ${Show_Preview_BUTTON}
    ${previewed_content}=    Get Text    ${Preview_Box_Displayed_CONTENT}
    ${api_path}=    Fetch From Left    ${previewed_content}    {
    ${url1}=    Remove Leading And Trailing Spaces    ${api_path}
    Click Element    ${Preview_Box_Close_BUTTON}    
    ${History_Table_Row_Url_XPATH}=    Set Variable    ${History_Table_List_ROW}//div[@class="tddiv rh-col3"]/span
    ${Url}=    Get Text    ${History_Table_Row_Url_XPATH}
    ${url2}=    Remove Leading And Trailing Spaces    ${Url}
    Should Be Equal As Strings    ${url1}    ${url2}
    
    ${History_Table_Row_Status_XPATH}=    Set Variable    ${History_Table_List_ROW}//div[@class="tddiv rh-col4"]/span
    ${status}=    Get Text    ${History_Table_Row_Status_XPATH}
    Should Be Equal As Strings    ${status}    ${Request_Status}

    
Verify Element Presence In History Table Row
    [Arguments]    ${Element}     ${Element_Xpath}     
    [Documentation]    This keyword sets D/E button variable and verifies its presence on the page.
    #${History_Table_List_ROW}=    Set Variable    //div[@ng-repeat="req in requestList.list track by $index"][${Row_NUMBER}]
    ${Element} =    Set Variable    ${Element_Xpath}
    Page Should Contain Element     ${Element}
    Sleep    1                


Verify Error Status Elements Presence In History Table Row
    [Documentation]    This keyword verifies the presence of elements in History table associated with unsuccessfully executed operation.
    ${dict}=    Create Dictionary    ${History_Table_Row_Sent_Data_Disabled_BUTTON}=${History_Table_List_ROW}//div[@class="tddiv rh-col5"]//button[@class="btn btn-primary ng-scope btn-slim disabled"]
    ...    ${History_Table_Row_Received_Data_Disabled_BUTTON}=${History_Table_List_ROW}//div[@class="tddiv rh-col6"]//button[@class="btn btn-primary ng-scope btn-slim disabled"]
    ...    ${History_Table_Row_Execute_Request_BUTTON}=${History_Table_List_ROW}//div[@class="tddiv rh-col7"]//button[@ng-click="executeRequest()"]
    ...    ${History_Table_Row_Add_To_Collection_BUTTON}=${History_Table_List_ROW}//div[@class="tddiv rh-col7"]//div[@ng-click="showCollBox(req)"]
    ...    ${History_Table_Row_Fill_Data_Disabled_BUTTON}=${History_Table_List_ROW}//div[@class="tddiv rh-col7"]//button[@class="yangButton iconFillData disabled"]
    ...    ${History_Table_Row_Delete_BUTTON}=${History_Table_List_ROW}//div[@class="tddiv rh-col7"]//button[@class="yangButton iconClose"]
    @{keys}=    Get Dictionary Keys    ${dict}
    : FOR    ${key}    IN    @{keys}
    \    ${value}=    Get From Dictionary    ${dict}    ${key}
    \    Run Keyword    Verify Element Presence In History Table Row    ${key}    ${value}


Verify Success Sent Data Elements Presence In History Table Row
    [Documentation]    This keyword verifies the presence of elements in History table associated with succesfully executed Put/ Post operation.
    ${dict}=    Create Dictionary    ${History_Table_Row_Sent_Data_Enabled_BUTTON}=${History_Table_List_ROW}//div[@class="tddiv rh-col5"]//button[@class="btn btn-primary ng-scope btn-slim "]
    ...    ${History_Table_Row_Received_Data_Disabled_BUTTON}=${History_Table_List_ROW}//div[@class="tddiv rh-col6"]//button[@class="btn btn-primary ng-scope btn-slim disabled"]
    ...    ${History_Table_Row_Execute_Request_BUTTON}=${History_Table_List_ROW}//div[@class="tddiv rh-col7"]//button[@ng-click="executeRequest()"]
    ...    ${History_Table_Row_Add_To_Collection_BUTTON}=${History_Table_List_ROW}//div[@class="tddiv rh-col7"]//div[@ng-click="showCollBox(req)"]
    ...    ${History_Table_Row_Fill_Data_Enabled_BUTTON}=${History_Table_List_ROW}//div[@class="tddiv rh-col7"]//button[@class="yangButton iconFillData "]
    ...    ${History_Table_Row_Delete_BUTTON}=${History_Table_List_ROW}//div[@class="tddiv rh-col7"]//button[@class="yangButton iconClose"]
    @{keys}=    Get Dictionary Keys    ${dict}
    : FOR    ${key}    IN    @{keys}
    \    ${value}=    Get From Dictionary    ${dict}    ${key}
    \    Run Keyword    Verify Element Presence In History Table Row    ${key}    ${value}
    
    
Verify History Sent Data Box Elements
    [Documentation]    This keyword verifies the presence of elements of History tab Sent data box.
    Click Element    ${History_Table_Row_Sent_Data_Enabled_BUTTON}    
    Wait Until Page Contains Element    ${History_Table_Sent_Data_BOX}
    ${status}=    Run Keyword And Return Status    Page Should Contain Element    ${History_Table_Sent_Data_Box_Path_WRAPPER}//span[contains(text(),"/${Testing_Root_API_Topology_NAME}")]
    Run Keyword If    "${status}"=="True"    Page Should Contain Element    ${History_Table_Sent_Data_Box_Topology_Id_Path_Wrapper_INPUT}
    ${status}=    Run Keyword And Return Status    Page Should Contain Element    ${History_Table_Sent_Data_Box_Path_WRAPPER}//span[contains(text(),"/${Testing_Root_API_Node_NAME}")]
    Run Keyword If    "${status}"=="True"    Page Should Contain Element    ${History_Table_Sent_Data_Box_Node_Id_Path_Wrapper_INPUT}        
    ${status}=    Run Keyword And Return Status    Page Should Contain Element    ${History_Table_Sent_Data_Box_Path_WRAPPER}//span[contains(text(),"/${Testing_Root_API_Link_NAME}")]
    Run Keyword If    "${status}"=="True"    Page Should Contain Element    ${History_Table_Sent_Data_Box_Link_Id_Path_Wrapper_INPUT}
    Page Should Contain Element    ${History_Table_Sent_Data_Box_Copy_To_Clipboard_BUTTON}
    Page Should Contain Element    ${History_Table_Sent_Data_Box_Reset_Parametrized_Data_BUTTON}
    Page Should Contain Element    ${History_Table_Sent_Data_Box_Save_Parametrized_Data_BUTTON}
    Page Should Contain Element    ${History_Table_Sent_Data_Box_Close_BUTTON}
   
    
Close History Sent Data Box And Clear History Data
    Click Element    ${History_Table_Sent_Data_Box_Close_BUTTON}
    Wait Until Page Does Not Contain Element    ${History_Table_Sent_Data_BOX}
    Click Element    ${Clear_History_Data_BUTTON}
    Page Should Not Contain Element    ${History_Table_List_ROW} 
    
  
    
 
    
         
                           
           
    
    
    
                                
     
         





