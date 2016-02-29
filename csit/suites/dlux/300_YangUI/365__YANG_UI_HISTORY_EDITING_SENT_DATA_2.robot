*** Settings ***
Documentation     Verification that it is possible to edit History tab sent data with parameters.
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
    ...    Click Sent data button. Edit sent data - insert parameter1 key
    ...    to topology id input in path wrapper. Param1 key = <<p1>> Click Close button to close Sent data box.
    ...    Result
    ...    The page should contain: - topology id path wrapper input.
    ...    Code mirror code should contain param1 key.
    Step_05_run

Step_06
    [Documentation]    Navigate to API tab. Load "node list" button in customContainer Area.
    ...    Click "node list" icon Plus to add node id. Execute Put operation with valid data.
    ...    Topology id value: t0, Node id value: t0n0
    ...    Click History tab. Click Sent data button. Edit sent data - insert parameter2 key
    ...    to node id input in path wrapper. Param2 key = <<p2>> Click Close button to close Sent data box.
    ...    Result
    ...    The page should contain: - node id path wrapper input.
    ...    Code mirror code should contain param2 key. The page should not contain Sent data box.   
    Step_06_run

Step_07
    [Documentation]    Navigate to API tab. Load "link list" button in customContainer Area.
    ...    Click "link list" icon Plus to add link id. Click source expander to input
    ...    source-node and destination arrow expander to insert destination node.
    ...    Execute Put operation with valid data. Click History tab. Topology id value: t0,
    ...    Link id value: t0l0, Source-node: s0, Dest-node: d0, Name value: N3
    ...    Click Sent data button. Edit sent data - insert parameter3 key
    ...    to link id input in path wrapper. Param3 key = <<p3>> Click Close button to close Sent data box.
    ...    Result
    ...    The page should contain: - link id path wrapper input.
    ...    Code mirror code should contain param3 key. The page should not contain Sent data box.
    ...    Clear collection table data.
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


Step_04_run
    Click Element    ${PARAMETERS_TAB}
    Wait Until Page Contains Element    ${Add_New_Parameter_BUTTON}
    ${parameter_data}=    Create Dictionary    ${Param_Name_1}=${Param_Value_1}    ${Param_Name_2}=${Param_Value_2}    ${Param_Name_3}=${Param_Value_3}    
    @{param_names}=    Create List    ${Param_Name_1}    ${Param_Name_2}    ${Param_Name_3}
    : FOR    ${param_name}    IN    @{param_names}
    \    ${value}=    Get From Dictionary    ${parameter_data}    ${param_name}
    \    Run Keyword    Add New Parameter    ${param_name}    ${value}    Verify Add_New_Parameter_Box NONVisibility


Step_05_run
    ${row_number}=    Set Variable    ${row_number_1}
    Click Element    ${HISTORY_TAB}
    If History Table Contains Data Then Clear History Data
    Click Element    ${Testing_Root_API_Topology_List_Plus_BUTTON}
    PUT ID    ${Testing_Root_API_Topology_List_Topology_Id_INPUT}    ${Topology_Id_0}    ${Topology_ID}    ${Testing_Root_API_Topology_List_NAME}
    
    Verify History Table Row Content    ${row_number}    ${Put_Method_NAME}    ${Success_STATUS}    
    Verify Sent Data Elements Presence In History Table Row    ${row_number}

    Insert Parameters To History Sent Data Path Wrapper        ${row_number}    ${Param_Name_1}    ${EMPTY}    ${EMPTY}
    ${param_key_1}=    Return Parameter Key    ${Param_Name_1}    
    Verify History Sent Box Data Presence In Code Mirror    ${row_number}     ${param_key_1}
    Close History Sent Data Box    ${row_number}        
    
    
Step_06_run
    ${row_number}=    Set Variable    ${row_number_2}
    Click Element    ${API_TAB}
    Wait Until Page Contains Element    ${Testing_Root_API_Topology_Topology_Id_Plus_EXPANDER}
    Load Node List Button In CustomContainer Area
    Click Element    ${Testing_Root_API_Node_List_Plus_BUTTON}
    Wait Until Page Contains Element    ${Testing_Root_API_Node_List_Node_Id_INPUT}    
    Insert Text To Input Field    ${Topology_Id_Path_Wrapper_INPUT}    ${Topology_Id_0}    
    Insert Text To Input Field    ${Node_Id_Path_Wrapper_INPUT}    ${Node_Id_0}
    Execute Chosen Operation    ${Put_OPERATION}    ${Request_sent_successfully_ALERT}
    
    Click Element    ${HISTORY_TAB}
    Verify History Table Row Content    ${row_number}    ${Put_Method_NAME}    ${Success_STATUS}
    Verify Sent Data Elements Presence In History Table Row    ${row_number}
    
    Insert Parameters To History Sent Data Path Wrapper        ${row_number}    ${EMPTY}    ${Param_Name_2}    ${EMPTY}
    ${param_key_2}=    Return Parameter Key    ${Param_Name_2}    
    Verify History Sent Box Data Presence In Code Mirror    ${row_number}     ${param_key_2}
    Close History Sent Data Box    ${row_number}        



Step_07_run
    ${row_number}=    Set Variable    ${row_number_3}
    Click Element    ${API_TAB}
    Wait Until Page Contains Element    ${Testing_Root_API_Node_Node_Id_Plus_EXPANDER}
    Load Link List Button In CustomContainer Area
    Click Element    ${Testing_Root_API_Link_List_Plus_BUTTON}
    Wait Until Page Contains Element    ${Testing_Root_API_Link_List_Link_Id_INPUT}        
    Insert Text To Input Field    ${Topology_Id_Path_Wrapper_INPUT}    ${Topology_Id_0}    
    Insert Text To Input Field    ${Link_Id_Path_Wrapper_INPUT}    ${Link_Id_0}
    
    Click Element    ${Testing_Root_API_Source_Arrow_EXPANDER}
    Wait Until Page Contains Element    ${Testing_Root_API_Source_Source_Node_INPUT}
    Input Text    ${Testing_Root_API_Source_Source_Node_INPUT}    ${Source-node}
   
    Click Element    ${Testing_Root_API_Destination_Arrow_EXPANDER}
    Wait Until Page Contains Element    ${Testing_Root_API_Destination_Destination_Node_INPUT}
    Input Text    ${Testing_Root_API_Destination_Destination_Node_INPUT}   ${Destination-node}
    Execute Chosen Operation    ${Put_OPERATION}    ${Request_sent_successfully_ALERT}
    
    Click Element    ${HISTORY_TAB}
    Verify History Table Row Content    ${row_number}    ${Put_Method_NAME}    ${Success_STATUS}
    Verify Sent Data Elements Presence In History Table Row    ${row_number}
    
    Insert Parameters To History Sent Data Path Wrapper        ${row_number}    ${EMPTY}    ${EMPTY}    ${Param_Name_3}
    ${param_key_3}=    Return Parameter Key    ${Param_Name_3}    
    Verify History Sent Box Data Presence In Code Mirror    ${row_number}     ${param_key_3}
    Close History Sent Data Box And Clear History Data    ${row_number}       

Step_08_run
    Close DLUX
