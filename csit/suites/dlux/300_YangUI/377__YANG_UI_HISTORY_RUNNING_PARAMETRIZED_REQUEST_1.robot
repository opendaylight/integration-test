*** Settings ***
Documentation     Verification that it is possible to run parametrized request from history tab.
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
    ...    Param2: name = p2,value = v2; Param3: name = p3,value = v3.
    Step_05_run

Step_06
    [Documentation]    Navigate to History tab. Click Sent data button 1st row.
    ...    Edit sent data - insert param1 key to topology id input in path wrapper.
    ...    Click Save parametrized data. Click Run request button.
    ...    Click Sent data button 2nd row. Edit sent data - insert parameter1 key to topology id input
    ...    and insert parameter2 key to node id input in path wrapper.
    ...    Click Save parametrized data. Click Run request button.
    ...    Click Sent data button 3rd row. Edit sent data - insert parameter1 key to topology id input
    ...    and insert parameter3 key to link id input in path wrapper.
    ...    Click Save parametrized data. Click Run request button.
    ...    Param1 key = <<p1>>, Param2 key = <<p2>>, Param3 key = <<p3>>
    ...    Open Sent data box in rows 4, 5, 6.
    ...    Result
    ...    The page should contain: -4th row - success sent data elements, Param1 key = <<p1>> in code mirror,
    ...    -5th row: - success sent data elements, Param2 key = <<p2>> in code mirror,
    ...    -6th row: - success sent data elements, Param3 key = <<p3>> in code mirror.
    Step_06_run

Step_07
    [Documentation]    Get Urls from parametrized and saved requests - rows 4, 5, 6. 
    ...    Get Urls from run parametrized requests in rows 7, 8, 9.
    ...    Result
    ...    The page should contain: 
    ...    - 7th row: - success sent data elements, Param1 value v1 in code mirror, url same as one in 
    ...    relevant saved parametrized request but parameter keys replaced with parameters values,
    ...    - 8th row: - success sent data elements, Param2 value v2 in code mirror, url same as one in
    ...    relevant saved parametrized request but parameter keys replaced with parameters values,
    ...    - 9th row: - success sent data elements, Param3 value v3 in code mirror, url same as one in
    ...    relevant saved parametrized request but parameter keys replaced with parameters values. 
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
    @{param_names}=    Create List    ${Param_Name_1}    ${Param_Name_2}    ${Param_Name_3}
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

    @{row_1_data}=    Create List    ${Param_Name_1}    ${EMPTY}    ${EMPTY}    ${row_number_4}    ${row_number_5}    ${Param_Value_1}    
    Set Suite Variable    @{row_1_data}             
    @{row_2_data}=    Create List    ${Param_Name_1}    ${Param_Name_2}    ${EMPTY}    ${row_number_6}    ${row_number_7}    ${Param_Value_2}         
    Set Suite Variable    @{row_2_data}        
    @{row_3_data}=    Create List    ${Param_Name_1}    ${EMPTY}    ${Param_Name_3}    ${row_number_8}    ${row_number_9}    ${Param_Value_3}       
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
    \    ${run_data_row}=    Get From List    ${values}    ${index}
    \    Set Suite Variable    ${run_data_row_index}    ${index}
    \    ${index}    Evaluate    ${index}+1
    \    ${param_value}    Get From List    ${values}    ${index}
    \    Set Suite Variable    ${param_value_index}    ${index}
    \    Insert Parameters To History Sent Data Path Wrapper    ${row}    ${topo_param}    ${node_param}    ${link_param}
    \    Save History Sent Box Parametrized Data    ${row}
    \    Wait Until Page Contains Element    ${Parametrized_data_was_saved_ALERT}
    \    Close Alert Panel
    \    Click History Table Execute Request Button In Row    ${param_row}    
    \    Wait Until Page Contains Element    ${Request_sent_successfully_ALERT}
    \    Close Alert Panel
    \    Open History Table Sent Data Box    ${param_row}
    \    ${param_key_1}    Return Parameter Key    ${topo_param}
    \    Run Keyword If    "${param_key_1}"!="${EMPTY}"    Set Suite Variable    ${param_key_1}
    \    ${param_key_2}    Return Parameter Key    ${node_param}
    \    Run Keyword If    "${param_key_2}"!="${EMPTY}"    Set Suite Variable    ${param_key_2}
    \    ${param_key_3}    Return Parameter Key    ${link_param}
    \    Run Keyword If    "${param_key_3}"!="${EMPTY}"    Set Suite Variable    ${param_key_3}
    \    Run Keyword If    "${row}"=="1"    Verify History Sent Box Data Presence In Code Mirror    ${param_row}    ${param_key_1}
    \    Run Keyword If    "${row}"=="2"    Verify History Sent Box Data Presence In Code Mirror    ${param_row}    ${param_key_2}    
    \    Run Keyword If    "${row}"=="3"    Verify History Sent Box Data Presence In Code Mirror    ${param_row}    ${param_key_3}
    

Step_07_run
    ${url_topo}=    Return History Table Row Url    ${row_number_4}    
    ${url_topo_edited}=   Return Edited String    ${url_topo}    ${param_key_1}    ${Param_Value_1}
    
    ${url_node}=    Return History Table Row Url    ${row_number_6}    
    ${url_node_edited}=   Return Edited String    ${url_node}    ${param_key_2}    ${Param_Value_2}
    
    ${url_topo_and_node}=    Return Edited String    ${url_node_edited}    ${param_key_1}    ${Param_Value_1}                
    
    ${url_link}=    Return History Table Row Url    ${row_number_8}    
    ${url_link_edited}=   Return Edited String    ${url_link}    ${param_key_3}    ${Param_Value_3}
    
    ${url_topo_and_link}=    Return Edited String    ${url_link_edited}    ${param_key_1}    ${Param_Value_1}
    
    : FOR    ${row}    IN    @{rows}
    \    ${values}=    Get From Dictionary    ${dict}    ${row}
    \    ${run_data_row}=    Get From List    ${values}    ${run_data_row_index}
    \    ${param_value}=    Get From List    ${values}    ${param_value_index}
    \    Verify History Table Row Content    ${run_data_row}     ${Put_Method_NAME}    ${Success_STATUS}
    \    Verify Sent Data Elements Presence In History Table Row    ${run_data_row}
    \    Open History Table Sent Data Box    ${run_data_row}  
    \    Verify History Sent Box Data Presence In Code Mirror    ${run_data_row}    ${param_value}

    Compare History Table Row Url And Variable    ${row_number_5}    ${url_topo_edited}
    
    Compare History Table Row Url And Variable    ${row_number_7}    ${url_topo_and_node}

    Compare History Table Row Url And Variable    ${row_number_9}    ${url_topo_and_link}

    If History Table Contains Data Then Clear History Data
Step_08_run
    Close DLUX
