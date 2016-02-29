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
${max_group1_row}    ${row_number_3}
${max_group2_row}    ${row_number_2}

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
    [Documentation]    Execute DELETE operation. Add request to Collection with no name, group G1.
    ...    Execute GET operation. Add request to Collection with no name, group G1.
    ...    Execute PUT operation. Add request to Collection with no name, group G1. Topology id: t0.
    ...    Execute GET operation. Add request to Collection with no name, group G2.
    ...    Execute PUToperation. Add request to Collection with no name, group G2.
    ...    Clear History data. Navigate to Collection tab.
    ...    Result
    ...    The page should contain: - G1 Row 1, method Remove, status success.
    ...    - G1 Row 2, method Get, status error. - G1 Row 3, method Put, status success.
    ...    - G2 Row 1, method Get, status success. - G2 Row 2, method Put, status error
    Step_04_run
    
Step_05
    [Documentation]    Click Edit button in all requests one by one. 
    ...    G1 Req 1 - Insert name and click Save button. Name value: N1    
    ...    G1 Req 2 - Insert name and click Save button. Name value: N2
    ...    G1 Req 3 - Insert name and click Save button. Name value: N3
    ...    G2 Req 1 - Insert name and click Save button. Name value: N4
    ...    G2 Req 2 - Insert name and click Save button. Name value: N5
    ...    Result
    ...    The page should contain: - Row 1, name N1, method Remove, status success.
    ...    - Row 2, name N2, method Get, status error. - Row 3, name N3, method Put, status success.
    ...    - Row 4, name N4, method Get, status success. - Row 5, name N5, method Put, status error.
    Step_05_run
    
Step_06
   [Documentation]    Click Edit button in all requests one by one. 
    ...    G1 Req 1 - Insert name and click Save button. Name value: N6    
    ...    G1 Req 2 - Insert name and click Save button. Name value: N7
    ...    G1 Req 3 - Insert name and click Save button. Name value: N8
    ...    G2 Req 1 - Insert name and click Save button. Name value: N9
    ...    G2 Req 2 - Insert name and click Save button. Name value: N10
    ...    Clear collection data.
    ...    Result
    ...    The page should contain: - Row 1, name N6, method Remove, status success.
    ...    - Row 2, name N7, method Get, status error. - Row 3, name N8, method Put, status success.
    ...    - Row 4, name N9, method Get, status success. - Row 5, name N10, method Put, status error.  
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
    Add Request To Collection    ${row_number_1}    ${EMPTY}    ${Select_Option}    ${Group_1}
    Click Element    ${Add_To_Collection_Box_Add_BUTTON}    
    
    Execute Chosen Operation    ${Get_OPERATION}    ${Data_missing_Relevant_data_model_not_existing_ALERT}
    Verify History Table Row Content    ${row_number_2}    ${Get_Method_NAME}    ${Error_STATUS}
    Verify No Sent No Received Data Elements Presence In History Table Row    ${row_number_2}
    Add Request To Collection    ${row_number_2}    ${EMPTY}    ${Select_Option}    ${Group_1}
    Click Element    ${Add_To_Collection_Box_Add_BUTTON}
    
    Expand Network Topology Arrow Expander
    Click Element    ${Testing_Root_API_Topology_List_Plus_BUTTON}
    PUT ID    ${Testing_Root_API_Topology_List_Topology_Id_INPUT}    ${Topology_Id_0}    ${Topology_ID}    ${Testing_Root_API_Topology_List_NAME}    
    Verify History Table Row Content    ${row_number_3}    ${Put_Method_NAME}    ${Success_STATUS}
    Verify Sent Data Elements Presence In History Table Row    ${row_number_3}
    Add Request To Collection    ${row_number_3}    ${EMPTY}    ${Select_Option}    ${Group_1}
    Click Element    ${Add_To_Collection_Box_Add_BUTTON}    
    
    Execute Chosen Operation    ${Get_OPERATION}    ${Request_sent_successfully_ALERT}    
    Verify History Table Row Content    ${row_number_4}    ${Get_Method_NAME}    ${Success_STATUS}
    Verify Received Data Elements Presence In History Table Row     ${row_number_4}
    Add Request To Collection    ${row_number_4}    ${EMPTY}    ${Select_Option}    ${Group_2}
    Click Element    ${Add_To_Collection_Box_Add_BUTTON}
    Close Form In CustomContainer Area    ${Testing_Root_API_Topology_List_Topology_Delete_BUTTON}    ${Testing_Root_API_Topology_List_Topology_Id_INPUT}

    Execute Chosen Operation    ${Put_OPERATION}    ${Error_sending_request_Input_is_required_ALERT}    
    Verify History Table Row Content    ${row_number_5}    ${Put_Method_NAME}    ${Error_STATUS}
    Verify No Sent No Received Data Elements Presence In History Table Row    ${row_number_5}
    Add Request To Collection    ${row_number_5}    ${EMPTY}    ${Select_Option}    ${Group_2}
    Click Element    ${Add_To_Collection_Box_Add_BUTTON}
    
    If History Table Contains Data Then Clear History Data


Step_05_run
    Click Element    ${COLLECTION_TAB}
    @{group1_row1_data}=    Create List    ${group_number_1}    ${Group_1}    ${max_group1_row}    ${Remove_Method_NAME}    ${Success_STATUS}    ${Name_6}
    Set Suite Variable    @{group1_row1_data}
    @{group1_row2_data}=    Create List    ${group_number_1}    ${Group_1}    ${max_group1_row}    ${Get_Method_NAME}    ${Error_STATUS}    ${Name_7}
    Set Suite Variable    @{group1_row2_data}
    @{group1_row3_data}=    Create List    ${group_number_1}    ${Group_1}    ${max_group1_row}    ${Put_Method_NAME}    ${Success_STATUS}    ${Name_8}
    Set Suite Variable    @{group1_row3_data}
    @{group2_row1_data}=    Create List    ${group_number_2}    ${Group_2}    ${max_group2_row}    ${Get_Method_NAME}    ${Success_STATUS}    ${Name_9}
    Set Suite Variable    @{group2_row1_data}
    @{group2_row2_data}=    Create List    ${group_number_2}    ${Group_2}    ${max_group2_row}    ${Put_Method_NAME}    ${Error_STATUS}    ${Name_10}
    Set Suite Variable    @{group2_row2_data}
    ${dict}=    Create Dictionary    ${Name_1}=@{group1_row1_data}    ${Name_2}=@{group1_row2_data}    ${Name_3}=@{group1_row3_data}
    ...    ${Name_4}=@{group2_row1_data}    ${Name_5}=@{group2_row2_data}
    Set Suite Variable    ${dict}        
    @{names}=    Create List    ${Name_1}    ${Name_2}    ${Name_3}    ${Name_4}    ${Name_5}
    Set Suite Variable    @{names}
    : FOR    ${name}    IN    @{names}
    \    ${index}    Evaluate    0
    \    ${values}    Get From Dictionary    ${dict}    ${name}
    \    ${group}=    Get From List    ${values}    ${index}
    \    ${index}    Evaluate    ${index}+1
    \    ${group_name}=    Get From List    ${values}    ${index}
    \    ${index}    Evaluate    ${index}+1
    \    ${max_row}=    Get From List    ${values}    ${index}
    \    ${index}    Evaluate    ${index}+1
    \    ${method}=    Get From List    ${values}    ${index}    
    \    ${index}    Evaluate    ${index}+1    
    \    ${status}=    Get From List    ${values}    ${index}
    \    Expand Collection Table Group Expander    ${group}    ${group_name}    ${row_number_1}
    \    Verify Collection Table Group Row Content    ${group}    ${row_number_1}    ${method}    ${EMPTY}    ${status}
    \    Click Collection Table Group Row Edit Button    ${group}    ${row_number_1}
    \    Fill Add To Collection Box    ${name}    ${Select_Option}    ${group_name}
    \    Patient Click Element    ${Add_To_Collection_Box_Add_BUTTON}    4
    \    Verify Collection Table Group Row Content    ${group}    ${max_row}    ${method}    ${name}    ${status}
        

Step_06_run
    : FOR    ${name}    IN    @{names}
    \    ${index}    Evaluate    0
    \    ${values}    Get From Dictionary    ${dict}    ${name}
    \    ${group}=    Get From List    ${values}    ${index}
    \    ${index}    Evaluate    ${index}+1
    \    ${group_name}=    Get From List    ${values}    ${index}
    \    ${index}    Evaluate    ${index}+1
    \    ${max_row}=    Get From List    ${values}    ${index}
    \    ${index}    Evaluate    ${index}+1
    \    ${method}=    Get From List    ${values}    ${index}    
    \    ${index}    Evaluate    ${index}+1    
    \    ${status}=    Get From List    ${values}    ${index}
    \    ${index}    Evaluate    ${index}+1
    \    ${name_b}=    Get From List    ${values}    ${index}
    \    Verify Collection Table Group Row Content    ${group}    ${row_number_1}    ${method}    ${name}    ${status}
    \    Click Collection Table Group Row Edit Button    ${group}    ${row_number_1}
    \    Fill Add To Collection Box    ${name_b}    ${Select_Option}    ${group_name}
    \    Patient Click Element    ${Add_To_Collection_Box_Add_BUTTON}    4
    \    Verify Collection Table Group Row Content    ${group}    ${max_row}    ${method}    ${name_b}    ${status}
    
   If Collection Table Contains Data Then Clear Collection Data


Step_07_run
    Close DLUX    
        
    

