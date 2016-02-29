*** Settings ***
Documentation     Verification that "PUT" operation is executed successfully
...    on selected levels of a network-topology. 
#Library           Selenium2Library    timeout=10    implicit_wait=10     run_on_failure=Log Source
Library           Selenium2Library    timeout=10    implicit_wait=10     
Resource          ../../../libraries/GUIKeywords.robot
Resource          ../../../libraries/Utils.robot
Resource          ../../../libraries/YangUIKeywords.robot
#Suite Teardown    Close Browser
#Suite Teardown    Run Keywords    Delete All Existing Topologies    Close Browser

*** Variables ***
${LOGIN_USERNAME}    admin
${LOGIN_PASSWORD}    admin
${Default_ID}    [0]
${Topology_Id_0}    t0
${Node_Id_0}    t0n0
${Node_Id_1}    t0n1
${Node_Id_2}    t0n2
${Link_Id_0}    t0l0
${Link_Id_1}    t0l1
${Link_Id_2}    t0l2
${Topology_ID}
${Node_ID}
${Link_ID}


*** Test Cases ***
Step_01
    [Documentation]    Open OpenDayLight page.
    ...    Result
    ...    Page http://127.0.0.1:8181/index.html#/login opened.
    ...    Login formular present on the page.
    Step_01_run

Step_02
    [Documentation]    Insert valid credentials and hit "Login" button.
    ...    Result
    ...    Location is http://127.0.0.1:8181/index.html#/topology.
    ...    Verification that the page contains "Controls" and button "Reload",
    ...    and Yang UI Submenu.
    Step_02_run

Step_03
    [Documentation]    Navigate to Yang UI.
    ...    Result
    ...    Location should be http://127.0.0.1:8181/index.html#/yangui/index.
    Step_03_run

Step_04
    [Documentation]   Expand chosen testing root API. Expand "config" plus 
    ...    expander under chosen testing root API.
    ...    Result
    ...    The page contains "network-tolopogy" plus expander (3rd level
    ...    of tree rows) and "network-tpology" element in API tree.
    Step_04_run

Step_05
    [Documentation]    Click "network-topology" element in API tree.
    ...    Result
    ...    The page contains "network-topology" arrow expander and "network-topology"  
    ...    button in customContainer Area. 
    Step_05_run    

Step_06
    [Documentation]    Click "network topology" arrow expander in customContainer 
    ...    Area.
    ...    Result
    ...    The page contains "topologylist" arrow expander and "topology list" 
    ...    button, and iconPlus in customContainer Area. 
    Step_06_run

Step_07
    [Documentation]   Click "topology list" iconPlus to add new topolgy.
    ...    Result
    ...    The page contains: - iconList, - Filter icon, - "topology [0]" button
    ...    - iconClose button (X button), - "topology-id" label, - key icon
    ...    - input field (for topology id).
    ...    The page contains: - "topology-types" arrow expander, 
    ...    - "topology-types" button, - iconQuestion, - augmentIcon.
    ...    The page contains: - "underlay-topology list"  arrow expander,
    ...    - "underlay-topology list"  button, - iconQuestion, - iconPlus.
    ...    The page contains: - "node list"  arrow expander, - "node list"  button,
    ...    - iconQuestion, - augmentIcon, - iconPlus.
    ...    The page contains: - "link list"  arrow expander, - "link list"  button,
    ...    - iconQuestion, - augmentIcon, - iconPlus.
    Step_07_run

Step_08
    [Documentation]   Insert topolgy-id, choose PUT operation and hit "Send" button.
    ...    Topology-id value: t0.
    ...    Result
    ...    The page contains "Request sent successfully" message and 
    ...    "topology <topology-id: t0>" button and iconClose button.   
    Step_08_run  

Step_09
    [Documentation]   Click "node list" iconPlus to add new node.
    ...    The page contains: - iconList, - Filter icon, - "node [0]" button,
    ...    - iconClose button (X button).
    ...    The page contains: - "termination-point list" arrow expander,
    ...    - "termination-point list" button, - iconQuestion, - augmentIcon,
    ...    - iconPlus.
    ...    The page contains: - "node-id" label, - key icon, - iconQuestion
    ...    - input field (for node id).
    ...    The page contains: - "supporting-node list"  arrow expander,
    ...    - "supporting-node list"  button, - iconQuestion, - iconPlus.
    Step_09_run
    
Step_10
    [Documentation]    Insert node-id into input field, choose PUT operation and
    ...    hit "Send" button. Node-id value: t1n0
    ...    Result
    ...    The page contains "Request sent successfully" message and 
    ...    "node <node-id: t1n0>" button and iconClose button.   
    Step_10_run
    
Step_11
    [Documentation]    Repeat 2 times: Click "node list" iconPlus to add new node.
    ...    Insert node-idinto input field, choose PUT operation and hit "Send" button.
    ...    Node-id values: t1n1, t1n2.
    ...    Result
    ...    The page contains "Request sent successfully" message and 
    ...    "node <node-id: t1n1>" and iconClose button and 
    ...    "node <node-id: t1n2>" button iconClose button.  
    Step_11_run

Step_12
    [Documentation]    Click "link list" iconPlus to add new link.
    ...    Result
    ...    The page contains: - iconList, - Filter icon, - "link [0]" button, 
    ...    - iconClose button (X button), - "link-id" label, - key icon,
    ...    - iconQuestion, - input field (for node id).
    ...    The page contains: - "source" arrow expander, - "source" button, 
    ...    - "destination" arrow expander, - "destination" button.
    ...    The page contains: - "supporting-link list"  arrow expander, 
    ...    - "supporting-link list"  button, - icon Plus.
    Step_12_run    

Step_13
    [Documentation]    Insert link-id into input field, choose PUT operation and
    ...    hit "Send" button. Link-ide value: t1l0
    ...    Result
    ...    The page contains "Request sent successfully" message and 
    ...    "link <link-id: t1l0>" button and iconClose button. 
    Step_13_run

Step_14
    [Documentation]    Repeat 2 times: Click "link list" iconPlus to add new link.
    ...    Insert link-id into input field, choose PUT operation and hit "Send" button.
    ...    Node-id values: t1l1, t1l2.
    ...    Result
    ...    The page contains "Request sent successfully" message and 
    ...    "link <link-id: t1n1>" and iconClose button and 
    ...    "link <link-id: t1n2>" button iconClose button.  
    Step_14_run
    
Step_15
    [Documentation]    Close Dlux.
    Step_15_run


*** Keywords ***
Step_01_run
    Launch DLUX
    #Open DLUX Login Page    ${LOGIN URL}
    Verify Elements Of DLUX Login Page

Step_02_run
    Login DLUX    ${LOGIN_USERNAME}    ${LOGIN_PASSWORD}
    Verify Elements of DLUX Home Page
    Page Should Contain Element    ${Yang_UI_SUBMENU}

Step_03_run
    Click Element    ${Yang_UI_SUBMENU}
    Wait Until Page Contains Element    ${Loading_completed_successfully_ALERT}
    Click Element    ${Alert_Close_BUTTON}
    Location Should Be    ${Yang_UI_Submenu_URL}

Step_04_run
    Click Element    ${Testing_Root_API_EXPANDER}
    Wait Until Page Contains Element    ${Testing_Root_API_Config_EXPANDER}
    Click Element    ${Testing_Root_API_Config_EXPANDER}
    Wait Until Page Contains Element    ${Testing_Root_API_Network_Topology_Plus_EXPANDER}
    
Step_05_run
    Click Element    ${Testing_Root_API_Network_Topology_XPATH}
    Wait Until Page Contains Element    ${Testing_Root_API_Network_Topology_BUTTON}
    Page Should Contain Button    ${Testing_Root_API_Network_Topology_Arrow_EXPANDER}
    
Step_06_run    
    Click Element    ${Testing_Root_API_Network_Topology_Arrow_EXPANDER}
    Wait Until Page Contains Element    ${Testing_Root_API_Topology_List_BUTTON}
    Page Should Contain Element    ${Testing_Root_API_Topology_List_Arrow_EXPANDER}
    Page Should Contain Element    ${Testing_Root_API_Topology_List_Plus_BUTTON}
    
Step_07_run
    Click Element    ${Testing_Root_API_Topology_List_Plus_BUTTON}
    ${Topology_ID}=    Set Variable    ${Default_ID}     
    
    Wait Until Page Contains Element    ${Testing_Root_API_Topology_List_Topology_Id_BUTTON}    
    
    Page Should Contain Element    ${Testing_Root_API_Topology_List_List_BUTTON}
    Page Should Contain Element    ${Testing_Root_API_Topology_List_Filter_BUTTON}
    Page Should Contain Element    ${Testing_Root_API_Topology_List_Topology_Delete_BUTTON}
    Page Should Contain Element    ${Testing_Root_API_Topology_List_Topology_Id_LABEL}
    Page Should Contain Element    ${Testing_Root_API_Topology_List_Topology_Id_Key_ICON}
    Page Should Contain Element    ${Testing_Root_API_Topology_List_Topology_Id_INPUT}
    Page Should Contain Element    ${Testing_Root_API_Topology_Types_BUTTON}
    Page Should Contain Element    ${Testing_Root_API_Topology_Types_Arrow_EXPANDER}
    Page Should Contain Element    ${Testing_Root_API_Topology_Types_Question_BUTTON}
    Page Should Contain Element    ${Testing_Root_API_Topology_Types_Augment_ICON}
    Page Should Contain Element    ${Testing_Root_API_Underlay-topology_List_BUTTON}
    Page Should Contain Element    ${Testing_Root_API_Underlay-topology_List_Arrow_EXPANDER}   
    Page Should Contain Element    ${Testing_Root_API_Underlay-topology_List_Question_BUTTON}
    Page Should Contain Element    ${Testing_Root_API_Underlay-topology_List_Plus_BUTTON}    
    Page Should Contain Element    ${Testing_Root_API_Node_List_BUTTON}
    Page Should Contain Element    ${Testing_Root_API_Node_List_Arrow_EXPANDER}
    Page Should Contain Element    ${Testing_Root_API_Node_List_Question_BUTTON} 
    Page Should Contain Element    ${Testing_Root_API_Node_List_Augment_ICON} 
    Page Should Contain Element    ${Testing_Root_API_Node_List_Plus_BUTTON}      
    Page Should Contain Element    ${Testing_Root_API_Link_List_BUTTON}
    Page Should Contain Element    ${Testing_Root_API_Link_List_Arrow_EXPANDER}
    Page Should Contain Element    ${Testing_Root_API_Link_List_Question_BUTTON}
    Page Should Contain Element    ${Testing_Root_API_Link_List_Augment_ICON}
    Page Should Contain Element    ${Testing_Root_API_Link_List_Plus_BUTTON}

Step_08_run
    PUT ID    ${Testing_Root_API_Topology_List_Topology_Id_INPUT}    ${Topology_Id_0}    ${Topology_ID}    ${Testing_Root_API_Topology_List_NAME}
          
Step_09_run    
    Click Element    ${Testing_Root_API_Node_List_Plus_BUTTON}    
    ${Node_ID}=    Set Variable    ${Default_ID}     
    Wait Until Page Contains Element    ${Testing_Root_API_Node_List_Node_Id_BUTTON}    
    
    Page Should Contain Element    ${Testing_Root_API_Node_List_List_BUTTON}
    Page Should Contain Element    ${Testing_Root_API_Node_List_Filter_BUTTON}
    Page Should Contain Element    ${Testing_Root_API_Node_List_Node_Delete_BUTTON}
    Page Should Contain Element    ${Testing_Root_API_Termination-point_List_BUTTON}
    Page Should Contain Element    ${Testing_Root_API_Termination-point_List_Arrow_EXPANDER}
    Page Should Contain Element    ${Testing_Root_API_Termination-point_List_Question_BUTTON}
    Page Should Contain Element    ${Testing_Root_API_Termination-point_List_Augment_ICON}
    Page Should Contain Element    ${Testing_Root_API_Termination-point_List_Plus_BUTTON}
    Page Should Contain Element    ${Testing_Root_API_Topology_Types_Question_BUTTON}
    Page Should Contain Element    ${Testing_Root_API_Node_List_Node_Id_LABEL}
    Page Should Contain Element    ${Testing_Root_API_Node_List_Node_Id_Key_ICON}
    Page Should Contain Element    ${Testing_Root_API_Node_List_Node_Id_INPUT}   
    Page Should Contain Element    ${Testing_Root_API_Supporting-node_List_BUTTON}
    Page Should Contain Element    ${Testing_Root_API_Supporting-node_List_Arrow_EXPANDER}    
    Page Should Contain Element    ${Testing_Root_API_Supporting-node_List_Question_BUTTON}
    Page Should Contain Element    ${Testing_Root_API_Supporting-node_Plus_BUTTON}

Step_10_run
    PUT ID    ${Testing_Root_API_Node_List_Node_Id_INPUT}    ${Node_Id_0}    ${Node_ID}    ${Testing_Root_API_Node_List_NAME}
    
Step_11_run
    Click Element    ${Testing_Root_API_Node_List_Plus_BUTTON}
    PUT ID    ${Testing_Root_API_Node_List_Node_Id_INPUT}    ${Node_Id_1}    ${Node_ID}    ${Testing_Root_API_Node_List_NAME}
    Click Element    ${Testing_Root_API_Node_List_Plus_BUTTON}
    PUT ID    ${Testing_Root_API_Node_List_Node_Id_INPUT}    ${Node_Id_2}    ${Node_ID}    ${Testing_Root_API_Node_List_NAME}
    
Step_12_run
    Click Element    ${Testing_Root_API_Link_List_Plus_BUTTON}    
    ${Link_ID}=    Set Variable    ${Default_ID}     
    Wait Until Page Contains Element    ${Testing_Root_API_Link_List_Link_Id_BUTTON}    
    
    Page Should Contain Element    ${Testing_Root_API_Link_List_List_BUTTON}
    Page Should Contain Element    ${Testing_Root_API_Link_List_Filter_BUTTON}
    Page Should Contain Element    ${Testing_Root_API_Link_List_Link_Id_LABEL}
    Page Should Contain Element    ${Testing_Root_API_Link_List_Link_Delete_BUTTON}
    Page Should Contain Element    ${Testing_Root_API_Link_List_Link_Id_Key_ICON}
    Page Should Contain Element    ${Testing_Root_API_Link_List_Link_Id_INPUT}
    Page Should Contain Element    ${Testing_Root_API_Source_BUTTON}    
    Page Should Contain Element    ${Testing_Root_API_Source_Arrow_EXPANDER}    
    Page Should Contain Element    ${Testing_Root_API_Destination_BUTTON}    
    Page Should Contain Element    ${Testing_Root_API_Destination_Arrow_EXPANDER}    
    Page Should Contain Element    ${Testing_Root_API_Supporting-link_List_BUTTON}    
    Page Should Contain Element    ${Testing_Root_API_Supporting-link_List_Arrow_EXPANDER}    
    Page Should Contain Element    ${Testing_Root_API_Supporting-link_Plus_BUTTON}    

Step_13_run
    PUT ID    ${Testing_Root_API_Link_List_Link_Id_INPUT}    ${Link_Id_0}    ${Link_ID}    ${Testing_Root_API_Link_List_NAME}

Step_14_run
    Click Element    ${Testing_Root_API_Link_List_Plus_BUTTON}    
    PUT ID    ${Testing_Root_API_Link_List_Link_Id_INPUT}    ${Link_Id_1}    ${Link_ID}    ${Testing_Root_API_Link_List_NAME}
    Click Element    ${Testing_Root_API_Link_List_Plus_BUTTON}
    PUT ID    ${Testing_Root_API_Link_List_Link_Id_INPUT}    ${Link_Id_2}    ${Link_ID}    ${Testing_Root_API_Link_List_NAME}
    
Step_15_run
    Close DLUX
                  