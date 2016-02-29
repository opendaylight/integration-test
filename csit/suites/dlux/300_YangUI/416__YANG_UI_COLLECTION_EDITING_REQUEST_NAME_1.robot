*** Settings ***
Documentation     Verification that it is possible to edit nongroup request name in collection tab.
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
    [Documentation]    Execute DELETE operation. Add request to Collection with no name.
    ...    Execute GET operation. Add request to Collection with no name.
    ...    Execute PUT operation. Add request to Collection with no name. Topology id: t0.
    ...    Execute GET operation. Add request to Collection with no name.
    ...    Execute PUToperation. Add request to Collection with no name.
    ...    Clear History data. Navigate to Collection tab.
    ...    Result
    ...    The page should contain: - Row 1, method Remove, status success.
    ...    - Row 2, method Get, status error. - Row 3, method Put, status success.
    ...    - Row 4, method Get, status success. - Row 5, method Put, status error
    Step_04_run
    
Step_05
    [Documentation]    Click Edit button in all requests one by one. 
    ...    Req 1 - Insert name and click Save button. Name value: N1    
    ...    Req 2 - Insert name and click Save button. Name value: N2
    ...    Req 3 - Insert name and click Save button. Name value: N3
    ...    Req 4 - Insert name and click Save button. Name value: N4
    ...    Req 5 - Insert name and click Save button. Name value: N5
    ...    Result
    ...    The page should contain: - Row 1, name N1, method Remove, status success.
    ...    - Row 2, name N2, method Get, status error. - Row 3, name N3, method Put, status success.
    ...    - Row 4, name N4, method Get, status success. - Row 5, name N5, method Put, status error.
    Step_05_run
    
Step_06
   [Documentation]    Click Edit button in all requests one by one. 
    ...    Req 1 - Insert name and click Save button. Name value: N6    
    ...    Req 2 - Insert name and click Save button. Name value: N7
    ...    Req 3 - Insert name and click Save button. Name value: N8
    ...    Req 4 - Insert name and click Save button. Name value: N9
    ...    Req 5 - Insert name and click Save button. Name value: N10
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
    Add Request To Collection    ${row_number_1}    ${EMPTY}    ${Select_Option}    ${EMPTY}
    Click Element    ${Add_To_Collection_Box_Add_BUTTON}    
    
    Execute Chosen Operation    ${Get_OPERATION}    ${Data_missing_Relevant_data_model_not_existing_ALERT}
    Verify History Table Row Content    ${row_number_2}    ${Get_Method_NAME}    ${Error_STATUS}
    Verify No Sent No Received Data Elements Presence In History Table Row    ${row_number_2}
    Add Request To Collection    ${row_number_2}    ${EMPTY}    ${Select_Option}    ${EMPTY}
    Click Element    ${Add_To_Collection_Box_Add_BUTTON}
    
    Expand Network Topology Arrow Expander
    Click Element    ${Testing_Root_API_Topology_List_Plus_BUTTON}
    PUT ID    ${Testing_Root_API_Topology_List_Topology_Id_INPUT}    ${Topology_Id_0}    ${Topology_ID}    ${Testing_Root_API_Topology_List_NAME}    
    Verify History Table Row Content    ${row_number_3}    ${Put_Method_NAME}    ${Success_STATUS}
    Verify Sent Data Elements Presence In History Table Row    ${row_number_3}
    Add Request To Collection    ${row_number_3}    ${EMPTY}    ${Select_Option}    ${EMPTY}
    Click Element    ${Add_To_Collection_Box_Add_BUTTON}    
    
    Execute Chosen Operation    ${Get_OPERATION}    ${Request_sent_successfully_ALERT}    
    Verify History Table Row Content    ${row_number_4}    ${Get_Method_NAME}    ${Success_STATUS}
    Verify Received Data Elements Presence In History Table Row     ${row_number_4}
    Add Request To Collection    ${row_number_4}    ${EMPTY}    ${Select_Option}    ${EMPTY}
    Click Element    ${Add_To_Collection_Box_Add_BUTTON}
    Close Form In CustomContainer Area    ${Testing_Root_API_Topology_List_Topology_Delete_BUTTON}    ${Testing_Root_API_Topology_List_Topology_Id_INPUT}

    Execute Chosen Operation    ${Put_OPERATION}    ${Error_sending_request_Input_is_required_ALERT}    
    Verify History Table Row Content    ${row_number_5}    ${Put_Method_NAME}    ${Error_STATUS}
    Verify No Sent No Received Data Elements Presence In History Table Row    ${row_number_5}
    Add Request To Collection    ${row_number_5}    ${EMPTY}    ${Select_Option}    ${EMPTY}
    Click Element    ${Add_To_Collection_Box_Add_BUTTON}
    
    If History Table Contains Data Then Clear History Data


Step_05_run
    Click Element    ${COLLECTION_TAB}
    @{row_num_1_data}=    Create List    ${EMPTY}    ${Remove_Method_NAME}    ${Success_STATUS}    ${Name_1}    ${Name_6}
    Set Suite Variable    @{row_num_1_data}    
    @{row_num_2_data}=    Create List    ${EMPTY}    ${Get_Method_NAME}    ${Error_STATUS}    ${Name_2}    ${Name_7}
    Set Suite Variable    @{row_num_2_data}
    @{row_num_3_data}=    Create List    ${EMPTY}    ${Put_Method_NAME}    ${Success_STATUS}    ${Name_3}    ${Name_8}
    Set Suite Variable    @{row_num_3_data}
    @{row_num_4_data}=    Create List    ${EMPTY}    ${Get_Method_NAME}    ${Success_STATUS}    ${Name_4}    ${Name_9}
    Set Suite Variable    @{row_num_4_data}
    @{row_num_5_data}=    Create List    ${EMPTY}    ${Put_Method_NAME}    ${Error_STATUS}    ${Name_5}    ${Name_10}
    Set Suite Variable    @{row_num_5_data}
    ${dict}=    Create Dictionary    ${row_number_1}=${row_num_1_data}    ${row_number_2}=${row_num_2_data}    ${row_number_3}=${row_num_3_data}
    ...    ${row_number_4}=${row_num_4_data}    ${row_number_5}=${row_num_5_data}
    Set Suite Variable    ${dict}        
    @{rows}=    Create List    ${row_number_1}    ${row_number_2}    ${row_number_3}    ${row_number_4}    ${row_number_5}    
    Set Suite Variable    @{rows}
    : FOR    ${row}    IN    @{rows}
    \    ${index}    Evaluate    0
    \    ${values}=    Get From Dictionary    ${dict}    ${row}
    \    ${name}=    Get From List    ${values}    ${index}
    \    ${index}    Evaluate    ${index}+1
    \    ${method}=    Get From List    ${values}    ${index}
    \    ${index}    Evaluate    ${index}+1
    \    ${status}=    Get From List    ${values}    ${index}
    \    ${index}    Evaluate    ${index}+1
    \    ${name_b}=    Get From List    ${values}    ${index}
    \    Verify Collection Table Nongroup Row Content    ${row_number_1}    ${method}    ${name}    ${status}
    \    Click Collection Table Nongroup Row Edit Button    ${row_number_1}
    \    Fill Add To Collection Box    ${name_b}    ${Select_Option}    ${EMPTY}
    \    Patient Click Element    ${Add_To_Collection_Box_Add_BUTTON}    4
    \    Verify Collection Table Nongroup Row Content    ${row_number_5}    ${method}    ${name_b}    ${status}
    
    
Step_06_run
    : FOR    ${row}    IN    @{rows}
    \    ${index}    Evaluate    0
    \    ${values}=    Get From Dictionary    ${dict}    ${row}
    \    ${name}=    Get From List    ${values}    ${index}
    \    ${index}    Evaluate    ${index}+1
    \    ${method}=    Get From List    ${values}    ${index}
    \    ${index}    Evaluate    ${index}+1
    \    ${status}=    Get From List    ${values}    ${index}
    \    ${index}    Evaluate    ${index}+1
    \    ${name_b}=    Get From List    ${values}    ${index}
    \    ${index}    Evaluate    ${index}+1
    \    ${name_c}=    Get From List    ${values}    ${index}
    \    Verify Collection Table Nongroup Row Content    ${row_number_1}    ${method}    ${name_b}    ${status}
    \    Click Collection Table Nongroup Row Edit Button    ${row_number_1}
    \    Fill Add To Collection Box    ${name_c}    ${Select_Option}    ${EMPTY}
    \    Patient Click Element    ${Add_To_Collection_Box_Add_BUTTON}    4
    \    Verify Collection Table Nongroup Row Content    ${row_number_5}    ${method}    ${name_c}    ${status}
    
    If Collection Table Contains Data Then Clear Collection Data


Step_07_run
    Close DLUX
