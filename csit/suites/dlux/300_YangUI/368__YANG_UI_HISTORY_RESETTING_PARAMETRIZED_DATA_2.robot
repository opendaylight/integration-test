*** Settings ***
Documentation     Verification that parametrized history sent data is reset only
...               in sent data box in which reset parametrized data button is hit.
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
    ...    Result
    ...    The page should contain: - Put method, - success sent data elements.
    Step_05_run

Step_06
    [Documentation]    Navigate to API tab. Load "node list" button in customContainer Area.
    ...    Click "node list" icon Plus to add node id. Execute Put operation with valid data.
    ...    Topology id value: t0, Node id value: t0n0
    ...    Click History tab. 
    ...    Result
    ...    The page should contain: - Put method, - success sent data elements.
    Step_06_run

Step_07
    [Documentation]    Click Sent data button in row 1. Edit sent data1 - insert 
    ...    parameter1 key (Param1 key = <<p1>>) to topology id input in path wrapper. 
    ...    Click Sent data button in row 2. Edit sent data2 - insert parameter2 key
    ...    (Param2 key = <<p2>>) to topology id input and parameter3 key (Param3 key = <<p3>>)
    ...    to node id input in path wrapper. Click Reset parametrized data button in row 1. 
    ...    Result
    ...    The page should contain: - t0 in code mirror in sent data box in row 1
    ...    - <<p3>> in code mirror in sent data bow in row 2
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
    

Step_07_run
    Insert Parameters To History Sent Data Path Wrapper        ${row_number_1}    ${Param_Name_1}    ${EMPTY}    ${EMPTY}
    ${param_key_1}=    Return Parameter Key    ${Param_Name_1}    
    Verify History Sent Box Data Presence In Code Mirror    ${row_number_1}     ${param_key_1}
    
    Insert Parameters To History Sent Data Path Wrapper        ${row_number_2}    ${Param_Name_2}    ${Param_Name_3}    ${EMPTY}
    ${param_key_3}=    Return Parameter Key    ${Param_Name_3}    
    Verify History Sent Box Data Presence In Code Mirror    ${row_number_2}     ${param_key_3}
    
    Reset History Sent Box Parametrized Data    ${row_number_1} 
    Verify History Sent Box Data NONPresence In Code Mirror    ${row_number_1}    ${param_key_1}
    Verify History Sent Box Data Presence In Code Mirror    ${row_number_1}    ${Topology_Id_0}
    Verify History Sent Box Data Presence In Code Mirror    ${row_number_2}     ${param_key_3}
    
    
Step_08_run
    Close DLUX
