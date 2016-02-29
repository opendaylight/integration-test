*** Settings ***
Documentation     A resource file containing all global
...               elements (Variables, keywords) to help
...               Yang UI module testing.
Library           OperatingSystem
Library           Collections
Library           Process
Library           Common.py
Library           Screenshot
Library           YangUILibrary.py
Library           HttpLibrary.HTTP           
Variables         ../variables/Variables.py
Resource          GUIKeywords.robot
Resource          ../variables/dlux/YangUITestData.robot

*** Variables ***
# Yang UI Submenu

${Yang_UI_Submenu_URL}    ${BASE_URL}#/yangui/index
${API_TAB}        //ul[@class="nav nav-tabs"]/li
${HISTORY_TAB}    //ul[@class="nav nav-tabs"]/li[2]
${COLLECTION_TAB}    //ul[@class="nav nav-tabs"]/li[3]
${PARAMETERS_TAB}    //ul[@class="nav nav-tabs"]/li[4]

# API tab

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

${Testing_Root_API_NAME}    network-topology
${Testing_Root_API_XPATH}    ${API_Tree_ROW_1st_Level_XPATH}/a/span[contains(text(),"${Testing_Root_API_NAME}")][1]
${Testing_Root_API_EXPANDER}    ${Testing_Root_API_XPATH}/preceding-sibling::i[@ng-class="row.tree_icon"]
${Testing_Root_API_Config_NAME}    config
${Testing_Root_API_Config_XPATH}    ${API_Tree_ROW_2nd_Level_XPATH}/a/span[contains(text(),"${Testing_Root_API_Config_NAME}")]
${Testing_Root_API_Config_EXPANDER}    ${Testing_Root_API_Config_XPATH}/preceding-sibling::i[@ng-class="row.tree_icon"]
${Testing_Root_API_Network_Topology_NAME}    network-topology
${Testing_Root_API_Network_Topology_XPATH}    ${API_Tree_ROW_3rd_Level_XPATH}/a/span[contains(text(),"${Testing_Root_API_Network_Topology_NAME}")]
${Testing_Root_API_Network_Topology_Plus_EXPANDER}    ${Testing_Root_API_Network_Topology_XPATH}/preceding-sibling::i[@ng-class="row.tree_icon"]

${Topology_ID}    ${EMPTY}
${Testing_Root_API_Topology_NAME}    topology
${Testing_Root_API_Topology_Id_NAME}    topology-id
${Testing_Root_API_Topology_Topology_Id_NAME}    ${Testing_Root_API_Topology_NAME} {${Testing_Root_API_Topology_Id_NAME}}
${Testing_Root_API_Topology_Topology_Id_XPATH}    ${API_Tree_ROW_4th_Level_XPATH}/a/span[contains(text(),"${Testing_Root_API_Topology_Topology_Id_NAME}")]
${Testing_Root_API_Topology_Topology_Id_Plus_EXPANDER}    ${Testing_Root_API_Topology_Topology_Id_XPATH}/preceding-sibling::i[@ng-class="row.tree_icon"]
${Testing_Root_API_Topology_Types_NAME}    topology-types
${Testing_Root_API_Topology_Types_XPATH}    ${API_Tree_ROW_5th_Level_XPATH}/a/span[contains(text(),"${Testing_Root_API_Topology_Types_NAME}")]
${Testing_Root_API_Topology_Types_Plus_EXPANDER}    ${Testing_Root_API_Topology_Types_XPATH}/preceding-sibling::i[@ng-class="row.tree_icon"]

${Node_ID}        ${EMPTY}
${Testing_Root_API_Node_NAME}    node
${Testing_Root_API_Node_Id_NAME}    node-id
${Testing_Root_API_Node_Node_Id_NAME}    ${Testing_Root_API_Node_NAME} {${Testing_Root_API_Node_Id_NAME}}
${Testing_Root_API_Node_Node_Id_XPATH}    ${API_Tree_ROW_5th_Level_XPATH}/a/span[contains(text(),"${Testing_Root_API_Node_Node_Id_NAME}")]
${Testing_Root_API_Node_Node_Id_Plus_EXPANDER}    ${Testing_Root_API_Node_Node_Id_XPATH}/preceding-sibling::i[@ng-class="row.tree_icon"]

${Link_ID}        ${EMPTY}
${Testing_Root_API_Link_NAME}    link
${Testing_Root_API_Link_Id_NAME}    link-id
${Testing_Root_API_Link_Link_Id_NAME}    ${Testing_Root_API_Link_NAME} {${Testing_Root_API_Link_Id_NAME}}
${Testing_Root_API_Link_Link_Id_XPATH}    ${API_Tree_ROW_5th_Level_XPATH}/a/span[contains(text(),"${Testing_Root_API_Link_Link_Id_NAME}")]
${Testing_Root_API_Link_Link_Id_Plus_EXPANDER}    ${Testing_Root_API_Link_Link_Id_XPATH}/preceding-sibling::i[@ng-class="row.tree_icon"]

### ACTION BUTTONS CONTAINER ###

${Action_Buttons_DIV}    //div[@class="actionButtons"]
${Custom_API_request_BUTTON}    //button[@ng-click='show_add_data_popup()']
${Operation_Select_BOX}    ${Action_Buttons_DIV}/div/select[@ng-model="selectedOperation"]

#${Get_OPERATION}    ${Operation_Select_BOX}/option[@label="GET"]
${Get_OPERATION}    GET    
#${Put_OPERATION}    ${Operation_Select_BOX}/option[@label="PUT"]
${Put_OPERATION}    PUT
#${Post_OPERATION}    ${Operation_Select_BOX}/option[@label="POST"]
${Post_OPERATION}    POST
#${Delete_OPERATION}    ${Operation_Select_BOX}/option[@label="DELETE"]
${Delete_OPERATION}    DELETE

${Path_Wrapper}    //span[@ng-show="pathElem.hasIdentifier()"]
${Topology_Id_Path_Wrapper_INPUT}    //div[@class="actionButtons"]//span[contains(.,"/${Testing_Root_API_Topology_NAME}")]//input
${Node_Id_Path_Wrapper_INPUT}    //div[@class="actionButtons"]//span[contains(.,"/${Testing_Root_API_Node_NAME}")]//input
${Link_Id_Path_Wrapper_INPUT}    //div[@class="actionButtons"]//span[contains(.,"/${Testing_Root_API_Link_NAME}")]//input
${Copy_To_Clipboard_BUTTON}    //button[contains(@clip-copy, "copyReqPathToClipboard")]
${Send_BUTTON}    //button[@ng-click="executeOperation(selectedOperation)"]
${Previewed_API}    ${EMPTY}
${Previewed_LIST}    ${EMPTY}

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
${Error_sending_request_MSG}    Error sending request
${Data_already_exists_for_path_MSG}    - : Data already exists for path:
${Error_sendin_request_Data_already_exists_ALERT}    ${Alert_PANEL}/div/b[contains(text(), "${Error_sending_request_MSG}")]/following-sibling::b[contains(text(), "${Data_already_exists_for_path_MSG}")]
${Error_parsing_input_missing_keys_MSG}    - : Error parsing input: Input is missing some of the keys of
${Error_sending_request_Error_parsing_input_missing_keys_ALERT}    ${Alert_PANEL}/div/b[contains(text(), "${Error_sending_request_MSG}")]/following-sibling::b[contains(text(), "${Error_parsing_input_missing_keys_MSG}")]
${Input_is_required_MSG}    - : Input is required.
${Error_sending_request_Input_is_required_ALERT}    ${Alert_PANEL}/div/b[contains(text(), "${Error_sending_request_MSG}")]/following-sibling::b[contains(text(), "${Input_is_required_MSG}")]
${Data_missing_Relevant_data_model_etc_MSG}    Data-missing : Request could not be completed because the relevant data model content does not exist.
${Relevant_data_model_content_not_existing_MSG}    - : Request could not be completed because the relevant data model content does not exist
${Data_missing_Relevant_data_model_not_existing_ALERT}    ${Alert_PANEL}/div/b[contains(text(), "${Data_missing_Relevant_data_model_etc_MSG}")]/following-sibling::b[contains(text(), "${Relevant_data_model_content_not_existing_MSG}")]
${Missing_key_for_list_MSG}    - : Missing key for list
${Data_missing_Missing_key_for_list_ALERT}    ${Alert_PANEL}/div/b[contains(text(), "${Data_missing_Relevant_data_model_etc_MSG}")]/following-sibling::b[contains(text(), "${Missing_key_for_list_MSG}")]
${Server_error_Server_encountered_unexpected_condition_MSG}    Server Error : The server encountered an unexpected condition which prevented it from fulfilling the request.
${Error_creating_data_MSG}    - : Error creating data
${Server_error_Error_creating_data_ALERT}    ${Alert_PANEL}/div/b[contains(text(), "${Server_error_Server_encountered_unexpected_condition_MSG}")]/following-sibling::b[contains(text(), "${Error_creating_data_MSG}")]
${Error_sending_request_Missing_key_for_list_ALERT}    ${Alert_PANEL}/div/b[contains(text(), "${Error_sending_request_MSG}")]/following-sibling::b[contains(text(), "${Missing_key_for_list_MSG}")]
${Cancommit_encountered_unexpected_failure_MSG}    - : canCommit encountered an unexpected failure
${Server_error_Cancommit_encountered_unexpected_failure_ALERT}    ${Alert_PANEL}/div/b[contains(text(), "${Server_error_Server_encountered_unexpected_condition_MSG}")]/following-sibling::b[contains(text(), "${Cancommit_encountered_unexpected_failure_MSG}")]
${Parametrized_data_was_saved_MSG}    Parametrized data was saved.
${Parametrized_data_was_saved_ALERT}    ${Alert_PANEL}/div/b[contains(., "${Parametrized_data_was_saved_MSG}")]
${Parameters_Was_Exported_Successfully_MSG}    Parameters was exported successfully
${Parameters_Was_Exported_Successfully_ALERT}    ${Alert_PANEL}/div/b[contains(., "${Parameters_Was_Exported_Successfully_MSG}")]
${Parameter_does_NOT_exist_MSG}    Parameter does NOT exist
${Parameter_does_NOT_exist_ALERT}    ${Alert_PANEL}/div/b[contains(., "${Parameter_does_NOT_exist_MSG}")]


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
${Testing_Root_API_Source_Source_Node_NAME}    source-node
${Testing_Root_API_Source_Source_Node_LABEL}    ${Testing_Root_API_Source_BUTTON}//following::span[contains(., "${Testing_Root_API_Source_Source_Node_NAME}")]
${Testing_Root_API_Source_Source_Node_INPUT}    ${Testing_Root_API_Source_Source_Node_LABEL}//following::input[@type="text"]

${Testing_Root_API_Destination_NAME}    destination
${Testing_Root_API_Destination_BUTTON}    //div[@class="topContainerPart"]/button[contains(text(),"${Testing_Root_API_Destination_NAME}")]
${Testing_Root_API_Destination_Arrow_EXPANDER}    ${Testing_Root_API_Destination_BUTTON}/preceding-sibling::${Arrow_EXPANDER}
${Testing_Root_API_Destination_Destination_Node_NAME}    dest-node
${Testing_Root_API_Destination_Destination_Node_LABEL}    ${Testing_Root_API_Destination_BUTTON}//following::span[contains(., "${Testing_Root_API_Destination_Destination_Node_NAME}")]
${Testing_Root_API_Destination_Destination_Node_INPUT}    ${Testing_Root_API_Destination_Destination_Node_LABEL}//following::input[@type="text"]

${Testing_Root_API_Supporting-link_List_NAME}    supporting-link
${Testing_Root_API_Supporting-link_List_BUTTON}    //div[@class="topContainerPart"]/button[contains(text(),"${Testing_Root_API_Supporting-link_List_NAME}") and contains(text(),"${List_NAME}")]
${Testing_Root_API_Supporting-link_List_Arrow_EXPANDER}    ${Testing_Root_API_Supporting-link_List_BUTTON}/preceding-sibling::${Arrow_EXPANDER}
${Testing_Root_API_Supporting-link_Plus_BUTTON}    ${Testing_Root_API_Supporting-link_List_BUTTON}/following::${Plus_BUTTON}

# PARAMETERS tab

${Parameters_TABLE}    //section[contains(@ng-controller, "requestHistoryCtrl") and contains(@class, "historyPopUp ng-scope" )]//div[@ng-show="mainTabs.parameters"]
${Name_Header_TEXT}    NAME
${Parameters_Table_Name_HEADER}    ${Parameters_TABLE}//div[@class="thdiv"]/div[text()="${Name_Header_TEXT}"]
${Value_Header_TEXT}    VALUE
${Parameters_Table_Value_HEADER}    ${Parameters_TABLE}//div[@class="thdiv"]/div[text()="${Value_Header_TEXT}"]
${Action_Header_TEXT}    ACTION
${Parameters_Table_Action_HEADER}    ${Parameters_TABLE}//div[@class="thdiv"]/div[text()="${Action_Header_TEXT}"]

${Add_New_Parameter_BUTTON}    ${Parameters_TABLE}//button[contains(text(), "Add new parameter")]
${Add_New_Parameter_Showed_BOX}    //div[@class= "paramBox popupContainer draggablePopup ng-scope ui-draggable ui-draggable-handle"]
${Add_New_Parameter_Hidden_BOX}    //div[@class= "paramBox popupContainer draggablePopup ng-scope ui-draggable ui-draggable-handle ng-hide"]
${Add_New_Parameter_Box_Close_BUTTON}    ${Add_New_Parameter_Showed_BOX}/button[contains(@class, "icon-remove close")]
${Add_New_Parameter_FORM}    ${Add_New_Parameter_Showed_BOX}/form[@name="paramForm"]
${Add_New_Parameter_Form_Name_TEXT}    Name
${Add_New_Parameter_Form_Name_LABEL}    ${Add_New_Parameter_FORM}/label[contains(text(), "${Add_New_Parameter_Form_Name_TEXT}")]
${Add_New_Parameter_Form_Param_Check_ICON}    ${Add_New_Parameter_FORM}//i[@id="paramCheck"]    
${Add_New_Parameter_Form_Name_INPUT}    ${Add_New_Parameter_Form_Name_LABEL}/following-sibling::input[@ng-model="paramObj.name"]
${Add_New_Parameter_Form_Value_TEXT}    Value
${Add_New_Parameter_Form_Value_LABEL}    ${Add_New_Parameter_FORM}/label[contains(text(), "${Add_New_Parameter_Form_Value_TEXT}")]
${Add_New_Parameter_Form_Value_INPUT}    ${Add_New_Parameter_Form_Value_LABEL}/following-sibling::input[@ng-model="paramObj.value"]
${Add_New_Parameter_Form_Save_BUTTON}    ${Add_New_Parameter_FORM}/button[@ng-click="saveParam()"]
${Key}            key

${Parameter_Name}    ${EMPTY}
${Parameter_Key}    ${EMPTY}
${Parameter_Value}    ${EMPTY}

${Parameter_Table_ROW}    ${Parameters_TABLE}//div[@ng-repeat="param in parameterList.list track by $index"][${Row_NUMBER}]
${Parameter_Table_Row_Parameter_Name_XPATH}    ${Parameter_Table_ROW}//div[@class="tddiv rh-col2"]/span[contains(., "${Parameter_Name}")]
${Parameter_Table_Row_Parameter_Value_XPATH}    ${Parameter_Table_ROW}//div[@class="tddiv rh-col3"]/span[contains(., "${Parameter_Value}")]
${Parameter_Table_Row_Edit_BUTTON}    ${Parameter_Table_ROW}//div[@class="tddiv rh-col4"]//button[@class="yangButton iconEdit"]
${Parameter_Table_Row_Delete_BUTTON}    ${Parameter_Table_ROW}//div[@class="tddiv rh-col4"]//button[@class="yangButton iconClose"]

${Clear_Parameters_BUTTON}    ${Parameters_TABLE}//button[contains(text(), "Clear parameters")]
${Import_Parameters_SECTION}    ${Parameters_TABLE}//span[contains(text(), "Import parameters")]
${Import_Parameters_INPUT}    ${Parameters_TABLE}//input[@id="upload-parameters"]
${Export_Parameters_BUTTON}    ${Parameters_TABLE}//button[contains(text(), "Export parameters")]

# HISTORY tab

${History_TABLE}    //section[contains(@ng-controller, "requestHistoryCtrl") and contains(@class, "historyPopUp ng-scope" )]//div[@ng-show="mainTabs.history"]
${Method_Header_TEXT}    METHOD
${History_Table_Method_HEADER}    ${History_TABLE}//div[@class="thdiv"]/div[text()="${Method_Header_TEXT}"]
${Url_Header_TEXT}    URL
${History_Table_Url_HEADER}    ${History_TABLE}//div[@class="thdiv"]/div[text()="${Url_Header_TEXT}"]
${Status_Header_TEXT}    STATUS
${History_Table_Status_HEADER}    ${History_TABLE}//div[@class="thdiv"]/div[text()="${Status_Header_TEXT}"]
${History_Table_Action_HEADER}    ${History_TABLE}//div[@class="thdiv"]/div[text()="${Action_Header_TEXT}"]

${Method_Name}    ${EMPTY}
${Row_NUMBER}     ${EMPTY}

${Get_Method_NAME}    GET
${Put_Method_NAME}    PUT
${Post_Method_NAME}    POST
${Remove_Method_NAME}    REMOVE
${Success_STATUS}    success
${Error_STATUS}    error
${History_Table_List_ROW}    ${History_TABLE}//div[@ng-repeat="req in requestList.list track by $index"][${Row_NUMBER}]
${History_Table_List_Row_ENUM}    ${History_TABLE}//div[@class="scroll"]/div[@ng-repeat="req in requestList.list track by $index"]
${History_Table_Row_Method_XPATH}    ${History_Table_List_ROW}//div[@class="tddiv rh-col2"]/span
${History_Table_Row_Method_Name_XPATH}    ${History_Table_List_ROW}//div[@class="tddiv rh-col2"]/span[text()="${Method_Name}"]
${History_Table_Row_Url_XPATH}    ${History_Table_List_ROW}//div[@class="tddiv rh-col3"]/span
${History_Table_Row_Status_XPATH}    ${History_Table_List_ROW}//div[@class="tddiv rh-col4"]/span
${History_Table_Row_Sent_Data_Disabled_BUTTON}    ${History_Table_List_ROW}//div[@class="tddiv rh-col5"]//button[@class="btn btn-primary ng-scope btn-slim disabled"]
${History_Table_Row_Sent_Data_Enabled_BUTTON}    ${History_Table_List_ROW}//div[@class="tddiv rh-col5"]//button[@class="btn btn-primary ng-scope btn-slim "]
${History_Table_Row_Received_Data_Disabled_BUTTON}    ${History_Table_List_ROW}//div[@class="tddiv rh-col6"]//button[@class="btn btn-primary ng-scope btn-slim disabled"]
${History_Table_Row_Received_Data_Enabled_BUTTON}    ${History_Table_List_ROW}//div[@class="tddiv rh-col6"]//button[@class="btn btn-primary ng-scope btn-slim "]
${History_Table_Row_Execute_Request_BUTTON}    ${History_Table_List_ROW}//div[@class="tddiv rh-col7"]//button[@ng-click="executeRequest()"]
${History_Table_Row_Add_To_Collection_BUTTON}    ${History_Table_List_ROW}//div[@class="tddiv rh-col7"]//div[@ng-click="showCollBox(req)"]
${History_Table_Row_Fill_Data_Disabled_BUTTON}    ${History_Table_List_ROW}//div[@class="tddiv rh-col7"]//button[@class="yangButton iconFillData disabled"]
${History_Table_Row_Fill_Data_Enabled_BUTTON}    ${History_Table_List_ROW}//div[@class="tddiv rh-col7"]//button[@class="yangButton iconFillData "]
${History_Table_Row_Delete_BUTTON}    ${History_Table_List_ROW}//div[@class="tddiv rh-col7"]//button[@class="yangButton iconClose"]
${Clear_History_Data_BUTTON}    ${History_TABLE}//button[contains(text(), "Clear history data")]
${Select_Option}    Select option
${Add_To_Collection_Showed_BOX}    //div[@class="collBox popupContainer draggablePopup ng-scope ui-draggable ui-draggable-handle"]
${Add_To_Collection_Hidden_BOX}    //div[@class="collBox popupContainer draggablePopup ng-scope ui-draggable ui-draggable-handle ng-hide"]
${Add_To_Collection_Box_Close_BUTTON}    ${Add_To_Collection_Showed_BOX}//button[contains(@class, "icon-remove close")]
${Add_To_Collection_Box_Name_TEXT}    Name
${Add_To_Collection_Box_Name_LABEL}    ${Add_To_Collection_Showed_BOX}//label[contains(text(), "${Add_To_Collection_Box_Name_TEXT}")]
${Add_To_Collection_Box_Name_INPUT}    ${Add_To_Collection_Box_Name_LABEL}/following-sibling::input[@ng-model="collection.name"]
${Add_To_Collection_Box_Select_Group_TEXT}    Select group
${Add_To_Collection_Box_Select_Group_LABEL}    ${Add_To_Collection_Showed_BOX}//label[contains(text(), "${Add_To_Collection_Box_Select_Group_TEXT}")]
${Add_To_Collection_Box_Select_Group_SELECT}    ${Add_To_Collection_Showed_BOX}//select[@ng-model="collection.group"]
${Add_To_Collection_Box_Select_Group_Select_OPTION}    ${Add_To_Collection_Box_Select_Group_SELECT}//option[contains(., "${Select_Option}")]
${Add_To_Collection_Box_Group_Name_New_TEXT}    Group name (new):
${Add_To_Collection_Box_Group_Name_New_LABEL}    ${Add_To_Collection_Showed_BOX}//label[contains(text(), "${Add_To_Collection_Box_Group_Name_New_TEXT}")]
${Add_To_Collection_Box_Group_Name_New_INPUT}    ${Add_To_Collection_Box_Group_Name_New_LABEL}/following-sibling::input[@ng-model="collection.group"]
${Add_To_Collection_Box_Add_BUTTON}    ${Add_To_Collection_Showed_BOX}//button[@ng-click="addHistoryItemToColl(req)"]

# SENT DATA BOX #

${Sent_Data_BOX}    //div[@ng-show="showData" and @class="trdiv pre-div ng-scope"]
${Sent_Data_Box_Path_WRAPPER}    //div[@class="pathWrapper"]
${Sent_Data_Box_Topology_Id_Path_Wrapper_INPUT}    //span[contains(.,"/${Testing_Root_API_Topology_NAME}")]//input
${Sent_Data_Box_Node_Id_Path_Wrapper_INPUT}    //span[contains(.,"/${Testing_Root_API_Node_NAME}")]//input
${Sent_Data_Box_Link_Id_Path_Wrapper_INPUT}    //span[contains(.,"/${Testing_Root_API_Link_NAME}")]//input
${Sent_Data_Box_Copy_To_Clipboard_BUTTON}    //button[contains(@clip-copy, "copyReqPathToClipboard")]
${Sent_Data_Box_Reset_Parametrized_Data_BUTTON}    //button[@ng-click="clearParametrizedData()"]
${Sent_Data_Box_Save_Parametrized_Data_BUTTON}    //button[contains(@ng-click, "saveParametrizedData")]
${Sent_Data_Box_Code_Mirror_CODE}    //div[@class="CodeMirror-lines"]//div[@class="CodeMirror-code"]//span[contains(., "${Parameter_Key}")]
${Sent_Data_Box_Close_BUTTON}    //button[contains(@class, "yangButton icon-remove")]

${History_Table_Sent_Data_BOX}    ${History_Table_List_ROW}${Sent_Data_BOX}
${History_Table_Sent_Data_Box_Path_WRAPPER}    ${History_Table_Sent_Data_BOX}${Sent_Data_Box_Path_WRAPPER}
${History_Table_Sent_Data_Box_Topology_Id_Path_Wrapper_INPUT}    ${History_Table_Sent_Data_Box_Path_WRAPPER}${Sent_Data_Box_Topology_Id_Path_Wrapper_INPUT}
${History_Table_Sent_Data_Box_Node_Id_Path_Wrapper_INPUT}    ${History_Table_Sent_Data_Box_Path_WRAPPER}${Sent_Data_Box_Node_Id_Path_Wrapper_INPUT}
${History_Table_Sent_Data_Box_Link_Id_Path_Wrapper_INPUT}    ${History_Table_Sent_Data_Box_Path_WRAPPER}${Sent_Data_Box_Link_Id_Path_Wrapper_INPUT}
${History_Table_Sent_Data_Box_Copy_To_Clipboard_BUTTON}    ${History_Table_Sent_Data_BOX}${Sent_Data_Box_Copy_To_Clipboard_BUTTON}
${History_Table_Sent_Data_Box_Reset_Parametrized_Data_BUTTON}    ${History_Table_Sent_Data_BOX}${Sent_Data_Box_Reset_Parametrized_Data_BUTTON}
${History_Table_Sent_Data_Box_Save_Parametrized_Data_BUTTON}    ${History_Table_Sent_Data_BOX}${Sent_Data_Box_Save_Parametrized_Data_BUTTON}
${History_Table_Sent_Data_Box_Code_Mirror_CODE}    ${History_Table_Sent_Data_BOX}${Sent_Data_Box_Code_Mirror_CODE}
${History_Table_Sent_Data_Box_Close_BUTTON}    ${History_Table_Sent_Data_BOX}${Sent_Data_Box_Close_BUTTON}


# COLLECTION tab

${Collection_TABLE}    //section[contains(@ng-controller, "requestHistoryCtrl") and contains(@class, "historyPopUp ng-scope" )]//div[@ng-show="mainTabs.collection"]
${Collection_Table_Method_HEADER}    ${Collection_TABLE}//div[@class="thdiv"]/div[text()="${Method_Header_TEXT}"]
${Collection_Table_Name_HEADER}    ${Collection_TABLE}//div[@class="thdiv"]/div[text()="${Name_Header_TEXT}"]
${Collection_Table_Url_HEADER}    ${Collection_TABLE}//div[@class="thdiv"]/div[text()="${Url_Header_TEXT}"]
${Collection_Table_Status_HEADER}    ${Collection_TABLE}//div[@class="thdiv"]/div[text()="${Status_Header_TEXT}"]
${Collection_Table_Action_HEADER}    ${Collection_TABLE}//div[@class="thdiv"]/div[text()="${Action_Header_TEXT}"]
${Import_Collection_SECTION}    ${Collection_TABLE}//span[contains(text(), "Import collection")]
${Import_Collections_INPUT}    ${Collection_TABLE}//input[@id="upload-collection"]
${Export_Collection_BUTTON}    ${Collection_TABLE}//button[contains(text(), "Export collection")]
${Clear_Collection_Data_BUTTON}    ${Collection_TABLE}//button[contains(text(), "Clear collection data")]

${Collection_Table_List_Nongroup_ROW}    ${Collection_TABLE}//div[@ng-repeat="req in collectionList.ungrouped track by $index"][${Row_NUMBER}]
${Collection_Table_Nongroup_Row_Method_Name_XPATH}    ${Collection_Table_List_Nongroup_ROW}//div[@class="tddiv rh-col2"]/span[text()="${Method_Name}"]
${Collection_Table_Nongroup_Row_Name_XPATH}    ${Collection_Table_List_Nongroup_ROW}//div[@class="tddiv rh-col8"]/span
${Collection_Table_Nongroup_Row_Url_XPATH}    ${Collection_Table_List_Nongroup_ROW}//div[@class="tddiv rh-col3c"]/span
${Collection_Table_Nongroup_Row_Status_XPATH}    ${Collection_Table_List_Nongroup_ROW}//div[@class="tddiv rh-col4"]/span
${Collection_Table_Nongroup_Row_Sent_Data_Disabled_BUTTON}    ${Collection_Table_List_Nongroup_ROW}//div[@class="tddiv rh-col5"]//button[@class="btn btn-primary ng-scope btn-slim disabled"]
${Collection_Table_Nongroup_Row_Sent_Data_Enabled_BUTTON}    ${Collection_Table_List_Nongroup_ROW}//div[@class="tddiv rh-col5"]//button[@class="btn btn-primary ng-scope btn-slim "]
${Collection_Table_Nongroup_Row_Received_Data_Disabled_BUTTON}    ${Collection_Table_List_Nongroup_ROW}//div[@class="tddiv rh-col6"]//button[@class="btn btn-primary ng-scope btn-slim disabled"]
${Collection_Table_Nongroup_Row_Received_Data_Enabled_BUTTON}    ${Collection_Table_List_Nongroup_ROW}//div[@class="tddiv rh-col6"]//button[@class="btn btn-primary ng-scope btn-slim "]
${Collection_Table_Nongroup_Row_Execute_Request_BUTTON}    ${Collection_Table_List_Nongroup_ROW}//div[@class="tddiv rh-col7"]//button[contains(@ng-click, "executeCollectionRequest")]
${Collection_Table_Nongroup_Row_Fill_Data_Disabled_BUTTON}    ${Collection_Table_List_Nongroup_ROW}//div[@class="tddiv rh-col7"]//button[@class="yangButton iconFillData disabled"]
${Collection_Table_Nongroup_Row_Fill_Data_Enabled_BUTTON}    ${Collection_Table_List_Nongroup_ROW}//div[@class="tddiv rh-col7"]//button[@class="yangButton iconFillData "]
${Collection_Table_Nongroup_Row_Move_To_Group_BUTTON}    ${Collection_Table_List_Nongroup_ROW}//div[@class="tddiv rh-col7"]//div[contains(@ng-click, "showCollBox")]
${Collection_Table_Nongroup_Row_Delete_BUTTON}    ${Collection_Table_List_Nongroup_ROW}//div[@class="tddiv rh-col7"]//button[@class="yangButton iconClose"]
${Collection_Table_Nongroup_Row_Sent_Data_BOX}    ${Collection_Table_List_Nongroup_ROW}${Sent_Data_BOX}
${Collection_Table_Nongroup_Row_Sent_Data_Box_Path_WRAPPER}    ${Collection_Table_Nongroup_Row_Sent_Data_BOX}${Sent_Data_Box_Path_WRAPPER}
${Collection_Table_Nongroup_Row_Sent_Data_Box_Topology_Id_Path_Wrapper_INPUT}    ${Collection_Table_Nongroup_Row_Sent_Data_Box_Path_WRAPPER}${Sent_Data_Box_Topology_Id_Path_Wrapper_INPUT}
${Collection_Table_Nongroup_Row_Sent_Data_Box_Node_Id_Path_Wrapper_INPUT}    ${Collection_Table_Nongroup_Row_Sent_Data_Box_Path_WRAPPER}${Sent_Data_Box_Node_Id_Path_Wrapper_INPUT}
${Collection_Table_Nongroup_Row_Sent_Data_Box_Link_Id_Path_Wrapper_INPUT}    ${Collection_Table_Nongroup_Row_Sent_Data_Box_Path_WRAPPER}${Sent_Data_Box__Link_Id_Path_Wrapper_INPUT}
${Collection_Table_Nongroup_Row_Sent_Data_Box_Copy_To_Clipboard_BUTTON}    ${Collection_Table_Nongroup_Row_Sent_Data_BOX}${Sent_Data_Box_Copy_To_Clipboard_BUTTON}
${Collection_Table_Nongroup_Row_Sent_Data_Box_Reset_Parametrized_Data_BUTTON}    ${Collection_Table_Nongroup_Row_Sent_Data_BOX}${Sent_Data_Box_Reset_Parametrized_Data_BUTTON}
${Collection_Table_Nongroup_Row_Sent_Data_Box_Save_Parametrized_Data_BUTTON}    ${Collection_Table_Nongroup_Row_Sent_Data_BOX}${Sent_Data_Box_Save_Parametrized_Data_BUTTON}
${Collection_Table_Nongroup_Row_Sent_Data_Box_Code_Mirror_CODE}    ${Collection_Table_List_Nongroup_ROW}${Sent_Data_Box_Code_Mirror_CODE}
${Collection_Table_Nongroup_Row_Sent_Data_Box_Close_BUTTON}    ${Collection_Table_Nongroup_Row_Sent_Data_BOX}${Sent_Data_Box_Close_BUTTON}

${Group_NUMBER}    ${EMPTY}
${Group_NAME}     ${EMPTY}
${Collection_Table_List_GROUP}    ${Collection_TABLE}//div[contains(@ng-repeat, "in collectionList.groups track by $index")][${Group_NUMBER}]
${Collection_Table_List_Group_EXPANDER}    ${Collection_Table_List_GROUP}//section[contains(@ng-click, "toggleExpanded(key)") and contains(., "${Group_NAME}")]
${Collection_Table_List_Group_ROW}    ${Collection_Table_List_GROUP}//section[@class="trdiv groupList ng-scope"][${Row_NUMBER}]
${Collection_Table_Group_Row_Method_Name_XPATH}    ${Collection_Table_List_Group_ROW}//div[@class="tddiv rh-col2"]/span[text()="${Method_Name}"]
${Collection_Table_Group_Row_Name_XPATH}    ${Collection_Table_List_Group_ROW}//div[@class="tddiv rh-col8"]/span
${Collection_Table_Group_Row_Url_XPATH}    ${Collection_Table_List_Group_ROW}//div[@class="tddiv rh-col3c"]/span
${Collection_Table_Group_Row_Status_XPATH}    ${Collection_Table_List_Group_ROW}//div[@class="tddiv rh-col4"]/span
${Collection_Table_Group_Row_Sent_Data_Disabled_BUTTON}    ${Collection_Table_List_Group_ROW}//div[@class="tddiv rh-col5"]//button[@class="btn btn-primary ng-scope btn-slim disabled"]
${Collection_Table_Group_Row_Sent_Data_Enabled_BUTTON}    ${Collection_Table_List_Group_ROW}//div[@class="tddiv rh-col5"]//button[@class="btn btn-primary ng-scope btn-slim "]
${Collection_Table_Group_Row_Received_Data_Disabled_BUTTON}    ${Collection_Table_List_Group_ROW}//div[@class="tddiv rh-col6"]//button[@class="btn btn-primary ng-scope btn-slim disabled"]
${Collection_Table_Group_Row_Received_Data_Enabled_BUTTON}    ${Collection_Table_List_Group_ROW}//div[@class="tddiv rh-col6"]//button[@class="btn btn-primary ng-scope btn-slim "]
${Collection_Table_Group_Row_Execute_Request_BUTTON}    ${Collection_Table_List_Group_ROW}//div[@class="tddiv rh-col7"]//button[contains(@ng-click, "executeCollectionRequest")]
${Collection_Table_Group_Row_Fill_Data_Disabled_BUTTON}    ${Collection_Table_List_Group_ROW}//div[@class="tddiv rh-col7"]//button[@class="yangButton iconFillData disabled"]
${Collection_Table_Group_Row_Fill_Data_Enabled_BUTTON}    ${Collection_Table_List_Group_ROW}//div[@class="tddiv rh-col7"]//button[@class="yangButton iconFillData "]
${Collection_Table_Group_Row_Move_To_Group_BUTTON}    ${Collection_Table_List_Group_ROW}//div[@class="tddiv rh-col7"]//div[contains(@ng-click, "showCollBox")]
${Collection_Table_Group_Row_Delete_BUTTON}    ${Collection_Table_List_Group_ROW}//div[@class="tddiv rh-col7"]//button[@class="yangButton iconClose"]
${Collection_Table_Group_Row_Sent_Data_BOX}    ${Collection_Table_List_Group_ROW}${Sent_Data_BOX}
${Collection_Table_Group_Row_Sent_Data_Box_Path_WRAPPER}    ${Collection_Table_Group_Row_Sent_Data_BOX}${Sent_Data_Box_Path_WRAPPER}
${Collection_Table_Group_Row_Sent_Data_Box_Topology_Id_Path_Wrapper_INPUT}    ${Collection_Table_Group_Row_Sent_Data_Box_Path_WRAPPER}${Sent_Data_Box_Topology_Id_Path_Wrapper_INPUT}
${Collection_Table_Group_Row_Sent_Data_Box_Node_Id_Path_Wrapper_INPUT}    ${Collection_Table_Group_Row_Sent_Data_Box_Path_WRAPPER}${Sent_Data_Box_Node_Id_Path_Wrapper_INPUT}
${Collection_Table_Group_Row_Sent_Data_Box_Link_Id_Path_Wrapper_INPUT}    ${Collection_Table_Group_Row_Sent_Data_Box_Path_WRAPPER}${Sent_Data_Box__Link_Id_Path_Wrapper_INPUT}
${Collection_Table_Group_Row_Sent_Data_Box_Copy_To_Clipboard_BUTTON}    ${Collection_Table_Group_Row_Sent_Data_BOX}${Sent_Data_Box_Copy_To_Clipboard_BUTTON}
${Collection_Table_Group_Row_Sent_Data_Box_Reset_Parametrized_Data_BUTTON}    ${Collection_Table_Group_Row_Sent_Data_BOX}${Sent_Data_Box_Reset_Parametrized_Data_BUTTON}
${Collection_Table_Group_Row_Sent_Data_Box_Save_Parametrized_Data_BUTTON}    ${Collection_Table_Group_Row_Sent_Data_BOX}${Sent_Data_Box_Save_Parametrized_Data_BUTTON}
${Collection_Table_Group_Row_Sent_Data_Box_Code_Mirror_CODE}    ${Collection_Table_List_Group_ROW}${Sent_Data_Box_Code_Mirror_CODE}
${Collection_Table_Group_Row_Sent_Data_Box_Close_BUTTON}    ${Collection_Table_Group_Row_Sent_Data_BOX}${Sent_Data_Box_Close_BUTTON}

*** Keywords ***

### GENERAL ###

Delete Text From Input Field
    [Arguments]    ${input_field}
    [Documentation]    Will erase data from chosen input field.
    Focus    ${input_field}
    Clear Element Text    ${input_field}

Insert Text To Input Field
    [Arguments]    ${input_field}    ${text}
    [Documentation]    Will erase data from chosen input field and insert chosen data.
    Focus    ${input_field}
    Clear Element Text    ${input_field}
    Press Key    ${input_field}    ${text}

Compare Text And Variable
    [Arguments]    ${element_xpath}    ${variable}
    [Documentation]    Will compare as strings text from a page and variable.
    ${text_1}=    Return Text From Element    ${element_xpath}
    Should Be Equal As Strings    ${text_1}    ${variable}

Return Text From Element
    [Arguments]    ${element_xpath}
    Wait Until Element Is Visible    ${element_xpath}
    Focus    ${element_xpath}
    ${text}=    Get Text    ${element_xpath}
    ${text_1}=    Remove Leading And Trailing Spaces    ${text}
    [Return]    ${text_1}

Return Edited String
    [Arguments]    ${string_to_edit}    ${separator}    ${string_to_add}
    [Documentation]    Will return new string as a result of erasing and adding some part of the original string.
    ${str_1}=    Fetch From Left    ${string_to_edit}    ${separator}
    ${str_2}=    Fetch From Right    ${string_to_edit}    ${separator}
    ${new_string}=    Catenate    SEPARATOR=    ${str_1}    ${string_to_add}    ${str_2}
    [Return]    ${new_string}

Patient Click Element
    [Arguments]    ${locator}    ${wait}=4 second
    [Documentation]    A workaround to mysterious no-effect Click Element (maybe because CSS transition)
    Sleep    ${wait}
    Wait Until Element Is Visible    ${locator}    timeout=10
    Focus    ${locator}
    Click Element    ${locator}
    Sleep    ${wait}

### DLUX SUBMENUS ###

Navigate To Yang UI Submenu
    Click Element    ${Yang_UI_SUBMENU}
    Wait Until Page Contains Element    ${Loading_completed_successfully_ALERT}
    Click Element    ${Alert_Close_BUTTON}
    Location Should Be    ${Yang_UI_Submenu_URL}


### API TAB ###

Load Network-topology Button In CustomContainer Area
    [Documentation]    Contains steps to navigate from loaded API tree to loaded
    ...    network-topology button in custom Container Area.
    ${status}=    Run Keyword And Return Status    Page Should Contain Element    ${Testing_Root_API_Config_XPATH}
    Run Keyword If    "${status}"=="False"    Click Element    ${Testing_Root_API_EXPANDER}
    ${status}=    Run Keyword And Return Status    Page Should Contain Element    ${Testing_Root_API_Network_Topology_XPATH}
    Run Keyword If    "${status}"=="False"    Click Element    ${Testing_Root_API_Config_EXPANDER}
    ${status}=    Run Keyword And Return Status    Page Should Contain Element    ${Testing_Root_API_Network_Topology_BUTTON}
    Run Keyword If    "${status}"=="False"    Click Element    ${Testing_Root_API_Network_Topology_XPATH}
    Wait Until Page Contains Element    ${Testing_Root_API_Network_Topology_BUTTON}
    Page Should Contain Button    ${Testing_Root_API_Network_Topology_Arrow_EXPANDER}

Load Topology List Button In CustomContainer Area
    [Documentation]    Contains steps to navigate from loaded network-topology in API to loaded
    ...    topology list button in custom Container Area.
    ${status}=    Run Keyword And Return Status    Page Should Contain Element    ${Testing_Root_API_Network_Topology_Plus_EXPANDER}
    Run Keyword If    "${status}"=="False"    Load Network-topology Button In CustomContainer Area
    Page Should Contain Element    ${Testing_Root_API_Network_Topology_Plus_EXPANDER}
    ${status}=    Run Keyword And Return Status    Page Should Contain Element    ${Testing_Root_API_Topology_Topology_Id_XPATH}
    Run Keyword If    "${status}"=="False"    Click Element    ${Testing_Root_API_Network_Topology_Plus_EXPANDER}
    Wait Until Page Contains Element    ${Testing_Root_API_Topology_Topology_Id_XPATH}
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

Load Link List Button In CustomContainer Area
    [Documentation]    Contains steps to navigate from loaded topology {topology-id}
    ...    in API to loaded node list button in custom Container Area.
    ${status}=    Run Keyword And Return Status    Page Should Contain Element    ${Testing_Root_API_Link_Link_Id_XPATH}
    Run Keyword If    "${status}"=="True"    Run Keywords    Click Element    ${Testing_Root_API_Link_Link_Id_XPATH}    AND    Wait Until Page Contains Element
    ...    ${Testing_Root_API_Link_List_BUTTON}
    Run Keyword If    "${status}"=="False"    Run Keywords    Click Element    ${Testing_Root_API_Topology_Topology_Id_Plus_EXPANDER}    AND    Wait Until Page Contains Element
    ...    ${Testing_Root_API_Link_Link_Id_XPATH}    AND    Click Element    ${Testing_Root_API_Link_Link_Id_XPATH}
    Page Should Contain Button    ${Testing_Root_API_Link_List_Plus_BUTTON}


### ACTION BUTTONS AREA ###

Save Preview Box Content
    [Arguments]    ${variable}
    [Documentation]    Saves content of the preview box into a variable.
    Click Element    ${Show_Preview_BUTTON}
    ${variable}    Get Text    ${Preview_Box_Displayed_CONTENT}
    Click Element    ${Preview_Box_Close_BUTTON}


### CUSTOM CONTAINER AREA ###

Expand Network Topology Arrow Expander
    ${status}=    Run Keyword And Return Status    Page Should Contain Element    ${Testing_Root_API_Topology_List_Plus_BUTTON}
    Run Keyword If    "${status}"=="False"    Click Element    ${Testing_Root_API_Network_Topology_Arrow_EXPANDER}
    Page Should Contain Element    ${Testing_Root_API_Topology_List_Plus_BUTTON}


Close Form In CustomContainer Area
    [Arguments]    ${delete_button}    ${input_field}
    [Documentation]    Closes the form opened in customConainer Area.
    ${status}=    Run Keyword And Return Status    Page Should Contain Element    ${input_field}        
    Run Keyword If    "${status}"=="True"    Run Keywords    Click Element    ${delete_button}    AND
    ...    Page Should Not Contain Element    ${input_field}


Close Alert Panel
    Click Element    ${Alert_Close_BUTTON}


Insert Topology Or Node Or Link Id In Form
    [Arguments]    ${topology_id}    ${node_id}    ${link_id}
    [Documentation]    Will insert given values in id input fields in customContainer area form.
    ${status}=    Run Keyword And Return Status    Page Should Contain Element    ${Testing_Root_API_Topology_List_Plus_BUTTON}
    Run Keyword If    "${status}"=="True"    Run Keywords    Click Element    ${Testing_Root_API_Topology_List_Plus_BUTTON}    AND    Insert Text To Input Field
    ...    ${Testing_Root_API_Topology_List_Topology_Id_INPUT}    ${topology_id}
    ${status}=    Run Keyword And Return Status    Page Should Contain Element    ${Testing_Root_API_Node_List_Plus_BUTTON}
    Run Keyword If    "${status}"=="True"    Run Keywords    Click Element    ${Testing_Root_API_Node_List_Plus_BUTTON}    AND    Insert Text To Input Field
    ...    ${Testing_Root_API_Node_List_Node_Id_INPUT}    ${node_id}
    ${status}=    Run Keyword And Return Status    Page Should Contain Element    ${Testing_Root_API_Link_List_Plus_BUTTON}
    Run Keyword If    "${status}"=="True"    Run Keywords    Click Element    ${Testing_Root_API_Link_List_Plus_BUTTON}    AND    Insert Text To Input Field
    ...    ${Testing_Root_API_Link_List_Link_Id_INPUT}    ${link_id}


Insert Link Id In Form
    [Arguments]    ${link_id}    ${source-node}    ${destination-node}
    [Documentation]    Will insert link id with source and destination point rto form.
    Insert Text To Input Field    ${Link_Id_Path_Wrapper_INPUT}    ${link_id}
    ${status}=    Run Keyword And Return Status    Page Should Contain Element    ${Testing_Root_API_Source_Source_Node_INPUT}
    Run Keyword If    "${status}"=="False"    Patient Click Element    ${Testing_Root_API_Source_Arrow_EXPANDER}    4
    Wait Until Page Contains Element    ${Testing_Root_API_Source_Source_Node_INPUT}
    Input Text    ${Testing_Root_API_Source_Source_Node_INPUT}    ${source-node}
    ${status}=    Run Keyword And Return Status    Page Should Contain Element    ${Testing_Root_API_Destination_Destination_Node_INPUT}
    Run Keyword If    "${status}"=="False"    Patient Click Element    ${Testing_Root_API_Destination_Arrow_EXPANDER}    4
    Wait Until Page Contains Element    ${Testing_Root_API_Destination_Destination_Node_INPUT}
    Input Text    ${Testing_Root_API_Destination_Destination_Node_INPUT}    ${destination-node}


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
    Patient Click Element    ${Operation_Select_BOX}    
    Sleep    4
    Press Key    ${Operation_Select_BOX}    ${Chosen_Operation}        
    Sleep    4
    Press Key    ${Operation_Select_BOX}    \\13    


Execute Chosen Operation
    [Arguments]    ${Chosen_Operation}    ${Alert_Expected}
    [Documentation]    Will click desired operation and hit Send button to execute it
    ...    and check the alert message.
    Select Chosen Operation    ${Chosen_Operation}
    Patient Click Element    ${Send_BUTTON}    
    Wait Until Page Contains Element    ${Alert_Expected}
    Patient Click Element    ${Alert_Close_BUTTON}


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


Verify Topology And Node And Link Id Presence In Form
    [Arguments]    ${topology_id}    ${node_id}    ${link_id}
    [Documentation]    Verifies whether the chosen data is present in the form.
    ${l_inputs}=    Create List    ${Testing_Root_API_Topology_List_Topology_Id_INPUT}    ${Testing_Root_API_Node_List_Node_Id_INPUT}    ${Testing_Root_API_Link_List_Link_Id_INPUT}
    ${l_chosenIds}=    Create List    ${topology_id}    ${node_id}    ${link_id}
    ${l_IDs}=    Create List    ${Topology_ID}    ${Node_ID}    ${Link_ID}
    ${l_list_names}=    Create List    ${Testing_Root_API_Topology_List_NAME}    ${Testing_Root_API_Node_List_NAME}    ${Testing_Root_API_Link_List_NAME}
    ${times}=    List Length    ${l_inputs}
    ${times}    Evaluate    ${times}+1
    : FOR    ${index}    IN RANGE    1    ${times}
    \    ${index}    Evaluate    ${index}-1
    \    ${input}=    Get From List    ${l_inputs}    ${index}
    \    ${chosen_id}=    Get From List    ${l_chosenIds}    ${index}
    \    ${id}=    Get From List    ${l_IDs}    ${index}
    \    ${list_name}=    Get From List    ${l_list_names}    ${index}
    \    If Input Field Present Verify Chosen_ID Presence On The Page    ${input}    ${chosen_id}    ${id}    ${list_name}


If Input Field Present Verify Chosen_ID Presence On The Page
    [Arguments]    ${input_field}    ${Chosen_Id}    ${Topology/Node/Link_ID}    ${topology/node/link_list_name}
    [Documentation]    This keyword verifies, that the page CONTAINS topology/ node/ link with given id in customContainer Area.
    ...    ${Chosen_Id} is id to be input; ${Topology/Node/Link_ID} has values of ${Topology_ID},
    ...    or ${Node_ID}, or ${Link_ID}; ${topology/node/link_list_name} is ${...Topology/Node/Link_List_NAME}.
    ${status}=    Run Keyword And Return Status    Page Should Contain Element    ${input_field}
    Run Keyword If    "${status}"=="True"    Verify Chosen_Id Presence On The Page    ${Chosen_Id}    ${Topology/Node/Link_ID}    ${topology/node/link_list_name}


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
    ${status}=    Run Keyword And Return Status    Page Should Contain Element    ${Testing_Root_API_Network_Topology_BUTTON}
    Run Keyword If    "${status}"=="False"    Run Keywords    Click Element    ${API_TAB}    AND    Load Network-topology Button In CustomContainer Area
    Execute Chosen Operation    ${Delete_OPERATION}    ${Request_sent_successfully_ALERT}


### PARAMETERS TAB ###

Fill Add New Parameter Box
    [Arguments]    ${Chosen_Name}    ${Chosen_Value}    
    Wait Until Page Contains Element    ${Add_New_Parameter_Showed_BOX}
    Input Text    ${Add_New_Parameter_Form_Name_INPUT}    ${Chosen_Name}
    Input Text    ${Add_New_Parameter_Form_Value_INPUT}    ${Chosen_Value}
    Patient Click Element    ${Add_New_Parameter_Form_Save_BUTTON}    4


Add New Parameter
    [Arguments]    ${Chosen_Name}    ${Chosen_Value}    ${Verification_Function}
    [Documentation]    This keyword inputs new parameter into parameters table.
    ...    ${Chosen_Name} has a value of chosen parameter name,
    ...    ${Chosen_Value} has a value of chosen parameter name,
    ...    ${Verification_Function} is either Verify Visibility of NONVisibility.
    Click Element    ${Add_New_Parameter_BUTTON}
    Fill Add New Parameter Box    ${Chosen_Name}    ${Chosen_Value}      
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
    [Arguments]    ${Row_NUMBER}    ${param_name}    ${param_value}
    [Documentation]    This keyword verifies that the page contains Chosen Parameter Name,
    ...    chosen Parameter value, Edit and Delete button.
    ${param_key}=    Return Parameter Key    ${param_name}
    ${Parameter_Table_ROW}=    Set Variable    ${Parameters_TABLE}//div[@ng-repeat="param in parameterList.list track by $index"][${Row_NUMBER}]
    ${Parameter_Table_Row_Parameter_Name_XPATH}=    Set Variable    ${Parameter_Table_ROW}//div[@class="tddiv rh-col2"]/span[contains(., "${param_key}")]
    ${Parameter_Table_Row_Parameter_Value_XPATH}=    Set Variable    ${Parameter_Table_ROW}//div[@class="tddiv rh-col3"]/span[contains(., "${param_value}")]
    ${Parameter_Table_Row_Edit_BUTTON}=    Set Variable    ${Parameter_Table_ROW}//div[@class="tddiv rh-col4"]//button[@class="yangButton iconEdit"]
    ${Parameter_Table_Row_Delete_BUTTON}=    Set Variable    ${Parameter_Table_ROW}//div[@class="tddiv rh-col4"]//button[@class="yangButton iconClose"]
    Page Should Contain Element    ${Parameter_Table_Row_Parameter_Name_XPATH}
    Page Should Contain Element    ${Parameter_Table_Row_Parameter_Value_XPATH}
    Page Should Contain Element    ${Parameter_Table_Row_Edit_BUTTON}
    Page Should Contain Element    ${Parameter_Table_Row_Delete_BUTTON}


Click Parameter Table Edit Parameter Button In Row
    [Arguments]    ${row_number}
    ${Parameter_Table_ROW}=    Set Variable    ${Parameters_TABLE}//div[@ng-repeat="param in parameterList.list track by $index"][${Row_NUMBER}]
    ${Parameter_Table_Row_Edit_BUTTON}=    Set Variable    ${Parameter_Table_ROW}//div[@class="tddiv rh-col4"]//button[@class="yangButton iconEdit"]
    Patient Click Element    ${Parameter_Table_Row_Edit_BUTTON}    4


Click Parameter Table Delete Parameter Button In Row
    [Arguments]    ${row_number}
    ${Parameter_Table_ROW}=    Set Variable    ${Parameters_TABLE}//div[@ng-repeat="param in parameterList.list track by $index"][${Row_NUMBER}]
    ${Parameter_Table_Row_Delete_BUTTON}=    Set Variable    ${Parameter_Table_ROW}//div[@class="tddiv rh-col4"]//button[@class="yangButton iconClose"]
    Patient Click Element    ${Parameter_Table_Row_Delete_BUTTON}    4


Verify Deleted Parameter NONPresence On The Page
    [Arguments]    ${Row_NUMBER}    ${param_name}    ${param_value}
    [Documentation]    This keyword verifies that the page does not contain parameter with
    ...    given name, value and edit and delete buttons. 
    ${param_key}=    Return Parameter Key    ${param_name}
    ${Parameter_Table_ROW}=    Set Variable    ${Parameters_TABLE}//div[@ng-repeat="param in parameterList.list track by $index"][${Row_NUMBER}]
    ${Parameter_Table_Row_Parameter_Name_XPATH}=    Set Variable    ${Parameter_Table_ROW}//div[@class="tddiv rh-col2"]/span[contains(., "${param_key}")]
    Page Should Not Contain Element    ${Parameter_Table_Row_Parameter_Name_XPATH}


Return Parameter Key
    [Arguments]    ${param_name}
    [Documentation]    Will return parameter key in format <<${param_name}>>.
    ${parameter_key_nonempty}=    Catenate    SEPARATOR=    <<    ${param_name}    >>
    ${parameter_key}=    Set Variable If   "${param_name}"=="${EMPTY}"    ${EMPTY}    ${parameter_key_nonempty}    
    [Return]    ${parameter_key}


If Parameters Table Contains Data Then Clear Parameters Data
    ${Row_NUMBER}=    Set Variable    1
    ${Parameter_Table_ROW}=    Set Variable    ${Parameters_TABLE}//div[@ng-repeat="param in parameterList.list track by $index"][${Row_NUMBER}]
    ${status}=    Run Keyword And Return Status    Page Should Contain Element    ${Parameter_Table_ROW}
    Run Keyword If    "${status}"=="True"    Click Element    ${Clear_Parameters_BUTTON}
    Wait Until Page Does Not Contain Element     ${Parameter_Table_ROW}    


### HISTORY TAB ###

Verify History Table Row NONPresence
    [Arguments]    ${Row_NUMBER}
    ${History_Table_List_ROW}=    Set Variable    ${History_TABLE}//div[@ng-repeat="req in requestList.list track by $index"][${Row_NUMBER}]
    Page Should Not Contain Element    ${History_Table_List_ROW}


Verify History Table Row Content
    [Arguments]    ${Row_NUMBER}    ${Method_NAME}    ${Request_Status}
    [Documentation]    This keyword verifies the occurence elements in History tab.
    ${History_Table_List_ROW}=    Set Variable    ${History_TABLE}//div[@ng-repeat="req in requestList.list track by $index"][${Row_NUMBER}]
    ${History_Table_Row_Method_Name_XPATH}=    Set Variable    ${History_Table_List_ROW}//div[@class="tddiv rh-col2"]/span[text()="${Method_Name}"]
    Page Should Contain Element    ${History_Table_Row_Method_Name_XPATH}
    ${History_Table_Row_Status_XPATH}=    Set Variable    ${History_Table_List_ROW}//div[@class="tddiv rh-col4"]/span
    ${status}=    Get Text    ${History_Table_Row_Status_XPATH}
    Should Be Equal As Strings    ${status}    ${Request_Status}


Return History Table Row Url
    [Arguments]    ${Row_NUMBER}
    ${History_Table_List_ROW}=    Set Variable    ${History_TABLE}//div[@ng-repeat="req in requestList.list track by $index"][${Row_NUMBER}]
    ${History_Table_Row_Url_XPATH}=    Set Variable    ${History_Table_List_ROW}//div[@class="tddiv rh-col3"]/span
    ${url_hist}=    Return Text From Element    ${History_Table_Row_Url_XPATH}
    [Return]    ${url_hist}


Compare History Table Row Url And Variable
    [Arguments]    ${Row_NUMBER}    ${variable}
    ${History_Table_List_ROW}=    Set Variable    ${History_TABLE}//div[@ng-repeat="req in requestList.list track by $index"][${Row_NUMBER}]
    ${History_Table_Row_Url_XPATH}=    Set Variable    ${History_Table_List_ROW}//div[@class="tddiv rh-col3"]/span
    Compare Text And Variable    ${History_Table_Row_Url_XPATH}    ${variable}


Verify Element Presence In History Table Row
    [Arguments]    ${Element}    ${Element_Xpath}
    [Documentation]    This keyword sets D/E button variable and verifies its presence on the page.
    #${History_Table_List_ROW}=    Set Variable    //div[@ng-repeat="req in requestList.list track by $index"][${Row_NUMBER}]
    ${Element} =    Set Variable    ${Element_Xpath}
    Page Should Contain Element    ${Element}
    Sleep    1


Verify No Sent No Received Data Elements Presence In History Table Row
    [Arguments]    ${row_number}
    [Documentation]    This keyword verifies the presence of elements in History table associated with unsuccessfully executed operation.
    ${Row_NUMBER}=    Set Variable    ${row_number}
    ${History_Table_List_ROW}=    Set Variable    ${History_TABLE}//div[@ng-repeat="req in requestList.list track by $index"][${Row_NUMBER}]
    ${dict}=    Create Dictionary    ${History_Table_Row_Sent_Data_Disabled_BUTTON}=${History_Table_List_ROW}//div[@class="tddiv rh-col5"]//button[@class="btn btn-primary ng-scope btn-slim disabled"]    ${History_Table_Row_Received_Data_Disabled_BUTTON}=${History_Table_List_ROW}//div[@class="tddiv rh-col6"]//button[@class="btn btn-primary ng-scope btn-slim disabled"]    ${History_Table_Row_Execute_Request_BUTTON}=${History_Table_List_ROW}//div[@class="tddiv rh-col7"]//button[@ng-click="executeRequest()"]    ${History_Table_Row_Add_To_Collection_BUTTON}=${History_Table_List_ROW}//div[@class="tddiv rh-col7"]//div[@ng-click="showCollBox(req)"]    ${History_Table_Row_Fill_Data_Disabled_BUTTON}=${History_Table_List_ROW}//div[@class="tddiv rh-col7"]//button[@class="yangButton iconFillData disabled"]
    ...    ${History_Table_Row_Delete_BUTTON}=${History_Table_List_ROW}//div[@class="tddiv rh-col7"]//button[@class="yangButton iconClose"]
    @{keys}=    Create List    ${History_Table_Row_Sent_Data_Disabled_BUTTON}    ${History_Table_Row_Received_Data_Disabled_BUTTON}    ${History_Table_Row_Execute_Request_BUTTON}    ${History_Table_Row_Add_To_Collection_BUTTON}    ${History_Table_Row_Fill_Data_Disabled_BUTTON}
    ...    ${History_Table_Row_Delete_BUTTON}
    : FOR    ${key}    IN    @{keys}
    \    ${value}=    Get From Dictionary    ${dict}    ${key}
    \    Run Keyword    Verify Element Presence In History Table Row    ${key}    ${value}


Verify Sent Data Elements Presence In History Table Row
    [Arguments]    ${row_number}
    [Documentation]    This keyword verifies the presence of elements in History table associated with succesfully executed Put/ Post operation.
    ${Row_NUMBER}=    Set Variable    ${row_number}
    ${History_Table_List_ROW}=    Set Variable    ${History_TABLE}//div[@ng-repeat="req in requestList.list track by $index"][${Row_NUMBER}]
    ${dict}=    Create Dictionary    ${History_Table_Row_Sent_Data_Enabled_BUTTON}=${History_Table_List_ROW}//div[@class="tddiv rh-col5"]//button[@class="btn btn-primary ng-scope btn-slim "]    ${History_Table_Row_Received_Data_Disabled_BUTTON}=${History_Table_List_ROW}//div[@class="tddiv rh-col6"]//button[@class="btn btn-primary ng-scope btn-slim disabled"]    ${History_Table_Row_Execute_Request_BUTTON}=${History_Table_List_ROW}//div[@class="tddiv rh-col7"]//button[@ng-click="executeRequest()"]    ${History_Table_Row_Add_To_Collection_BUTTON}=${History_Table_List_ROW}//div[@class="tddiv rh-col7"]//div[@ng-click="showCollBox(req)"]    ${History_Table_Row_Fill_Data_Enabled_BUTTON}=${History_Table_List_ROW}//div[@class="tddiv rh-col7"]//button[@class="yangButton iconFillData "]
    ...    ${History_Table_Row_Delete_BUTTON}=${History_Table_List_ROW}//div[@class="tddiv rh-col7"]//button[@class="yangButton iconClose"]
    @{keys}=    Create List    ${History_Table_Row_Sent_Data_Enabled_BUTTON}    ${History_Table_Row_Received_Data_Disabled_BUTTON}    ${History_Table_Row_Execute_Request_BUTTON}    ${History_Table_Row_Add_To_Collection_BUTTON}    ${History_Table_Row_Fill_Data_Enabled_BUTTON}
    ...    ${History_Table_Row_Delete_BUTTON}
    : FOR    ${key}    IN    @{keys}
    \    ${value}=    Get From Dictionary    ${dict}    ${key}
    \    Run Keyword    Verify Element Presence In History Table Row    ${key}    ${value}


Verify Received Data Elements Presence In History Table Row
    [Arguments]    ${row_number}
    [Documentation]    This keyword verifies the presence of elements in History table associated with succesfully executed Get operation.
    ${Row_NUMBER}=    Set Variable    ${row_number}
    ${History_Table_List_ROW}=    Set Variable    ${History_TABLE}//div[@ng-repeat="req in requestList.list track by $index"][${Row_NUMBER}]
    ${dict}=    Create Dictionary    ${History_Table_Row_Sent_Data_Disabled_BUTTON}=${History_Table_List_ROW}//div[@class="tddiv rh-col5"]//button[@class="btn btn-primary ng-scope btn-slim disabled"]    ${History_Table_Row_Received_Data_Enabled_BUTTON}=${History_Table_List_ROW}//div[@class="tddiv rh-col6"]//button[@class="btn btn-primary ng-scope btn-slim "]    ${History_Table_Row_Execute_Request_BUTTON}=${History_Table_List_ROW}//div[@class="tddiv rh-col7"]//button[@ng-click="executeRequest()"]    ${History_Table_Row_Add_To_Collection_BUTTON}=${History_Table_List_ROW}//div[@class="tddiv rh-col7"]//div[@ng-click="showCollBox(req)"]    ${History_Table_Row_Fill_Data_Enabled_BUTTON}=${History_Table_List_ROW}//div[@class="tddiv rh-col7"]//button[@class="yangButton iconFillData "]
    ...    ${History_Table_Row_Delete_BUTTON}=${History_Table_List_ROW}//div[@class="tddiv rh-col7"]//button[@class="yangButton iconClose"]
    @{keys}=    Create List    ${History_Table_Row_Sent_Data_Disabled_BUTTON}    ${History_Table_Row_Received_Data_Enabled_BUTTON}    ${History_Table_Row_Execute_Request_BUTTON}    ${History_Table_Row_Add_To_Collection_BUTTON}    ${History_Table_Row_Fill_Data_Enabled_BUTTON}
    ...    ${History_Table_Row_Delete_BUTTON}
    : FOR    ${key}    IN    @{keys}
    \    ${value}=    Get From Dictionary    ${dict}    ${key}
    \    Run Keyword    Verify Element Presence In History Table Row    ${key}    ${value}

Open History Table Sent Data Box
    [Arguments]    ${row_number}
    [Documentation]    This keyword opens collection table nongroup sent data box.
    ${History_Table_List_ROW}=    Set Variable    ${History_TABLE}//div[@ng-repeat="req in requestList.list track by $index"][${row_number}]
    ${History_Table_Row_Sent_Data_Enabled_BUTTON}=    Set Variable    ${History_Table_List_ROW}//div[@class="tddiv rh-col5"]//button[@class="btn btn-primary ng-scope btn-slim "]
    ${History_Table_Sent_Data_BOX}=    Set Variable    ${History_Table_List_ROW}${Sent_Data_BOX}
    ${status}=    Run Keyword And Return Status    Page Should Contain Element    ${History_Table_Sent_Data_BOX}
    Run Keyword If    "${status}" == "False"    Click Element    ${History_Table_Row_Sent_Data_Enabled_BUTTON}
    Wait Until Page Contains Element    ${History_Table_Sent_Data_BOX}

Open History Table Received Data Box
    [Arguments]    ${row_number}
    [Documentation]    This keyword opens collection table nongroup sent data box.
    ${History_Table_List_ROW}=    Set Variable    ${History_TABLE}//div[@ng-repeat="req in requestList.list track by $index"][${row_number}]
    ${History_Table_Row_Received_Data_Enabled_BUTTON}=    Set Variable    ${History_Table_List_ROW}//div[@class="tddiv rh-col6"]//button[@class="btn btn-primary ng-scope btn-slim "]
    ${History_Table_Sent_Data_BOX}=    Set Variable    ${History_Table_List_ROW}${Sent_Data_BOX}
    ${status}=    Run Keyword And Return Status    Page Should Contain Element    ${History_Table_Sent_Data_BOX}
    Run Keyword If    "${status}" == "False"    Click Element    ${History_Table_Row_Received_Data_Enabled_BUTTON}
    Wait Until Page Contains Element    ${History_Table_Sent_Data_BOX}


Verify History Sent Data Box Elements
    [Arguments]    ${row_number}
    [Documentation]    This keyword verifies the presence of elements of History tab Sent data box.
    Open History Table Sent Data Box    ${row_number}
    ${History_Table_List_ROW}=    Set Variable    ${History_TABLE}//div[@ng-repeat="req in requestList.list track by $index"][${Row_NUMBER}]
    ${History_Table_Sent_Data_BOX}=    Set Variable    ${History_Table_List_ROW}${Sent_Data_BOX}    
    ${History_Table_Sent_Data_Box_Path_WRAPPER}=    Set Variable    ${History_Table_Sent_Data_BOX}${Sent_Data_Box_Path_WRAPPER}
    ${History_Table_Sent_Data_Box_Topology_Id_Path_Wrapper_INPUT}=    Set Variable    ${History_Table_Sent_Data_Box_Path_WRAPPER}${Sent_Data_Box_Topology_Id_Path_Wrapper_INPUT}
    ${History_Table_Sent_Data_Box_Node_Id_Path_Wrapper_INPUT}=    Set Variable    ${History_Table_Sent_Data_Box_Path_WRAPPER}${Sent_Data_Box_Node_Id_Path_Wrapper_INPUT}
    ${History_Table_Sent_Data_Box_Link_Id_Path_Wrapper_INPUT}=    Set Variable    ${History_Table_Sent_Data_Box_Path_WRAPPER}${Sent_Data_Box_Link_Id_Path_Wrapper_INPUT}
    ${History_Table_Sent_Data_Box_Copy_To_Clipboard_BUTTON}=    Set Variable    ${History_Table_Sent_Data_BOX}${Sent_Data_Box_Copy_To_Clipboard_BUTTON}
    ${History_Table_Sent_Data_Box_Reset_Parametrized_Data_BUTTON}=    Set Variable    ${History_Table_Sent_Data_BOX}${Sent_Data_Box_Reset_Parametrized_Data_BUTTON}
    ${History_Table_Sent_Data_Box_Save_Parametrized_Data_BUTTON}=    Set Variable    ${History_Table_Sent_Data_BOX}${Sent_Data_Box_Save_Parametrized_Data_BUTTON}
    ${History_Table_Sent_Data_Box_Close_BUTTON}=    Set Variable    ${History_Table_Sent_Data_BOX}${Sent_Data_Box_Close_BUTTON}
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


Insert String To History Sent Data Path Wrapper
    [Arguments]    ${row_number}    ${string_topo}    ${string_node}    ${string_link}
    [Documentation]    Will insert parameters to topology id and/or node id and/or link id path wrapper inputs in sent data box.
    Open History Table Sent Data Box    ${row_number}
    ${History_Table_List_ROW}=    Set Variable    ${History_TABLE}//div[@ng-repeat="req in requestList.list track by $index"][${Row_NUMBER}]
    ${History_Table_Sent_Data_BOX}=    Set Variable    ${History_Table_List_ROW}${Sent_Data_BOX}    
    ${History_Table_Sent_Data_Box_Path_WRAPPER}=    Set Variable    ${History_Table_Sent_Data_BOX}${Sent_Data_Box_Path_WRAPPER}
    ${History_Table_Sent_Data_Box_Topology_Id_Path_Wrapper_INPUT}=    Set Variable    ${History_Table_Sent_Data_Box_Path_WRAPPER}${Sent_Data_Box_Topology_Id_Path_Wrapper_INPUT}
    ${History_Table_Sent_Data_Box_Node_Id_Path_Wrapper_INPUT}=    Set Variable    ${History_Table_Sent_Data_Box_Path_WRAPPER}${Sent_Data_Box_Node_Id_Path_Wrapper_INPUT}
    ${History_Table_Sent_Data_Box_Link_Id_Path_Wrapper_INPUT}=    Set Variable    ${History_Table_Sent_Data_Box_Path_WRAPPER}${Sent_Data_Box_Link_Id_Path_Wrapper_INPUT}
    ${dict}=    Create Dictionary    ${string_topo}=${History_Table_Sent_Data_Box_Topology_Id_Path_Wrapper_INPUT}
    ...    ${string_node}=${History_Table_Sent_Data_Box_Node_Id_Path_Wrapper_INPUT}
    ...    ${string_link}=${History_Table_Sent_Data_Box_Link_Id_Path_Wrapper_INPUT}
    @{strings}=    Create List    ${string_topo}    ${string_node}    ${string_link}
    : FOR    ${string}    IN    @{strings}
    \    Run Keyword If    "${string}"=="${EMPTY}"    No Operation
    \    ${input_field}=    Get From Dictionary    ${dict}    ${string}
    \    Run Keyword If    "${string}"!="${EMPTY}"    Insert Text To Input Field    ${input_field}    ${string}


Insert Parameters To History Sent Data Path Wrapper
    [Arguments]    ${row_number}    ${param_name_topo}    ${param_name_node}    ${param_name_link}
    [Documentation]    Will insert parameters to topology id and/or node id and/or link id path wrapper inputs in sent data box.
    Open History Table Sent Data Box    ${row_number}
    ${History_Table_List_ROW}=    Set Variable    ${History_TABLE}//div[@ng-repeat="req in requestList.list track by $index"][${Row_NUMBER}]
    ${History_Table_Sent_Data_BOX}=    Set Variable    ${History_Table_List_ROW}${Sent_Data_BOX}    
    ${History_Table_Sent_Data_Box_Path_WRAPPER}=    Set Variable    ${History_Table_Sent_Data_BOX}${Sent_Data_Box_Path_WRAPPER}
    ${History_Table_Sent_Data_Box_Topology_Id_Path_Wrapper_INPUT}=    Set Variable    ${History_Table_Sent_Data_Box_Path_WRAPPER}${Sent_Data_Box_Topology_Id_Path_Wrapper_INPUT}
    ${History_Table_Sent_Data_Box_Node_Id_Path_Wrapper_INPUT}=    Set Variable    ${History_Table_Sent_Data_Box_Path_WRAPPER}${Sent_Data_Box_Node_Id_Path_Wrapper_INPUT}
    ${History_Table_Sent_Data_Box_Link_Id_Path_Wrapper_INPUT}=    Set Variable    ${History_Table_Sent_Data_Box_Path_WRAPPER}${Sent_Data_Box_Link_Id_Path_Wrapper_INPUT}
    ${dict}=    Create Dictionary    ${param_name_topo}=${History_Table_Sent_Data_Box_Topology_Id_Path_Wrapper_INPUT}
    ...    ${param_name_node}=${History_Table_Sent_Data_Box_Node_Id_Path_Wrapper_INPUT}
    ...    ${param_name_link}=${History_Table_Sent_Data_Box_Link_Id_Path_Wrapper_INPUT}
    @{param_names}=    Create List    ${param_name_topo}    ${param_name_node}    ${param_name_link}
    : FOR    ${param_name}    IN    @{param_names}
    \    ${param_key}    Return Parameter Key    ${param_name}
    \    Run Keyword If    "${param_name}"=="${EMPTY}"    No Operation
    \    ${input_field}=    Get From Dictionary    ${dict}    ${param_name}
    \    Run Keyword If    "${param_name}"!="${EMPTY}"    Insert Text To Input Field    ${input_field}    ${param_key}


Verify History Sent Box Data Presence In Code Mirror
    [Arguments]    ${row_number}    ${data}
    Open History Table Sent Data Box    ${row_number}
    ${History_Table_List_ROW}=    Set Variable    ${History_TABLE}//div[@ng-repeat="req in requestList.list track by $index"][${Row_NUMBER}]
    ${Sent_Data_Box_Code_Mirror_CODE}=    Set Variable    //div[@class="CodeMirror-lines"]//div[@class="CodeMirror-code"]//span[contains(., "${data}")]
    ${History_Table_Sent_Data_BOX}=    Set Variable    ${History_Table_List_ROW}${Sent_Data_BOX}
    ${History_Table_Sent_Data_Box_Code_Mirror_CODE}=    Set Variable    ${History_Table_Sent_Data_BOX}${Sent_Data_Box_Code_Mirror_CODE}
    Run Keyword If    "${data}"=="${EMPTY}"    No Operation    
    Run Keyword If    "${data}"!="${EMPTY}"    Page Should Contain Element    ${History_Table_Sent_Data_Box_Code_Mirror_CODE}    


Verify History Sent Box Data NONPresence In Code Mirror
    [Arguments]    ${row_number}    ${data}
    Open History Table Sent Data Box    ${row_number}
    ${History_Table_List_ROW}=    Set Variable    ${History_TABLE}//div[@ng-repeat="req in requestList.list track by $index"][${Row_NUMBER}]
    ${Sent_Data_Box_Code_Mirror_CODE}=    Set Variable    //div[@class="CodeMirror-lines"]//div[@class="CodeMirror-code"]//span[contains(., "${data}")]
    ${History_Table_Sent_Data_BOX}=    Set Variable    ${History_Table_List_ROW}${Sent_Data_BOX}
    ${History_Table_Sent_Data_Box_Code_Mirror_CODE}=    Set Variable    ${History_Table_Sent_Data_BOX}${Sent_Data_Box_Code_Mirror_CODE}
    Run Keyword If    "${data}"=="${EMPTY}"    No Operation    
    Run Keyword If    "${data}"!="${EMPTY}"    Page Should Not Contain Element    ${History_Table_Sent_Data_Box_Code_Mirror_CODE}    


Reset History Sent Box Parametrized Data  
    [Arguments]    ${row_number}
    ${History_Table_List_ROW}=    Set Variable    ${History_TABLE}//div[@ng-repeat="req in requestList.list track by $index"][${Row_NUMBER}]
    ${History_Table_Sent_Data_BOX}=    Set Variable    ${History_Table_List_ROW}${Sent_Data_BOX}
    ${History_Table_Sent_Data_Box_Reset_Parametrized_Data_BUTTON}=    Set Variable    ${History_Table_Sent_Data_BOX}${Sent_Data_Box_Reset_Parametrized_Data_BUTTON}
    Click Element    ${History_Table_Sent_Data_Box_Reset_Parametrized_Data_BUTTON}


Save History Sent Box Parametrized Data  
    [Arguments]    ${row_number}
    ${History_Table_List_ROW}=    Set Variable    ${History_TABLE}//div[@ng-repeat="req in requestList.list track by $index"][${Row_NUMBER}]
    ${History_Table_Sent_Data_BOX}=    Set Variable    ${History_Table_List_ROW}${Sent_Data_BOX}
    ${History_Table_Sent_Data_Box_Save_Parametrized_Data_BUTTON}=    Set Variable    ${History_Table_Sent_Data_BOX}${Sent_Data_Box_Save_Parametrized_Data_BUTTON}
    Click Element    ${History_Table_Sent_Data_Box_Save_Parametrized_Data_BUTTON}
        

Close History Sent Data Box
    [Arguments]    ${Row_NUMBER}
    [Documentation]    This keyword verifies the presence of elements of History tab Sent data box.
    ${Row_NUMBER}=    Set Variable    ${row_number}
    ${History_Table_List_ROW}=    Set Variable    ${History_TABLE}//div[@ng-repeat="req in requestList.list track by $index"][${Row_NUMBER}]
    ${History_Table_Sent_Data_BOX}=    Set Variable    ${History_Table_List_ROW}${Sent_Data_BOX}
    ${History_Table_Sent_Data_Box_Close_BUTTON}=    Set Variable    ${History_Table_Sent_Data_BOX}${Sent_Data_Box_Close_BUTTON}
    Click Element    ${History_Table_Sent_Data_Box_Close_BUTTON}
    Wait Until Page Does Not Contain Element    ${History_Table_Sent_Data_BOX}
    
    
Close History Sent Data Box And Clear History Data
    [Arguments]    ${Row_NUMBER}
    [Documentation]    This keyword verifies the presence of elements of History tab Sent data box.
    ${Row_NUMBER}=    Set Variable    ${row_number}
    ${History_Table_List_ROW}=    Set Variable    ${History_TABLE}//div[@ng-repeat="req in requestList.list track by $index"][${Row_NUMBER}]
    ${History_Table_Sent_Data_BOX}=    Set Variable    ${History_Table_List_ROW}${Sent_Data_BOX}
    ${History_Table_Sent_Data_Box_Close_BUTTON}=    Set Variable    ${History_Table_Sent_Data_BOX}${Sent_Data_Box_Close_BUTTON}
    Click Element    ${History_Table_Sent_Data_Box_Close_BUTTON}
    Wait Until Page Does Not Contain Element    ${History_Table_Sent_Data_BOX}
    If History Table Contains Data Then Clear History Data


Fill History Table Row Request To Form
    [Arguments]    ${row_number}
    ${Row_NUMBER}=    Set Variable    ${row_number}
    ${History_Table_List_ROW}=    Set Variable    ${History_TABLE}//div[@ng-repeat="req in requestList.list track by $index"][${Row_NUMBER}]
    ${History_Table_Row_Fill_Data_Enabled_BUTTON}=    Set Variable    ${History_Table_List_ROW}//div[@class="tddiv rh-col7"]//button[@class="yangButton iconFillData "]
    Patient Click Element    ${History_Table_Row_Fill_Data_Enabled_BUTTON}    4


Return History Table Row Number
    [Arguments]    ${row_number}
    ${Row_NUMBER}=    Set Variable    ${row_number}
    ${History_Table_List_ROW}=    Set Variable    ${History_TABLE}//div[@ng-repeat="req in requestList.list track by $index"][${Row_NUMBER}]
    [Return]    ${History_Table_List_ROW}


Click History Table Execute Request Button In Row
    [Arguments]    ${row_number}
    ${History_Table_List_ROW}=    Return History Table Row Number    ${row_number}
    ${History_Table_Row_Execute_Request_BUTTON}=    Set Variable    ${History_Table_List_ROW}//div[@class="tddiv rh-col7"]//button[@ng-click="executeRequest()"]
    Patient Click Element    ${History_Table_Row_Execute_Request_BUTTON}    4


Click History Table Delete Request Button In Row
    [Arguments]    ${row_number}
    ${History_Table_List_ROW}=    Return History Table Row Number    ${row_number}
    ${History_Table_Row_Delete_BUTTON}=    Set Variable    ${History_Table_List_ROW}//div[@class="tddiv rh-col7"]//button[@class="yangButton iconClose"]
    Wait Until Page Contains Element    ${History_Table_Row_Delete_BUTTON}
    Focus    ${History_Table_Row_Delete_BUTTON}
    Patient Click Element    ${History_Table_Row_Delete_BUTTON}    4


If History Table Contains Data Then Clear History Data
    ${Row_NUMBER}=    Set Variable    1
    ${History_Table_List_ROW}=    Set Variable    ${History_TABLE}//div[@ng-repeat="req in requestList.list track by $index"][${Row_NUMBER}]
    ${status}=    Run Keyword And Return Status    Page Should Contain Element    ${History_Table_List_ROW}
    Run Keyword If    "${status}"=="True"    Click Element    ${Clear_History_Data_BUTTON}
    Wait Until Page Does Not Contain Element    ${History_Table_List_ROW}    


### COLLECTION TAB ###

Click Add To Collection Button
    [Arguments]    ${Row_NUMBER}
    [Documentation]    This keyword adds request in given row to collection.
    ${History_Table_List_ROW}=    Return History Table Row Number    ${Row_NUMBER}
    ${History_Table_Row_Add_To_Collection_BUTTON}=    Set Variable    ${History_Table_List_ROW}//div[@class="tddiv rh-col7"]//div[@ng-click="showCollBox(req)"]
    Patient Click Element    ${History_Table_Row_Add_To_Collection_BUTTON}    4

Return Collection Table Nongroup Row Number
    [Arguments]    ${row_number}
    ${Row_NUMBER}=    Set Variable    ${row_number}
    ${Collection_Table_List_Nongroup_ROW}=    Set Variable    ${Collection_TABLE}//div[@ng-repeat="req in collectionList.ungrouped track by $index"][${Row_NUMBER}]
    [Return]    ${Collection_Table_List_Nongroup_ROW}

Verify Collection Table Nongroup Row Presence
    [Arguments]    ${row_number}
    ${Collection_Table_List_Nongroup_ROW}=    Return Collection Table Nongroup Row Number    ${row_number}
    ${status}=    Run Keyword And Return Status    Page Should Contain Element    ${Collection_Table_List_Nongroup_ROW}
    [Return]    ${status}

Return Collection Table Group Number
    [Arguments]    ${group_number}
    ${Group_NUMBER}=    Set Variable    ${group_number}
    ${Collection_Table_List_GROUP}=    Set Variable    ${Collection_TABLE}//div[contains(@ng-repeat, "in collectionList.groups track by $index")][${Group_NUMBER}]
    [Return]    ${Collection_Table_List_GROUP}

Verify Collection Table Group Presence
    [Arguments]    ${group_number}
    ${Collection_Table_List_GROUP}=    Return Collection Table Group Number    ${group_number}
    ${status}=    Run Keyword And Return Status    Page Should Contain Element    ${Collection_Table_List_GROUP}
    [Return]    ${status}

Return Collection Table Group Row Number
    [Arguments]    ${group_number}    ${row_number}
    ${Collection_Table_List_GROUP}=    Return Collection Table Group Number    ${group_number}
    ${Row_NUMBER}=    Set Variable    ${row_number}
    ${Collection_Table_List_Group_ROW}=    Set Variable    ${Collection_Table_List_GROUP}//section[@class="trdiv groupList ng-scope"][${Row_NUMBER}]
    [Return]    ${Collection_Table_List_Group_ROW}

Return Collection Table Nongroup Row Url
    [Arguments]    ${row_number}
    ${Collection_Table_List_Nongroup_ROW}=    Return Collection Table Nongroup Row Number    ${row_number}
    ${Collection_Table_Nongroup_Row_Url_XPATH}=    Set Variable    ${Collection_Table_List_Nongroup_ROW}//div[@class="tddiv rh-col3c"]/span
    ${url}=    Return Text From Element    ${Collection_Table_Nongroup_Row_Url_XPATH}
    [Return]    ${url}

Return Collection Table Group Row Url
    [Arguments]    ${group_number}    ${row_number}
    ${Collection_Table_List_Group_ROW}=    Return Collection Table Group Row Number    ${group_number}    ${row_number}
    ${Collection_Table_Group_Row_Url_XPATH}=    Set Variable    ${Collection_Table_List_Group_ROW}//div[@class="tddiv rh-col3c"]/span
    ${url}=    Return Text From Element    ${Collection_Table_Group_Row_Url_XPATH}
    [Return]    ${url}

Select Chosen Collection Group
    [Arguments]    ${select_group}
    [Documentation]    Will select desired collection group from group selectbox in add to collection box.
    ${Add_To_Collection_Box_Select_Group_Select_OPTION}=    Set Variable    ${Add_To_Collection_Box_Select_Group_SELECT}//option[contains(., "${select_group}")]
    Click Element    ${Add_To_Collection_Box_Select_Group_SELECT}
    Wait Until Page Contains Element    ${Add_To_Collection_Box_Select_Group_Select_OPTION}
    Focus    ${Add_To_Collection_Box_Select_Group_Select_OPTION}
    Sleep    2
    Click Element    ${Add_To_Collection_Box_Select_Group_Select_OPTION}
    Sleep    2
    Click Element    ${Add_To_Collection_Box_Select_Group_LABEL}

Fill Add To Collection Box
    [Arguments]    ${name}    ${select_group}    ${new_group}
    Insert Text To Input Field    ${Add_To_Collection_Box_Name_INPUT}    ${name}
    Delete Text From Input Field    ${Add_To_Collection_Box_Group_Name_New_INPUT}
    ${status_1}=    Run Keyword And Return Status    Should Be Equal As Strings    ${select_group}    ${Select_Option}
    ${status_2}=    Run Keyword And Return Status    Should Be Equal As Strings    ${new_group}    ${EMPTY}
    ${status_1_str}=    Convert To String    ${status_1}
    ${status_2_str}=    Convert To String    ${status_2}
    @{statuses}=    Create List    ${status_1_str}    ${status_2_str}
    @{true_true}=    Create List    True    True
    @{true_false}=    Create List    True    False
    @{false_true}=    Create List    False    True
    ${comp_1}=    Run Keyword And Return Status    Lists Should Be Equal    ${statuses}    ${true_true}
    ${comp_2}=    Run Keyword And Return Status    Lists Should Be Equal    ${statuses}    ${true_false}
    ${comp_3}=    Run Keyword And Return Status    Lists Should Be Equal    ${statuses}    ${false_true}
    Run Keyword If    "${comp_1}" == "True"    Run Keyword    Focus    ${Add_To_Collection_Box_Add_BUTTON}
    Run Keyword If    "${comp_2}" == "True"    Run Keywords    Insert Text To Input Field    ${Add_To_Collection_Box_Group_Name_New_INPUT}    ${new_group}    AND
    ...    Focus    ${Add_To_Collection_Box_Add_BUTTON}
    Run Keyword If    "${comp_3}" == "True"    Run Keywords    Select Chosen Collection Group    ${select_group}    AND    Focus
    ...    ${Add_To_Collection_Box_Add_BUTTON}

Add Request To Collection
    [Arguments]    ${Row_NUMBER}    ${name}    ${select_group}    ${new_group}
    [Documentation]    Will add given request in selected row to collection.
    Click Add To Collection Button    ${Row_NUMBER}
    Wait Until Page Contains Element    ${Add_To_Collection_Box_Name_INPUT}
    Fill Add To Collection Box    ${name}    ${select_group}    ${new_group}

Verify Collection Table Nongroup Row Content
    [Arguments]    ${Row_NUMBER}    ${Method_NAME}    ${name}    ${Request_Status}
    [Documentation]    This keyword verifies the occurence elements in Collection tab, nongroup rows.
    ${Collection_Table_List_Nongroup_ROW}=    Return Collection Table Nongroup Row Number    ${Row_NUMBER}
    ${Collection_Table_Nongroup_Row_Method_Name_XPATH}=    Set Variable    ${Collection_Table_List_Nongroup_ROW}//div[@class="tddiv rh-col2"]/span[text()="${Method_Name}"]
    Page Should Contain Element    ${Collection_Table_Nongroup_Row_Method_Name_XPATH}
    ${Collection_Table_Nongroup_Row_Name_XPATH}=    Set Variable    ${Collection_Table_List_Nongroup_ROW}//div[@class="tddiv rh-col8"]/span
    Page Should Contain Element    ${Collection_Table_Nongroup_Row_Name_XPATH}
    Wait Until Element Is Visible    ${Collection_Table_Nongroup_Row_Name_XPATH}
    ${got_name}=    Get Text    ${Collection_Table_Nongroup_Row_Name_XPATH}
    ${got_name_2}=    Remove Leading And Trailing Spaces    ${got_name}
    Should Be Equal As Strings    ${name}    ${got_name_2}
    ${Collection_Table_Nongroup_Row_Status_XPATH}=    Set Variable    ${Collection_Table_List_Nongroup_ROW}//div[@class="tddiv rh-col4"]/span
    ${status}=    Get Text    ${Collection_Table_Nongroup_Row_Status_XPATH}
    Should Be Equal As Strings    ${status}    ${Request_Status}

Verify Collection Table Nongroup Row Content NONPresence
    [Arguments]    ${Row_NUMBER}    ${Method_NAME}    ${name}    ${Request_Status}
    [Documentation]    This keyword verifies the nonpresence of elements in Collection tab, nongroup rows.
    ${Collection_Table_List_Nongroup_ROW}=    Return Collection Table Nongroup Row Number    ${Row_NUMBER}
    ${Collection_Table_Nongroup_Row_Method_Name_XPATH}=    Set Variable    ${Collection_Table_List_Nongroup_ROW}//div[@class="tddiv rh-col2"]/span[text()="${Method_Name}"]
    Page Should Not Contain Element    ${Collection_Table_Nongroup_Row_Method_Name_XPATH}
    ${Collection_Table_Nongroup_Row_Name_XPATH}=    Set Variable    ${Collection_Table_List_Nongroup_ROW}//div[@class="tddiv rh-col8"]/span
    Page Should Contain Element    ${Collection_Table_Nongroup_Row_Name_XPATH}
    ${got_name}=    Get Text    ${Collection_Table_Nongroup_Row_Name_XPATH}
    ${got_name_2}=    Remove Leading And Trailing Spaces    ${got_name}
    Should Not Be Equal As Strings    ${name}    ${got_name_2}

Expand Collection Table Group Expander
    [Arguments]    ${Group_NUMBER}    ${Group_NAME}    ${Row_NUMBER}
    [Documentation]    If the page contains collection group but no record of the group is displayed,
    ...    the keyword will expand collection group expander.
    ${Collection_Table_List_GROUP}=    Return Collection Table Group Number    ${Group_NUMBER}
    ${Collection_Table_List_Group_EXPANDER}=    Set Variable    ${Collection_Table_List_GROUP}//section[contains(@ng-click, "toggleExpanded(key)") and contains(., "${Group_NAME}")]
    Page Should Contain Element    ${Collection_Table_List_Group_EXPANDER}
    ${Collection_Table_List_Group_ROW}=    Return Collection Table Group Row Number    ${Group_NUMBER}    ${Row_NUMBER}
    ${status}=    Run Keyword And Return Status    Page Should Contain Element    ${Collection_Table_List_Group_ROW}
    Run Keyword If    "${status}" == "False"    Run Keywords    Focus    ${Collection_Table_List_Group_EXPANDER}    AND    Click Element
    ...    ${Collection_Table_List_Group_EXPANDER}    AND    Wait Until Page Contains Element    ${Collection_Table_List_Group_ROW}

Verify Collection Table Group Row Content
    [Arguments]    ${Group_NUMBER}    ${Row_NUMBER}    ${Method_NAME}    ${name}    ${Request_Status}
    [Documentation]    This keyword verifies the occurence elements in Collection tab, group rows.
    ${Collection_Table_List_Group_ROW}=    Return Collection Table Group Row Number    ${Group_NUMBER}    ${Row_NUMBER}
    ${Collection_Table_Group_Row_Method_Name_XPATH}=    Set Variable    ${Collection_Table_List_Group_ROW}//div[@class="tddiv rh-col2"]/span[text()="${Method_Name}"]
    Page Should Contain Element    ${Collection_Table_Group_Row_Method_Name_XPATH}
    ${got_name}=    Get Text    ${Collection_Table_List_Group_ROW}//div[@class="tddiv rh-col8"]/span
    ${got_name_2}=    Remove Leading And Trailing Spaces    ${got_name}
    Should Be Equal As Strings    ${name}    ${got_name_2}
    ${Collection_Table_Group_Row_Status_XPATH}=    Set Variable    ${Collection_Table_List_Group_ROW}//div[@class="tddiv rh-col4"]/span
    ${status}=    Get Text    ${Collection_Table_Group_Row_Status_XPATH}
    Should Be Equal As Strings    ${status}    ${Request_Status}

Verify Collection Table Group Row Content NONPresence
    [Arguments]    ${Group_NUMBER}    ${Row_NUMBER}    ${Method_NAME}    ${name}    ${Request_Status}
    [Documentation]    This keyword verifies the nonpresence of elements in Collection tab, group rows.
    ${Collection_Table_List_Group_ROW}=    Return Collection Table Group Row Number    ${Group_NUMBER}    ${Row_NUMBER}
    ${Collection_Table_Group_Row_Name_XPATH}=    Set Variable    ${Collection_Table_List_Group_ROW}//div[@class="tddiv rh-col8"]/span
    Page Should Contain Element    ${Collection_Table_Group_Row_Name_XPATH}
    ${got_name}=    Get Text    ${Collection_Table_Group_Row_Name_XPATH}
    ${got_name_2}=    Remove Leading And Trailing Spaces    ${got_name}
    Should Not Be Equal As Strings    ${name}    ${got_name_2}

Verify Element Presence In Collection Table Row
    [Arguments]    ${Element}    ${Element_Xpath}
    [Documentation]    This keyword sets D/E button variable and verifies its presence on the page.
    ${Element} =    Set Variable    ${Element_Xpath}
    Page Should Contain Element    ${Element}
    Sleep    1

Verify No Sent No Received Data Elements Presence In Collection Table Nongroup Row
    [Arguments]    ${row_number}
    [Documentation]    This keyword verifies the presence of elements in Collection table associated with unsuccessfully executed operation.
    ${Collection_Table_List_Nongroup_ROW}=    Return Collection Table Nongroup Row Number    ${row_number}
    ${dict}=    Create Dictionary    ${Collection_Table_Nongroup_Row_Sent_Data_Disabled_BUTTON}=${Collection_Table_List_Nongroup_ROW}//div[@class="tddiv rh-col5"]//button[@class="btn btn-primary ng-scope btn-slim disabled"]    ${Collection_Table_Nongroup_Row_Received_Data_Disabled_BUTTON}=${Collection_Table_List_Nongroup_ROW}//div[@class="tddiv rh-col6"]//button[@class="btn btn-primary ng-scope btn-slim disabled"]    ${Collection_Table_Nongroup_Row_Execute_Request_BUTTON}=${Collection_Table_List_Nongroup_ROW}//div[@class="tddiv rh-col7"]//button[contains(@ng-click, "executeCollectionRequest")]    ${Collection_Table_Nongroup_Row_Fill_Data_Disabled_BUTTON}=${Collection_Table_List_Nongroup_ROW}//div[@class="tddiv rh-col7"]//button[@class="yangButton iconFillData disabled"]    ${Collection_Table_Nongroup_Row_Move_To_Group_BUTTON}=${Collection_Table_List_Nongroup_ROW}//div[@class="tddiv rh-col7"]//div[contains(@ng-click, "showCollBox")]
    ...    ${Collection_Table_Nongroup_Row_Delete_BUTTON}=${Collection_Table_List_Nongroup_ROW}//div[@class="tddiv rh-col7"]//button[@class="yangButton iconClose"]
    @{keys}=    Create List    ${Collection_Table_Nongroup_Row_Sent_Data_Disabled_BUTTON}    ${Collection_Table_Nongroup_Row_Received_Data_Disabled_BUTTON}    ${Collection_Table_Nongroup_Row_Execute_Request_BUTTON}    ${Collection_Table_Nongroup_Row_Fill_Data_Disabled_BUTTON}    ${Collection_Table_Nongroup_Row_Move_To_Group_BUTTON}
    ...    ${Collection_Table_Nongroup_Row_Delete_BUTTON}
    : FOR    ${key}    IN    @{keys}
    \    ${value}=    Get From Dictionary    ${dict}    ${key}
    \    Run Keyword    Verify Element Presence In Collection Table Row    ${key}    ${value}

Verify No Sent No Received Data Elements Presence In Collection Table Group Row
    [Arguments]    ${group_number}    ${row_number}
    [Documentation]    This keyword verifies the presence of elements in Collection table associated with unsuccessfully executed operation.
    ${Collection_Table_List_Group_ROW}=    Return Collection Table Group Row Number    ${group_number}    ${row_number}
    ${dict}=    Create Dictionary    ${Collection_Table_Group_Row_Sent_Data_Disabled_BUTTON}=${Collection_Table_List_Group_ROW}//div[@class="tddiv rh-col5"]//button[@class="btn btn-primary ng-scope btn-slim disabled"]    ${Collection_Table_Group_Row_Received_Data_Disabled_BUTTON}=${Collection_Table_List_Group_ROW}//div[@class="tddiv rh-col6"]//button[@class="btn btn-primary ng-scope btn-slim disabled"]    ${Collection_Table_Group_Row_Execute_Request_BUTTON}=${Collection_Table_List_Group_ROW}//div[@class="tddiv rh-col7"]//button[contains(@ng-click, "executeCollectionRequest")]    ${Collection_Table_Group_Row_Fill_Data_Disabled_BUTTON}=${Collection_Table_List_Group_ROW}//div[@class="tddiv rh-col7"]//button[@class="yangButton iconFillData disabled"]    ${Collection_Table_Group_Row_Move_To_Group_BUTTON}=${Collection_Table_List_Group_ROW}//div[@class="tddiv rh-col7"]//div[contains(@ng-click, "showCollBox")]
    ...    ${Collection_Table_Group_Row_Delete_BUTTON}=${Collection_Table_List_Group_ROW}//div[@class="tddiv rh-col7"]//button[@class="yangButton iconClose"]
    @{keys}=    Create List    ${Collection_Table_Group_Row_Sent_Data_Disabled_BUTTON}    ${Collection_Table_Group_Row_Received_Data_Disabled_BUTTON}    ${Collection_Table_Group_Row_Execute_Request_BUTTON}    ${Collection_Table_Group_Row_Fill_Data_Disabled_BUTTON}    ${Collection_Table_Group_Row_Move_To_Group_BUTTON}
    ...    ${Collection_Table_Group_Row_Delete_BUTTON}
    : FOR    ${key}    IN    @{keys}
    \    ${value}=    Get From Dictionary    ${dict}    ${key}
    \    Run Keyword    Verify Element Presence In Collection Table Row    ${key}    ${value}

Verify Sent Data Elements Presence In Collection Table Nongroup Row
    [Arguments]    ${row_number}
    [Documentation]    This keyword verifies the presence of elements in Collection table associated with succesfully executed Put/ Post operation.
    ${Collection_Table_List_Nongroup_ROW}=    Return Collection Table Nongroup Row Number    ${row_number}
    ${dict}=    Create Dictionary    ${Collection_Table_Nongroup_Row_Sent_Data_Enabled_BUTTON}=${Collection_Table_List_Nongroup_ROW}//div[@class="tddiv rh-col5"]//button[@class="btn btn-primary ng-scope btn-slim "]    ${Collection_Table_Nongroup_Row_Received_Data_Disabled_BUTTON}=${Collection_Table_List_Nongroup_ROW}//div[@class="tddiv rh-col6"]//button[@class="btn btn-primary ng-scope btn-slim disabled"]    ${Collection_Table_Nongroup_Row_Execute_Request_BUTTON}=${Collection_Table_List_Nongroup_ROW}//div[@class="tddiv rh-col7"]//button[contains(@ng-click, "executeCollectionRequest")]    ${Collection_Table_Nongroup_Row_Fill_Data_Enabled_BUTTON}=${Collection_Table_List_Nongroup_ROW}//div[@class="tddiv rh-col7"]//button[@class="yangButton iconFillData "]    ${Collection_Table_Nongroup_Row_Move_To_Group_BUTTON}=${Collection_Table_List_Nongroup_ROW}//div[@class="tddiv rh-col7"]//div[contains(@ng-click, "showCollBox")]
    ...    ${Collection_Table_Nongroup_Row_Delete_BUTTON}=${Collection_Table_List_Nongroup_ROW}//div[@class="tddiv rh-col7"]//button[@class="yangButton iconClose"]
    @{keys}=    Create List    ${Collection_Table_Nongroup_Row_Sent_Data_Enabled_BUTTON}    ${Collection_Table_Nongroup_Row_Received_Data_Disabled_BUTTON}    ${Collection_Table_Nongroup_Row_Execute_Request_BUTTON}    ${Collection_Table_Nongroup_Row_Fill_Data_Enabled_BUTTON}    ${Collection_Table_Nongroup_Row_Move_To_Group_BUTTON}
    ...    ${Collection_Table_Nongroup_Row_Delete_BUTTON}
    : FOR    ${key}    IN    @{keys}
    \    ${value}=    Get From Dictionary    ${dict}    ${key}
    \    Run Keyword    Verify Element Presence In Collection Table Row    ${key}    ${value}

Verify Sent Data Elements Presence In Collection Table Group Row
    [Arguments]    ${group_number}    ${row_number}
    [Documentation]    This keyword verifies the presence of elements in Collection table associated with succesfully executed Put/ Post operation.
    ${Collection_Table_List_Group_ROW}=    Return Collection Table Group Row Number    ${group_number}    ${row_number}
    ${dict}=    Create Dictionary    ${Collection_Table_Group_Row_Sent_Data_Enabled_BUTTON}=${Collection_Table_List_Group_ROW}//div[@class="tddiv rh-col5"]//button[@class="btn btn-primary ng-scope btn-slim "]    ${Collection_Table_Group_Row_Received_Data_Disabled_BUTTON}=${Collection_Table_List_Group_ROW}//div[@class="tddiv rh-col6"]//button[@class="btn btn-primary ng-scope btn-slim disabled"]    ${Collection_Table_Group_Row_Execute_Request_BUTTON}=${Collection_Table_List_Group_ROW}//div[@class="tddiv rh-col7"]//button[contains(@ng-click, "executeCollectionRequest")]    ${Collection_Table_Group_Row_Fill_Data_Enabled_BUTTON}=${Collection_Table_List_Group_ROW}//div[@class="tddiv rh-col7"]//button[@class="yangButton iconFillData "]    ${Collection_Table_Group_Row_Move_To_Group_BUTTON}=${Collection_Table_List_Group_ROW}//div[@class="tddiv rh-col7"]//div[contains(@ng-click, "showCollBox")]
    ...    ${Collection_Table_Group_Row_Delete_BUTTON}=${Collection_Table_List_Group_ROW}//div[@class="tddiv rh-col7"]//button[@class="yangButton iconClose"]
    @{keys}=    Create List    ${Collection_Table_Group_Row_Sent_Data_Enabled_BUTTON}    ${Collection_Table_Group_Row_Received_Data_Disabled_BUTTON}    ${Collection_Table_Group_Row_Execute_Request_BUTTON}    ${Collection_Table_Group_Row_Fill_Data_Enabled_BUTTON}    ${Collection_Table_Group_Row_Move_To_Group_BUTTON}
    ...    ${Collection_Table_Group_Row_Delete_BUTTON}
    : FOR    ${key}    IN    @{keys}
    \    ${value}=    Get From Dictionary    ${dict}    ${key}
    \    Run Keyword    Verify Element Presence In Collection Table Row    ${key}    ${value}

Verify Received Data Elements Presence In Collection Table Nongroup Row
    [Arguments]    ${row_number}
    [Documentation]    This keyword verifies the presence of elements in Collection table associated with succesfully executed Get operation.
    ${Collection_Table_List_Nongroup_ROW}=    Return Collection Table Nongroup Row Number    ${row_number}
    ${dict}=    Create Dictionary    ${Collection_Table_Nongroup_Row_Sent_Data_Disabled_BUTTON}=${Collection_Table_List_Nongroup_ROW}//div[@class="tddiv rh-col5"]//button[@class="btn btn-primary ng-scope btn-slim disabled"]    ${Collection_Table_Nongroup_Row_Received_Data_Enabled_BUTTON}=${Collection_Table_List_Nongroup_ROW}//div[@class="tddiv rh-col6"]//button[@class="btn btn-primary ng-scope btn-slim "]    ${Collection_Table_Nongroup_Row_Execute_Request_BUTTON}=${Collection_Table_List_Nongroup_ROW}//div[@class="tddiv rh-col7"]//button[contains(@ng-click, "executeCollectionRequest")]    ${Collection_Table_Nongroup_Row_Fill_Data_Enabled_BUTTON}=${Collection_Table_List_Nongroup_ROW}//div[@class="tddiv rh-col7"]//button[@class="yangButton iconFillData "]    ${Collection_Table_Nongroup_Row_Move_To_Group_BUTTON}=${Collection_Table_List_Nongroup_ROW}//div[@class="tddiv rh-col7"]//div[contains(@ng-click, "showCollBox")]
    ...    ${Collection_Table_Nongroup_Row_Delete_BUTTON}=${Collection_Table_List_Nongroup_ROW}//div[@class="tddiv rh-col7"]//button[@class="yangButton iconClose"]
    @{keys}=    Create List    ${Collection_Table_Nongroup_Row_Sent_Data_Disabled_BUTTON}    ${Collection_Table_Nongroup_Row_Received_Data_Enabled_BUTTON}    ${Collection_Table_Nongroup_Row_Execute_Request_BUTTON}    ${Collection_Table_Nongroup_Row_Fill_Data_Enabled_BUTTON}    ${Collection_Table_Nongroup_Row_Move_To_Group_BUTTON}
    ...    ${Collection_Table_Nongroup_Row_Delete_BUTTON}
    : FOR    ${key}    IN    @{keys}
    \    ${value}=    Get From Dictionary    ${dict}    ${key}
    \    Run Keyword    Verify Element Presence In Collection Table Row    ${key}    ${value}

Verify Received Data Elements Presence In Collection Table Group Row
    [Arguments]    ${group_number}    ${row_number}
    [Documentation]    This keyword verifies the presence of elements in Collection table associated with succesfully executed Get operation.
    ${Collection_Table_List_Group_ROW}=    Return Collection Table Group Row Number    ${group_number}    ${row_number}
    ${dict}=    Create Dictionary    ${Collection_Table_Group_Row_Sent_Data_Disabled_BUTTON}=${Collection_Table_List_Group_ROW}//div[@class="tddiv rh-col5"]//button[@class="btn btn-primary ng-scope btn-slim disabled"]    ${Collection_Table_Group_Row_Received_Data_Enabled_BUTTON}=${Collection_Table_List_Group_ROW}//div[@class="tddiv rh-col6"]//button[@class="btn btn-primary ng-scope btn-slim "]    ${Collection_Table_Group_Row_Execute_Request_BUTTON}=${Collection_Table_List_Group_ROW}//div[@class="tddiv rh-col7"]//button[contains(@ng-click, "executeCollectionRequest")]    ${Collection_Table_Group_Row_Fill_Data_Enabled_BUTTON}=${Collection_Table_List_Group_ROW}//div[@class="tddiv rh-col7"]//button[@class="yangButton iconFillData "]    ${Collection_Table_Group_Row_Move_To_Group_BUTTON}=${Collection_Table_List_Group_ROW}//div[@class="tddiv rh-col7"]//div[contains(@ng-click, "showCollBox")]
    ...    ${Collection_Table_Group_Row_Delete_BUTTON}=${Collection_Table_List_Group_ROW}//div[@class="tddiv rh-col7"]//button[@class="yangButton iconClose"]
    @{keys}=    Get Dictionary Keys    ${dict}
    : FOR    ${key}    IN    @{keys}
    \    ${value}=    Get From Dictionary    ${dict}    ${key}
    \    Run Keyword    Verify Element Presence In Collection Table Row    ${key}    ${value}

Open Collection Table Nongroup Sent Data Box
    [Arguments]    ${row_number}
    [Documentation]    This keyword opens collection table nongroup sent data box.
    ${Collection_Table_List_Nongroup_ROW}=    Return Collection Table Nongroup Row Number    ${row_number}
    ${Collection_Table_Nongroup_Row_Sent_Data_Enabled_BUTTON}    Set Variable    ${Collection_Table_List_Nongroup_ROW}//div[@class="tddiv rh-col5"]//button[@class="btn btn-primary ng-scope btn-slim "]
    ${Collection_Table_Nongroup_Row_Sent_Data_BOX}=    Set Variable    ${Collection_Table_List_Nongroup_ROW}${Sent_Data_BOX}
    ${status}=    Run Keyword And Return Status    Page Should Contain Element    ${Collection_Table_List_Nongroup_ROW}${Sent_Data_BOX}
    Run Keyword If    "${status}" == "False"    Click Element    ${Collection_Table_Nongroup_Row_Sent_Data_Enabled_BUTTON}
    Wait Until Page Contains Element    ${Collection_Table_Nongroup_Row_Sent_Data_BOX}

Open Collection Table Group Sent Data Box
    [Arguments]    ${group_number}    ${row_number}
    ${Collection_Table_List_Group_ROW}=    Return Collection Table Group Row Number    ${group_number}    ${row_number}
    ${Collection_Table_Group_Row_Sent_Data_Enabled_BUTTON}=    Set Variable    ${Collection_Table_List_Group_ROW}//div[@class="tddiv rh-col5"]//button[@class="btn btn-primary ng-scope btn-slim "]
    ${Collection_Table_Group_Row_Sent_Data_BOX}=    Set Variable    ${Collection_Table_List_Group_ROW}${Sent_Data_BOX}
    ${status}=    Run Keyword And Return Status    Page Should Contain Element    ${Collection_Table_List_Group_ROW}${Sent_Data_BOX}
    Run Keyword If    "${status}" == "False"    Click Element    ${Collection_Table_Group_Row_Sent_Data_Enabled_BUTTON}
    Wait Until Page Contains Element    ${Collection_Table_Group_Row_Sent_Data_BOX}

Verify Elements Of Nongroup Row Sent Data Box
    [Arguments]    ${row_number}
    [Documentation]    This keyword verifies presence of the elements of sent data box.
    ${Collection_Table_List_Nongroup_ROW}=    Return Collection Table Nongroup Row Number    ${row_number}
    Open Collection Table Nongroup Sent Data Box    ${row_number}
    ${Collection_Table_Nongroup_Row_Sent_Data_BOX}=    Set Variable    ${Collection_Table_List_Nongroup_ROW}${Sent_Data_BOX}
    ${Collection_Table_Nongroup_Row_Sent_Data_Box_Path_WRAPPER}=    Set Variable    ${Collection_Table_Nongroup_Row_Sent_Data_BOX}${Sent_Data_Box_Path_WRAPPER}
    ${Collection_Table_Nongroup_Row_Sent_Data_Box_Copy_To_Clipboard_BUTTON}=    Set Variable    ${Collection_Table_Nongroup_Row_Sent_Data_BOX}${Sent_Data_Box_Copy_To_Clipboard_BUTTON}
    ${Collection_Table_Nongroup_Row_Sent_Data_Box_Reset_Parametrized_Data_BUTTON}=    Set Variable    ${Collection_Table_Nongroup_Row_Sent_Data_BOX}${Sent_Data_Box_Reset_Parametrized_Data_BUTTON}
    ${Collection_Table_Nongroup_Row_Sent_Data_Box_Save_Parametrized_Data_BUTTON}=    Set Variable    ${Collection_Table_Nongroup_Row_Sent_Data_BOX}${Sent_Data_Box_Save_Parametrized_Data_BUTTON}
    ${Collection_Table_Nongroup_Row_Sent_Data_Box_Close_BUTTON}=    Set Variable    ${Collection_Table_Nongroup_Row_Sent_Data_BOX}${Sent_Data_Box_Close_BUTTON}
    Page Should Contain Element    ${Collection_Table_Nongroup_Row_Sent_Data_Box_Path_WRAPPER}
    Page Should Contain Element    ${Collection_Table_Nongroup_Row_Sent_Data_Box_Copy_To_Clipboard_BUTTON}
    Page Should Contain Element    ${Collection_Table_Nongroup_Row_Sent_Data_Box_Reset_Parametrized_Data_BUTTON}
    Page Should Contain Element    ${Collection_Table_Nongroup_Row_Sent_Data_Box_Save_Parametrized_Data_BUTTON}
    Page Should Contain Element    ${Collection_Table_Nongroup_Row_Sent_Data_Box_Close_BUTTON}

Verify Elements Of Group Row Sent Data Box
    [Arguments]    ${group_number}    ${row_number}
    [Documentation]    This keyword verifies presence of the elements of sent data box.
    ${Collection_Table_List_Group_ROW}=    Return Collection Table Group Row Number    ${group_number}    ${row_number}
    ${Collection_Table_Group_Row_Sent_Data_Enabled_BUTTON}=    Set Variable    ${Collection_Table_List_Group_ROW}//div[@class="tddiv rh-col5"]//button[@class="btn btn-primary ng-scope btn-slim "]
    Click Element    ${Collection_Table_Group_Row_Sent_Data_Enabled_BUTTON}
    ${Collection_Table_Group_Row_Sent_Data_BOX}=    Set Variable    ${Collection_Table_List_Group_ROW}${Sent_Data_BOX}
    Wait Until Page Contains Element    ${Collection_Table_Group_Row_Sent_Data_BOX}
    Page Should Contain Element    ${Collection_Table_Group_Row_Sent_Data_BOX}
    ${Collection_Table_Group_Row_Sent_Data_Box_Path_WRAPPER}=    Set Variable    ${Collection_Table_Group_Row_Sent_Data_BOX}${Sent_Data_Box_Path_WRAPPER}
    ${Collection_Table_Group_Row_Sent_Data_Box_Copy_To_Clipboard_BUTTON}=    Set Variable    ${Collection_Table_Group_Row_Sent_Data_BOX}${Sent_Data_Box_Copy_To_Clipboard_BUTTON}
    ${Collection_Table_Group_Row_Sent_Data_Box_Reset_Parametrized_Data_BUTTON}=    Set Variable    ${Collection_Table_Group_Row_Sent_Data_BOX}${Sent_Data_Box_Reset_Parametrized_Data_BUTTON}
    ${Collection_Table_Group_Row_Sent_Data_Box_Save_Parametrized_Data_BUTTON}=    Set Variable    ${Collection_Table_Group_Row_Sent_Data_BOX}${Sent_Data_Box_Save_Parametrized_Data_BUTTON}
    ${Collection_Table_Group_Row_Sent_Data_Box_Close_BUTTON}=    Set Variable    ${Collection_Table_Group_Row_Sent_Data_BOX}${Sent_Data_Box_Close_BUTTON}
    Page Should Contain Element    ${Collection_Table_Group_Row_Sent_Data_Box_Path_WRAPPER}
    Page Should Contain Element    ${Collection_Table_Group_Row_Sent_Data_Box_Copy_To_Clipboard_BUTTON}
    Page Should Contain Element    ${Collection_Table_Group_Row_Sent_Data_Box_Reset_Parametrized_Data_BUTTON}
    Page Should Contain Element    ${Collection_Table_Group_Row_Sent_Data_Box_Save_Parametrized_Data_BUTTON}
    Page Should Contain Element    ${Collection_Table_Group_Row_Sent_Data_Box_Close_BUTTON}

Insert Parameters To Nongroup Row Sent Data Path Wrapper
    [Arguments]    ${row_number}    ${param_name_topo}    ${param_name_node}    ${param_name_link}
    [Documentation]    Will insert parameters to topology id and/or node id and/or link id path wrapper inputs in sent data box.
    ${Collection_Table_List_Nongroup_ROW}=    Return Collection Table Nongroup Row Number    ${row_number}
    Open Collection Table Nongroup Sent Data Box    ${row_number}
    ${Collection_Table_Nongroup_Row_Sent_Data_BOX}=    Set Variable    ${Collection_Table_List_Nongroup_ROW}${Sent_Data_BOX}
    ${Collection_Table_Nongroup_Row_Sent_Data_Box_Path_WRAPPER}=    Set Variable    ${Collection_Table_Nongroup_Row_Sent_Data_BOX}${Sent_Data_Box_Path_WRAPPER}
    ${Collection_Table_Nongroup_Row_Sent_Data_Box_Topology_Id_Path_Wrapper_INPUT}=    Set Variable    ${Collection_Table_Nongroup_Row_Sent_Data_Box_Path_WRAPPER}${Sent_Data_Box_Topology_Id_Path_Wrapper_INPUT}
    ${Collection_Table_Nongroup_Row_Sent_Data_Box_Node_Id_Path_Wrapper_INPUT}=    Set Variable    ${Collection_Table_Nongroup_Row_Sent_Data_Box_Path_WRAPPER}${Sent_Data_Box_Node_Id_Path_Wrapper_INPUT}
    ${Collection_Table_Nongroup_Row_Sent_Data_Box_Link_Id_Path_Wrapper_INPUT}=    Set Variable    ${Collection_Table_Nongroup_Row_Sent_Data_Box_Path_WRAPPER}${Sent_Data_Box_Link_Id_Path_Wrapper_INPUT}
    ${Collection_Table_Nongroup_Row_Sent_Data_Box_Save_Parametrized_Data_BUTTON}=    Set Variable    ${Collection_Table_Nongroup_Row_Sent_Data_BOX}${Sent_Data_Box_Save_Parametrized_Data_BUTTON}
    ${dict}=    Create Dictionary    ${param_name_topo}=${Collection_Table_Nongroup_Row_Sent_Data_Box_Topology_Id_Path_Wrapper_INPUT}
    ...    ${param_name_node}=${Collection_Table_Nongroup_Row_Sent_Data_Box_Node_Id_Path_Wrapper_INPUT}
    ...    ${param_name_link}=${Collection_Table_Nongroup_Row_Sent_Data_Box_Link_Id_Path_Wrapper_INPUT}
    @{param_names}=    Create List    ${param_name_topo}    ${param_name_node}    ${param_name_link}
    : FOR    ${param_name}    IN    @{param_names}
    \    ${param_key}    Return Parameter Key    ${param_name}
    \    Run Keyword If    "${param_name}"=="${EMPTY}"    No Operation
    \    ${input_field}=    Get From Dictionary    ${dict}    ${param_name}
    \    Run Keyword If    "${param_name}"!="${EMPTY}"    Insert Text To Input Field    ${input_field}    ${param_key}

Insert Parameters To Group Row Sent Data Path Wrapper
    [Arguments]    ${group_number}    ${row_number}    ${param_name_topo}    ${param_name_node}    ${param_name_link}
    [Documentation]    Will insert parameters to topology id and/or node id and/or link id path wrapper inputs in sent data box.
    ${Collection_Table_List_Group_ROW}=    Return Collection Table Group Row Number    ${group_number}    ${row_number}
    Open Collection Table Group Sent Data Box    ${group_number}    ${row_number}
    ${Collection_Table_Group_Row_Sent_Data_BOX}=    Set Variable    ${Collection_Table_List_Group_ROW}${Sent_Data_BOX}
    ${Collection_Table_Group_Row_Sent_Data_Box_Path_WRAPPER}=    Set Variable    ${Collection_Table_Group_Row_Sent_Data_BOX}${Sent_Data_Box_Path_WRAPPER}
    ${Collection_Table_Group_Row_Sent_Data_Box_Topology_Id_Path_Wrapper_INPUT}=    Set Variable    ${Collection_Table_Group_Row_Sent_Data_Box_Path_WRAPPER}${Sent_Data_Box_Topology_Id_Path_Wrapper_INPUT}
    ${Collection_Table_Group_Row_Sent_Data_Box_Node_Id_Path_Wrapper_INPUT}=    Set Variable    ${Collection_Table_Group_Row_Sent_Data_Box_Path_WRAPPER}${Sent_Data_Box_Node_Id_Path_Wrapper_INPUT}
    ${Collection_Table_Group_Row_Sent_Data_Box_Link_Id_Path_Wrapper_INPUT}=    Set Variable    ${Collection_Table_Group_Row_Sent_Data_Box_Path_WRAPPER}${Sent_Data_Box_Link_Id_Path_Wrapper_INPUT}
    ${Collection_Table_Group_Row_Sent_Data_Box_Save_Parametrized_Data_BUTTON}=    Set Variable    ${Collection_Table_Group_Row_Sent_Data_BOX}${Sent_Data_Box_Save_Parametrized_Data_BUTTON}
    ${dict}=    Create Dictionary    ${param_name_topo}=${Collection_Table_Group_Row_Sent_Data_Box_Topology_Id_Path_Wrapper_INPUT}    ${param_name_node}=${Collection_Table_Group_Row_Sent_Data_Box_Node_Id_Path_Wrapper_INPUT}    ${param_name_link}=${Collection_Table_Group_Row_Sent_Data_Box_Link_Id_Path_Wrapper_INPUT}
    @{param_names}=    Create List    ${param_name_topo}    ${param_name_node}    ${param_name_link}
    : FOR    ${param_name}    IN    @{param_names}
    \    ${param_key}    Return Parameter Key    ${param_name}
    \    Run Keyword If    "${param_name}"=="${EMPTY}"    No Operation
    \    ${input_field}=    Get From Dictionary    ${dict}    ${param_name}
    \    Run Keyword If    "${param_name}"!="${EMPTY}"    Insert Text To Input Field    ${input_field}    ${param_key}

Verify Collection Nongroup Sent Box Data Presence In Code Mirror
    [Arguments]    ${row_number}    ${data}
    ${Collection_Table_List_Nongroup_ROW}=    Return Collection Table Nongroup Row Number    ${row_number}
    ${Sent_Data_Box_Code_Mirror_CODE}=    Set Variable    //div[@class="CodeMirror-lines"]//div[@class="CodeMirror-code"]//span[contains(., "${data}")]
    ${Collection_Table_Nongroup_Row_Sent_Data_Box_Code_Mirror_CODE}=    Set Variable    ${Collection_Table_List_Nongroup_ROW}${Sent_Data_Box_Code_Mirror_CODE}
    Page Should Contain Element    ${Collection_Table_Nongroup_Row_Sent_Data_Box_Code_Mirror_CODE}

Verify Collection Nongroup Sent Box Data NONPresence In Code Mirror
    [Arguments]    ${row_number}    ${data}
    ${Collection_Table_List_Nongroup_ROW}=    Return Collection Table Nongroup Row Number    ${row_number}
    ${Sent_Data_Box_Code_Mirror_CODE}=    Set Variable    //div[@class="CodeMirror-lines"]//div[@class="CodeMirror-code"]//span[contains(., "${data}")]
    ${Collection_Table_Nongroup_Row_Sent_Data_Box_Code_Mirror_CODE}=    Set Variable    ${Collection_Table_List_Nongroup_ROW}${Sent_Data_Box_Code_Mirror_CODE}
    Page Should Not Contain Element    ${Collection_Table_Nongroup_Row_Sent_Data_Box_Code_Mirror_CODE}

Verify Collection Group Sent Box Data Presence In Code Mirror
    [Arguments]    ${group_number}    ${row_number}    ${data}
    ${Collection_Table_List_Group_ROW}=    Return Collection Table Group Row Number    ${group_number}    ${row_number}
    ${Sent_Data_Box_Code_Mirror_CODE}=    Set Variable    //div[@class="CodeMirror-lines"]//div[@class="CodeMirror-code"]//span[contains(., "${data}")]
    ${Collection_Table_Group_Row_Sent_Data_Box_Code_Mirror_CODE}=    Set Variable    ${Collection_Table_List_Group_ROW}${Sent_Data_Box_Code_Mirror_CODE}
    Page Should Contain Element    ${Collection_Table_Group_Row_Sent_Data_Box_Code_Mirror_CODE}

Verify Collection Group Sent Box Data NONPresence In Code Mirror
    [Arguments]    ${group_number}    ${row_number}    ${data}
    ${Collection_Table_List_Group_ROW}=    Return Collection Table Group Row Number    ${group_number}    ${row_number}
    ${Sent_Data_Box_Code_Mirror_CODE}=    Set Variable    //div[@class="CodeMirror-lines"]//div[@class="CodeMirror-code"]//span[contains(., "${data}")]
    ${Collection_Table_Group_Row_Sent_Data_Box_Code_Mirror_CODE}=    Set Variable    ${Collection_Table_List_Group_ROW}${Sent_Data_Box_Code_Mirror_CODE}
    Page Should Not Contain Element    ${Collection_Table_Group_Row_Sent_Data_Box_Code_Mirror_CODE}

Close Collection Nongroup Sent Box
    [Arguments]    ${row_number}
    ${Collection_Table_List_Nongroup_ROW}=    Return Collection Table Nongroup Row Number    ${row_number}
    ${Collection_Table_Nongroup_Row_Sent_Data_BOX}=    Set Variable    ${Collection_Table_List_Nongroup_ROW}${Sent_Data_BOX}
    ${Collection_Table_Nongroup_Row_Sent_Data_Box_Close_BUTTON}=    Set Variable    ${Collection_Table_Nongroup_Row_Sent_Data_BOX}${Sent_Data_Box_Close_BUTTON}
    Click Element    ${Collection_Table_Nongroup_Row_Sent_Data_Box_Close_BUTTON}
    Wait Until Page Does Not Contain Element    ${Collection_Table_Nongroup_Row_Sent_Data_BOX}

Close Collection Nongroup Sent Box And Clear Collection Data
    [Arguments]    ${row_number}
    Close Collection Nongroup Sent Box    ${row_number}
    If Collection Table Contains Data Then Clear Collection Data

Close Collection Group Sent Box
    [Arguments]    ${group_number}    ${row_number}
    ${Collection_Table_List_Group_ROW}=    Return Collection Table Group Row Number    ${group_number}    ${row_number}
    ${Collection_Table_Group_Row_Sent_Data_BOX}=    Set Variable    ${Collection_Table_List_Group_ROW}${Sent_Data_BOX}
    ${Collection_Table_Group_Row_Sent_Data_Box_Close_BUTTON}=    Set Variable    ${Collection_Table_Group_Row_Sent_Data_BOX}${Sent_Data_Box_Close_BUTTON}
    Click Element    ${Collection_Table_Group_Row_Sent_Data_Box_Close_BUTTON}
    Wait Until Page Does Not Contain Element    ${Collection_Table_Group_Row_Sent_Data_BOX}

Reset Nongroup Parametrized Data
    [Arguments]    ${row_number}
    ${Collection_Table_List_Nongroup_ROW}=    Return Collection Table Nongroup Row Number    ${row_number}
    ${Collection_Table_Nongroup_Row_Sent_Data_BOX}=    Set Variable    ${Collection_Table_List_Nongroup_ROW}${Sent_Data_BOX}
    ${Collection_Table_Nongroup_Row_Sent_Data_Box_Reset_Parametrized_Data_BUTTON}=    Set Variable    ${Collection_Table_Nongroup_Row_Sent_Data_BOX}${Sent_Data_Box_Reset_Parametrized_Data_BUTTON}
    Click Element    ${Collection_Table_Nongroup_Row_Sent_Data_Box_Reset_Parametrized_Data_BUTTON}

Reset Group Parametrized Data
    [Arguments]    ${group_number}    ${row_number}
    ${Collection_Table_List_Group_ROW}=    Return Collection Table Group Row Number    ${group_number}    ${row_number}
    ${Collection_Table_Group_Row_Sent_Data_BOX}=    Set Variable    ${Collection_Table_List_Group_ROW}${Sent_Data_BOX}
    ${Collection_Table_Group_Row_Sent_Data_Box_Reset_Parametrized_Data_BUTTON}=    Set Variable    ${Collection_Table_Group_Row_Sent_Data_BOX}${Sent_Data_Box_Reset_Parametrized_Data_BUTTON}
    Click Element    ${Collection_Table_Group_Row_Sent_Data_Box_Reset_Parametrized_Data_BUTTON}

Run Request Nongroup Row Sent Data Box
    [Arguments]    ${row_number}
    ${Collection_Table_List_Nongroup_ROW}=    Return Collection Table Nongroup Row Number    ${row_number}
    ${Collection_Table_Nongroup_Row_Execute_Request_BUTTON}=    Set Variable    ${Collection_Table_List_Nongroup_ROW}//div[@class="tddiv rh-col7"]//button[contains(@ng-click, "executeCollectionRequest")]
    Patient Click Element    ${Collection_Table_Nongroup_Row_Execute_Request_BUTTON}    4

Run Request Group Row Sent Data Box
    [Arguments]    ${group_number}    ${row_number}
    ${Collection_Table_List_Group_ROW}=    Return Collection Table Group Row Number    ${group_number}    ${row_number}
    ${Collection_Table_Group_Row_Execute_Request_BUTTON}=    Set Variable    ${Collection_Table_List_Group_ROW}//div[@class="tddiv rh-col7"]//button[contains(@ng-click, "executeCollectionRequest")]
    Patient Click Element    ${Collection_Table_Group_Row_Execute_Request_BUTTON}    4

Save Parametrized Data Nongroup Row Sent Data Box
    [Arguments]    ${row_number}
    ${Collection_Table_List_Nongroup_ROW}=    Return Collection Table Nongroup Row Number    ${row_number}
    ${Collection_Table_Nongroup_Row_Sent_Data_BOX}=    Set Variable    ${Collection_Table_List_Nongroup_ROW}${Sent_Data_BOX}
    ${Collection_Table_Nongroup_Row_Sent_Data_Box_Save_Parametrized_Data_BUTTON}=    Set Variable    ${Collection_Table_Nongroup_Row_Sent_Data_BOX}${Sent_Data_Box_Save_Parametrized_Data_BUTTON}
    Patient Click Element    ${Collection_Table_Nongroup_Row_Sent_Data_Box_Save_Parametrized_Data_BUTTON}    4

Save Parametrized Data Group Row Sent Data Box
    [Arguments]    ${group_number}    ${row_number}
    ${Collection_Table_List_Group_ROW}=    Return Collection Table Group Row Number    ${group_number}    ${row_number}
    ${Collection_Table_Group_Row_Sent_Data_BOX}=    Set Variable    ${Collection_Table_List_Group_ROW}${Sent_Data_BOX}
    ${Collection_Table_Group_Row_Sent_Data_Box_Save_Parametrized_Data_BUTTON}=    Set Variable    ${Collection_Table_Group_Row_Sent_Data_BOX}${Sent_Data_Box_Save_Parametrized_Data_BUTTON}
    Patient Click Element    ${Collection_Table_Group_Row_Sent_Data_Box_Save_Parametrized_Data_BUTTON}    4

Fill Collection Table Nongroup Row Request To Form
    [Arguments]    ${row_number}
    ${Collection_Table_List_Nongroup_ROW}=    Return Collection Table Nongroup Row Number    ${row_number}
    ${Collection_Table_Nongroup_Row_Fill_Data_Enabled_BUTTON}=    Set Variable    ${Collection_Table_List_Nongroup_ROW}//div[@class="tddiv rh-col7"]//button[@class="yangButton iconFillData "]
    Patient Click Element    ${Collection_Table_Nongroup_Row_Fill_Data_Enabled_BUTTON}    4

Fill Collection Table Group Row Request To Form
    [Arguments]    ${group_number}    ${row_number}
    ${Collection_Table_List_Group_ROW}=    Return Collection Table Group Row Number    ${group_number}    ${row_number}
    ${Collection_Table_Group_Row_Fill_Data_Enabled_BUTTON}=    Set Variable    ${Collection_Table_List_Group_ROW}//div[@class="tddiv rh-col7"]//button[@class="yangButton iconFillData "]
    Patient Click Element    ${Collection_Table_Group_Row_Fill_Data_Enabled_BUTTON}    4

Click Collection Table Nongroup Row Edit Button
    [Arguments]    ${row_number}
    ${Collection_Table_List_Nongroup_ROW}=    Return Collection Table Nongroup Row Number    ${row_number}
    ${Collection_Table_Nongroup_Row_Move_To_Group_BUTTON}=    Set Variable    ${Collection_Table_List_Nongroup_ROW}//div[@class="tddiv rh-col7"]//div[contains(@ng-click, "showCollBox")]
    Patient Click Element    ${Collection_Table_Nongroup_Row_Move_To_Group_BUTTON}    4

Click Collection Table Group Row Edit Button
    [Arguments]    ${group_number}    ${row_number}
    ${Collection_Table_List_Group_ROW}=    Return Collection Table Group Row Number    ${group_number}    ${row_number}
    ${Collection_Table_Group_Row_Move_To_Group_BUTTON}=    Set Variable    ${Collection_Table_List_Group_ROW}//div[@class="tddiv rh-col7"]//div[contains(@ng-click, "showCollBox")]
    Patient Click Element    ${Collection_Table_Group_Row_Move_To_Group_BUTTON}    4

Delete Collection Table Nongroup Row Request
    [Arguments]    ${row_number}
    ${Collection_Table_List_Nongroup_ROW}=    Return Collection Table Nongroup Row Number    ${row_number}
    ${Collection_Table_Nongroup_Row_Delete_BUTTON}=    Set Variable    ${Collection_Table_List_Nongroup_ROW}//div[@class="tddiv rh-col7"]//button[@class="yangButton iconClose"]
    Patient Click Element    ${Collection_Table_Nongroup_Row_Delete_BUTTON}    4

Delete Collection Table Group Row Request
    [Arguments]    ${group_number}    ${row_number}
    ${Collection_Table_List_Group_ROW}=    Return Collection Table Group Row Number    ${group_number}    ${row_number}
    ${Collection_Table_Group_Row_Delete_BUTTON}=    Set Variable    ${Collection_Table_List_Group_ROW}//div[@class="tddiv rh-col7"]//button[@class="yangButton iconClose"]
    Patient Click Element    ${Collection_Table_Group_Row_Delete_BUTTON}    4

If Collection Table Contains Data Then Clear Collection Data
    ${Collection_Table_List_Nongroup_ROW}=    Return Collection Table Nongroup Row Number    1
    ${status}=    Run Keyword And Return Status    Page Should Contain Element    ${Collection_Table_List_Nongroup_ROW}
    Run Keyword If    "${status}"=="True"    Click Element    ${Clear_Collection_Data_BUTTON}
    ${Collection_Table_List_GROUP}=    Return Collection Table Group Number    1
    ${status}=    Run Keyword And Return Status    Page Should Contain Element    ${Collection_Table_List_GROUP}
    Run Keyword If    "${status}"=="True"    Click Element    ${Clear_Collection_Data_BUTTON}
