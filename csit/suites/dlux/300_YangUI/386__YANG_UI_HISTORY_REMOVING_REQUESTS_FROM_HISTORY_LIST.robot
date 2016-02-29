*** Settings ***
Documentation     Verification that various operations are added to request history list. 
#Library           Selenium2Library    timeout=10    implicit_wait=10     run_on_failure=Log Source
Library           Selenium2Library    timeout=10    implicit_wait=10
Library           ../../../libraries/YangUILibrary.py     
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
${Topology_Id_1}    t1
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
    [Documentation]    Insert valid credentials and hit "Login" button. Navigate to Yang UI.
    ...    Result
    ...    Location is http://127.0.0.1:8181/index.html#/topology.
    ...    Verification that the page contains "Controls" and button "Reload",
    ...    and Yang UI Submenu.
    ...    Location should be http://127.0.0.1:8181/index.html#/yangui/index.
    Step_02_run

Step_03
    [Documentation]    Load "network-topology" button in customContainer Area. Delete
    ...    all existing topologies.
    ...    Result
    ...    The page contains "network-topology" arrow expander and button in customContainer Area.
    Step_03_run

Step_04
    [Documentation]    Click HISTORY tab. If the page contains any request in 
    ...    history list, click Clear history data
    ...    Result
    ...    The page does not contain History table row.
    Step_04_run

    
Step_05
    [Documentation]    Execute  DELETE operation on the level of network-topology.
    ...    Result
    ...    The page should contain: - Request sent successfully msg, - REMOVE method,
    ...    - URL identical to one in preview box, - status success, - no sent no received data elements.   
    Step_05_run

Step_06
    [Documentation]    Click "delete" button to remove the request from history list.
    ...    Result
    ...    The page does not contain History list.
    Step_06_run
    
Step_07
    [Documentation]    Expand network-topology arrow expander in custom Container area.
    ...    Click + button to add new topology id. Execute POST operation with data Topology id = t0.
    ...    Click topology id delete button.
    ...    Result
    ...    The page should contain: - Request sent successfully msg, - POST method,
    ...    - URL identical to one in preview box, - status success, - sent data elements.
    Step_07_run
  
    
Step_08
    [Documentation]    Click "delete" button to remove the request from history list.
    ...    Result
    ...    The page does not contain History list.
    Step_08_run    


Step_09
    [Documentation]    Click + button to add new topology id. Execute PUT operation 
    ...    with data Topology id = t1. Click topology id delete button.
    ...    Result
    ...    The page should contain: - Request sent successfully msg, - PUT method,
    ...    - URL identical to one in preview box, - status success, - sent data elements.
    Step_09_run    

Step_10
    [Documentation]    Click "delete" button to remove the request from history list.
    ...    Result
    ...    The page does not contain History list.
    Step_10_run

Step_11
    [Documentation]    Verify that the page contains network-topology button. Execute GET operation.
    ...    Result
    ...    The page should contain: - Request sent successfully msg, - GET method,
    ...    - URL identical to one in preview box, - status success, - received data elements.
    Step_11_run

Step_12
    [Documentation]    Click "delete" button to remove the request from history list.
    ...    Delete all existing topologies.
    ...    Result
    ...    The page does not contain History list.
    Step_12_run

Step_13
    [Documentation]    Close DLUX.
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
    Navigate To Yang UI Submenu


Step_03_run
    Load Network-topology Button In CustomContainer Area
    
    
Step_04_run 
    Click Element    ${HISTORY_TAB}
    If History Table Contains Data Then Clear History Data
  

Step_05_run
    Execute Chosen Operation    ${Delete_OPERATION}    ${Request_sent_successfully_ALERT}
    Verify History Table Row Content    1    ${Remove_Method_NAME}    ${Success_Status}
    Verify No Sent No Received Data Elements Presence In History Table Row    1                 


Step_06_run
    Click History Table Delete Request Button In Row    1
    ${History_Table_List_ROW}=    Return History Table Row Number    1
    Wait Until Page Does Not Contain Element    ${History_Table_List_ROW}        
    
   
Step_07_run
    Expand Network Topology Arrow Expander
    Wait Until Page Contains Element    ${Testing_Root_API_Topology_List_Plus_BUTTON}    
    Click Element    ${Testing_Root_API_Topology_List_Plus_BUTTON}
    Wait Until Page Contains Element    ${Testing_Root_API_Topology_List_Topology_Id_INPUT}
    Insert Text To Input Field    ${Testing_Root_API_Topology_List_Topology_Id_INPUT}    ${Topology_Id_0}    
    Execute Chosen Operation    ${Post_OPERATION}    ${Request_sent_successfully_ALERT}
    Verify History Table Row Content    1    ${Post_Method_NAME}    ${Success_Status} 
    Verify Sent Data Elements Presence In History Table Row    1


Step_08_run
    Click History Table Delete Request Button In Row    1
    ${History_Table_List_ROW}=    Return History Table Row Number    1
    Wait Until Page Does Not Contain Element    ${History_Table_List_ROW}   
   
   
Step_09_run
    Close Form In CustomContainer Area    ${Testing_Root_API_Topology_List_Topology_Delete_BUTTON}    ${Testing_Root_API_Topology_List_Topology_Id_INPUT}    
    Click Element    ${Testing_Root_API_Topology_List_Plus_BUTTON}
    Wait Until Page Contains Element    ${Testing_Root_API_Topology_List_Topology_Id_INPUT}
    Insert Text To Input Field    ${Testing_Root_API_Topology_List_Topology_Id_INPUT}    ${Topology_Id_1}
    Execute Chosen Operation    ${Put_OPERATION}    ${Request_sent_successfully_ALERT}
    Verify History Table Row Content    1    ${Put_Method_NAME}    ${Success_Status} 
    Verify Sent Data Elements Presence In History Table Row    1


Step_10_run
    Click History Table Delete Request Button In Row    1
    ${History_Table_List_ROW}=    Return History Table Row Number    1
    Wait Until Page Does Not Contain Element    ${History_Table_List_ROW}
    

Step_11_run
    Page Should Contain Element    ${Testing_Root_API_Network_Topology_BUTTON}
    Execute Chosen Operation    ${Get_OPERATION}    ${Request_sent_successfully_ALERT}
    Verify History Table Row Content    1    ${Get_Method_NAME}    ${Success_Status} 
    Verify Received Data Elements Presence In History Table Row    1

    
Step_12_run
    Click History Table Delete Request Button In Row    1
    ${History_Table_List_ROW}=    Return History Table Row Number    1
    Wait Until Page Does Not Contain Element    ${History_Table_List_ROW}
    Delete All Existing Topologies
    
Step_13_run
    Close DLUX 
    

        


    
           
    
                  