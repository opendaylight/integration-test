*** Settings ***
Documentation     Verification that fill button enables to fill data from request to the form.
Library           Selenium2Library    timeout=10    implicit_wait=10    #Library    Selenium2Library    timeout=10    implicit_wait=10
...               #run_on_failure=Log Source
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
    [Documentation]    Load "topology list" button in customContainer Area.
    ...    Result
    ...    The page contains "topology list" arrow expander, "topology list" plus button and "topology list"
    ...    button in customContainer Area.
    Step_03_run

Step_04
    [Documentation]    Execute PUT operation with valid data. Topology id value: t0,
    ...    Node id value: t0n0, List id value: t0l0.
    ...    Close topology form in customContainer area. Click HISTORY tab.
    ...    Result
    ...    The page should contain Success Sent Data Elements In History Table Row. 
    Step_04_run

Step_05
    [Documentation]    Click drop button to fill sent data in form. Click Clear hist. data 
    ...    to delete history data. Close topology form in customContainer area.
    ...    Result
    ...    The page contains: - topology id t0 in topology input field, - node id value in node id input field,
    ...    - link id value in link id input field. The page should not contain History table row.
    ...    The page should not contain topolgy id input field.   
    Step_05_run

Step_06
    [Documentation]    Click API tab. Execute GET operation with valid data.
    ...    Topology id value: t0, Node id value: t0n0, List id value: t0l0. 
    ...    Close topology form in customContainer area. Click HISTORY tab.
    ...    Result
    ...    The page should contain: - Success Received Data Elements In History Table Row.
    Step_06_run

Step_07
    [Documentation]    Click drop button to fill sent data in form. Click Clear hist. data 
    ...    to delete history data. Close topology form in customContainer area.
    ...    Result
    ...    The page contains: - topology id t0 in topology input field, - node id value in node id input field,
    ...    - link id value in link id input field. The page should not contain History table row.
    ...    The page should not contain topolgy id input field.
    Step_07_run
    
Step_08
    [Documentation]    Click API tab. Execute DELETE operation with valid data.
    ...    Topology id value: t0, Node id value: t0n0, List id value: t0l0. 
    ...    Click HISTORY tab.
    ...    Result
    ...    The page should contain: - Success Sent Data Elements In History Table Row.
    Step_08_run

Step_09
    [Documentation]    Click drop button to fill sent data in form. Click Clear hist. data 
    ...    to delete history data. Close topology form in customContainer area. 
    ...    Result
    ...    The page contains: - topology id t0 in topology input field, - node id value in node id input field,
    ...    - link id value in link id input field. The page should not contain History table row.
    ...    The page should not contain topolgy id input field 
    Step_09_run

#Step_10
    #[Documentation]    Click API tab. Execute POST operation with valid data.
    #...    Topology id value: t0, Node id value: t0n0, List id value: t0l0. 
    #...    Click HISTORY tab.
    #...    Result
    #...    The page should contain: - Success Sent Data Elements In History Table Row.
    #Step_10_run

#Step_11
    #[Documentation]    Click drop button to fill sent data in form. 
    #...    Result
    #...    The page contains: - topology id t0 in topology input field, - node id value in node id input field,
    #...    - link id value in link id input field.
    #Step_11_run

Step_12    
    [Documentation]    If the page contains any request in history list, click Clear history data.
    ...    Result
    ...    The page does not contain History table row.
    Step_12_run

Step_13
    [Documentation]    Close Dlux.
    Step_13_run

*** Keywords ***
Step_01_run
    Launch Or Open DLUX Page And Login DLUX


Step_02_run
    Navigate To Yang UI Submenu


Step_03_run
    Load Network-topology Button In CustomContainer Area
    Load Topology List Button In CustomContainer Area


Step_04_run
    Insert Topology Or Node Or Link Id In Form    ${Topology_Id_0}    ${Node_Id_0}    ${Link_Id_0}   
    Execute Chosen Operation    ${Put_OPERATION}    ${Request_sent_successfully_ALERT}
    Close Form In CustomContainer Area    ${Testing_Root_API_Topology_List_Topology_Delete_BUTTON}    ${Testing_Root_API_Topology_List_Topology_Id_INPUT}        
    Click Element    ${HISTORY_TAB}
    Verify Sent Data Elements Presence In History Table Row    1 


Step_05_run
    Fill History Table Row Request To Form    1
    Verify Topology And Node And Link Id Presence In Form    ${Topology_Id_0}    ${Node_Id_0}    ${Link_Id_0}    
    If History Table Contains Data Then Clear History Data
    Close Form In CustomContainer Area    ${Testing_Root_API_Topology_List_Topology_Delete_BUTTON}    ${Testing_Root_API_Topology_List_Topology_Id_INPUT}


Step_06_run
    Click Element    ${API_TAB}
    Page Should Contain Element    ${Testing_Root_API_Topology_List_Plus_BUTTON}
    
    Insert Topology Or Node Or Link Id In Form    ${Topology_Id_0}    ${Node_Id_0}    ${Link_Id_0}
    Execute Chosen Operation    ${Get_OPERATION}    ${Request_sent_successfully_ALERT}
    Close Form In CustomContainer Area    ${Testing_Root_API_Topology_List_Topology_Delete_BUTTON}    ${Testing_Root_API_Topology_List_Topology_Id_INPUT}        
    Click Element    ${HISTORY_TAB}
    Verify Received Data Elements Presence In History Table Row    1


Step_07_run
    Fill History Table Row Request To Form    1
    Verify Topology And Node And Link Id Presence In Form    ${Topology_Id_0}    ${Node_Id_0}    ${Link_Id_0}
    If History Table Contains Data Then Clear History Data
    Close Form In CustomContainer Area    ${Testing_Root_API_Topology_List_Topology_Delete_BUTTON}    ${Testing_Root_API_Topology_List_Topology_Id_INPUT} 


Step_08_run
    Click Element    ${API_TAB}
    Page Should Contain Element    ${Testing_Root_API_Topology_List_Plus_BUTTON}
    
    Insert Topology Or Node Or Link Id In Form    ${Topology_Id_0}    ${Node_Id_0}    ${Link_Id_0}
    Execute Chosen Operation    ${Delete_OPERATION}    ${Request_sent_successfully_ALERT}
    Click Element    ${HISTORY_TAB}
    Verify Sent Data Elements Presence In History Table Row    1


Step_09_run
    Fill History Table Row Request To Form    1
    Verify Topology And Node And Link Id Presence In Form    ${Topology_Id_0}    ${Node_Id_0}    ${Link_Id_0}
    If History Table Contains Data Then Clear History Data
    Close Form In CustomContainer Area    ${Testing_Root_API_Topology_List_Topology_Delete_BUTTON}    ${Testing_Root_API_Topology_List_Topology_Id_INPUT} 
    

#Step_10_run
    #Click Element    ${API_TAB}
    #Page Should Contain Element    ${Testing_Root_API_Topology_List_Plus_BUTTON}
    
    #Insert Topology Or Node Or Link Id In Form    ${Topology_Id_0}    ${Node_Id_0}    ${Link_Id_0}
    #Execute Chosen Operation    ${Post_OPERATION}    ${Request_sent_successfully_ALERT}
    #Click Element    ${HISTORY_TAB}
    #Verify Sent Data Elements Presence In History Table Row


#Step_11_run
    #Click Element    ${History_Table_Row_Fill_Data_Enabled_BUTTON}
    #Verify Topology And Node And Link Id Presence In Form    ${Topology_Id_0}    ${Node_Id_0}    ${Link_Id_0}


Step_12_run
    If History Table Contains Data Then Clear History Data
    Click Element    ${API_TAB}
    Delete All Existing Topologies    


Step_13_run
    Close DLUX
