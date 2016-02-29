*** Settings ***
Documentation     Verification that "run request" button in history tab runs the requests POST, DELETE in history table.
Library           Selenium2Library    timeout=10    implicit_wait=10    #Library    Selenium2Library    timeout=10    implicit_wait=10
...               #run_on_failure=Log Source
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
    [Documentation]    Execute Delete operation on the level of network-topology with no data. 
    ...    Result
    ...    The page should contain: - REMOVE method, URL identical to one in preview box,
    ...    success status, no sent no received data.
    Step_05_run


Step_06
    [Documentation]    Execute the same request from History tab by clicking "run request" button.
    ...    Wait until page contains Request sent successfully alert.
    ...    If the page contains any request in history list, click Clear history data    
    ...    Result
    ...    The page should contain: - REMOVE method, URL identical to one in preview box,
    ...    success status, no sent no received data in 2nd row.
    Step_06_run    


Step_07
    [Documentation]    Expand "network-topology" arrow expander to load "topology-id" button.
    ...    Click + button to add topology-id. Execute POST operation to add topology-id.
    ...    The page should contain: - POST method, URL identical to one in preview box,
    ...    success status, success sent data.
    Step_07_run
    
    
Step_08
    [Documentation]    Execute the same request from History tab by clicking "run request" button.
    ...    Wait until page contains Wait until page contains Error sending request - : Data already exists for path:
    ...    If the page contains any request in history list, click Clear history data    
    ...    Result
    ...    The page should contain: - POST method, URL identical to one in preview box,
    ...    success status, success sent data in 2nd row.
    Step_08_run


Step_09
    [Documentation]    Click API tab. Load topology list button in customContainer area.
    ...    Execute DELETE operation. Click History Tab.
    ...    The page should contain: - REMOVE method, URL identical to one in preview box,
    ...    error status, no sent no received data.
    Step_09_run
    
    
Step_10
    [Documentation]    Execute the same request from History tab by clicking "run request" button.
    ...    Wait until page contains Wait until page contains Error sending request - : Missing key for list 
    ...    If the page contains any request in history list, click Clear history data    
    ...    Result
    ...    The page should contain: - REMOVE method, URL identical to one in preview box,
    ...    error status, no sent no received data in 2nd row.
    Step_10_run


Step_11
    [Documentation]    Close DLUX.
    Step_11_run


*** Keywords ***
Step_01_run
    Launch Or Open DLUX Page And Login DLUX


Step_02_run
    Navigate To Yang UI Submenu


Step_03_run
    Load Network-topology Button In CustomContainer Area
    Delete All Existing Topologies


Step_04_run
    Click Element    ${HISTORY_TAB}
    If History Table Contains Data Then Clear History Data


Step_05_run
    Execute Chosen Operation    ${Delete_OPERATION}    ${Request_sent_successfully_ALERT}
    Verify History Table Row Content    1    ${Remove_Method_NAME}    ${Success_STATUS}
    Verify No Sent No Received Data Elements Presence In History Table Row    1

    
Step_06_run
    Click History Table Execute Request Button In Row    1
    Wait Until Page Contains Element    ${Request_sent_successfully_ALERT}
    Close Alert Panel
    Verify History Table Row Content    2    ${Remove_Method_NAME}    ${Success_STATUS}
    Verify No Sent No Received Data Elements Presence In History Table Row    2
    If History Table Contains Data Then Clear History Data    
            

Step_07_run
    Click Element    ${Testing_Root_API_Network_Topology_Arrow_EXPANDER}
    Wait Until Page Contains Element    ${Testing_Root_API_Topology_List_Plus_BUTTON}    
    Click Element    ${Testing_Root_API_Topology_List_Plus_BUTTON}
    POST ID    ${Testing_Root_API_Topology_List_Topology_Id_INPUT}    ${Topology_Id_0}    ${Topology_ID}    ${Testing_Root_API_Topology_NAME}    
    Verify History Table Row Content    1    ${Post_Method_NAME}    ${Success_STATUS}
    Verify Sent Data Elements Presence In History Table Row    1

    
Step_08_run
    Click History Table Execute Request Button In Row    1
    Wait Until Page Contains Element    ${Error_sendin_request_Data_already_exists_ALERT}
    Close Alert Panel
    Verify History Table Row Content    2    ${Post_Method_NAME}    ${Error_STATUS}
    Verify No Sent No Received Data Elements Presence In History Table Row    2
    If History Table Contains Data Then Clear History Data
        
    
Step_09_run
    Click Element    ${API_TAB}
    Load Topology List Button In CustomContainer Area
    Execute Chosen Operation    ${Delete_OPERATION}    ${Error_sending_request_Missing_key_for_list_ALERT}
    Click Element    ${HISTORY_TAB}
    Verify History Table Row Content    1    ${Remove_Method_NAME}    ${Error_STATUS}
    Verify No Sent No Received Data Elements Presence In History Table Row    1
    ${History_Table_List_ROW}=    Return History Table Row Number    1
    ${History_Table_Row_Execute_Request_BUTTON}=    Set Variable    ${History_Table_List_ROW}//div[@class="tddiv rh-col7"]//button[@ng-click="executeRequest()"]
    Click Element    ${History_Table_Row_Execute_Request_BUTTON}
    Wait Until Page Contains Element    ${Error_sending_request_Missing_key_for_list_ALERT}
    Close Alert Panel
    

Step_10_run
    Verify History Table Row Content    2    ${Remove_Method_NAME}    ${Error_STATUS}
    Verify No Sent No Received Data Elements Presence In History Table Row    2
    If History Table Contains Data Then Clear History Data
    Delete All Existing Topologies


Step_11_run
    Close DLUX
