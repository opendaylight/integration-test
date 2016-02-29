*** Settings ***
Documentation     Verification that it is possible to run parametrized group request from collection tab.
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
    ...    Param2: name = p2,value = v2; Param3: name = p3,value = v3.
    Step_06_run

Step_07
    [Documentation]    Navigate to Collection tab. Click Sent data button G1 1st row.
    ...    Edit sent data - insert parameter1 key to topology id input in path wrapper.
    ...    Param1 key = <<p1>>. Click Save parametrized data. Click Run request button.
    ...    Click Sent data button G1 2nd row. Edit sent data - insert parameter2 key 
    ...    to node id input in path wrapper. Param2 key = <<p2>>. Click Save parametrized data.
    ...    Click Run request button.
    ...    Click Sent data button G2 1st row. Edit sent data - insert parameter3 key 
    ...    to link id input in path wrapper. Param3 key = <<p3>>. Click Save parametrized data.
    ...    Click Run request button.
    ...    Open Sent data box in G1 row3, G1 row4, G2 row2.
    ...    Result
    ...    The page should contain: -4th row: - name N1, - success sent data elements,
    ...    -5th row: - name N2, - success sent data elements, -6th row: - name N3, - success sent data element,
    ...    Param1 key = <<p1>> in G1 row 3  code mirror, Param2 key = <<p2>> in G1 row 4  code mirror,
    ...    Param3 key = <<p3>> in G2 row 2  code mirror.
    Step_07_run

Step_08
    [Documentation]    Get Urls from parametrized and saved requests - rows 4, 5, 6. 
    ...    Clear collection data. Click History tab.
    ...    Result
    ...    The page should contain: The page shoud contain: - no collection record.
    ...    The history tab should contain:
    ...    - 4th row: - name N1, - success sent data elements, url same as one in G1 row 3 
    ...    the collection table but parameter keys replaced with parameters values,
    ...    - 5th row: - name N2, - success sent data elements, url same as one in G1 row 4
    ...    the collection table but parameter keys replaced with parameters value,
    ...    - 6th row: - name N1, - success sent data elements, url same as one in G2 row 2
    ...    the collection table but parameter keys replaced with parameters value. 
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
    Click Element    ${HISTORY_TAB}
    Verify History Table Row Content    ${row_number_1}     ${Put_Method_NAME}    ${Success_STATUS}
    Verify Sent Data Elements Presence In History Table Row    ${row_number_1}
    Add Request To Collection    ${row_number_1}    ${Name_1}    ${Select_Option}    ${Group_1}
    Click Element    ${Add_To_Collection_Box_Add_BUTTON}
    
    Verify History Table Row Content    ${row_number_2}     ${Put_Method_NAME}    ${Success_STATUS}
    Verify Sent Data Elements Presence In History Table Row    ${row_number_2}
    Add Request To Collection    ${row_number_2}    ${Name_2}    ${Group_1}    ${EMPTY}
    Click Element    ${Add_To_Collection_Box_Add_BUTTON}
    
    Verify History Table Row Content    ${row_number_3}     ${Put_Method_NAME}    ${Success_STATUS}
    Verify Sent Data Elements Presence In History Table Row    ${row_number_3}
    Add Request To Collection    ${row_number_3}    ${Name_3}    ${Select_Option}    ${Group_2}
    Click Element    ${Add_To_Collection_Box_Add_BUTTON}

    If History Table Contains Data Then Clear History Data


Step_06_run
    Click Element    ${PARAMETERS_TAB}
    Wait Until Page Contains Element    ${Add_New_Parameter_BUTTON}
    ${parameters}=    Create Dictionary    ${Param_Name_1}=${Param_Value_1}    ${Param_Name_2}=${Param_Value_2}    ${Param_Name_3}=${Param_Value_3}
    @{keys}=    Get Dictionary Keys    ${parameters}
    : FOR    ${key}    IN    @{keys}
    \    ${value}=    Get From Dictionary    ${parameters}    ${key}
    \    Run Keyword    Add New Parameter    ${key}    ${value}    Verify Add_New_Parameter_Box NONVisibility

    Click Element    ${COLLECTION_TAB}    
        
    
Step_07_run
    Click Element    ${COLLECTION_TAB}
    Expand Collection Table Group Expander    ${group_number_1}    ${Group_1}    ${row_number_1}    
    Expand Collection Table Group Expander    ${group_number_2}    ${Group_2}    ${row_number_1}    
    @{groups}=    Create List    ${group_number_1}    ${group_number_1}    ${group_number_2}
    @{rows}=    Create List    ${row_number_1}     ${row_number_2}    ${row_number_1}    
    @{names}=    Create List    ${Name_1}    ${Name_2}    ${Name_3}
    ${index}    Evaluate    0
    : FOR    ${group}    IN    @{groups}
    \    ${row}=     Get From List    ${rows}    ${index}               
    \    ${name}=    Get From List    ${names}    ${index}                
    \    Verify Collection Table Group Row Content    ${group}    ${row}    ${Put_Method_NAME}    ${name}    ${Success_STATUS}
    \    Verify Sent Data Elements Presence In Collection Table Group Row    ${group}    ${row}             
    \    ${index}    Evaluate    ${index}+1
    
    Insert Parameters To Group Row Sent Data Path Wrapper    ${group_number_1}    ${row_number_1}    ${Param_Name_1}    ${EMPTY}    ${EMPTY}
    Save Parametrized Data Group Row Sent Data Box    ${group_number_1}    ${row_number_1}
    
    Insert Parameters To Group Row Sent Data Path Wrapper    ${group_number_1}    ${row_number_2}    ${EMPTY}    ${Param_Name_2}    ${EMPTY}
    Save Parametrized Data Group Row Sent Data Box    ${group_number_1}    ${row_number_2}

    Insert Parameters To Group Row Sent Data Path Wrapper    ${group_number_2}    ${row_number_1}    ${EMPTY}    ${EMPTY}    ${Param_Name_3}    
    Save Parametrized Data Group Row Sent Data Box    ${group_number_2}    ${row_number_1}

    ${param_key_1}    Return Parameter Key    ${Param_Name_1}
    Set Suite Variable    ${param_key_1}    
    ${param_key_2}    Return Parameter Key    ${Param_Name_2}
    Set Suite Variable    ${param_key_2}
    ${param_key_3}    Return Parameter Key    ${Param_Name_3}
    Set Suite Variable    ${param_key_3}
    @{rows_2}=    Create List    ${row_number_3}     ${row_number_4}    ${row_number_2}
    @{param_keys}=    Create List    ${param_key_1}     ${param_key_2}    ${param_key_3}
    ${index}    Evaluate    0
    : FOR    ${group}    IN    @{groups}
    \    ${row}=     Get From List    ${rows_2}    ${index}               
    \    ${name}=    Get From List    ${names}    ${index}                
    \    Verify Collection Table Group Row Content    ${group}    ${row}    ${Put_Method_NAME}    ${name}    ${Success_STATUS}
    \    Verify Sent Data Elements Presence In Collection Table Group Row    ${group}    ${row}
    \    Open Collection Table Group Sent Data Box    ${group}    ${row}
    \    ${param_key}=    Get From List    ${param_keys}    ${index}
    \    Verify Collection Group Sent Box Data Presence In Code Mirror    ${group}    ${row}    ${param_key}
    \    Close Collection Group Sent Box    ${group}    ${row}
    \    Run Request Group Row Sent Data Box    ${group}    ${row}        
    \    ${index}    Evaluate    ${index}+1

Step_08_run
    ${url_topo}=    Return Collection Table Group Row Url    ${group_number_1}    ${row_number_3}    
    ${url_topo_edited}=   Return Edited String    ${url_topo}    ${param_key_1}    ${Param_Value_1}
    
    ${url_node}=    Return Collection Table Group Row Url    ${group_number_1}    ${row_number_4}    
    ${url_node_edited}=   Return Edited String    ${url_node}    ${param_key_2}    ${Param_Value_2}
    
    ${url_link}=    Return Collection Table Group Row Url    ${group_number_2}    ${row_number_2}    
    ${url_link_edited}=   Return Edited String    ${url_link}    ${param_key_3}    ${Param_Value_3}
    
    If Collection Table Contains Data Then Clear Collection Data
    
    Click Element    ${HISTORY_TAB}
    
    Verify History Table Row Content    ${row_number_1}     ${Put_Method_NAME}    ${Success_STATUS}
    Verify Sent Data Elements Presence In History Table Row    ${row_number_1}
    Compare History Table Row Url And Variable    ${row_number_1}    ${url_topo_edited}
    
    Verify History Table Row Content    ${row_number_2}     ${Put_Method_NAME}    ${Success_STATUS}
    Verify Sent Data Elements Presence In History Table Row    ${row_number_2}
    Compare History Table Row Url And Variable    ${row_number_2}    ${url_node_edited}
    
    Verify History Table Row Content    ${row_number_3}     ${Put_Method_NAME}    ${Success_STATUS}
    Verify Sent Data Elements Presence In History Table Row    ${row_number_3}
    Compare History Table Row Url And Variable    ${row_number_3}    ${url_link_edited}


Step_09_run
    Close DLUX
