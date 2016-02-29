*** Settings ***
Documentation     Verification that fill button enables to fill parametrized data from request to the form.
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
    ...    all existing topologies. Load "topology-list" in customContainer Area. Click HISTORY tab.
    ...    If the page contains any request in history list, click Clear history data.
    ...    Result
    ...    The page contains "topology list" arrow expander, "topology list" plus button and "topology list"
    ...    button in customContainer Area.
    Step_03_run

Step_04
    [Documentation]    Navigate to API tab. Execute PUT operation with valid data. 
    ...    Topology id value: t0, Node id value: t0n0, Link id value: t0l0.
    ...    Load "link list" button in customContainer Area. Execute Put operation with valid data. 
    ...    Topology id value: t0, Link id value: t0l0, Source-node: s0, Dest-node: d0. 
    Step_04_run

Step_05
    [Documentation]    Navigate to Parameters tab. Add 3 parameters. Param1: name = p1,value = v1
    ...    Param2: name = p2,value = v2; Param3: name = p3,value = v3.
    Step_05_run

Step_06
    [Documentation]    Navigate to History tab. Click Sent data button 1st row.
    ...    Edit sent data - insert param1 key to topology id input in path wrapper.
    ...    Click Save parametrized data.
    ...    Click Sent data button 2nd row. Edit sent data - insert parameter1 key to topology id input
    ...    and insert parameter2 key to link id input in path wrapper.
    ...    Click Save parametrized data.
    ...    Param1 key = <<p1>>, Param2 key = <<p3>>.
    ...    Open Sent data box in rows 3, 4.
    ...    Result
    ...    The page should contain: -3rd row - success sent data elements, Param1 key = <<p1>> in code mirror,
    ...    -4th row: - success sent data elements, Param3 key = <<p3>> in code mirror.
    Step_06_run

Step_07
    [Documentation]    Click drop button to fill sent data in form in rows - 3, 4. 
    ...    Result
    ...    The page should contain: 
    ...    - 3rd row filling in form: Topology id value: v1, Node id value: t0n0, Link id value: t0l0, Source-node: s0, Dest-node: d0. 
    ...    - 4th row filling in form: Link id value: v3, Source-node: s0, Dest-node: d0.
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

    Load Node List Button In CustomContainer Area
    Load Link List Button In CustomContainer Area
    Click Element    ${Testing_Root_API_Link_List_Plus_BUTTON}
    Insert Text To Input Field    ${Topology_Id_Path_Wrapper_INPUT}    ${Topology_Id_1}
    Insert Link Id In Form    ${Link_Id_1}    ${Source-node}    ${Destination-node}
    Wait Until Page Contains Element    ${Testing_Root_API_Link_List_Link_Id_INPUT}        
    Execute Chosen Operation    ${Put_OPERATION}    ${Request_sent_successfully_ALERT}
  

Step_05_run
    Click Element    ${PARAMETERS_TAB}
    Wait Until Page Contains Element    ${Add_New_Parameter_BUTTON}
    ${parameters}=    Create Dictionary    ${Param_Name_1}=${Param_Value_1}    ${Param_Name_2}=${Param_Value_2}    ${Param_Name_3}=${Param_Value_3}
    @{param_names}=    Create List    ${Param_Name_1}    ${Param_Name_2}    ${Param_Name_3}
    : FOR    ${param_name}    IN    @{param_names}
    \    ${value}=    Get From Dictionary    ${parameters}    ${param_name}
    \    Run Keyword    Add New Parameter    ${param_name}    ${value}    Verify Add_New_Parameter_Box NONVisibility

    
Step_06_run
    Click Element    ${HISTORY_TAB}
    @{rows}=    Create List    ${row_number_1}    ${row_number_2}
    Set Suite Variable    @{rows}    
    : FOR    ${row}    IN    @{rows}
    \    Verify History Table Row Content    ${row}    ${Put_Method_NAME}    ${Success_STATUS}
    \    Verify Sent Data Elements Presence In History Table Row    ${row}

    @{row_1_data}=    Create List    ${Param_Name_1}    ${EMPTY}    ${EMPTY}    ${row_number_3}    ${Param_Value_1}    ${Topology_Id_0}    ${Node_Id_0}    ${Link_Id_0}      
    Set Suite Variable    @{row_1_data}             
    @{row_2_data}=    Create List    ${Param_Name_1}    ${EMPTY}    ${Param_Name_3}    ${row_number_4}    ${Param_Value_3}    ${EMPTY}    ${EMPTY}    ${Link_Id_0}    
    Set Suite Variable    @{row_2_data}        
    ${dict}=    Create Dictionary    ${row_number_1}=@{row_1_data}    ${row_number_2}=@{row_2_data}
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
    \    ${param_value}    Get From List    ${values}    ${index}
    \    Set Suite Variable    ${param_value_index}    ${index}
    \    ${index}    Evaluate    ${index}+1
    \    ${topo_id}    Get From List    ${values}    ${index}
    \    Set Suite Variable    ${topo_id_index}    ${index}
    \    ${index}    Evaluate    ${index}+1
    \    ${node_id}    Get From List    ${values}    ${index}
    \    Set Suite Variable    ${node_id_index}    ${index}
    \    ${index}    Evaluate    ${index}+1
    \    ${link_id}    Get From List    ${values}    ${index}
    \    Set Suite Variable    ${link_id_index}    ${index}
    \    Insert Parameters To History Sent Data Path Wrapper    ${row}    ${topo_param}    ${node_param}    ${link_param}
    \    Save History Sent Box Parametrized Data    ${row}
    \    Wait Until Page Contains Element    ${Parametrized_data_was_saved_ALERT}
    \    Close Alert Panel
    \    Open History Table Sent Data Box    ${param_row}
    \    ${param_key_1}    Return Parameter Key    ${topo_param}
    \    Run Keyword If    "${param_key_1}"!="${EMPTY}"    Set Suite Variable    ${param_key_1}
    \    ${param_key_2}    Return Parameter Key    ${node_param}
    \    Run Keyword If    "${param_key_2}"!="${EMPTY}"    Set Suite Variable    ${param_key_2}
    \    ${param_key_3}    Return Parameter Key    ${link_param}
    \    Run Keyword If    "${param_key_3}"!="${EMPTY}"    Set Suite Variable    ${param_key_3}
    \    Run Keyword If    "${row}"=="1"    Verify History Sent Box Data Presence In Code Mirror    ${param_row}    ${param_key_1}
    \    Run Keyword If    "${row}"=="2"    Verify History Sent Box Data Presence In Code Mirror    ${param_row}    ${param_key_3}
    \    Close History Sent Data Box    ${param_row}        
    

Step_07_run
    : FOR    ${row}    IN    @{rows}
    \    ${values}=    Get From Dictionary    ${dict}    ${row}
    \    ${param_row}=    Get From List    ${values}    ${param_row_index}
    \    ${param_value}=    Get From List    ${values}    ${param_value_index}
    \    ${topo_id}    Get From List    ${values}    ${topo_id_index}
    \    ${node_id}    Get From List    ${values}    ${node_id_index}
    \    ${link_id}    Get From List    ${values}    ${link_id_index}
    \    ${param_value}    Get From List    ${values}    ${param_value_index}
    \    Fill History Table Row Request To Form    ${param_row}
    \    Run Keyword If    "${row}"=="1"    Verify Topology And Node And Link Id Presence In Form    ${param_value}    ${node_id}    ${link_id}    
    \    Run Keyword If    "${row}"=="2"    Verify Topology And Node And Link Id Presence In Form    ${EMPTY}    ${EMPTY}    ${param_value}
    
    If History Table Contains Data Then Clear History Data


Step_08_run
    Close DLUX