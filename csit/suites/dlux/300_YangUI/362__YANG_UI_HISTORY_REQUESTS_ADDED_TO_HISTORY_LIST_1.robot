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
    [Documentation]   Load "netowork-topology" button in customContainer Area.
    ...    Result
    ...    The page contains "network-tolopogy" plus expander (3rd level
    ...    of tree rows) and "network-tpology" element in API tree. The page contains
    ...    "network-topology" arrow expander and "network-topology" button in customContainer Area. 
    Step_03_run

Step_04
    [Documentation]    Click HISTORY tab. If the page contains any request in 
    ...    history list, click Clear history data
    ...    Result
    ...    The page does not contain History table row.
    Step_04_run

    
Step_05
    [Documentation]    Select DELETE operation and click Send button.
    ...    Result
    ...    The page should contain:- Request sent successfully msg, - Remove method,
    ...    - URL identical to one in preview box, - status success, - disabled "Sent data" button,
    ...    - disabled "Received data" button, - "Execute request" button, - Add to collection button,
    ...    - disabled "Fill data"  button, - "Delete" button.    
    Step_05_run

Step_06
    [Documentation]    If the page contains any request in history list, click Clear history data.
    ...    Expand network-topology arrow expander in custom Container area. Click + button and add new topology id.
    ...    Topology id: t0. Execute POST operation.
    ...    The page should contain:- Request sent successfully msg, - POST method,
    ...    - URL identical to one in preview box, - status success, - enabled "Sent data" button,
    ...    - disabled "Received data" button, - "Execute request" button, - Add to collection button,
    ...    - enabled "Fill data"  button, - "Delete" button.
    Step_06_run

Step_07
    [Documentation]    If the page contains any request in history list, click Clear history data.
    ...    If the page does not contain network-topology arrow expander, expand network-topology arrow expander in custom Container area. Click + button and add new topology id.
    ...    Topology id: t1. Execute PUT operation.
    ...    The page should contain:- Request sent successfully msg, - POST method,
    ...    - URL identical to one in preview box, - status success, - enabled "Sent data" button,
    ...    - disabled "Received data" button, - "Execute request" button, - Add to collection button,
    ...    - enabled "Fill data"  button, - "Delete" button.
    Step_07_run

Step_08
    [Documentation]    If the page contains any request in history list, click Clear history data.
    ...    If the page does not contain network-topology arrow expander, expand network-topology arrow expander in custom Container area.
    ...    Execute GET operation.
    ...    The page should contain:- Request sent successfully msg, - GET method,
    ...    - URL identical to one in preview box, - status success, - disabled "Sent data" button,
    ...    - enabled "Received data" button, - "Execute request" button, - Add to collection button,
    ...    - enabled "Fill data"  button, - "Delete" button.
    Step_08_run    

Step_09
    [Documentation]    Close DLUX.
    Step_09_run

*** Keywords ***
Step_01_run
    Launch Or Open DLUX Page And Login DLUX


Step_02_run
    Navigate To Yang UI Submenu


Step_03_run
    Load Network-topology Button In CustomContainer Area
    
    
Step_04_run 
    Click Element    ${HISTORY_TAB}
    If History Table Contains Data Then Clear History Data
  

Step_05_run
    Execute Chosen Operation    ${Delete_OPERATION}    ${Request_sent_successfully_ALERT}
    Verify No Sent No Received Data Elements Presence In History Table Row    1                 


Step_06_run
    If History Table Contains Data Then Clear History Data
    
    ${status}=    Run Keyword And Return Status    Page Should Contain Element    ${Testing_Root_API_Topology_List_Plus_BUTTON}
    Run Keyword If    "${status}"=="False"    Click Element    ${Testing_Root_API_Network_Topology_Arrow_EXPANDER}
    Wait Until Page Contains Element    ${Testing_Root_API_Topology_List_Plus_BUTTON}    
    Click Element    ${Testing_Root_API_Topology_List_Plus_BUTTON}
    Wait Until Page Contains Element    ${Testing_Root_API_Topology_List_Topology_Id_INPUT}    
    POST ID    ${Testing_Root_API_Topology_List_Topology_Id_INPUT}    ${Topology_Id_0}    ${Topology_ID}    ${Testing_Root_API_Topology_List_NAME}
    
    Verify Sent Data Elements Presence In History Table Row    1


Step_07_run
    If History Table Contains Data Then Clear History Data
        
    ${status}=    Run Keyword And Return Status    Page Should Contain Element    ${Testing_Root_API_Topology_List_Plus_BUTTON}
    Run Keyword If    "${status}"=="False"    Click Element    ${Testing_Root_API_Network_Topology_Arrow_EXPANDER}
    
    Wait Until Page Contains Element    ${Testing_Root_API_Topology_List_Plus_BUTTON}    
    Click Element    ${Testing_Root_API_Topology_List_Plus_BUTTON}
    Wait Until Page Contains Element    ${Testing_Root_API_Topology_List_Topology_Id_INPUT}    
    PUT ID    ${Testing_Root_API_Topology_List_Topology_Id_INPUT}    ${Topology_Id_1}    ${Topology_ID}    ${Testing_Root_API_Topology_List_NAME}
    
   Verify Sent Data Elements Presence In History Table Row    1
   
   
Step_08_run
    If History Table Contains Data Then Clear History Data
        
    Page Should Contain Element    ${Testing_Root_API_Network_Topology_BUTTON}
    
    Execute Chosen Operation    ${Get_OPERATION}    ${Request_sent_successfully_ALERT}
    
    Verify Received Data Elements Presence In History Table Row    1
    
Step_09_run
    Close DLUX 
    

        


    
           
    
                  