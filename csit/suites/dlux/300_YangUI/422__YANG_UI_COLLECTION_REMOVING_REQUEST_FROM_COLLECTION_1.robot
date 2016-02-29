*** Settings ***
Documentation    Verification that requests can be moved from no group to new group to 
...              existing group and then to no group.
Library           Selenium2Library    timeout=10    implicit_wait=10    
#Library    Selenium2Library    timeout=10    implicit_wait=10
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
    ...    and Yang UI Submenu. Location should be http://127.0.0.1:8181/index.html#/yangui/index.
    Step_02_run

Step_03
    [Documentation]    Load "network-topology" button in customContainer Area. Delete 
    ...    all existing topologies. Click HISTORY tab.
    ...    If the page contains any request in history list, click Clear history data.
    ...    Result
    ...    The page contains "network-topology" arrow expander and "network-topology" button in 
    ...    customContainer Area.
    Step_03_run

Step_04
    [Documentation]    Execute DELETE operation. Add request to Collection
    ...    with name. Name value: N1. Execute GET operation. Add request to Collection
    ...    with name. Name value: N2. 
    ...    Execute PUT operation. Topology id: t0. Add request to Collection
    ...    with name. Name value: N3. Execute GET operation. Add request to Collection
    ...    with name. Name value: N4. 
    ...    Result
    ...    The page should contain: - Row 1, method Remove, status success, Name value: N1.
    ...    - Row 2, method Get, status error. Name value: N2. - Row 3, method Put, status success, 
    ...    Name value: N3, - Row 4, method Get, status success, Name value: N4. 
    Step_04_run


Step_05
    [Documentation]    Click Delete button successivly in each request`s row. After each 
    ...    Deletion action execute check of the 1st row content. 
    ...    Result
    ...    The page should not contain: - Row 1, method Remove, status success.
    ...    - Row 2, method Get, status error. - Row 3, method Put, status success.
    ...    - Row 4, method Get, status success. 
    Step_05_run

        
Step_06
    [Documentation]    Close Dlux.    
    Step_06_run    

*** Keywords ***
Step_01_run
    Launch Or Open DLUX Page And Login DLUX


Step_02_run
    Navigate To Yang UI Submenu


Step_03_run
    Load Network-topology Button In CustomContainer Area
    Delete All Existing Topologies
    Click Element    ${HISTORY_TAB}
    If History Table Contains Data Then Clear History Data


Step_04_run
    Execute Chosen Operation    ${Delete_OPERATION}    ${Request_sent_successfully_ALERT}
    Verify History Table Row Content    ${row_number_1}    ${Remove_Method_NAME}    ${Success_STATUS}
    Verify No Sent No Received Data Elements Presence In History Table Row    ${row_number_1}
    
    Execute Chosen Operation    ${Get_OPERATION}    ${Data_missing_Relevant_data_model_not_existing_ALERT}
    Verify History Table Row Content    ${row_number_2}    ${Get_Method_NAME}    ${Error_STATUS}
    Verify No Sent No Received Data Elements Presence In History Table Row    ${row_number_2}
    
    Expand Network Topology Arrow Expander
    Click Element    ${Testing_Root_API_Topology_List_Plus_BUTTON}
    PUT ID    ${Testing_Root_API_Topology_List_Topology_Id_INPUT}    ${Topology_Id_0}    ${Topology_ID}    ${Testing_Root_API_Topology_List_NAME}    
    Verify History Table Row Content    ${row_number_3}    ${Put_Method_NAME}    ${Success_STATUS}
    Verify Sent Data Elements Presence In History Table Row    ${row_number_3}
    Close Form In CustomContainer Area    ${Testing_Root_API_Topology_List_Topology_Delete_BUTTON}    ${Testing_Root_API_Topology_List_Topology_Id_INPUT}
   
    Execute Chosen Operation    ${Get_OPERATION}    ${Request_sent_successfully_ALERT}    
    Verify History Table Row Content    ${row_number_4}    ${Get_Method_NAME}    ${Success_STATUS}
    Verify Received Data Elements Presence In History Table Row     ${row_number_4}
    Close Form In CustomContainer Area    ${Testing_Root_API_Topology_List_Topology_Delete_BUTTON}    ${Testing_Root_API_Topology_List_Topology_Id_INPUT}
    
    @{req_1_data}=    Create List    ${row_number_1}    ${Remove_Method_NAME}    ${Success_STATUS}         
    Set Suite Variable    @{req_1_data}
    @{req_2_data}=    Create List    ${row_number_2}    ${Get_Method_NAME}    ${Error_STATUS}    
    Set Suite Variable    @{req_2_data}
    @{req_3_data}=    Create List    ${row_number_3}    ${Put_Method_NAME}    ${Success_STATUS}    
    Set Suite Variable    @{req_3_data}
    @{req_4_data}=    Create List    ${row_number_4}    ${Get_Method_NAME}    ${Success_STATUS}    
    Set Suite Variable    @{req_4_data}
    @{names}=    Create List    ${Name_1}    ${Name_2}    ${Name_3}    ${Name_4}    
    Set Suite Variable    @{names}    
    ${dict}=    Create Dictionary    ${Name_1}=@{req_1_data}    ${Name_2}=@{req_2_data}    ${Name_3}=@{req_3_data}    ${Name_4}=@{req_4_data}    
    Set Suite Variable    ${dict}
    : FOR    ${name}    IN    @{names}
    \    ${index}    Evaluate    0
    \    ${values}=    Get From Dictionary    ${dict}    ${name}
    \    ${row}=    Get From List    ${values}    ${index}
    \    Set Suite Variable    ${row_index}    ${index}        
    \    ${index}    Evaluate    ${index}+1
    \    ${method}=    Get From List    ${values}    ${index}
    \    Set Suite Variable    ${method_index}    ${index}
    \    ${index}    Evaluate    ${index}+1
    \    ${status}=    Get From List    ${values}    ${index}
    \    Set Suite Variable    ${status_index}    ${index}
    \    Add Request To Collection    ${row}    ${name}    ${Select_Option}    ${EMPTY}
    \    Click Element    ${Add_To_Collection_Box_Add_BUTTON}

    If History Table Contains Data Then Clear History Data
    
    Click Element    ${COLLECTION_TAB}


Step_05_run
    : FOR    ${name}    IN    @{names}
    \    ${values}=    Get From Dictionary    ${dict}    ${name}
    \    ${method}=    Get From List    ${values}    ${method_index}
    \    ${status}=    Get From List    ${values}    ${status_index}
    \    Verify Collection Table Nongroup Row Content    ${row_number_1}    ${method}    ${name}    ${status}
    \    Delete Collection Table Nongroup Row Request    ${row_number_1}
    \    ${status}=    Verify Collection Table Nongroup Row Presence    ${row_number_1}    
    \    Run Keyword If    "${status}"=="True"    Verify Collection Table Nongroup Row Content NONPresence    ${row_number_1}    ${method}    ${name}    ${status}
    
    ${Collection_Table_List_Nongroup_ROW}=    Return Collection Table Nongroup Row Number    ${row_number_1}
    Page Should Not Contain Element    ${Collection_Table_List_Nongroup_ROW}    
   
Step_06_run
    Close DLUX
