*** Settings ***
Documentation     Verification that it is possible to run group request from Collection tab.
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
    [Documentation]    Execute DELETEoperation. Add request to Collection with name N1 and new group G1.
    ...    Execute GET operation. Add request to Collection with name N2 and existing group G1.
    ...    Execute PUT operation. Add request to Collection with name N3 and existing group G1. Topology id: t0.
    ...    Execute GET operation. Add request to Collection with name N4 and new group G2.
    ...    Execute PUToperation. Add request to Collection with name N5 and existing group G2.
    Step_04_run

Step_05
    [Documentation]    Navigate to Collection tab. Click Run request button in:
    ...    - G1 group 1 row, - G1 group 2 row, G1 group 3 row, G2 group 1 row, G2 group 2 row.
    ...    Navigate to History table. Clear history data after each verification.
    ...    Result
    ...    The page should contain: - Row 1, method Remove, status success.
    ...    - Row 1, method Get, status error. - Row 1, method Remove, status success.
    ...    - Row 1, method Remove, status success. - Row content - row 1, method Remove, status success.      
    Step_05_run
    
Step_06
   [Documentation]     Clear collection data.
    ...    Result
    ...    Page should not contain any recrd in collection table.   
    Step_06_run

Step_07
    [Documentation]    Close Dlux.    
    Step_07_run
    

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
    Add Request To Collection    ${row_number_1}    ${Name_1}    ${Select_Option}    ${Group_1}
    Click Element    ${Add_To_Collection_Box_Add_BUTTON}    
    
    
    Execute Chosen Operation    ${Get_OPERATION}    ${Data_missing_Relevant_data_model_not_existing_ALERT}
    Verify History Table Row Content    ${row_number_2}    ${Get_Method_NAME}    ${Error_STATUS}
    Verify No Sent No Received Data Elements Presence In History Table Row    ${row_number_2}
    Add Request To Collection    ${row_number_2}    ${Name_2}    ${Group_1}    ${EMPTY}
    Click Element    ${Add_To_Collection_Box_Add_BUTTON}
    
    Expand Network Topology Arrow Expander
    Click Element    ${Testing_Root_API_Topology_List_Plus_BUTTON}
    PUT ID    ${Testing_Root_API_Topology_List_Topology_Id_INPUT}    ${Topology_Id_0}    ${Topology_ID}    ${Testing_Root_API_Topology_List_NAME}    
    Verify History Table Row Content    ${row_number_3}    ${Put_Method_NAME}    ${Success_STATUS}
    Verify Sent Data Elements Presence In History Table Row    ${row_number_3}
    Add Request To Collection    ${row_number_3}    ${Name_3}    ${Group_1}    ${EMPTY}
    Click Element    ${Add_To_Collection_Box_Add_BUTTON}    
    
    Execute Chosen Operation    ${Get_OPERATION}    ${Request_sent_successfully_ALERT}    
    Verify History Table Row Content    ${row_number_4}    ${Get_Method_NAME}    ${Success_STATUS}
    Verify Received Data Elements Presence In History Table Row     ${row_number_4}
    Add Request To Collection    ${row_number_4}    ${Name_4}    ${Select_Option}    ${Group_2}
    Click Element    ${Add_To_Collection_Box_Add_BUTTON}
    Close Form In CustomContainer Area    ${Testing_Root_API_Topology_List_Topology_Delete_BUTTON}    ${Testing_Root_API_Topology_List_Topology_Id_INPUT}
    
    Execute Chosen Operation    ${Put_OPERATION}    ${Error_sending_request_Input_is_required_ALERT}    
    Verify History Table Row Content    ${row_number_5}    ${Put_Method_NAME}    ${Error_STATUS}
    Verify No Sent No Received Data Elements Presence In History Table Row    ${row_number_5}
    Add Request To Collection    ${row_number_5}    ${Name_5}    ${Group_2}    ${EMPTY}
    Click Element    ${Add_To_Collection_Box_Add_BUTTON}
    
    If History Table Contains Data Then Clear History Data


Step_05_run
    Click Element    ${COLLECTION_TAB}
    @{group1_row1_data}=    Create List    ${group_number_1}    ${Group_1}    ${row_number_1}    ${Remove_Method_NAME}    ${Success_STATUS}
    @{group1_row2_data}=    Create List    ${group_number_1}    ${Group_1}    ${row_number_2}    ${Get_Method_NAME}    ${Error_STATUS}
    @{group1_row3_data}=    Create List    ${group_number_1}    ${Group_1}    ${row_number_3}    ${Put_Method_NAME}    ${Success_STATUS}
    @{group2_row1_data}=    Create List    ${group_number_2}    ${Group_2}    ${row_number_1}    ${Get_Method_NAME}    ${Success_STATUS}
    @{group2_row2_data}=    Create List    ${group_number_2}    ${Group_2}    ${row_number_2}    ${Put_Method_NAME}    ${Error_STATUS}
    ${dict}=    Create Dictionary    ${Name_1}=@{group1_row1_data}    ${Name_2}=@{group1_row2_data}    ${Name_3}=@{group1_row3_data}
    ...    ${Name_4}=@{group2_row1_data}    ${Name_5}=@{group2_row2_data}        
    @{names}=    Create List    ${Name_1}    ${Name_2}    ${Name_3}    ${Name_4}    ${Name_5}    
    : FOR    ${name}    IN    @{names}
    \    ${index}    Evaluate    0
    \    ${values}    Get From Dictionary    ${dict}    ${name}
    \    ${group}=    Get From List    ${values}    ${index}
    \    ${index}    Evaluate    ${index}+1
    \    ${group_name}=    Get From List    ${values}    ${index}
    \    ${index}    Evaluate    ${index}+1
    \    ${row}=    Get From List    ${values}    ${index}
    \    ${index}    Evaluate    ${index}+1
    \    ${method}=    Get From List    ${values}    ${index}    
    \    ${index}    Evaluate    ${index}+1    
    \    ${status}=    Get From List    ${values}    ${index}
    \    Expand Collection Table Group Expander    ${group}    ${group_name}    ${row}
    \    Verify Collection Table Group Row Content    ${group}    ${row}    ${method}    ${name}    ${status}
    \    ${url_coll}=    Return Collection Table Group Row Url    ${group}    ${row}
    \    Run Request Group Row Sent Data Box     ${group}    ${row}
    \    Click Element    ${HISTORY_TAB}
    \    Verify History Table Row Content    1    ${method}    ${status}
    \    ${url_hist}=    Return History Table Row Url    1    
    \    Should Be Equal As Strings    ${url_coll}    ${url_hist}
    \    If History Table Contains Data Then Clear History Data    
    \    Click Element    ${COLLECTION_TAB}
    \    Wait Until Page Contains Element    ${Collection_TABLE}
    
        

Step_06_run
    If Collection Table Contains Data Then Clear Collection Data



Step_07_run
    Close DLUX    
        
    

