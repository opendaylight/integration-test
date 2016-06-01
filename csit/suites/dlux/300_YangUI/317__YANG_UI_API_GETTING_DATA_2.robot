*** Settings ***
Documentation     Verification that "GET" operation is executed successfully on 
...    topology, nodes and links level, i.e. that data previously PUT are, after
...    getting it, displayed in customContainer Area.  
#Library           Selenium2Library    timeout=10    implicit_wait=10     run_on_failure=Log Source
Library           Selenium2Library    timeout=10    implicit_wait=10     
Resource          ../../../libraries/GUIKeywords.robot
Resource          ../../../libraries/Utils.robot
Resource          ../../../libraries/YangUIKeywords.robot
#Suite Teardown    Close Browser
#Suite Teardown    Run Keywords    Delete All Existing Topologies    Close Browser

*** Variables ***


*** Test Cases ***
Step_01
    [Documentation]    Open OpenDayLight page.
    ...    Result
    ...    Page http://127.0.0.1:8181/index.html#/login opened.
    ...    Login formular present on the page.
    Step_01_run

Step_02
    [Documentation]    Insert valid credentials and hit "Login" button. Navigate to Yang UI.
    ...    Result
    ...    Location is http://127.0.0.1:8181/index.html#/topology.
    ...    Verification that the page contains "Controls" and button "Reload",
    ...    and Yang UI Submenu. Location should be http://127.0.0.1:8181/index.html#/yangui/index.
    Step_02_run

Step_03
    [Documentation]   Load Network-topology Button in customContainer Area
    ...    Result
    ...    The page contains "network-topology" arrow expander and "network-topology"  
    ...    button in customContainer Area.     
    Step_03_run

Step_04
    [Documentation]    Expand "network-topology" plus expander.
    ...    Result
    ...    The page contains "topology {topology-id}" plus expander (4th level of 
    ...    tree rows) and "topology {topology-id}" element in API tree.
    Step_04_run

Step_05
    [Documentation]   Click "topology {topology-id}" element in API tree.
    ...    Result
    ...    The page contains: - "topology list" arrow expander, - "topology list" button,
    ...    - iconPlus, - topology id path Wrapper input. 
    Step_05_run  

Step_06
    [Documentation]   Insert topolgy-id into topology id path Wrapper input, 
    ...    choose GET operation and hit "Send" button. Topology-id value: t0
    ...    Result
    ...    The page contains: - "Request sent successfully" alert,
    ...    - "topology <topology-id: t0>" button and iconClose button;
    ...    - "node <node-id: t1n0>" button and iconClose button;
    ...    - "link <link-id: t1l0>" button and iconClose button. 
    Step_06_run

Step_07
    [Documentation]   Close alert. Hit topology iconClose button.
    ...    The page DOES NOT CONTAIN: - "topology <topology-id: t0>" button and iconClose button;
    ...    - "node <node-id: t1n0>" button and iconClose button;
    ...    - "link <link-id: t1l0>" button and iconClose button. 
    Step_07_run

Step_08
    [Documentation]   Expand "topology {topology-id}" plus expander and click
    ...    "node {node-id}" element in API tree.
    ...    Result
    ...    The page contains: - "node list" arrow expander, - "node list" button,
    ...    - iconPlus, - topology id path Wrapper input, - node id path Wrapper input.
    Step_08_run

Step_09
    [Documentation]   Insert topology-id into topology id path Wrapper input.
    ...    Insert node-id into node id path Wrapper input. Choose GET operation 
    ...    and hit "Send" button. Topology-id value: t0; Node-id value: t0n0.
    ...    Result
    ...    The page contains: - "Request sent successfully" alert
    ...    - "node <node-id: t1n0>" button and iconClose button.
    Step_09_run

Step_10
    [Documentation]   Close alert. Hit node iconClose button.
    ...    The page DOES NOT CONTAIN: - "node <node-id: t1n0>" button and iconClose button.
    Step_10_run

Step_11
    [Documentation]   Click "node {node-id}" element in API tree.
    ...    Result
    ...    The page contains: - "link list" arrow expander, - "link list" button,
    ...    - iconPlus, - topology id path Wrapper input, - link id path Wrapper input.
    Step_11_run

Step_12
    [Documentation]    Insert topology-id into topology id path Wrapper input.
    ...    Insert link-id into link id path Wrapper input. Choose GET operation 
    ...    and hit "Send" button. Topology-id value: t0; Link-id value: t0l0.
    ...    Result
    ...    The page contains: - "Request sent successfully" alert,
    ...    - "link <link-id: t1l0>" button and iconClose button.
    Step_12_run

Step_13
    [Documentation]   Close alert. Hit link iconClose button.
    ...    The page DOES NOT CONTAIN: - "link <link-id: t1n0>" button and iconClose button.
    Step_13_run
    
Step_14
    [Documentation]    Close DLUX.
    Step_14_run


*** Keywords ***
Step_01_run
    Launch Or Open DLUX Page And Login DLUX


Step_02_run
    Navigate To Yang UI Submenu

Step_03_run
    Load Network-topology Button In CustomContainer Area
    
Step_04_run
    Click Element    ${Testing_Root_API_Network_Topology_Plus_EXPANDER}
    Wait Until Page Contains Element    ${Testing_Root_API_Topology_Topology_Id_Plus_EXPANDER}
    
Step_05_run    
    Click Element    ${Testing_Root_API_Topology_Topology_Id_XPATH}
    Page Should Contain Element    ${Testing_Root_API_Topology_List_BUTTON}
    Page Should Contain Element    ${Testing_Root_API_Topology_List_Arrow_Expander}
    Page Should Contain Element    ${Testing_Root_API_Topology_List_Plus_BUTTON}
    Page Should Contain Element    ${Topology_Id_Path_Wrapper_INPUT}

Step_06_run
    Focus    ${Topology_Id_Path_Wrapper_INPUT}
    Input Text    ${Topology_Id_Path_Wrapper_INPUT}    ${Topology_Id_0}        
    Execute Chosen Operation    ${Get_OPERATION}    ${Request_sent_successfully_ALERT}    
        
    Verify Chosen_Id Presence On The Page    ${Topology_Id_0}    ${Topology_ID}    ${Testing_Root_API_Topology_List_NAME}
    Verify Chosen_Id Presence On The Page    ${Node_Id_0}    ${Node_ID}    ${Testing_Root_API_Node_List_NAME}
    Verify Chosen_Id Presence On The Page    ${Link_Id_0}    ${Link_ID}    ${Testing_Root_API_Link_List_NAME}

Step_07_run
    ${Topology_ID}=    Set Variable    ${Topology_Id_0}
    Click Element    ${Testing_Root_API_Topology_List_Topology_Delete_BUTTON}
    Sleep    1
    Verify Chosen_Id NON-Presence On The Page    ${Topology_Id_0}    ${Topology_ID}    ${Testing_Root_API_Topology_List_NAME}
    Verify Chosen_Id NON-Presence On The Page    ${Node_Id_0}    ${Node_ID}    ${Testing_Root_API_Node_List_NAME}        
    Verify Chosen_Id NON-Presence On The Page    ${Link_Id_0}    ${Link_ID}    ${Testing_Root_API_Link_List_NAME}            
    
Step_08_run
    Click Element    ${Testing_Root_API_Topology_Topology_Id_Plus_EXPANDER}
    Wait Until Page Contains Element    ${Testing_Root_API_Node_Node_Id_Plus_EXPANDER}
    Page Should Contain Element    ${Testing_Root_API_Link_Link_Id_Plus_EXPANDER}
    
    Click Element    ${Testing_Root_API_Node_Node_Id_XPATH}
    Wait Until Page Contains Element    ${Testing_Root_API_Node_List_BUTTON}
    Page Should Contain Button    ${Testing_Root_API_Node_List_Arrow_EXPANDER}
    Page Should Contain Element    ${Testing_Root_API_Node_List_Plus_BUTTON}
    Page Should Contain Element    ${Topology_Id_Path_Wrapper_INPUT} 
    Page Should Contain Element    ${Node_Id_Path_Wrapper_INPUT}        

Step_09_run
    Focus    ${Topology_Id_Path_Wrapper_INPUT}
    Input Text    ${Topology_Id_Path_Wrapper_INPUT}    ${Topology_Id_0}
    Focus    ${Node_Id_Path_Wrapper_INPUT}    
    Input Text    ${Node_Id_Path_Wrapper_INPUT}    ${Node_Id_0}                
    Execute Chosen Operation    ${Get_OPERATION}    ${Request_sent_successfully_ALERT}    
        
    Verify Chosen_Id Presence On The Page    ${Node_Id_0}    ${Node_ID}    ${Testing_Root_API_Node_List_NAME}

Step_10_run
    ${Node_ID}=    Set Variable    ${Node_Id_0}
    Click Element    ${Testing_Root_API_Node_List_Node_Delete_BUTTON}
    Sleep    1
    
    Verify Chosen_Id NON-Presence On The Page    ${Node_Id_0}    ${Node_ID}    ${Testing_Root_API_Node_List_NAME}        

Step_11_run
    Click Element    ${Testing_Root_API_Link_Link_Id_XPATH}
    Wait Until Page Contains Element    ${Testing_Root_API_Link_List_BUTTON}
    Page Should Contain Button    ${Testing_Root_API_Link_List_Arrow_EXPANDER}
    Page Should Contain Element    ${Testing_Root_API_Link_List_Plus_BUTTON}
    Page Should Contain Element    ${Topology_Id_Path_Wrapper_INPUT} 
    Page Should Contain Element    ${Link_Id_Path_Wrapper_INPUT}

Step_12_run
    Focus    ${Topology_Id_Path_Wrapper_INPUT}
    Input Text    ${Topology_Id_Path_Wrapper_INPUT}    ${Topology_Id_0}
    Focus    ${Link_Id_Path_Wrapper_INPUT}    
    Input Text    ${Link_Id_Path_Wrapper_INPUT}    ${Link_Id_0}                
    Execute Chosen Operation    ${Get_OPERATION}    ${Request_sent_successfully_ALERT}    
        
    Verify Chosen_Id Presence On The Page    ${Link_Id_0}    ${Link_ID}    ${Testing_Root_API_Link_List_NAME}    

Step_13_run 
    ${Link_ID}=    Set Variable    ${Link_Id_0}
    Click Element    ${Testing_Root_API_Link_List_Link_Delete_BUTTON}
    Sleep    1    
    
    Verify Chosen_Id NON-Presence On The Page    ${Link_Id_0}    ${Link_ID}    ${Testing_Root_API_Link_List_NAME}

Step_14_run
    Close DLUX
    
           
    
                  