*** Settings ***
Documentation     Verification that it is impossible to edit History tab sent data
...               with nonexisting parameters.
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
    [Documentation]    Navigate to Parameters tab. Add 1 parameter. Param1: name = p1.
    Step_04_run
    
Step_05
    [Documentation]    Navigate to History tab. If the page contains any request 
    ...    in history list, click Clear history data. Execute PUT operation with valid data.
    ...    Click Sent data button 1st row. Edit sent data - insert existing 
    ...    parameter1 key to topology id input in path wrapper.
    ...    Topology id value: t0, Param1 key = <<p1>>. Click Save param data.
    ...    Result
    ...    The page should contain: row2 - Put method, success sent data, url 
    ...    with <<p1>> instead "t0".
    Step_05_run

Step_06
    [Documentation]    Click Sent data button 1st row. Edit sent data - insert 
    ...    nonexisting parameter2 key to topology id input in path wrapper.
    ...    Click Save param data. Param key = <<p2>>
    ...    Result
    ...    The page should contain: - topology id path wrapper input.
    ...    Code mirror code should contain param2 key. Page should contain Sent 
    ...    data Box and "Parameter does NOT exist"alert.
    Step_06_run

Step_07
    [Documentation]     Navigate to Parameters tab. Add 1 parameter.
    Step_07_run

Step_08
    [Documentation]     Navigate to History tab. Insert newly added parameter2 key
    ...    to topology id input in path wrapper. Click Save param data. Param2 key = <<p2>>
    ...    Result
    ...    The page should contain: row3 - Put method, success sent data, url 
    ...    with <<p3>> instead "t0".   
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
    Click Element    ${PARAMETERS_TAB}
    Run Keyword    Add New Parameter    ${Param_Name_1}    ${Param_Value_1}    Verify Add_New_Parameter_Box NONVisibility
  

Step_05_run
    Click Element    ${HISTORY_TAB}
    If History Table Contains Data Then Clear History Data
    
    Click Element    ${Testing_Root_API_Topology_List_Plus_BUTTON}
    PUT ID    ${Testing_Root_API_Topology_List_Topology_Id_INPUT}    ${Topology_Id_0}    ${Topology_ID}    ${Testing_Root_API_Topology_List_NAME}
    Verify History Table Row Content    ${row_number_1}    ${Put_Method_NAME}    ${Success_STATUS}
    Verify Sent Data Elements Presence In History Table Row   ${row_number_1}
    
    Insert Parameters To History Sent Data Path Wrapper    ${row_number_1}    ${Param_Name_1}    ${EMPTY}    ${EMPTY}
    Save History Sent Box Parametrized Data    ${row_number_1}
    Wait Until Page Contains Element    ${Parametrized_data_was_saved_ALERT}
    Close Alert Panel

    Verify History Table Row Content    ${row_number_2}    ${Put_Method_NAME}    ${Success_STATUS}
    Verify Sent Data Elements Presence In History Table Row    ${row_number_2}
    
    ${param_key_1}=    Return Parameter Key    ${Param_Name_1}
    Open History Table Sent Data Box    ${row_number_2}
    Verify History Sent Box Data Presence In Code Mirror    ${row_number_2}    ${param_key_1}
    Close History Sent Data Box    ${row_number_2}
    ${url_1}=    Return History Table Row Url    ${row_number_1}
    ${url_1_edited}    Return Edited String    ${url_1}    ${Topology_Id_0}    ${param_key_1}
    ${url_2}=    Return History Table Row Url    ${row_number_2}
    Should Be Equal As Strings    ${url_1_edited}    ${url_2}    

   
Step_06_run
    Insert Parameters To History Sent Data Path Wrapper    ${row_number_1}    ${Param_Name_2}    ${EMPTY}    ${EMPTY}
    Save History Sent Box Parametrized Data    ${row_number_1}
    Wait Until Page Contains Element    ${Parameter_does_NOT_exist_ALERT}
    Verify History Sent Data Box Elements    ${row_number_1}
    Close Alert Panel


Step_07_run
    Click Element    ${PARAMETERS_TAB}
    Run Keyword    Add New Parameter    ${Param_Name_2}    ${Param_Value_2}    Verify Add_New_Parameter_Box NONVisibility
  

Step_08_run
    Click Element    ${HISTORY_TAB}
    Save History Sent Box Parametrized Data    ${row_number_1}
    Wait Until Page Contains Element    ${Parametrized_data_was_saved_ALERT}
    Close Alert Panel

    Verify History Table Row Content    ${row_number_3}    ${Put_Method_NAME}    ${Success_STATUS}
    Verify Sent Data Elements Presence In History Table Row    ${row_number_3}
    
    ${param_key_2}=    Return Parameter Key    ${Param_Name_2}
    Open History Table Sent Data Box    ${row_number_3}
    Verify History Sent Box Data Presence In Code Mirror    ${row_number_3}    ${param_key_2}
    Close History Sent Data Box    ${row_number_3}
    ${url_1}=    Return History Table Row Url    ${row_number_1}
    ${url_1_edited}    Return Edited String    ${url_1}    ${Topology_Id_0}    ${param_key_2}
    ${url_2}=    Return History Table Row Url    ${row_number_3}
    Should Be Equal As Strings    ${url_1_edited}    ${url_2}    

    If History Table Contains Data Then Clear History Data


Step_09_run
    Close DLUX
