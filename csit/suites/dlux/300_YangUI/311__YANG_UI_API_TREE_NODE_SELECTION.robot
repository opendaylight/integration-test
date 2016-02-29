*** Settings ***
Documentation     Verification that the information from a "config" expander
...    is loaded in custom container area below  actionButtons area.
#Library           Selenium2Library    timeout=10    implicit_wait=10     run_on_failure=Log Source
Library           Selenium2Library    timeout=10    implicit_wait=10     
Resource          ../../../libraries/GUIKeywords.robot
Resource          ../../../libraries/Utils.robot
Resource          ../../../libraries/YangUIKeywords.robot
#Suite Teardown    Close Browser

*** Variables ***
${LOGIN_USERNAME}    admin
${LOGIN_PASSWORD}    admin

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
    [Documentation]   Expand chosen testing root API.
    ...    Result
    ...    The testing root API contains "config" expander (2nd level of tree rows) 
    ...    and "config" element.
    Step_04_run

Step_05
    [Documentation]   Expand "config" plus expander under chosen testing root API.
    ...    Result
    ...    The page contains "network-tolopogy" plus expander (3rd level
    ...    of tree rows) and "network-tpology" element in API tree.
    Step_05_run    

Step_06
    [Documentation]   Click "network-topology" element in API tree.
    ...    Result
    ...    The page contains "network-topology" arrow expander and "network-topology" 
    ...    button in the area below API tree container and Action buttons container.
    ...    The page contains Operation select box with operations Get, Put, Post, 
    ...    Delete; Path Wrapper (box with API address); buttons Copy to clipboard, 
    ...    Send, Show prewiew, Custom API Request.
    Step_06_run

Step_07
    [Documentation]   Expand "network-topology" plus expander.
    ...    Result
    ...    The page contains "topology {topology-id}" plus expander (4th level of 
    ...    tree rows) and "topology {topology-id}" element in API tree.
    Step_07_run

Step_08
    [Documentation]   Click "topology {topology-id}" element in API tree.
    ...    Result
    ...    The page contains "topology {topology-id}" arrow expander and 
    ...    "topology {topology-id}" button in the area below API tree container and 
    ...    Action buttons container. 
    ...    The page contains Operation select box with operations Get, Put, Post, 
    ...    Delete; Path Wrapper (box with API address); buttons Copy to clipboard, 
    ...    Send, Show prewiew, Custom API Request; buttons iconQuestion, augemntIcon 
    ...    and iconPlus.   
    Step_08_run  

Step_09
    [Documentation]   Expand "topology {topology-id}" plus expander.
    ...    Result
    ...    The page contains "topology-types" plus expander (5th level of 
    ...    tree rows) and "topology-types" element in API tree; "node {node-id}" plus
    ...    expander (5th level of tree rows) and "node {node-id}" element in API tree;   
    ...    "link {link-id}" plus expander (5th level of tree rows) and "link {link-id}"
    ...    element in API tree.
    Step_09_run
    
Step_10
    [Documentation]    Click "topology-types" element in API tree.
    ...    Result
    ...    The page contains "topology-types" arrow expander and 
    ...    "topology-types" button in the area below API tree container and Action 
    ...    buttons container. 
    ...    The page contains Operation select box with operations Get, Put, Post, 
    ...    Delete; Path Wrapper (box with API address); buttons Copy to clipboard, 
    ...    Send, Show prewiew, Custom API Request; buttons iconQuestion, augemntIcon.   
    Step_10_run
    
Step_11
    [Documentation]    Click "node {node-id}" element in API tree.
    ...    Result
    ...    The page contains "node list" arrow expander and "node list" button
    ...    in the area below API tree container and Action buttons container. 
    ...    The page contains Operation select box with operations Get, Put, Post, 
    ...    Delete; Path Wrapper (box with API address); buttons Copy to clipboard, 
    ...    Send, Show prewiew, Custom API Request; buttons iconQuestion, augemntIcon
    ...    and iconPlus.   
    Step_11_run

Step_12
    [Documentation]    Click "link {link-id}" element in API tree.
    ...    Result
    ...    The page contains "link list" arrow expander and "link list" button
    ...    in the area below API tree container and Action buttons container. 
    ...    The page contains Operation select box with operations Get, Put, Post, 
    ...    Delete; Path Wrapper (box with API address); buttons Copy to clipboard, 
    ...    Send, Show prewiew, Custom API Request; buttons iconQuestion, augemntIcon
    ...    and iconPlus.   
    Step_12_run
    
Step_13
    [Documentation]    Close Dlux.
    Step_13_run    
    

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
    Location Should Be    ${Yang_UI_Submenu_URL}
    

Step_04_run
    Click Element    ${Testing_Root_API_EXPANDER}
    Wait Until Page Contains Element    ${Testing_Root_API_Config_EXPANDER}
    
Step_05_run
    Click Element    ${Testing_Root_API_Config_EXPANDER}
    Wait Until Page Contains Element    ${Testing_Root_API_Network_Topology_Plus_EXPANDER}
    
Step_06_run
    Click Element    ${Testing_Root_API_Network_Topology_XPATH}
    Page Should Contain Element    ${Testing_Root_API_Network_Topology_BUTTON}
    Page Should Contain Button    ${Testing_Root_API_Network_Topology_Arrow_EXPANDER}
    
    Page Should Contain Element    ${Operation_Select_BOX}
    Click Element          ${Operation_Select_BOX}
    Wait Until Page Contains Element    ${Get_OPERATION}
    Page Should Contain Element    ${Put_OPERATION}
    Page Should Contain Element    ${Post_OPERATION}
    Page Should Contain Element    ${Delete_OPERATION}
    Page Should Contain Element    ${Path_Wrapper}
    Page Should Contain Element    ${Copy_To_Clipboard_BUTTON} 
    Page Should Contain Element    ${Send_BUTTON} 
    Page Should Contain Element    ${Show_Preview_BUTTON}      
    Page Should Contain Element    ${Custom_API_request_BUTTON}    
   
Step_07_run    
    Click Element    ${Testing_Root_API_Network_Topology_Plus_EXPANDER}
    Wait Until Page Contains Element    ${Testing_Root_API_Topology_Topology_Id_Plus_EXPANDER}

Step_08_run
    Click Element    ${Testing_Root_API_Topology_Topology_Id_XPATH}
    Page Should Contain    ${Testing_Root_API_Topology_List_NAME}
    Page Should Contain Element    ${Testing_Root_API_Topology_List_BUTTON}
    Page Should Contain Element    ${Testing_Root_API_Topology_List_Arrow_Expander}
    
    Page Should Contain Element    ${Operation_Select_BOX}
    Click Element          ${Operation_Select_BOX}
    Wait Until Page Contains Element    ${Get_OPERATION}
    Page Should Contain Element    ${Put_OPERATION}
    Page Should Contain Element    ${Post_OPERATION}
    Page Should Contain Element    ${Delete_OPERATION}
    Page Should Contain Element    ${Path_Wrapper}
    Page Should Contain Element    ${Copy_To_Clipboard_BUTTON} 
    Page Should Contain Element    ${Send_BUTTON} 
    Page Should Contain Element    ${Show_Preview_BUTTON}      
    Page Should Contain Element    ${Custom_API_request_BUTTON}
    
    Page Should Contain Element    ${Testing_Root_API_Topology_List_Question_BUTTON}
    Page Should Contain Element    ${Testing_Root_API_Topology_List_Augment_ICON}
    Page Should Contain Element    ${Testing_Root_API_Topology_List_Plus_BUTTON}         
 
Step_09_run
    Click Element    ${Testing_Root_API_Topology_Topology_Id_Plus_EXPANDER}
    Wait Until Page Contains Element    ${Testing_Root_API_Topology_Types_Plus_EXPANDER}
    Page Should Contain Element    ${Testing_Root_API_Node_Node_Id_Plus_EXPANDER}
    Page Should Contain Element    ${Testing_Root_API_Link_Link_Id_Plus_EXPANDER}
    
Step_10_run
    Click Element    ${Testing_Root_API_Topology_Types_XPATH}
    Page Should Contain Element    ${Testing_Root_API_Topology_Types_BUTTON}
    Page Should Contain Button    ${Testing_Root_API_Topology_Types_Arrow_EXPANDER}
    
    Page Should Contain Element    ${Operation_Select_BOX}
    Click Element          ${Operation_Select_BOX}
    Wait Until Page Contains Element    ${Get_OPERATION}
    Page Should Contain Element    ${Put_OPERATION}
    Page Should Contain Element    ${Post_OPERATION}
    Page Should Contain Element    ${Delete_OPERATION}
    Page Should Contain Element    ${Path_Wrapper}
    Page Should Contain Element    ${Copy_To_Clipboard_BUTTON} 
    Page Should Contain Element    ${Send_BUTTON} 
    Page Should Contain Element    ${Show_Preview_BUTTON}      
    Page Should Contain Element    ${Custom_API_request_BUTTON}
    
    Page Should Contain Element    ${Testing_Root_API_Topology_Types_Question_BUTTON}
    Page Should Contain Element    ${Testing_Root_API_Topology_Types_Augment_ICON}

Step_11_run
    Click Element    ${Testing_Root_API_Node_Node_Id_XPATH}
    Page Should Contain Element    ${Testing_Root_API_Node_List_BUTTON}
    Page Should Contain Button    ${Testing_Root_API_Node_List_Arrow_EXPANDER}
    
    Page Should Contain Element    ${Operation_Select_BOX}
    Click Element          ${Operation_Select_BOX}
    Wait Until Page Contains Element    ${Get_OPERATION}
    Page Should Contain Element    ${Put_OPERATION}
    Page Should Contain Element    ${Post_OPERATION}
    Page Should Contain Element    ${Delete_OPERATION}
    Page Should Contain Element    ${Path_Wrapper}
    Page Should Contain Element    ${Copy_To_Clipboard_BUTTON} 
    Page Should Contain Element    ${Send_BUTTON} 
    Page Should Contain Element    ${Show_Preview_BUTTON}      
    Page Should Contain Element    ${Custom_API_request_BUTTON}
    
    Page Should Contain Element    ${Testing_Root_API_Node_List_Question_BUTTON}
    Page Should Contain Element    ${Testing_Root_API_Node_List_Augment_ICON}
    Page Should Contain Element    ${Testing_Root_API_Node_List_Plus_BUTTON}
    
Step_12_run
    Click Element    ${Testing_Root_API_Link_Link_Id_XPATH}
    Page Should Contain Element    ${Testing_Root_API_Link_List_BUTTON}
    Page Should Contain Button    ${Testing_Root_API_Link_List_Arrow_EXPANDER}
    
    Page Should Contain Element    ${Operation_Select_BOX}
    Click Element          ${Operation_Select_BOX}
    Wait Until Page Contains Element    ${Get_OPERATION}
    Page Should Contain Element    ${Put_OPERATION}
    Page Should Contain Element    ${Post_OPERATION}
    Page Should Contain Element    ${Delete_OPERATION}
    Page Should Contain Element    ${Path_Wrapper}
    Page Should Contain Element    ${Copy_To_Clipboard_BUTTON} 
    Page Should Contain Element    ${Send_BUTTON} 
    Page Should Contain Element    ${Show_Preview_BUTTON}      
    Page Should Contain Element    ${Custom_API_request_BUTTON}
    
    Page Should Contain Element    ${Testing_Root_API_Link_List_Question_BUTTON}
    Page Should Contain Element    ${Testing_Root_API_Link_List_Augment_ICON}
    Page Should Contain Element    ${Testing_Root_API_Link_List_Plus_BUTTON}
    
Step_13_run
    Close DLUX                               