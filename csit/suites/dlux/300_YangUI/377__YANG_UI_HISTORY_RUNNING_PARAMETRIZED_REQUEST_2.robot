*** Settings ***
Documentation     Verification that it is possible to run edited request from history tab,
...               edited with strings that are not parameters and do not have parameters form, i.e. <<parameter_name>>.
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
    [Documentation]    Navigate to Parameters tab. If parameters contain any data, clear parameters table.
    Step_05_run

Step_06
    [Documentation]    Navigate to History tab. Click Sent data button 1st row.
    ...    Edit sent data - insert "str1" to topology id input in path wrapper.
    ...    Click Save parametrized data. Click Run request button.
    ...    Click Sent data button 2nd row. Edit sent data - insert "str1"  to topology id input
    ...    and insert "str2" to node id input in path wrapper.
    ...    Click Save parametrized data. Click Run request button.
    ...    Click Sent data button 3rd row. Edit sent data - insert "str1" to topology id input
    ...    and insert "str3" to link id input in path wrapper.
    ...    Click Save parametrized data. Click Run request button.
    ...    Open Sent data box in rows 4, 5, 6.
    ...    Result
    ...    The page should contain: -4th row - success sent data elements, "str1" in code mirror,
    ...    -5th row: - success sent data elements, "str2" in code mirror,
    ...    -6th row: - success sent data elements, "str3" in code mirror.
    Step_06_run

Step_07
    [Documentation]    Get Urls from parametrized and saved requests - rows 4, 5, 6. 
    ...    Get Urls from run parametrized requests in rows 7, 8, 9.
    ...    Result
    ...    The page should contain: 
    ...    - 7th row: - success sent data elements, url same as one in 
    ...    relevant saved parametrized request.
    ...    - 8th row: - success sent data elements, url same as one in
    ...    relevant saved parametrized request.
    ...    - 9th row: - success sent data elements, url same as one in
    ...    relevant saved parametrized request.
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
    If Parameters Table Contains Data Then Clear Parameters Data

    
Step_06_run
    Click Element    ${HISTORY_TAB}
    @{rows}=    Create List    ${row_number_1}    ${row_number_2}    ${row_number_3}
    Set Suite Variable    @{rows}    
    : FOR    ${row}    IN    @{rows}
    \    Verify History Table Row Content    ${row}    ${Put_Method_NAME}    ${Success_STATUS}
    \    Verify Sent Data Elements Presence In History Table Row    ${row}

    @{row_1_data}=    Create List    str1    ${EMPTY}    ${EMPTY}    ${row_number_4}    ${row_number_5}
    Set Suite Variable    @{row_1_data}             
    @{row_2_data}=    Create List    str1    str2    ${EMPTY}    ${row_number_6}    ${row_number_7}      
    Set Suite Variable    @{row_2_data}        
    @{row_3_data}=    Create List    str1    ${EMPTY}    str3    ${row_number_8}    ${row_number_9}   
    Set Suite Variable    @{row_3_data}
    ${dict}=    Create Dictionary    ${row_number_1}=@{row_1_data}    ${row_number_2}=@{row_2_data}    ${row_number_3}=@{row_3_data}
    Set Suite Variable    ${dict}
    : FOR    ${row}    IN    @{rows}
    \    ${index}    Evaluate    0
    \    ${values}=    Get From Dictionary    ${dict}    ${row}
    \    ${topo_string}=    Get From List    ${values}    ${index}
    \    Set Suite Variable    ${topo_string}
    \    ${index}    Evaluate    ${index}+1
    \    ${node_string}=    Get From List    ${values}    ${index}
    \    Set Suite Variable    ${node_string}    
    \    ${index}    Evaluate    ${index}+1
    \    ${link_string}=    Get From List    ${values}    ${index}
    \    Set Suite Variable    ${link_string}
    \    ${index}    Evaluate    ${index}+1
    \    ${edited_data_row}=    Get From List    ${values}    ${index}
    \    Set Suite Variable    ${edited_data_row_index}    ${index}
    \    ${index}    Evaluate    ${index}+1
    \    ${run_data_row}=    Get From List    ${values}    ${index}
    \    Set Suite Variable    ${run_data_row_index}    ${index}
    \    ${index}    Evaluate    ${index}+1
    \    Insert String To History Sent Data Path Wrapper    ${row}    ${topo_string}    ${node_string}    ${link_string}
    \    Save History Sent Box Parametrized Data    ${row}
    \    Wait Until Page Contains Element    ${Parametrized_data_was_saved_ALERT}
    \    Close Alert Panel
    \    Click History Table Execute Request Button In Row    ${edited_data_row}    
    \    Wait Until Page Contains Element    ${Request_sent_successfully_ALERT}
    \    Close Alert Panel
    \    Open History Table Sent Data Box    ${edited_data_row}
    \    Run Keyword If    "${row}"=="1"    Verify History Sent Box Data Presence In Code Mirror    ${edited_data_row}    ${topo_string}
    \    Run Keyword If    "${row}"=="2"    Verify History Sent Box Data Presence In Code Mirror    ${edited_data_row}    ${node_string}    
    \    Run Keyword If    "${row}"=="3"    Verify History Sent Box Data Presence In Code Mirror    ${edited_data_row}    ${link_string}
    

Step_07_run
    : FOR    ${row}    IN    @{rows}
    \    ${values}=    Get From Dictionary    ${dict}    ${row}
    \    ${edited_data_row}=    Get From List    ${values}    ${edited_data_row_index}
    \    ${run_data_row}=    Get From List    ${values}    ${run_data_row_index}
    \    Verify History Table Row Content    ${run_data_row}     ${Put_Method_NAME}    ${Success_STATUS}
    \    Verify Sent Data Elements Presence In History Table Row    ${run_data_row}
    \    Run Keyword If    "${row}"=="1"    Verify History Sent Box Data Presence In Code Mirror    ${run_data_row}    ${topo_string}
    \    Run Keyword If    "${row}"=="2"    Verify History Sent Box Data Presence In Code Mirror    ${run_data_row}    ${node_string}   
    \    Run Keyword If    "${row}"=="3"    Verify History Sent Box Data Presence In Code Mirror    ${run_data_row}    ${link_string}
    \    ${url_edited_data_row}=    Return History Table Row Url    ${edited_data_row}
    \    Compare History Table Row Url And Variable    ${run_data_row}    ${url_edited_data_row}

    If History Table Contains Data Then Clear History Data

Step_08_run
    Close DLUX
