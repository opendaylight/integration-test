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
    ...    with name. Name value: N4. Navigate to Collection tab, click Clear collection data.  
    ...    Result
    ...    The page should not contain any collection table row.
    Step_04_run


Step_05
    [Documentation]    Navigate to History tab. Add 1st row Delete request to Collection
    ...    with name and group. Name value: N1. Group value: G1. 
    ...    Add 2nd row GET request to Collection with name and group. Name value: N2. Group value: G2. 
    ...    Add 3rd row PUT request to Collection with name and group. Name value: N3. Group value: G1. 
    ...    Add 4th row GET request to Collection with name and group. Name value: N4. Group value: G2.
    ...    Navigate to Collection tab, click Clear collection data.   
    ...    Result
    ...    The page should not contain any collection table row.
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
    @{req_2_data}=    Create List    ${row_number_2}    ${Get_Method_NAME}    ${Error_STATUS}    
    @{req_3_data}=    Create List    ${row_number_3}    ${Put_Method_NAME}    ${Success_STATUS}    
    @{req_4_data}=    Create List    ${row_number_4}    ${Get_Method_NAME}    ${Success_STATUS}    
    @{names}=    Create List    ${Name_1}    ${Name_2}    ${Name_3}    ${Name_4}    
    ${dict}=    Create Dictionary    ${Name_1}=@{req_1_data}    ${Name_2}=@{req_2_data}    ${Name_3}=@{req_3_data}    ${Name_4}=@{req_4_data}    
    : FOR    ${name}    IN    @{names}
    \    ${index}    Evaluate    0
    \    ${values}=    Get From Dictionary    ${dict}    ${name}
    \    ${row}=    Get From List    ${values}    ${index}
    \    ${row_index}    Set Variable    ${index}        
    \    ${index}    Evaluate    ${index}+1
    \    ${method}=    Get From List    ${values}    ${index}
    \    ${method_index}    Set Variable    ${index}
    \    ${index}    Evaluate    ${index}+1
    \    ${status}=    Get From List    ${values}    ${index}
    \    ${status_index}    Set Variable    ${index}
    \    Add Request To Collection    ${row}    ${name}    ${Select_Option}    ${EMPTY}
    \    Click Element    ${Add_To_Collection_Box_Add_BUTTON}

    
    Click Element    ${COLLECTION_TAB}

    : FOR    ${name}    IN    @{names}
    \    ${values}=    Get From Dictionary    ${dict}    ${name}
    \    ${row}=    Get From List    ${values}    ${row_index}
    \    ${method}=    Get From List    ${values}    ${method_index}
    \    ${status}=    Get From List    ${values}    ${status_index}
    \    Verify Collection Table Nongroup Row Content    ${row}    ${method}    ${name}    ${status}
    
    Click Element    ${Clear_Collection_Data_BUTTON}
        
    ${Collection_Table_List_Nongroup_ROW}=    Return Collection Table Nongroup Row Number    ${row_number_1}
    Wait Until Page Does Not Contain Element    ${Collection_Table_List_Nongroup_ROW}    
  
   
Step_05_run
    Click Element    ${HISTORY_TAB}    
    
    @{req_1_data}=    Create List    ${group_number_1}    ${Group_1}    ${row_number_1}    ${row_number_1}    ${Remove_Method_NAME}    ${Success_STATUS}      
    @{req_2_data}=    Create List    ${group_number_2}    ${Group_2}    ${row_number_2}    ${row_number_1}    ${Get_Method_NAME}    ${Error_STATUS}
    @{req_3_data}=    Create List    ${group_number_1}    ${Group_1}    ${row_number_3}    ${row_number_2}    ${Put_Method_NAME}    ${Success_STATUS}
    @{req_4_data}=    Create List    ${group_number_2}    ${Group_2}    ${row_number_4}    ${row_number_2}    ${Get_Method_NAME}    ${Success_STATUS}
    @{names}=    Create List    ${Name_1}    ${Name_2}    ${Name_3}    ${Name_4}        
    ${dict}=    Create Dictionary    ${Name_1}=@{req_1_data}    ${Name_2}=@{req_2_data}    ${Name_3}=@{req_3_data}    ${Name_4}=@{req_4_data}    
    : FOR    ${name}    IN    @{names}
    \    ${index}    Evaluate    0
    \    ${values}=    Get From Dictionary    ${dict}    ${name}
    \    ${group}=    Get From List    ${values}    ${index}
    \    ${group_index}    Set Variable    ${index}        
    \    ${index}    Evaluate    ${index}+1
    \    ${group_name}=    Get From List    ${values}    ${index}
    \    ${group_name_index}    Set Variable    ${index}        
    \    ${index}    Evaluate    ${index}+1
    \    ${row}=    Get From List    ${values}    ${index}
    \    ${row_index}    Set Variable    ${index}        
    \    ${index}    Evaluate    ${index}+1
    \    ${group_row}=    Get From List    ${values}    ${index}
    \    ${group_row_index}    Set Variable    ${index}        
    \    ${index}    Evaluate    ${index}+1
    \    ${method}=    Get From List    ${values}    ${index}
    \    ${method_index}    Set Variable    ${index}
    \    ${index}    Evaluate    ${index}+1
    \    ${status}=    Get From List    ${values}    ${index}
    \    ${status_index}    Set Variable    ${index}
    \    Add Request To Collection    ${row}    ${name}    ${Select_Option}    ${group_name}
    \    Click Element    ${Add_To_Collection_Box_Add_BUTTON}

    Click Element    ${COLLECTION_TAB}

    : FOR    ${name}    IN    @{names}
    \    ${values}=    Get From Dictionary    ${dict}    ${name}
    \    ${group}=    Get From List    ${values}    ${group_index}
    \    ${group_name}=    Get From List    ${values}    ${group_name_index}
    \    ${group_row}=    Get From List    ${values}    ${group_row_index}
    \    ${method}=    Get From List    ${values}    ${method_index}    
    \    ${status}=    Get From List    ${values}    ${status_index}
    \    Expand Collection Table Group Expander    ${group}    ${group_name}    ${row_number_1}    
    \    Verify Collection Table Group Row Content    ${group}    ${group_row}    ${method}    ${name}    ${status}
    
    Click Element    ${Clear_Collection_Data_BUTTON}
    ${Collection_Table_List_Group_ROW}=    Return Collection Table Group Row Number    ${group_name}    ${row_number_1}
    Wait Until Page Does Not Contain Element    ${Collection_Table_List_Group_ROW}    

     
Step_06_run
    Close DLUX
