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

${Testing_Root_API_Topology_NAME}    topology
${Testing_Root_API_Topology_Id_NAME}    topology-id
${Testing_Root_API_Topology_Topology_Id_NAME}    ${Testing_Root_API_Topology_NAME} {${Testing_Root_API_Topology_Id_NAME}}
${Testing_Root_API_Topology_Topology_Id_XPATH}    ${API_Tree_ROW_4th_Level_XPATH}/a/span[contains(text(),"${Testing_Root_API_Topology_Topology_Id_NAME}")]
${Testing_Root_API_Topology_Topology_Id_Plus_EXPANDER}    ${Testing_Root_API_Topology_Topology_Id_XPATH}/preceding-sibling::i[@ng-class="row.tree_icon"]
${Testing_Root_API_Topology_Types_NAME}    topology-types
${Testing_Root_API_Topology_Types_XPATH}    ${API_Tree_ROW_5th_Level_XPATH}/a/span[contains(text(),"${Testing_Root_API_Topology_Types_NAME}")]
${Testing_Root_API_Topology_Types_Plus_EXPANDER}    ${Testing_Root_API_Topology_Types_XPATH}/preceding-sibling::i[@ng-class="row.tree_icon"]

${Testing_Root_API_Node_NAME}    node
${Testing_Root_API_Node_Id_NAME}    node-id
${Testing_Root_API_Node_Node_Id_NAME}    ${Testing_Root_API_Node_NAME} {${Testing_Root_API_Node_Id_NAME}}
${Testing_Root_API_Node_Node_Id_XPATH}    ${API_Tree_ROW_5th_Level_XPATH}/a/span[contains(text(),"${Testing_Root_API_Node_Node_Id_NAME}")]
${Testing_Root_API_Node_Node_Id_Plus_EXPANDER}    ${Testing_Root_API_Node_Node_Id_XPATH}/preceding-sibling::i[@ng-class="row.tree_icon"]

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
${Path_Wrapper}    //div[@class="pathWrapper"]
${Copy_To_Clipboard_BUTTON}    //button[@clip-copy="copyReqPathToClipboard()"]
${Send_BUTTON}    //button[@ng-click="executeOperation(selectedOperation)"]
${Show_Preview_BUTTON}    //button[@ng-click="showPreview()"]


### CUSTOM CONTAINER AREA ###

${Alert_PANEL}    //div[@class="alert ng-isolate-scope alert-dismissible alert-success"]
${Alert_Close_BUTTON}    ${Alert_PANEL}/button[@class="close"]
${Loading_completed_successfully_MSG}    Loading completed successfully
${Loading_completed_successfully_ALERT}    ${Alert_PANEL}/div/b[contains(text(), "${Loading_completed_successfully_MSG}")]
${Request_sent_successfully_MSG}    Request sent successfully
${Request_sent_successfully_ALERT}    ${Alert_PANEL}/div/b[contains(text(), "${Request_sent_successfully_MSG}")]

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

${Topology_ID}
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

${Node_ID}
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

${Link_ID}
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

==========================
# Yang Visualizer Submenu
==========================
${Yang_Visualizer_Submenu_URL}    ${BASE_URL}#/yangvisualizer/index


*** Keywords ***

PUT ID
    [Arguments]    ${input_field}    ${Chosen_Id}    ${Topology/Node/Link_ID}    ${topology/node/link_list_name}
    [Documentation]    Will insert topology, node or link id and put it to the structure.
    ...    ${id} is id to be input; ${input_field} is locator of an INPUT field;
    ...    ${ID} are global ${Topology_ID}, ${Node_ID} or ${Link_ID};
    ...    ${topology/node/link_list_name} is ${...Topology/Node/Link_List_NAME}.
    Focus    ${input_field}
    Input Text    ${input_field}    ${Chosen_Id}
    Sleep    1
    Click Element    ${Operation_Select_BOX}
    Wait Until Page Contains Element    ${Put_OPERATION}
    Click Element    ${Put_OPERATION}
    Click Element    ${Action_Buttons_DIV}
    Focus    ${Send_BUTTON}
    Click Element    ${Send_BUTTON}
    Wait Until Page Contains Element    ${Request_sent_successfully_ALERT}
    Sleep    1
    ${Topology/Node/Link_ID}=    Set Variable    ${Chosen_Id}
    Page Should Contain Element    //button[contains(text(), "${topology/node/link_list_name}") and contains(text(),"${Topology/Node/Link_ID}")]
    ${id_button}=    Set Variable    //button[contains(text(), "${topology/node/link_list_name}") and contains(text(),"${Topology/Node/Link_ID}")]
    Page Should Contain Element    ${id_button}/following::${Delete_BUTTON}

Delete All Existing Topologies
    [Documentation]    This keyword deletes all existing topologies.
    Click Element    ${Testing_Root_API_Network_Topology_XPATH}
    Wait Until Page Contains Element    ${Testing_Root_API_Network_Topology_BUTTON}
    Click Element    ${Operation_Select_BOX}
    Wait Until Page Contains Element    ${Delete_OPERATION}
    Click Element    ${Delete_OPERATION}
    Click Element    ${Send_BUTTON}
    Wait Until Page Contains Element    ${Request_sent_successfully_ALERT}
