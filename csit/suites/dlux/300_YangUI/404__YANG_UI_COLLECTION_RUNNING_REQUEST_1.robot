*** Settings ***
Documentation     Verification that it is possible to run nongroup request from Collection tab.
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
    [Documentation]    Execute DELETEoperation. Add request to Collection with name N1.
    ...    Execute GET operation. Add request to Collection with name N2.
    ...    Execute PUT operation. Add request to Collection with name N3. Topology id: t0.
    ...    Execute GET operation. Add request to Collection with name N4.
    ...    Execute PUToperation. Add request to Collection with name N5.
    Step_04_run
    
Step_05
    [Documentation]    Navigate to Collection tab. Click Run request button in X row. Navigate to History table.
    ...    Run for X = {1, 2, 3, 4, 5}
    ...    Result
    ...    The page should contain: - Row 1, method Remove, status success.
    ...    - Row 2, method Get, status error. - Row 3, method Remove, status success.
    ...    - Row 4, method Remove, status success. - Row content - row 5, method Remove, status success.     
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
    Add Request To Collection    ${row_number_1}    ${Name_1}    ${Select_Option}    ${EMPTY}
    Click Element    ${Add_To_Collection_Box_Add_BUTTON}    
    
    Execute Chosen Operation    ${Get_OPERATION}    ${Data_missing_Relevant_data_model_not_existing_ALERT}
    Verify History Table Row Content    ${row_number_2}    ${Get_Method_NAME}    ${Error_STATUS}
    Verify No Sent No Received Data Elements Presence In History Table Row    ${row_number_2}
    Add Request To Collection    ${row_number_2}    ${Name_2}    ${Select_Option}    ${EMPTY}
    Click Element    ${Add_To_Collection_Box_Add_BUTTON}
    
    Expand Network Topology Arrow Expander
    Click Element    ${Testing_Root_API_Topology_List_Plus_BUTTON}
    PUT ID    ${Testing_Root_API_Topology_List_Topology_Id_INPUT}    ${Topology_Id_0}    ${Topology_ID}    ${Testing_Root_API_Topology_List_NAME}    
    Verify History Table Row Content    ${row_number_3}    ${Put_Method_NAME}    ${Success_STATUS}
    Verify Sent Data Elements Presence In History Table Row    ${row_number_3}
    Add Request To Collection    ${row_number_3}    ${Name_3}    ${Select_Option}    ${EMPTY}
    Click Element    ${Add_To_Collection_Box_Add_BUTTON}    
    
    Execute Chosen Operation    ${Get_OPERATION}    ${Request_sent_successfully_ALERT}    
    Verify History Table Row Content    ${row_number_4}    ${Get_Method_NAME}    ${Success_STATUS}
    Verify Received Data Elements Presence In History Table Row     ${row_number_4}
    Add Request To Collection    ${row_number_4}    ${Name_4}    ${Select_Option}    ${EMPTY}
    Click Element    ${Add_To_Collection_Box_Add_BUTTON}
    Close Form In CustomContainer Area    ${Testing_Root_API_Topology_List_Topology_Delete_BUTTON}    ${Testing_Root_API_Topology_List_Topology_Id_INPUT}
    
    Execute Chosen Operation    ${Put_OPERATION}    ${Error_sending_request_Input_is_required_ALERT}    
    Verify History Table Row Content    ${row_number_5}    ${Put_Method_NAME}    ${Error_STATUS}
    Verify No Sent No Received Data Elements Presence In History Table Row    ${row_number_5}
    Add Request To Collection    ${row_number_5}    ${Name_5}    ${Select_Option}    ${EMPTY}
    Click Element    ${Add_To_Collection_Box_Add_BUTTON}
    
    If History Table Contains Data Then Clear History Data


Step_05_run
    Click Element    ${COLLECTION_TAB}
    @{row_num_1_data}=    Create List    ${Name_1}    ${Remove_Method_NAME}    ${Success_STATUS}
    @{row_num_2_data}=    Create List    ${Name_2}    ${Get_Method_NAME}    ${Error_STATUS}
    @{row_num_3_data}=    Create List    ${Name_3}    ${Put_Method_NAME}    ${Success_STATUS}
    @{row_num_4_data}=    Create List    ${Name_4}    ${Get_Method_NAME}    ${Success_STATUS}
    @{row_num_5_data}=    Create List    ${Name_5}    ${Put_Method_NAME}    ${Error_STATUS}
    ${dict}=    Create Dictionary    ${row_number_1}=${row_num_1_data}    ${row_number_2}=${row_num_2_data}    ${row_number_3}=${row_num_3_data}
    ...    ${row_number_4}=${row_num_4_data}    ${row_number_5}=${row_num_5_data}        
    @{rows}=    Create List    ${row_number_1}    ${row_number_2}    ${row_number_3}    ${row_number_4}    ${row_number_5}    
    : FOR    ${row}    IN    @{rows}
    \    ${index}    Evaluate    0
    \    ${values}=    Get From Dictionary    ${dict}    ${row}
    \    ${name}=    Get From List    ${values}    ${index}
    \    ${index}    Evaluate    ${index}+1
    \    ${method}=    Get From List    ${values}    ${index}
    \    ${index}    Evaluate    ${index}+1
    \    ${status}=    Get From List    ${values}    ${index}
    \    Verify Collection Table Nongroup Row Content    ${row}    ${method}    ${name}    ${status}
    \    ${url_coll}=    Return Collection Table Nongroup Row Url    ${row}
    \    Run Request Nongroup Row Sent Data Box    ${row}        
    \    Click Element    ${HISTORY_TAB}
    \    Verify History Table Row Content    ${row}    ${method}    ${status}
    \    ${url_hist}=    Return History Table Row Url     ${row}
    \    Should Be Equal As Strings    ${url_coll}    ${url_hist}        
    \    Click Element    ${COLLECTION_TAB}        
    \    Wait Until Page Contains Element    ${Collection_TABLE}
    

Step_06_run
    If Collection Table Contains Data Then Clear Collection Data


Step_07_run
    Close DLUX
