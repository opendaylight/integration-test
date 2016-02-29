*** Settings ***
Documentation     Verification that "run request" button in history tab runs the requests GET, PUT in history table.
Library           Selenium2Library    timeout=10    implicit_wait=10    #Library    Selenium2Library    timeout=10    implicit_wait=10
...               #run_on_failure=Log Source
Library           ../../../libraries/YangUILibrary.py
Resource          ../../../libraries/GUIKeywords.robot
Resource          ../../../libraries/Utils.robot
Resource          ../../../libraries/YangUIKeywords.robot    
#Suite Teardown    Close Browser    
#Suite Teardown    Run Keywords    Delete All Existing Topologies    Close Browser

*** Variables ***
${LOGIN_USERNAME}    admin
${LOGIN_PASSWORD}    admin
${Default_ID}     [0]
${Row_NUMBER}    1
${History_Table_List_ROW}    ${History_TABLE}//div[@ng-repeat="req in requestList.list track by $index"][${Row_NUMBER}]
${Topology_Id_0}    t0
${Link_Id_0}    tol0


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
    [Documentation]    Execute GET operation on the level of network-topology with no data. 
    ...    Result
    ...    The page should contain: - GET method, URL identical to one in preview box, 
    ...    error status, no sent no received data.
    Step_05_run


Step_06
    [Documentation]    Execute the same request from History tab by clicking "run request" button.
    ...    Wait until page contains Data-missing : Request could not be completed because the relevant data model
    ...    content does not exist. - : Request could not be completed because the relevant 
    ...    data model content does not exist alert.
    ...    If the page contains any request in history list, click Clear history data    
    ...    Result
    ...    The page should contain: - GET method, URL identical to one in preview box, 
    ...    error status, no sent no received data in 2nd row.
    Step_06_run    


Step_07
    [Documentation]    Execute PUT operation to add topology-id. Topology-id: t0
    ...    The page should contain: - PUT method, URL identical to one in preview box,
    ...    success status, success sent data.
    Step_07_run
    
    
Step_08
    [Documentation]    Execute the same request from History tab by clicking "run request" button.
    ...    Wait until page contains Request sent succesfuly.
    ...    If the page contains any request in history list, click Clear history data    
    ...    Result
    ...    The page should contain: - PUT method, URL identical to one in preview box,
    ...    success status, success sent data in 2nd row.
    Step_08_run


Step_09
    [Documentation]    Execute GET operation on the level of network-topology.
    ...    The page should contain: - GET method, URL identical to one in preview box,
    ...    success status, success received data.
    Step_09_run
    
    
Step_10
    [Documentation]    Execute the same request from History tab by clicking "run request" button.
    ...    Wait until page contains Request sent succesfuly.
    ...    If the page contains any request in history list, click Clear history data    
    ...    Result
    ...    The page should contain: - GET method, URL identical to one in preview box,
    ...    success status, success received data in 2nd row.
    Step_10_run


Step_11
    [Documentation]    Click topology-id plus button to input topology id. Insert no data
    ...    in topology id input field and Execute PUT operation.
    ...    Result
    ...    The page should contain: - PUT method, URL identical to one in preview box,
    ...    error status, no sent no received data.
    Step_11_run
    
    
Step_12
    [Documentation]    Execute the same request from History tab by clicking "run request" button.
    ...    Wait until page contains Error sending request - : Input is required.
    ...    If the page contains any request in history list, click Clear history data    
    ...    Result
    ...    The page should contain: - PUT method, URL identical to one in preview box,
    ...    error status, no sent no received data in 2nd row.
    Step_12_run
    

Step_13
    [Documentation]    Execute PUT operation with data Topology id = "empty", Node id = "empty",
    ...    Link id = "t0l0"
    ...    Result
    ...    The page should contain: - PUT method, URL identical to one in preview box,
    ...    error status, sent data elements.
    Step_13_run
    
    
Step_14
    [Documentation]    Execute the same request from History tab by clicking "run request" button.
    ...    Wait until page contains Error sending request - : Error parsing input: Input is 
    ...    missing some of the keys of alert.   
    ...    Result
    ...    The page should contain: - PUT method, URL identical to one in preview box,
    ...    error status, sent data elements in 2nd row.
    Step_14_run    
    

Step_15
    [Documentation]    Close DLUX.
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
    Navigate To Yang UI Submenu


Step_03_run
    Load Network-topology Button In CustomContainer Area
    Load Topology List Button In CustomContainer Area
    Delete All Existing Topologies


Step_04_run
    Click Element    ${HISTORY_TAB}
    If History Table Contains Data Then Clear History Data


Step_05_run
    Execute Chosen Operation    ${Get_OPERATION}    ${Data_missing_Relevant_data_model_not_existing_ALERT}
    Verify History Table Row Content    1    ${Get_Method_NAME}    ${Error_STATUS}
    Verify No Sent No Received Data Elements Presence In History Table Row    1

    
Step_06_run
    Click History Table Execute Request Button In Row    1
    Wait Until Page Contains Element    ${Data_missing_Relevant_data_model_not_existing_ALERT}
    Close Alert Panel
    Verify History Table Row Content    2    ${Get_Method_NAME}    ${Error_STATUS}
    Verify No Sent No Received Data Elements Presence In History Table Row    2
    If History Table Contains Data Then Clear History Data
            

Step_07_run
    Click Element    ${Testing_Root_API_Network_Topology_Arrow_EXPANDER}
    Wait Until Page Contains Element    ${Testing_Root_API_Topology_List_Plus_BUTTON}    
    Click Element    ${Testing_Root_API_Topology_List_Plus_BUTTON}
    Insert Text To Input Field    ${Testing_Root_API_Topology_List_Topology_Id_INPUT}    ${Topology_Id_0}        
    Execute Chosen Operation    ${Put_OPERATION}    ${Request_sent_successfully_ALERT}
    Verify History Table Row Content    1    ${Put_Method_NAME}    ${Success_STATUS}
    Verify Sent Data Elements Presence In History Table Row    1

    
Step_08_run
    Click History Table Execute Request Button In Row    1
    Wait Until Page Contains Element    ${Request_sent_successfully_ALERT}
    Verify History Table Row Content    2    ${Put_Method_NAME}    ${Success_STATUS}
    Verify Sent Data Elements Presence In History Table Row    2
    If History Table Contains Data Then Clear History Data
    Close Form In CustomContainer Area    ${Testing_Root_API_Topology_List_Topology_Delete_BUTTON}    ${Testing_Root_API_Topology_List_Topology_Id_INPUT}    
        
    
Step_09_run
    Click Element    ${Testing_Root_API_Topology_List_Plus_BUTTON}
    Insert Text To Input Field    ${Testing_Root_API_Topology_List_Topology_Id_INPUT}    ${Topology_Id_0}        
    Execute Chosen Operation    ${Get_OPERATION}    ${Request_sent_successfully_ALERT}
    Verify History Table Row Content    1    ${Get_Method_NAME}    ${Success_STATUS}
    Verify Received Data Elements Presence In History Table Row    1


Step_10_run
    Click History Table Execute Request Button In Row    1
    Wait Until Page Contains Element    ${Request_sent_successfully_ALERT}
    Verify History Table Row Content    2    ${Get_Method_NAME}    ${Success_STATUS}
    Verify Received Data Elements Presence In History Table Row    2
    If History Table Contains Data Then Clear History Data
    Close Form In CustomContainer Area    ${Testing_Root_API_Topology_List_Topology_Delete_BUTTON}    ${Testing_Root_API_Topology_List_Topology_Id_INPUT}


Step_11_run
    Click Element    ${Testing_Root_API_Topology_List_Plus_BUTTON}
    Insert Text To Input Field    ${Testing_Root_API_Topology_List_Topology_Id_INPUT}    ${EMPTY}        
    Execute Chosen Operation    ${Put_OPERATION}    ${Error_sending_request_Error_parsing_input_missing_keys_ALERT}
    Verify History Table Row Content    1    ${Put_Method_NAME}    ${Error_STATUS}
    Verify Sent Data Elements Presence In History Table Row    1

    
Step_12_run
    Click History Table Execute Request Button In Row    1
    Wait Until Page Contains Element    ${Error_sending_request_Error_parsing_input_missing_keys_ALERT}
    Verify History Table Row Content    2    ${Put_Method_NAME}    ${Error_STATUS}
    Verify Sent Data Elements Presence In History Table Row    2
    If History Table Contains Data Then Clear History Data
    Close Form In CustomContainer Area    ${Testing_Root_API_Topology_List_Topology_Delete_BUTTON}    ${Testing_Root_API_Topology_List_Topology_Id_INPUT}
    
    
Step_13_run
    Insert Topology Or Node Or Link Id In Form    ${EMPTY}    ${EMPTY}    ${Link_Id_0}
    Execute Chosen Operation    ${Put_OPERATION}    ${Error_sending_request_Error_parsing_input_missing_keys_ALERT}
    Verify History Table Row Content    1    ${Put_Method_NAME}    ${Error_STATUS}
    Verify Sent Data Elements Presence In History Table Row    1

    
Step_14_run
    Click History Table Execute Request Button In Row    1
    Wait Until Page Contains Element    ${Error_sending_request_Error_parsing_input_missing_keys_ALERT}
    Verify History Table Row Content    2    ${Put_Method_NAME}    ${Error_STATUS}
    Verify Sent Data Elements Presence In History Table Row    2
    If History Table Contains Data Then Clear History Data
    Close Form In CustomContainer Area    ${Testing_Root_API_Topology_List_Topology_Delete_BUTTON}    ${Testing_Root_API_Topology_List_Topology_Id_INPUT}
    Delete All Existing Topologies


Step_15_run
    Close DLUX
