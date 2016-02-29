*** Settings ***
Documentation     Verification that it is possible to run filled request with the 
...               same data as original request.
Library           Selenium2Library    timeout=10    implicit_wait=10    
#Library    Selenium2Library    timeout=10    implicit_wait=10    run_on_failure=Log Source
Resource          ../../../libraries/GUIKeywords.robot
Resource          ../../../libraries/Utils.robot
Resource          ../../../libraries/YangUIKeywords.robot    
#Suite Teardown    Close Browser    
#Suite Teardown    Run Keywords    Delete All Existing Topologies    Close Browser

*** Variables ***
${LOGIN_USERNAME}    admin
${LOGIN_PASSWORD}    admin
${Default_ID}     [0]
${Topology_Id_0}    t0
${Node_Id_0}      t0n0
${Link_Id_0}      t0l0
${Topology_ID}    ${EMPTY}
${Node_ID}        ${EMPTY}
${Link_ID}        ${EMPTY}
${Row_NUMBER}    1
${History_Table_List_ROW}    //div[@ng-repeat="req in requestList.list track by $index"][${Row_NUMBER}]
${put_data_1}
${put_data_2}
${get_data_1}    
${get_data_2}
${delete_data_1}    
${delete_data_2}

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
    [Documentation]    Load "topology list" button in customContainer Area.
    ...    Result
    ...    The page contains "topology list" arrow expander, "topology list" plus button and "topology list"
    ...    button in customContainer Area.
    Step_03_run

Step_04
    [Documentation]    Execute PUT operation with valid data. Topology id value: t0,
    ...    Node id value: t0n0, List id value: t0l0. Save content of the preview box.
    ...    Close topology form in customContainer area. Click HISTORY tab.
    ...    Result
    ...    The page should contain: - Success Sent Data Elements In History Table Row.   
    Step_04_run

Step_05
    [Documentation]    Click drop button to fill sent data in form. Click Clear hist. data to delete history data.
    ...    Execute PUT operation with filled data. Compare the content of the preview box 
    ...    with the content of preview box of the original request.
    ...    Close topology form in customContainer area. If the page contains any 
    ...    request in history list, click Clear history data.
    ...    Result
    ...    The page should contain Success Sent Data Elements In History Table Row.
    ...    The content of the preview box should be equal to the content of the preview box  
    ...    of the original PUT request. The page should not contain History table row.   
    Step_05_run

Step_06
    [Documentation]    Click API tab. Execute GET operation with valid data.
    ...    Topology id value: t0, Node id value: t0n0, List id value: t0l0.
    ...    Click Show preview button and save content of the preview box.
    ...    Close topology form in customContainer area. Click HISTORY tab.
    ...    Result
    ...    The page should contain: - Success Received Data Elements In History Table Row.   
    Step_06_run

Step_07
    [Documentation]    Click drop button to fill sent data in form. Click Clear hist. data to delete history data.
    ...    Execute GET operation with filled data. Compare the content of the preview box 
    ...    with the content of preview box of the original request.
    ...    Close topology form in customContainer area. If the page contains any 
    ...    request in history list, click Clear history data.
    ...    Result
    ...    The page should contain: - Success Received Data Elements In History Table Row.
    ...    The content of the preview box should be equal to the content of the preview box 
    ...    of the original GET request. The page should not contain History table row.
    Step_07_run

Step_08
    [Documentation]    Click API tab. Execute DELETE operation with valid data.
    ...    Topology id value: t0, Node id value: t0n0, List id value: t0l0.
    ...    Click Show preview button and save content of the preview box.
    ...    Click HISTORY tab.
    ...    Result
    ...    The page should contain: - Success Sent Data Elements In History Table Row.   
    Step_08_run

Step_09
    [Documentation]    Click drop button to fill sent data in form. Click Clear hist. data to delete history data.
    ...    Execute DELETE operation with filled data. Compare the content of the preview box 
    ...    with the content of preview box of the original request.
    ...    If the page contains any request in history list, click Clear history data.
    ...    Result
    ...    The page should contain: - Success Sent Data Elements In History Table Row.
    ...    The content of the preview box should be equal to the content of the preview box 
    ...    of the original DELETE request. The page should not contain History table row.
    Step_09_run

#Step_10
    #[Documentation]    Click API tab. Execute POST operation with valid data.
    #...    Topology id value: t0, Node id value: t0n0, List id value: t0l0.
    #...    Close topology form in customContainer area. Click HISTORY tab.
    #...    Result
    #...    The page should contain: - Success Sent Data Elements In History Table Row.   
    #Step_10_run

#Step_11
    #[Documentation]    Click drop button to fill sent data in form. Click Clear hist. data to delete history data.
    #...    Execute POST operation with filled data. Error msg should appear: 
    #...    Error sending request - : Data already exists for path:
    #...    Close topology form in customContainer area. If the page contains any 
    #...    request in history list, click Clear history data.
    #...    Result
    #...    The page should contain: - Error No Sent No Received Data Elements In History Table Row.
    #Step_11_run

Step_12
    [Documentation]    If the page contains any request in history list, click Clear history data.
    ...    Delete all existing topologies.
    ...    Result
    ...    The page does not contain History table row.
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
    Navigate To Yang UI Submenu


Step_03_run
    Load Network-topology Button In CustomContainer Area
    Load Topology List Button In CustomContainer Area


Step_04_run
    Insert Topology Or Node Or Link Id In Form    ${Topology_Id_0}    ${Node_Id_0}    ${Link_Id_0}   
    Execute Chosen Operation    ${Put_OPERATION}    ${Request_sent_successfully_ALERT}
    Save Preview Box Content    ${put_data_1}
    Close Form In CustomContainer Area    ${Testing_Root_API_Topology_List_Topology_Delete_BUTTON}    ${Testing_Root_API_Topology_List_Topology_Id_INPUT}
    Click Element    ${HISTORY_TAB}
    Verify Sent Data Elements Presence In History Table Row    1


Step_05_run
    Click Element    ${History_Table_Row_Fill_Data_Enabled_BUTTON}
    Wait Until Page Contains Element    ${Testing_Root_API_Topology_List_Topology_Id_INPUT}
    If History Table Contains Data Then Clear History Data
    Execute Chosen Operation    ${Put_OPERATION}    ${Request_sent_successfully_ALERT}
    Verify Sent Data Elements Presence In History Table Row    1
    Save Preview Box Content    ${put_data_2}
    Should Be Equal As Strings   ${put_data_1}    ${put_data_2}            
    Close Form In CustomContainer Area    ${Testing_Root_API_Topology_List_Topology_Delete_BUTTON}    ${Testing_Root_API_Topology_List_Topology_Id_INPUT}
    If History Table Contains Data Then Clear History Data


Step_06_run
    Click Element    ${API_TAB}
    Page Should Contain Element    ${Testing_Root_API_Topology_List_Plus_BUTTON}
    
    Insert Topology Or Node Or Link Id In Form    ${Topology_Id_0}    ${Node_Id_0}    ${Link_Id_0}
    Execute Chosen Operation    ${Get_OPERATION}    ${Request_sent_successfully_ALERT}
    Save Preview Box Content    ${get_data_1}
    Close Form In CustomContainer Area    ${Testing_Root_API_Topology_List_Topology_Delete_BUTTON}    ${Testing_Root_API_Topology_List_Topology_Id_INPUT}
    Click Element    ${HISTORY_TAB}
    Verify Received Data Elements Presence In History Table Row    1
     

Step_07_run
    Click Element    ${History_Table_Row_Fill_Data_Enabled_BUTTON}
    Wait Until Page Contains Element    ${Testing_Root_API_Topology_List_Topology_Id_INPUT}
    If History Table Contains Data Then Clear History Data
    Execute Chosen Operation    ${Get_OPERATION}    ${Request_sent_successfully_ALERT}
    Verify Received Data Elements Presence In History Table Row    1
    Save Preview Box Content    ${get_data_2}
    Should Be Equal As Strings   ${get_data_1}    ${get_data_2}            
    Close Form In CustomContainer Area    ${Testing_Root_API_Topology_List_Topology_Delete_BUTTON}    ${Testing_Root_API_Topology_List_Topology_Id_INPUT}
    If History Table Contains Data Then Clear History Data


Step_08_run
    Click Element    ${API_TAB}
    Page Should Contain Element    ${Testing_Root_API_Topology_List_Plus_BUTTON}
    
    Insert Topology Or Node Or Link Id In Form    ${Topology_Id_0}    ${Node_Id_0}    ${Link_Id_0}
    Execute Chosen Operation    ${Delete_OPERATION}    ${Request_sent_successfully_ALERT}
    Save Preview Box Content    ${delete_data_1}
    Click Element    ${HISTORY_TAB}
    Verify Sent Data Elements Presence In History Table Row    1
     

Step_09_run
    Click Element    ${History_Table_Row_Fill_Data_Enabled_BUTTON}
    Wait Until Page Contains Element    ${Testing_Root_API_Topology_List_Topology_Id_INPUT}
    If History Table Contains Data Then Clear History Data
    Execute Chosen Operation    ${Delete_OPERATION}    ${Request_sent_successfully_ALERT}
    Verify Sent Data Elements Presence In History Table Row    1
    Save Preview Box Content    ${delete_data_2}
    Should Be Equal As Strings   ${delete_data_1}    ${delete_data_2}            
    If History Table Contains Data Then Clear History Data    


#Step_10_run
    #Click Element    ${API_TAB}
    #Page Should Contain Element    ${Testing_Root_API_Topology_List_Plus_BUTTON}
    
    #Insert Topology Or Node Or Link Id In Form    ${Topology_Id_0}    ${Node_Id_0}    ${Link_Id_0}
    #Execute Chosen Operation    ${Post_OPERATION}    ${Request_sent_successfully_ALERT}
    #Verify Sent Data Elements Presence In History Table Row
    #Click Element    ${HISTORY_TAB}
    #Verify No Sent No Received Data Elements Presence In History Table Row
     

#Step_11_run
    #Click Element    ${History_Table_Row_Fill_Data_Enabled_BUTTON}
    #Wait Until Page Contains Element    ${Testing_Root_API_Topology_List_Topology_Id_INPUT}
    #If History Table Contains Data Then Clear History Data
    #Execute Chosen Operation    ${Post_OPERATION}    ${Error_sendin_request_Data_already_exists_ALERT}
    #Verify No Sent No Received Data Elements Presence In History Table Row
    #If History Table Contains Data Then Clear History Data


Step_12_run
    If History Table Contains Data Then Clear History Data
    Click Element    ${API_TAB}
    Delete All Existing Topologies    


Step_13_run
    Close DLUX
