*** Settings ***
Documentation     Verification that when nongroup edited parametrized request is saved, 
...               the edited request is present in collection table. 
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
    ...    all existing topologies. Load "topology-list" in customContainer Area. Click HISTORY tab.
    ...    If the page contains any request in history list, click Clear history data.
    ...    Result
    ...    The page contains "topology list" arrow expander, "topology list" plus button and "topology list"
    ...    button in customContainer Area.
    Step_03_run

Step_04
    [Documentation]    Navigate to API tab. Execute PUT operation with valid data. Topology id value: t0.
    ...    Load "node list" button in customContainer Area. Click "node list" icon Plus to add node id.
    ...    Execute Put operation with valid data. Topology id value: t0, Node id value: t0n0.
    ...    Load "link list" button in customContainer Area. Click "link list" icon Plus to add link id.
    ...    Click source expander to input source-node and destination arrow expander to insert destination node.
    ...    Execute Put operation with valid data. Topology id value: t0, Link id value: t0l0, Source-node: s0,
    ...    Dest-node: d0.
    Step_04_run

Step_05
    [Documentation]    Navigate to History tab. Add requests to collection with name and group.
    ...    1st row request: Name value: N1, 2nd row request: Name value: N2, 3rd row request: Name value: N3.
    ...    Navigate to collection tab.
    ...    Result
    ...    The page should contain: - 1st row: - name N1, - success sent data elements,
    ...    - 2nd row: - name N2, - success sent data elements, 
    ...    - 3rd row: - name N3, - success sent data elements.     
    Step_05_run
    
Step_06
    [Documentation]    Navigate to Parameters tab. Add 5 parameters. Param1: name = p1,value = v1
    ...    Param2: name = p2,value = v2; Param3: name = p3,value = v3, Param4: name = p4,value = v4,
    ...    Param5: name = p5,value = v5.
    Step_06_run

Step_07
    [Documentation]    Navigate to Collection tab. Click Sent data button 1st row.
    ...    Edit sent data - insert parameter1 key to topology id input in path wrapper.
    ...    Param1 key = <<p1>>. Click Save parametrized data.
    ...    Click Sent data button 2nd row. Edit sent data - insert parameter2 key 
    ...    to node id input in path wrapper. Param2 key = <<p2>>. Click Save parametrized data.
    ...    Click Sent data button 3rd row. Edit sent data - insert parameter3 key 
    ...    to link id input in path wrapper. Param3 key = <<p3>>. Click Save parametrized data.
    ...    Result
    ...    The page should contain: -4th row: - name N1, - success sent data elements,
    ...    -5th row: - name N2, - success sent data elements, -6th row: - name N3, - success sent data element
    Step_07_run

Step_08
    [Documentation]    Click Sent data button 4th row. Click Sent data button 5th row.
    ...    Click Sent data button 6th row.
    ...    Result
    ...    The page should contain: Param1 key = <<p1>> in row 4 code mirror.
    ...    Param2 key = <<p2>> in row 5 code mirror. Param3 key = <<p3>> in row 6 code mirror.
   Step_08_run

Step_09
   [Documentation]     Clear collection data.
    ...    Result
    ...    Page should not contain any recrd in collection table.   
    Step_09_run

Step_10
    [Documentation]    Close Dlux.    
    Step_10_run
    

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
    Click Element    ${Testing_Root_API_Topology_List_Plus_BUTTON}
    PUT ID    ${Testing_Root_API_Topology_List_Topology_Id_INPUT}    ${Topology_Id_0}    ${Topology_ID}    ${Testing_Root_API_Topology_List_NAME}

    Load Node List Button In CustomContainer Area
    Click Element    ${Testing_Root_API_Node_List_Plus_BUTTON}
    Wait Until Page Contains Element    ${Testing_Root_API_Node_List_Node_Id_INPUT}    
    Insert Text To Input Field    ${Topology_Id_Path_Wrapper_INPUT}    ${Topology_Id_0}    
    Insert Text To Input Field    ${Node_Id_Path_Wrapper_INPUT}    ${Node_Id_0}
    Execute Chosen Operation    ${Put_OPERATION}    ${Request_sent_successfully_ALERT}

    Load Link List Button In CustomContainer Area
    Click Element    ${Testing_Root_API_Link_List_Plus_BUTTON}
    Wait Until Page Contains Element    ${Testing_Root_API_Link_List_Link_Id_INPUT}        
    Insert Text To Input Field    ${Topology_Id_Path_Wrapper_INPUT}    ${Topology_Id_0}    
    Insert Link Id In Form    ${Link_Id_0}    ${Source-node}    ${Destination-node}    

    Execute Chosen Operation    ${Put_OPERATION}    ${Request_sent_successfully_ALERT}
  

Step_05_run
    Click Element    ${HISTORY_TAB}
    Verify Sent Data Elements Presence In History Table Row    ${row_number_1}
    Add Request To Collection    ${row_number_1}    ${Name_1}    ${Select_Option}    ${EMPTY}
    Click Element    ${Add_To_Collection_Box_Add_BUTTON}
    
    Verify Sent Data Elements Presence In History Table Row    ${row_number_2}
    Add Request To Collection    ${row_number_2}    ${Name_2}    ${Select_Option}    ${EMPTY}
    Click Element    ${Add_To_Collection_Box_Add_BUTTON}
    
    Verify Sent Data Elements Presence In History Table Row    ${row_number_3}
    Add Request To Collection    ${row_number_3}    ${Name_3}    ${Select_Option}    ${EMPTY}
    Click Element    ${Add_To_Collection_Box_Add_BUTTON}

    If History Table Contains Data Then Clear History Data


Step_06_run
    Click Element    ${PARAMETERS_TAB}
    Wait Until Page Contains Element    ${Add_New_Parameter_BUTTON}
    ${parameters}=    Create Dictionary    ${Param_Name_1}=${Param_Value_1}    ${Param_Name_2}=${Param_Value_2}    ${Param_Name_3}=${Param_Value_3}
    ...    ${Param_Name_4}=${Param_Value_4}    ${Param_Name_5}=${Param_Value_5}    
    @{param_names}=    Create List    ${Param_Name_1}    ${Param_Name_2}    ${Param_Name_3}    ${Param_Name_4}    ${Param_Name_5}
    : FOR    ${param_name}    IN    @{param_names}
    \    ${value}=    Get From Dictionary    ${parameters}    ${param_name}
    \    Run Keyword    Add New Parameter    ${param_name}    ${value}    Verify Add_New_Parameter_Box NONVisibility

    Click Element    ${COLLECTION_TAB}    
        
    
Step_07_run
    Click Element    ${COLLECTION_TAB}
    @{rows}=    Create List    ${row_number_1}    ${row_number_2}    ${row_number_3}    
    @{names}=    Create List    ${Name_1}    ${Name_2}    ${Name_3}
    : FOR    ${row}    IN    @{rows}
    \    ${index}    Evaluate    ${row}-1
    \    ${name}=    Get From List    ${names}    ${index}                
    \    Verify Collection Table Nongroup Row Content    ${row}    ${Put_Method_NAME}    ${name}    ${Success_STATUS}
    \    Verify Sent Data Elements Presence In Collection Table Nongroup Row    ${row}

    ${Collection_Table_List_Nongroup_ROW}=    Return Collection Table Nongroup Row Number    ${row_number_1}
    Open Collection Table Nongroup Sent Data Box    ${row_number_1}
    ${Collection_Table_Nongroup_Row_Sent_Data_BOX}=    Set Variable    ${Collection_Table_List_Nongroup_ROW}${Sent_Data_BOX}
    ${Collection_Table_Nongroup_Row_Sent_Data_Box_Path_WRAPPER}=    Set Variable    ${Collection_Table_Nongroup_Row_Sent_Data_BOX}${Sent_Data_Box_Path_WRAPPER}    
    ${Collection_Table_Nongroup_Row_Sent_Data_Box_Topology_Id_Path_Wrapper_INPUT}=    Set Variable    ${Collection_Table_Nongroup_Row_Sent_Data_Box_Path_WRAPPER}${Sent_Data_Box_Topology_Id_Path_Wrapper_INPUT}    
    ${Collection_Table_Nongroup_Row_Sent_Data_Box_Save_Parametrized_Data_BUTTON}=    Set Variable    ${Collection_Table_Nongroup_Row_Sent_Data_BOX}${Sent_Data_Box_Save_Parametrized_Data_BUTTON}
    ${parameter_key_1}=    Return Parameter Key    ${Param_Name_1}
    Set Suite Variable    ${parameter_key_1}    
    Insert Text To Input Field    ${Collection_Table_Nongroup_Row_Sent_Data_Box_Topology_Id_Path_Wrapper_INPUT}    ${parameter_key_1}
    Click Element    ${Collection_Table_Nongroup_Row_Sent_Data_Box_Save_Parametrized_Data_BUTTON}
    Wait Until Page Contains Element    ${Parametrized_data_was_saved_ALERT}
    Close Alert Panel    
    
    ${Collection_Table_List_Nongroup_ROW}=    Return Collection Table Nongroup Row Number    ${row_number_2}
    Open Collection Table Nongroup Sent Data Box    ${row_number_2}
    ${Collection_Table_Nongroup_Row_Sent_Data_BOX}=    Set Variable    ${Collection_Table_List_Nongroup_ROW}${Sent_Data_BOX}
    ${Collection_Table_Nongroup_Row_Sent_Data_Box_Path_WRAPPER}=    Set Variable    ${Collection_Table_Nongroup_Row_Sent_Data_BOX}${Sent_Data_Box_Path_WRAPPER}    
    ${Collection_Table_Nongroup_Row_Sent_Data_Box_Topology_Id_Path_Wrapper_INPUT}=    Set Variable    ${Collection_Table_Nongroup_Row_Sent_Data_Box_Path_WRAPPER}${Sent_Data_Box_Topology_Id_Path_Wrapper_INPUT}    
    ${Collection_Table_Nongroup_Row_Sent_Data_Box_Node_Id_Path_Wrapper_INPUT}=    Set Variable    ${Collection_Table_Nongroup_Row_Sent_Data_Box_Path_WRAPPER}${Sent_Data_Box_Node_Id_Path_Wrapper_INPUT}
    ${Collection_Table_Nongroup_Row_Sent_Data_Box_Save_Parametrized_Data_BUTTON}=    Set Variable    ${Collection_Table_Nongroup_Row_Sent_Data_BOX}${Sent_Data_Box_Save_Parametrized_Data_BUTTON}
    ${parameter_key_2}=    Return Parameter Key    ${Param_Name_2}
    ${parameter_key_3}=    Return Parameter Key    ${Param_Name_3}
    Set Suite Variable    ${parameter_key_3}
    Insert Text To Input Field    ${Collection_Table_Nongroup_Row_Sent_Data_Box_Topology_Id_Path_Wrapper_INPUT}    ${parameter_key_2}
    Insert Text To Input Field    ${Collection_Table_Nongroup_Row_Sent_Data_Box_Node_Id_Path_Wrapper_INPUT}    ${parameter_key_3}
    Verify Collection Nongroup Sent Box Data Presence In Code Mirror    ${row_number_2}    ${parameter_key_3}
    Click Element    ${Collection_Table_Nongroup_Row_Sent_Data_Box_Save_Parametrized_Data_BUTTON}
    Wait Until Page Contains Element    ${Parametrized_data_was_saved_ALERT}
    Close Alert Panel
    
    ${Collection_Table_List_Nongroup_ROW}=    Return Collection Table Nongroup Row Number    ${row_number_3}
    Open Collection Table Nongroup Sent Data Box    ${row_number_3}
    ${Collection_Table_Nongroup_Row_Sent_Data_BOX}=    Set Variable    ${Collection_Table_List_Nongroup_ROW}${Sent_Data_BOX}
    ${Collection_Table_Nongroup_Row_Sent_Data_Box_Path_WRAPPER}=    Set Variable    ${Collection_Table_Nongroup_Row_Sent_Data_BOX}${Sent_Data_Box_Path_WRAPPER}    
    ${Collection_Table_Nongroup_Row_Sent_Data_Box_Topology_Id_Path_Wrapper_INPUT}=    Set Variable    ${Collection_Table_Nongroup_Row_Sent_Data_Box_Path_WRAPPER}${Sent_Data_Box_Topology_Id_Path_Wrapper_INPUT}    
    ${Collection_Table_Nongroup_Row_Sent_Data_Box_Link_Id_Path_Wrapper_INPUT}=    Set Variable    ${Collection_Table_Nongroup_Row_Sent_Data_Box_Path_WRAPPER}${Sent_Data_Box_Link_Id_Path_Wrapper_INPUT}
    ${Collection_Table_Nongroup_Row_Sent_Data_Box_Save_Parametrized_Data_BUTTON}=    Set Variable    ${Collection_Table_Nongroup_Row_Sent_Data_BOX}${Sent_Data_Box_Save_Parametrized_Data_BUTTON}
    ${parameter_key_4}=    Return Parameter Key    ${Param_Name_4}
    ${parameter_key_5}=    Return Parameter Key    ${Param_Name_5}
    Set Suite Variable    ${parameter_key_5}
    Insert Text To Input Field    ${Collection_Table_Nongroup_Row_Sent_Data_Box_Topology_Id_Path_Wrapper_INPUT}    ${parameter_key_4}
    Insert Text To Input Field    ${Collection_Table_Nongroup_Row_Sent_Data_Box_Link_Id_Path_Wrapper_INPUT}    ${parameter_key_5}
    Verify Collection Nongroup Sent Box Data Presence In Code Mirror    ${row_number_3}    ${parameter_key_5}
    Click Element    ${Collection_Table_Nongroup_Row_Sent_Data_Box_Save_Parametrized_Data_BUTTON}
    Wait Until Page Contains Element    ${Parametrized_data_was_saved_ALERT}
    Close Alert Panel

Step_08_run
    ${dict}=    Create Dictionary    ${row_number_4}=${parameter_key_1}    ${row_number_5}=${parameter_key_3}    ${row_number_6}=${parameter_key_5}         
    @{rows}=    Create List    ${row_number_4}    ${row_number_5}    ${row_number_6}
    @{names}=    Create List    ${Name_1}    ${Name_2}    ${Name_3}
    : FOR    ${row}    IN    @{rows}
    \    ${index}    Evaluate    ${row}-4
    \    ${name}=    Get From List    ${names}    ${index}                
    \    Verify Collection Table Nongroup Row Content    ${row}    ${Put_Method_NAME}    ${name}    ${Success_STATUS}
    \    Verify Sent Data Elements Presence In Collection Table Nongroup Row    ${row}
    
    : FOR    ${row}    IN    @{rows}       
    \    ${value}=    Get From Dictionary    ${dict}    ${row}
    \    Open Collection Table Nongroup Sent Data Box    ${row}
    \    Verify Collection Nongroup Sent Box Data Presence In Code Mirror    ${row}    ${value}
        

Step_09_run
    If Collection Table Contains Data Then Clear Collection Data


Step_10_run
    Close DLUX
