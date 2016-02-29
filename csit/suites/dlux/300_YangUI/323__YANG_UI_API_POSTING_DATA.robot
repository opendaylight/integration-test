*** Settings ***
Documentation     Verification that "POST" operation does not rewrite an ID 
...    that has been "PUT" by the same ID and does return any error message. 
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
${Link_Id_0}    t0l0
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
    ...    The page contains "topology list" arrow expander and "topology list" 
    ...    button, and iconPlus in customContainer Area. 
    Step_06_run

Step_07
    [Documentation]   Click "topology list" iconPlus to add new topolgy.
    ...    Result
    ...    The page contains: - "topology [0]" button, - iconClose button (X button),
    ...    - "topology-id" label, - input field (for topology id).
    ...    The page contains: - "node list"  button, - iconPlus.
    ...    The page contains: - "link list"  button, - iconPlus.
    Step_07_run

Step_08
    [Documentation]   Insert topolgy-id, choose PUT operation and hit "Send" button.
    ...    Topology-id value: t0.
    ...    Result
    ...    The page contains "Request sent successfully" message and 
    ...    "topology <topology-id: t0>" button and iconClose button.   
    Step_08_run  

Step_09
    [Documentation]   Click topology iconClose button (X button). Click 
    ...    "topology list" iconPlus to add new topolgy. Insert topolgy-id, 
    ...    choose POST operation and hit "Send" button. Topology-id value: t0.
    ...    Result
    ...    The page contains "Error sending request - : Data already exists for 
    ...    path" message.
    Step_09_run
    
Step_10
    [Documentation]    Click "node list" iconPlus to add new node.
    ...    Result
    ...    The page contains: - "node [0]" button, - iconClose button (X button),
    ...    - "node-id" label, - input field (for node id). 
    Step_10_run

Step_11
    [Documentation]    Insert node-id into input field, choose PUT operation and
    ...    hit "Send" button. Node-id value: t1n0.
    ...    Result
    ...    The page contains "Request sent successfully" message and 
    ...    "node <node-id: t1n0>" button and iconClose button.   
    Step_11_run
    
Step_12
    [Documentation]   Click node iconClose button (X button). Click 
    ...    "node list" iconPlus to add new node. Insert node-id, 
    ...    choose POST operation and hit "Send" button. Node-id value: t1n0.
    ...    Result
    ...    The page contains "Error sending request - : Data already exists for 
    ...    path" message.
    Step_12_run
 
Step_13
    [Documentation]    Click "link list" iconPlus to add new node.
    ...    Result
    ...    The page contains: - "link [0]" button, - iconClose button (X button),
    ...    - "link-id" label, - input field (for link id). 
    Step_13_run

Step_14
    [Documentation]    Insert link-id into input field, choose PUT operation and
    ...    hit "Send" button. Link-id value: t1l0.
    ...    Result
    ...    The page contains "Request sent successfully" message and 
    ...    "link <link-id: t1l0>" button and iconClose button.   
    Step_14_run
    
Step_15
    [Documentation]   Click link iconClose button (X button). Click 
    ...    "link list" iconPlus to add new node. Insert link-id, 
    ...    choose POST operation and hit "Send" button. Link-id value: t1l0.
    ...    Result
    ...    The page contains "Error sending request - : Data already exists for 
    ...    path" message.
    Step_15_run

Step_16
    [Documentation]    Close Dlux.
    Step_16_run


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
    
    Page Should Contain Element    ${Testing_Root_API_Topology_List_Topology_Delete_BUTTON}
    Page Should Contain Element    ${Testing_Root_API_Topology_List_Topology_Id_LABEL}
    Page Should Contain Element    ${Testing_Root_API_Topology_List_Topology_Id_INPUT}
    
    Page Should Contain Element    ${Testing_Root_API_Node_List_BUTTON}
    Page Should Contain Element    ${Testing_Root_API_Node_List_Plus_BUTTON}      
    Page Should Contain Element    ${Testing_Root_API_Link_List_BUTTON}
    Page Should Contain Element    ${Testing_Root_API_Link_List_Plus_BUTTON}

Step_08_run
    PUT ID    ${Testing_Root_API_Topology_List_Topology_Id_INPUT}    ${Topology_Id_0}    ${Topology_ID}    ${Testing_Root_API_Topology_List_NAME}
          
Step_09_run
    Click Element    ${Testing_Root_API_Topology_List_Topology_Delete_BUTTON}
    Click Element    ${Testing_Root_API_Topology_List_Plus_BUTTON}
    
    Focus    ${Testing_Root_API_Topology_List_Topology_Id_INPUT}
    Input Text    ${Testing_Root_API_Topology_List_Topology_Id_INPUT}    ${Topology_Id_0}
    Sleep    1
    Click Element    ${Operation_Select_BOX}
    Wait Until Page Contains Element    ${Post_OPERATION}
    Click Element    ${Post_OPERATION}
    Click Element    ${Action_Buttons_DIV}
    Focus    ${Send_BUTTON}
    Click Element    ${Send_BUTTON}
    Wait Until Page Contains Element    ${Error_sendin_request_Data_already_exists_ALERT}    


Step_10_run    
    Click Element    ${Testing_Root_API_Node_List_Plus_BUTTON}    
    ${Node_ID}=    Set Variable    ${Default_ID}     
    
    Wait Until Page Contains Element    ${Testing_Root_API_Node_List_Node_Id_BUTTON}    
    
    Page Should Contain Element    ${Testing_Root_API_Node_List_Node_Delete_BUTTON}
    Page Should Contain Element    ${Testing_Root_API_Node_List_Node_Id_LABEL}
    Page Should Contain Element    ${Testing_Root_API_Node_List_Node_Id_INPUT}   
    
Step_11_run
    PUT ID    ${Testing_Root_API_Node_List_Node_Id_INPUT}    ${Node_Id_0}    ${Node_ID}    ${Testing_Root_API_Node_List_NAME}
    
Step_12_run
    Click Element    ${Testing_Root_API_Node_List_Node_Delete_BUTTON}
    Click Element    ${Testing_Root_API_Node_List_Plus_BUTTON}
    
    Focus    ${Testing_Root_API_Node_List_Node_Id_INPUT}
    Input Text    ${Testing_Root_API_Node_List_Node_Id_INPUT}    ${Node_Id_0}
    Sleep    1
    Click Element    ${Operation_Select_BOX}
    Wait Until Page Contains Element    ${Post_OPERATION}
    Click Element    ${Post_OPERATION}
    Click Element    ${Action_Buttons_DIV}
    Focus    ${Send_BUTTON}
    Click Element    ${Send_BUTTON}
    Wait Until Page Contains Element    ${Error_sendin_request_Data_already_exists_ALERT}

Step_13_run
    Click Element    ${Testing_Root_API_Link_List_Plus_BUTTON}    
    ${Link_ID}=    Set Variable    ${Default_ID}     
    
    Wait Until Page Contains Element    ${Testing_Root_API_Link_List_Link_Id_BUTTON}    
    
    Page Should Contain Element    ${Testing_Root_API_Link_List_Link_Id_LABEL}
    Page Should Contain Element    ${Testing_Root_API_Link_List_Link_Delete_BUTTON}
    Page Should Contain Element    ${Testing_Root_API_Link_List_Link_Id_INPUT}

Step_14_run
    PUT ID    ${Testing_Root_API_Link_List_Link_Id_INPUT}    ${Link_Id_0}    ${Link_ID}    ${Testing_Root_API_Link_List_NAME}

Step_15_run
    Click Element    ${Testing_Root_API_Link_List_Link_Delete_BUTTON}
    Click Element    ${Testing_Root_API_Link_List_Plus_BUTTON}
    
    Focus    ${Testing_Root_API_Link_List_Link_Id_INPUT}
    Input Text    ${Testing_Root_API_Link_List_Link_Id_INPUT}    ${Link_Id_0}
    Sleep    1
    Click Element    ${Operation_Select_BOX}
    Wait Until Page Contains Element    ${Post_OPERATION}
    Click Element    ${Post_OPERATION}
    Click Element    ${Action_Buttons_DIV}
    Focus    ${Send_BUTTON}
    Click Element    ${Send_BUTTON}
    Wait Until Page Contains Element    ${Error_sendin_request_Data_already_exists_ALERT}

Step_16_run
    Close DLUX
    