*** Settings ***
Documentation     Verification that when edited parametrized request is saved, the edited 
...              request is present in history table. 
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
    [Documentation]    Navigate to Parameters tab. Add 5 parameters. Param1: name = p1,value = v1
    ...    Param2: name = p2,value = v2; Param3: name = p3,value = v3, Param4: name = p4,value = v4,
    ...    Param5: name = p5,value = v5.     
    Step_05_run
    
Step_06
    [Documentation]    Navigate to History tab. Click Sent data button 1st row.
    ...    Edit sent data - insert parameter1 key to topology id input in path wrapper.
    ...    Param1 key = <<p1>>. Click Save parametrized data.
    ...    Click Sent data button 2nd row. Edit sent data - insert parameter2 key 
    ...    to node id input in path wrapper. Param2 key = <<p2>>. Click Save parametrized data.
    ...    Click Sent data button 3rd row. Edit sent data - insert parameter3 key 
    ...    to link id input in path wrapper. Param3 key = <<p3>>. Click Save parametrized data.
    ...    Result
    ...    The page should contain: -4th row - success sent data elements,
    ...    -5th row - success sent data elements, -6th row - success sent data element
    Step_06_run

Step_07
    [Documentation]    Click Sent data button 4th row. Click Sent data button 5th row.
    ...    Click Sent data button 6th row.
    ...    Result
    ...    The page should contain: Param1 key = <<p1>> in row 4 code mirror.
    ...    Param2 key = <<p2>> in row 5 code mirror. Param3 key = <<p3>> in row 6 code mirror.
   Step_07_run

Step_08
   [Documentation]     Clear collection data.
    ...    Result
    ...    Page should not contain any recrd in collection table.   
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
    Click Element    ${PARAMETERS_TAB}
    Wait Until Page Contains Element    ${Add_New_Parameter_BUTTON}
    ${parameters}=    Create Dictionary    ${Param_Name_1}=${Param_Value_1}    ${Param_Name_2}=${Param_Value_2}    ${Param_Name_3}=${Param_Value_3}
    ...    ${Param_Name_4}=${Param_Value_4}    ${Param_Name_5}=${Param_Value_5}    
    @{param_names}=    Create List    ${Param_Name_1}    ${Param_Name_2}    ${Param_Name_3}
    Set Suite Variable    @{param_names}    
    : FOR    ${param_name}    IN    @{param_names}
    \    ${value}=    Get From Dictionary    ${parameters}    ${param_name}
    \    Run Keyword    Add New Parameter    ${param_name}    ${value}    Verify Add_New_Parameter_Box NONVisibility

   
Step_06_run
    Click Element    ${HISTORY_TAB}
    @{rows}=    Create List    ${row_number_1}    ${row_number_2}    ${row_number_3}
    Set Suite Variable    @{rows}    
    : FOR    ${row}    IN    @{rows}
    \    Verify History Table Row Content    ${row}    ${Put_Method_NAME}    ${Success_STATUS}
    \    Verify Sent Data Elements Presence In History Table Row    ${row}

    @{row_1_data}=    Create List    ${Param_Name_1}    ${EMPTY}    ${EMPTY}    ${row_number_4}    ${Topology_Id_0}
    Set Suite Variable    @{row_1_data}             
    @{row_2_data}=    Create List    ${EMPTY}    ${Param_Name_2}    ${EMPTY}    ${row_number_5}    ${Node_Id_0}    
    Set Suite Variable    @{row_2_data}        
    @{row_3_data}=    Create List    ${EMPTY}    ${EMPTY}    ${Param_Name_3}    ${row_number_6}    ${Link_Id_0}    
    Set Suite Variable    @{row_3_data}
    ${dict}=    Create Dictionary    ${row_number_1}=@{row_1_data}    ${row_number_2}=@{row_2_data}    ${row_number_3}=@{row_3_data}
    Set Suite Variable    ${dict}
    : FOR    ${row}    IN    @{rows}
    \    ${index}    Evaluate    0
    \    ${values}=    Get From Dictionary    ${dict}    ${row}
    \    ${topo_param}=    Get From List    ${values}    ${index}
    \    ${index}    Evaluate    ${index}+1
    \    ${node_param}=    Get From List    ${values}    ${index}
    \    ${index}    Evaluate    ${index}+1
    \    ${link_param}=    Get From List    ${values}    ${index}
    \    ${index}    Evaluate    ${index}+1
    \    ${param_row}=    Get From List    ${values}    ${index}
    \    Set Suite Variable    ${param_row_index}    ${index}
    \    ${index}    Evaluate    ${index}+1
    \    ${url_separator}=    Get From List    ${values}    ${index}
    \    Set Suite Variable    ${url_separator_index}    ${index}        
    \    Insert Parameters To History Sent Data Path Wrapper    ${row}    ${topo_param}    ${node_param}    ${link_param}
    \    Save History Sent Box Parametrized Data    ${row}
    \    Wait Until Page Contains Element    ${Parametrized_data_was_saved_ALERT}
    \    Close Alert Panel
    


Step_07_run
    
    : FOR    ${row}    IN    @{rows}
    \    Verify History Table Row Content    ${row}    ${Put_Method_NAME}    ${Success_STATUS}
    \    Verify Sent Data Elements Presence In History Table Row    ${row}

    ${index}    Evaluate    0
    : FOR    ${row}    IN    @{rows}       
    \    ${param_name}=    Get From List    ${param_names}    ${index}        
    \    ${values}=    Get From Dictionary    ${dict}    ${row}
    \    ${param_row}=    Get From List    ${values}    ${param_row_index}
    \    ${param_key}=    Return Parameter Key    ${param_name}
    \    ${url_separator}=    Get From List    ${values}    ${url_separator_index}
    \    Open History Table Sent Data Box    ${param_row}
    \    Verify History Sent Box Data Presence In Code Mirror    ${param_row}    ${param_key}
    \    Close History Sent Data Box    ${param_row}
    \    ${url_1}=    Return History Table Row Url    ${row}
    \    ${url_1_edited}    Return Edited String    ${url_1}    ${url_separator}    ${param_key}
    \    ${url_2}=    Return History Table Row Url    ${param_row}
    \    Should Be Equal As Strings    ${url_1_edited}    ${url_2}    
    \    ${index}    Evaluate    ${index}+1  
  

Step_08_run
    If History Table Contains Data Then Clear History Data


Step_09_run
    Close DLUX
