*** Settings ***
Documentation     Verification that "PUT" operation rewrites an ID by the same ID
...    and does not return any error message. 
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
    [Documentation]   Expand chosen testing root API. Expand "config" plus 
    ...    expander under chosen testing root API.
    ...    Result
    ...    The page contains "network-tolopogy" plus expander (3rd level
    ...    of tree rows) and "network-tpology" element in API tree.
    Step_03_run

Step_04
    [Documentation]    Click "network-topology" element in API tree.
    ...    Result
    ...    The page contains "network-topology" arrow expander and "network-topology"  
    ...    button in customContainer Area. 
    Step_04_run    

Step_05
    [Documentation]    Click "network topology" arrow expander in customContainer 
    ...    Area.
    ...    Result
    ...    The page contains "topology list" arrow expander and "topology list" 
    ...    button, and iconPlus in customContainer Area. 
    Step_05_run

Step_06
    [Documentation]   Click "topology list" iconPlus to add new topolgy.
    ...    Result
    ...    The page contains: - "topology [0]" button, - iconClose button (X button),
    ...    - "topology-id" label, - input field (for topology id).
    ...    The page contains: - "node list"  button, - iconPlus.
    ...    The page contains: - "link list"  button, - iconPlus.
    Step_06_run

Step_07
    [Documentation]   Insert topolgy-id, choose PUT operation and hit "Send" button.
    ...    Topology-id value: t0. Execute instruction 2x.
    ...    Result
    ...    The page contains "Request sent successfully" message and 
    ...    "topology <topology-id: t0>" button and iconClose button.   
    Step_07_run  

Step_08
    [Documentation]   Click "node list" iconPlus to add new node.
    ...    Result
    ...    The page contains: - "node [0]" button, - iconClose button (X button).
    ...    The page contains: - "node-id" label, - input field (for node id).
    Step_08_run
    
Step_09
    [Documentation]    Insert node-id into input field, choose PUT operation and
    ...    hit "Send" button. Node-id value: t1n0. Execute instruction 2x.
    ...    Result
    ...    The page contains "Request sent successfully" message and 
    ...    "node <node-id: t1n0>" button and iconClose button.   
    Step_09_run
    
Step_10
    [Documentation]    Click "link list" iconPlus to add new link.
    ...    Result
    ...    The page contains: - "link [0]" button, - iconClose button (X button),
    ...    - "link-id" label, - input field (for node id).
    Step_10_run    

Step_11
    [Documentation]    Insert link-id into input field, choose PUT operation and
    ...    hit "Send" button. Link-ide value: t1l0. Execute instruction 2x.
    ...    Result
    ...    The page contains "Request sent successfully" message and 
    ...    "link <link-id: t1l0>" button and iconClose button. 
    Step_11_run

Step_12
    [Documentation]    Close Dlux or Close Browser.
    Step_12_run


*** Keywords ***
Step_01_run
    Launch Or Open DLUX Page And Login DLUX


Step_02_run
    Navigate To Yang UI Submenu

Step_03_run
    Click Element    ${Testing_Root_API_EXPANDER}
    Wait Until Page Contains Element    ${Testing_Root_API_Config_EXPANDER}
    Click Element    ${Testing_Root_API_Config_EXPANDER}
    Wait Until Page Contains Element    ${Testing_Root_API_Network_Topology_Plus_EXPANDER}
    
Step_04_run
    Click Element    ${Testing_Root_API_Network_Topology_XPATH}
    Wait Until Page Contains Element    ${Testing_Root_API_Network_Topology_BUTTON}
    Page Should Contain Button    ${Testing_Root_API_Network_Topology_Arrow_EXPANDER}
    
Step_05_run    
    Click Element    ${Testing_Root_API_Network_Topology_Arrow_EXPANDER}
    Wait Until Page Contains Element    ${Testing_Root_API_Topology_List_BUTTON}
    Page Should Contain Element    ${Testing_Root_API_Topology_List_Arrow_EXPANDER}
    Page Should Contain Element    ${Testing_Root_API_Topology_List_Plus_BUTTON}
    
Step_06_run
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

Step_07_run
    ${repetition_amount}=    Set Variable    2
    Repeat Keyword    ${repetition_amount} times
    ...    PUT ID    ${Testing_Root_API_Topology_List_Topology_Id_INPUT}    ${Topology_Id_0}    ${Topology_ID}    ${Testing_Root_API_Topology_List_NAME}
          
Step_08_run    
    Click Element    ${Testing_Root_API_Node_List_Plus_BUTTON}    
    ${Node_ID}=    Set Variable    ${Default_ID}     
    
    Wait Until Page Contains Element    ${Testing_Root_API_Node_List_Node_Id_BUTTON}    
    
    Page Should Contain Element    ${Testing_Root_API_Node_List_Node_Delete_BUTTON}
    Page Should Contain Element    ${Testing_Root_API_Node_List_Node_Id_LABEL}
    Page Should Contain Element    ${Testing_Root_API_Node_List_Node_Id_INPUT}   
    
Step_09_run
    ${repetition_amount}=    Set Variable    2
    Repeat Keyword    ${repetition_amount} times
    ...    PUT ID    ${Testing_Root_API_Node_List_Node_Id_INPUT}    ${Node_Id_0}    ${Node_ID}    ${Testing_Root_API_Node_List_NAME}
    
Step_10_run
    Click Element    ${Testing_Root_API_Link_List_Plus_BUTTON}    
    ${Link_ID}=    Set Variable    ${Default_ID}     
    
    Wait Until Page Contains Element    ${Testing_Root_API_Link_List_Link_Id_BUTTON}    
    
    Page Should Contain Element    ${Testing_Root_API_Link_List_Link_Id_LABEL}
    Page Should Contain Element    ${Testing_Root_API_Link_List_Link_Delete_BUTTON}
    Page Should Contain Element    ${Testing_Root_API_Link_List_Link_Id_INPUT}

Step_11_run
    ${repetition_amount}=    Set Variable    2
    Repeat Keyword    ${repetition_amount} times
    ...    PUT ID    ${Testing_Root_API_Link_List_Link_Id_INPUT}    ${Link_Id_0}    ${Link_ID}    ${Testing_Root_API_Link_List_NAME}

Step_12_run
    Close DLUX

                  