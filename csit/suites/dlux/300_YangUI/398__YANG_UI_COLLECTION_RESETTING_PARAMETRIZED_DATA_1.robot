*** Settings ***
Documentation     Verification that it is possible to reset edited nongroup row  sent parametrized data.
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
    ...    and Yang UI Submenu. Location should be http://127.0.0.1:8181/index.html#/yangui/index.
    Step_02_run

Step_03
    [Documentation]    Load "network-topology" button in customContainer Area. Delete 
    ...    all existing topologies. Load "topology-list" in customContainer Area.
    ...    Result
    ...    The page contains "topology list" arrow expander, "topology list" plus button and "topology list"
    ...    button in customContainer Area.
    Step_03_run

Step_04
    [Documentation]    Navigate to Parameters tab. Add 3 parameters. Param1: name = p1,value = v1
    ...    Param2: name = p2,value = v2; Param3: name = p3,value = v3.
    Step_04_run

Step_05
    [Documentation]    Click HISTORY tab. If the page contains any request in history list, 
    ...    click Clear history data. Execute PUT operation with valid data. Topology id value: t0
    ...    Name value: N1. Add request to collection with no goup. Navigate to COLLECTION tab.
    ...    Result
    ...    The page does not contain History table row. The page should contain:
    ...    - name N1, - success sent data elements. 
    Step_05_run

Step_06
    [Documentation]    Click Sent data button. Edit sent data - insert parameter1 key
    ...    to topology id input in path wrapper. Param1 key = <<p1>> Click Reset parametrized data button.
    ...    Close Sent data box.
    ...    Result
    ...    The page should contain: - topology id path wrapper input.
    ...    Param1 key should not be present in CodeMirror and topology id input.
    ...    The page should not contain Sent data box.
    Step_06_run

Step_07
    [Documentation]    Navigate to API tab. Load "node list" button in customContainer Area.
    ...    Click "node list" icon Plus to add node id. Execute Put operation with valid data.
    ...    Click History tab. Add request to collection with name and no group.
    ...    Navigate to collection tab. Topology id value: t0. Node id value: t0n0.
    ...    Name value: N2
    ...    Result
    ...    The page should contain: - name N2, - success sent data elements
    Step_07_run

Step_08
    [Documentation]     Click Sent data button. Edit sent data - insert parameter2 key
    ...    to topology id input and param3 key to node id input in path wrapper. Param2 key = <<p2>>, Param3 key = <<p3>>
    ...    Click Reset parametrized data button.
    ...    Result
    ...    The page should contain: The page should contain: - topology id path wrapper input,
    ...    - node id path wrapper input.
    ...    Param2 and param3 key should not be present in CodeMirror.
    ...    The page should not contain Sent data box.   
    Step_08_run

Step_09
    [Documentation]    Close Dlux.
    Step_09_run

*** Keywords ***
Step_01_run
    Launch Or Open DLUX Page And Login DLUX


Step_02_run
    Navigate To Yang UI Submenu


Step_03_run
    Load Network-topology Button In CustomContainer Area
    Delete All Existing Topologies
    Load Topology List Button In CustomContainer Area


Step_04_run
    Click Element    ${PARAMETERS_TAB}
    Wait Until Page Contains Element    ${Add_New_Parameter_BUTTON}
    ${parameters}=    Create Dictionary    ${Param_Name_1}=${Param_Value_1}    ${Param_Name_2}=${Param_Value_2}    ${Param_Name_3}=${Param_Value_3}    
    @{keys}=    Get Dictionary Keys    ${parameters}
    : FOR    ${key}    IN    @{keys}
    \    ${value}=    Get From Dictionary    ${parameters}    ${key}
    \    Run Keyword    Add New Parameter    ${key}    ${value}    Verify Add_New_Parameter_Box NONVisibility


Step_05_run
    ${row_number}=    Set Variable    1
    Click Element    ${HISTORY_TAB}
    If History Table Contains Data Then Clear History Data
    Click Element    ${Testing_Root_API_Topology_List_Plus_BUTTON}
    PUT ID    ${Testing_Root_API_Topology_List_Topology_Id_INPUT}    ${Topology_Id_0}    ${Topology_ID}    ${Testing_Root_API_Topology_List_NAME}
    Verify Sent Data Elements Presence In History Table Row    ${row_number}
    Add Request To Collection    1    ${Name_1}    ${Select_Option}    ${EMPTY}
    Click Element    ${Add_To_Collection_Box_Add_BUTTON}
    If History Table Contains Data Then Clear History Data
    Click Element    ${COLLECTION_TAB}  
    Verify Collection Table Nongroup Row Content    ${row_number}    ${Put_Method_NAME}    ${Name_1}    ${Success_STATUS}
    Verify Sent Data Elements Presence In Collection Table Nongroup Row    ${row_number}


Step_06_run
    ${row_number}=    Set Variable    1
    ${Collection_Table_List_Nongroup_ROW}=    Return Collection Table Nongroup Row Number    ${row_number}
    Open Collection Table Nongroup Sent Data Box    ${row_number}
    ${Collection_Table_Nongroup_Row_Sent_Data_BOX}=    Set Variable    ${Collection_Table_List_Nongroup_ROW}${Sent_Data_BOX}
    ${Collection_Table_Nongroup_Row_Sent_Data_Box_Path_WRAPPER}=    Set Variable    ${Collection_Table_Nongroup_Row_Sent_Data_BOX}${Sent_Data_Box_Path_WRAPPER}    
    ${Collection_Table_Nongroup_Row_Sent_Data_Box_Topology_Id_Path_Wrapper_INPUT}=    Set Variable    ${Collection_Table_Nongroup_Row_Sent_Data_Box_Path_WRAPPER}${Sent_Data_Box_Topology_Id_Path_Wrapper_INPUT}    
    Page Should Contain Element    ${Collection_Table_Nongroup_Row_Sent_Data_Box_Topology_Id_Path_Wrapper_INPUT}
    ${parameter_key_1}=    Return Parameter Key    ${Param_Name_1}
    Insert Text To Input Field    ${Collection_Table_Nongroup_Row_Sent_Data_Box_Topology_Id_Path_Wrapper_INPUT}    ${parameter_key_1}
    Verify Collection Nongroup Sent Box Data Presence In Code Mirror    ${row_number}    ${parameter_key_1}
    Reset Nongroup Parametrized Data    ${row_number} 
    Verify Collection Nongroup Sent Box Data NONPresence In Code Mirror    ${row_number}    ${parameter_key_1}
    Verify Collection Nongroup Sent Box Data Presence In Code Mirror    ${row_number}    ${Topology_Id_0}
    Close Collection Nongroup Sent Box    ${row_number}        
    
    
Step_07_run
    ${row_number}=    Set Variable    2
    Click Element    ${API_TAB}
    Wait Until Page Contains Element    ${Testing_Root_API_Topology_Topology_Id_Plus_EXPANDER}
    Load Node List Button In CustomContainer Area
    Click Element    ${Testing_Root_API_Node_List_Plus_BUTTON}
    Wait Until Page Contains Element    ${Testing_Root_API_Node_List_Node_Id_INPUT}    
    Insert Text To Input Field    ${Topology_Id_Path_Wrapper_INPUT}    ${Topology_Id_0}    
    Insert Text To Input Field    ${Node_Id_Path_Wrapper_INPUT}    ${Node_Id_0}
    Execute Chosen Operation    ${Put_OPERATION}    ${Request_sent_successfully_ALERT}
    Click Element    ${HISTORY_TAB}
    Verify Sent Data Elements Presence In History Table Row    1        
    Add Request To Collection    1    ${Name_2}    ${Select_Option}    ${EMPTY}
    Click Element    ${Add_To_Collection_Box_Add_BUTTON}
    If History Table Contains Data Then Clear History Data
    Click Element    ${COLLECTION_TAB}  
    Verify Collection Table Nongroup Row Content    ${row_number}    ${Put_Method_NAME}    ${Name_2}    ${Success_STATUS}
    Verify Sent Data Elements Presence In Collection Table Nongroup Row    ${row_number}


Step_08_run
    ${row_number}=    Set Variable    2
    ${Collection_Table_List_Nongroup_ROW}=    Return Collection Table Nongroup Row Number    ${row_number}
    Open Collection Table Nongroup Sent Data Box    ${row_number}
    ${Collection_Table_Nongroup_Row_Sent_Data_BOX}=    Set Variable    ${Collection_Table_List_Nongroup_ROW}${Sent_Data_BOX}
    ${Collection_Table_Nongroup_Row_Sent_Data_Box_Path_WRAPPER}=    Set Variable    ${Collection_Table_Nongroup_Row_Sent_Data_BOX}${Sent_Data_Box_Path_WRAPPER}    
    ${Collection_Table_Nongroup_Row_Sent_Data_Box_Topology_Id_Path_Wrapper_INPUT}=    Set Variable    ${Collection_Table_Nongroup_Row_Sent_Data_Box_Path_WRAPPER}${Sent_Data_Box_Topology_Id_Path_Wrapper_INPUT}    
    ${Collection_Table_Nongroup_Row_Sent_Data_Box_Node_Id_Path_Wrapper_INPUT}=    Set Variable    ${Collection_Table_Nongroup_Row_Sent_Data_Box_Path_WRAPPER}${Sent_Data_Box_Node_Id_Path_Wrapper_INPUT}
    Page Should Contain Element    ${Collection_Table_Nongroup_Row_Sent_Data_Box_Topology_Id_Path_Wrapper_INPUT}
    Page Should Contain Element    ${Collection_Table_Nongroup_Row_Sent_Data_Box_Node_Id_Path_Wrapper_INPUT}
    ${parameter_key_2}=    Return Parameter Key    ${Param_Name_2}
    ${parameter_key_3}=    Return Parameter Key    ${Param_Name_3}
    Insert Text To Input Field    ${Collection_Table_Nongroup_Row_Sent_Data_Box_Topology_Id_Path_Wrapper_INPUT}    ${parameter_key_2}
    Insert Text To Input Field    ${Collection_Table_Nongroup_Row_Sent_Data_Box_Node_Id_Path_Wrapper_INPUT}    ${parameter_key_3}
    Verify Collection Nongroup Sent Box Data Presence In Code Mirror    ${row_number}    ${parameter_key_3}
    Reset Nongroup Parametrized Data    ${row_number} 
    Verify Collection Nongroup Sent Box Data NONPresence In Code Mirror    ${row_number}    ${parameter_key_3}
    Verify Collection Nongroup Sent Box Data Presence In Code Mirror    ${row_number}    ${Node_Id_0}
    Close Collection Nongroup Sent Box    ${row_number}   
   
    If Collection Table Contains Data Then Clear Collection Data


Step_09_run
    Close DLUX
