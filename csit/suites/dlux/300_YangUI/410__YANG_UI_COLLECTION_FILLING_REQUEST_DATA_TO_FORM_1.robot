*** Settings ***
Documentation     Verification that it is possible to fill nongroup request to form.  
Library           Selenium2Library    timeout=10    implicit_wait=10    
#Library    Selenium2Library    timeout=10    implicit_wait=10
...               #run_on_failure=Log Source
Resource          ../../../libraries/GUIKeywords.robot
Resource          ../../../libraries/Utils.robot
Resource          ../../../libraries/YangUIKeywords.robot
#Suite Teardown    Close Browser    
#Suite Teardown    Run Keywords    Delete All Existing Topologies    Close Browser

*** Variables ***
${url_hist}
${url_coll}
            
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
    [Documentation]    Load "network-topology" button in customContainer Area. Delete 
    ...    all existing topologies. Load "topology-list" in customContainer Area. Click HISTORY tab.
    ...    If the page contains any request in history list, click Clear history data.
    ...    Result
    ...    The page contains "topology list" arrow expander, "topology list" plus button and "topology list"
    ...    button in customContainer Area.
    Step_03_run

Step_04
    [Documentation]    Navigate to API tab. Execute PUT operation with valid data. Topology id value: t0.
    ...    Execute GET operation with valid data. Topology id value: t0     
    ...    Eecute Put operation with valid data. Link id value: t0l0
    ...    Result
    ...    Page should contain: - Request sent successfully msg, - Request sent successfully msg,
    ...    - Error sending request Missing key for list.    
    Step_04_run

Step_05
    [Documentation]    Navigate to History tab. Add requests to collection with name.
    ...    1st row request: Name value: N1, 2nd row request: Name value: N2, 3rd row request: Name value: N3.
    ...    Navigate to collection tab.
    ...    Result
    ...    The page should contain: - 1st row: - name N1, - success sent data elements,
    ...    - 2nd row: - name N2, - success received data elements, 
    ...    - 3rd row: - name N3, - error sent data elements.     
    Step_05_run
    
Step_06
    [Documentation]    Fill each reuest to form.
    ...    Result
    ...    The page should contain: - topology id t0 in form (in case of 1st request),
    ...    - topology id t0 in form (in case of 2nd request), - link id t0l0 in form
    ...    (in case of 3rd request).
    Step_06_run

Step_07
    [Documentation]     Clear collection data.
    ...    Result
    ...    Page should not contain any recrd in collection table.   
    Step_07_run

Step_08
    [Documentation]    Close Dlux.    
    Step_08_run
    

*** Keywords ***
Step_01_run
    Launch Or Open DLUX Page And Login DLUX


Step_02_run
    Navigate To Yang UI Submenu


Step_03_run
    Load Network-topology Button In CustomContainer Area
    Delete All Existing Topologies
    Load Topology List Button In CustomContainer Area
    Click Element    ${HISTORY_TAB}
    If History Table Contains Data Then Clear History Data


Step_04_run
    Click Element    ${API_TAB}    
    Insert Topology Or Node Or Link Id In Form    ${Topology_Id_0}    ${Node_Id_0}    ${EMPTY}            
    Execute Chosen Operation    ${Put_OPERATION}    ${Request_sent_successfully_ALERT}
    Close Form In CustomContainer Area    ${Testing_Root_API_Topology_List_Topology_Delete_BUTTON}    ${Testing_Root_API_Topology_List_Topology_Id_INPUT}

    Insert Text To Input Field    ${Topology_Id_Path_Wrapper_INPUT}    ${Topology_Id_0}    
    Execute Chosen Operation    ${Get_OPERATION}    ${Request_sent_successfully_ALERT}
    Close Form In CustomContainer Area    ${Testing_Root_API_Topology_List_Topology_Delete_BUTTON}    ${Testing_Root_API_Topology_List_Topology_Id_INPUT}
    
    Insert Topology Or Node Or Link Id In Form    ${EMPTY}    ${EMPTY}    ${Link_Id_0}    
    Execute Chosen Operation    ${Put_OPERATION}    ${Error_sending_request_Missing_key_for_list_ALERT}
    Close Form In CustomContainer Area    ${Testing_Root_API_Link_List_Link_Delete_BUTTON}    ${Testing_Root_API_Link_List_Link_Id_INPUT}
    

Step_05_run
    Click Element    ${HISTORY_TAB}
    @{rows}=    Create List    ${row_number_1}    ${row_number_2}    ${row_number_3}    
    @{row_number_1_data}=    Create List    ${Put_Method_NAME}    ${Success_STATUS}    ${Name_1}    
    @{row_number_2_data}=    Create List    ${Get_Method_NAME}    ${Success_STATUS}    ${Name_2}    
    @{row_number_3_data}=    Create List    ${Put_Method_NAME}    ${Error_STATUS}    ${Name_3}    
    ${dict}=    Create Dictionary    ${row_number_1}=${row_number_1_data}    ${row_number_2}=${row_number_2_data}    ${row_number_3}=${row_number_3_data}        
    ${index}=    Evaluate    0
    : FOR    ${row}    IN    @{rows}
    \    ${data}=    Get From Dictionary    ${dict}    ${row}
    \    ${method}=    Get From List    ${data}    ${index}
    \    ${index}=    Evaluate    ${index}+1    
    \    ${status}=    Get From List    ${data}    ${index}
    \    ${index}=    Evaluate    ${index}+1    
    \    ${name}=    Get From List    ${data}    ${index}
    \    Verify History Table Row Content    ${row}    ${method}    ${status}
    \    ${url_hist}=    Return History Table Row Url    ${row}
    \    Add Request To Collection    ${row}    ${name}    ${Select_Option}    ${EMPTY}
    \    Click Element    ${Add_To_Collection_Box_Add_BUTTON}
    \    Click Element    ${COLLECTION_TAB}
    \    Verify Collection Table Nongroup Row Content    ${row}    ${method}    ${name}    ${status}
    \    ${url_coll}=    Return Collection Table Nongroup Row Url    ${row}
    \    Should Be Equal As Strings    ${url_hist}   ${url_coll}    
    \    Click Element    ${HISTORY_TAB}
    \    ${index}=    Evaluate    0
    
    
    Verify Sent Data Elements Presence In History Table Row    ${row_number_1}
    Verify Received Data Elements Presence In History Table Row    ${row_number_2}
    Verify Sent Data Elements Presence In History Table Row    ${row_number_3}

    If History Table Contains Data Then Clear History Data

    Click Element    ${COLLECTION_TAB}


Step_06_run
    Fill Collection Table Nongroup Row Request To Form    ${row_number_1}
    Verify Topology And Node And Link Id Presence In Form    ${Topology_Id_0}    ${Node_Id_0}    ${EMPTY}
    Close Form In CustomContainer Area    ${Testing_Root_API_Topology_List_Topology_Delete_BUTTON}    ${Testing_Root_API_Topology_List_Topology_Id_INPUT}
    
    Fill Collection Table Nongroup Row Request To Form    ${row_number_2}
    Verify Topology And Node And Link Id Presence In Form    ${Topology_Id_0}    ${Node_Id_0}    ${EMPTY}
    Close Form In CustomContainer Area    ${Testing_Root_API_Topology_List_Topology_Delete_BUTTON}    ${Testing_Root_API_Topology_List_Topology_Id_INPUT}
    
    Fill Collection Table Nongroup Row Request To Form    ${row_number_3}
    Verify Topology And Node And Link Id Presence In Form    ${EMPTY}    ${EMPTY}    ${Link_Id_0}    
    Close Form In CustomContainer Area    ${Testing_Root_API_Link_List_Link_Delete_BUTTON}    ${Testing_Root_API_Link_List_Link_Id_INPUT}


Step_07_run
    If Collection Table Contains Data Then Clear Collection Data


Step_08_run
    Close DLUX
