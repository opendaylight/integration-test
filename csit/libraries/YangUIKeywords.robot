*** Settings ***
Documentation     A resource file containing all global
...               elements (Variables, keywords) to help
...               Yang UI unit testing.
Library           OperatingSystem
Library           Process
Library           Common.py
Variables         ../variables/Variables.py
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
${Topology_Id_Path_Wrapper_INPUT}    //span[contains(text(),"/${Testing_Root_API_Topology_NAME}")]//input       
${Node_Id_Path_Wrapper_INPUT}    //span[contains(text(),"/${Testing_Root_API_Node_NAME}")]//input
${Link_Id_Path_Wrapper_INPUT}    //span[contains(text(),"/${Testing_Root_API_Link_NAME}")]//input

${Copy_To_Clipboard_BUTTON}    //button[@clip-copy="copyReqPathToClipboard()"]
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
${Add_New_Parameter_BOX}    //div[contains(@class, "paramBox popupContainer")]
${Add_New_Parameter_Box_Close_BUTTON}    ${Add_New_Parameter_BOX}/button[contains(@class, "icon-remove close")]
${Add_New_Parameter_FORM}    ${Add_New_Parameter_BOX}/form[@name="paramForm"]
${Add_New_Parameter_Form_Name_TEXT}    Name    
${Add_New_Parameter_Form_Name_LABEL}    ${Add_New_Parameter_FORM}/label[contains(text(), "${Add_New_Parameter_Form_Name_TEXT}")]
${Add_New_Parameter_Form_Name_INPUT}    ${Add_New_Parameter_Form_Name_LABEL}/following-sibling::input[@ng-model="paramObj.name"]
${Add_New_Parameter_Form_Value_TEXT}    Value    
${Add_New_Parameter_Form_Value_LABEL}    ${Add_New_Parameter_FORM}/label[contains(text(), "${Add_New_Parameter_Form_Value_LABEL}")]
${Add_New_Parameter_Form_Value_INPUT}    ${Add_New_Parameter_Form_Value_LABEL}/following-sibling::input[@ng-model="paramObj.value"]
${Add_New_Parameter_Form_Save_BUTTON}    ${Add_New_Parameter_FORM}/button[@ng-click="saveParam()"]   
            

${Clear_Parameters_BUTTON}    //button[contains(text(), "Clear parameters")]
${Import_Parameters_SECTION}    //span[contains(text(), "Import parameters")]
${Import_Parameters_INPUT}    //input[@id="upload-parameters"]
${Export_Parameters_BUTTON}    //button[contains(text(), "Export parameters")]



            



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
    

PUT ID
    [Arguments]    ${input_field}    ${Chosen_Id}    ${Topology/Node/Link_ID}    ${topology/node/link_list_name}
    [Documentation]    Will insert topology, node or link id and execute PUT operation on it.
    ...    ${Chosen_id} is id to be input; ${input_field} is locator of an INPUT field;
    ...    ${Topology/Node/Link_ID} has values of ${Topology_ID}, or ${Node_ID}, or ${Link_ID};
    ...    ${topology/node/link_list_name} is ${...Topology/Node/Link_List_NAME}.
    Focus    ${input_field}
    Clear Element Text    ${input_field}    
    Input Text    ${input_field}    ${Chosen_Id}
    Sleep    1
    Execute Chosen Operation    ${Put_OPERATION}    ${Request_sent_successfully_ALERT}    
    Verify Chosen_Id Presence On The Page    ${Chosen_Id}    ${Topology/Node/Link_ID}    ${topology/node/link_list_name}    

POST ID
    [Arguments]    ${input_field}    ${Chosen_Id}    ${Topology/Node/Link_ID}    ${topology/node/link_list_name}
    [Documentation]    Will insert topology, node or link id and execute POST operation on it.
    ...    ${Chosen_id} is id to be input; ${input_field} is locator of an INPUT field;
    ...    ${Topology/Node/Link_ID} has values of ${Topology_ID}, or ${Node_ID}, or ${Link_ID};
    ...    ${topology/node/link_list_name} is ${...Topology/Node/Link_List_NAME}.
    Focus    ${input_field}
    Clear Element Text    ${input_field}
    Input Text    ${input_field}    ${Chosen_Id}
    Sleep    1
    Execute Chosen Operation    ${Post_OPERATION}    ${Request_sent_successfully_ALERT}    
    Verify Chosen_Id Presence On The Page    ${Chosen_Id}    ${Topology/Node/Link_ID}    ${topology/node/link_list_name}   

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

Compare Previewed API And Copied-to-clipboard API
    [Documentation]    This keyword compares API previewed in Preview Box and API
    ...    copied via Copy to clipboard button
    [Arguments]    
    Click Element    ${Show_Preview_BUTTON}
    ${API_from_preview_box}=    Get Text    ${Preview_Box_Displayed_CONTENT}
    Click Element    ${Preview_Box_Close_BUTTON}
    Click Element    ${Copy_To_Clipboard_BUTTON}
    Click Element    ${Custom_API_request_BUTTON}
    Press Key    ${Custom_API_Request_API_Path_INPUT}    \136A
         





