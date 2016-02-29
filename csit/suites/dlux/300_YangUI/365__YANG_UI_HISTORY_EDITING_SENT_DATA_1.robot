*** Settings ***
Documentation     Verification that History tab row contains box with 
...    tools that enable to modify sent data with parameters.
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
    [Documentation]    Click HISTORY tab. If the page contains any request in history list, 
    ...    click Clear history data. Execute PUT operation with valid data. Topology id value: t0
    ...    Click Sent data button.
    ...    Result
    ...    The page contains: - Sent data box, - api path wrapper, - topology id input
    ...    - copy to clipboard button, - reset parametrized data button, - save parametrized data.
    ...    Click Close button to close Sent data box.
    ...    Click Clear history data to delete history data.
    ...    Result
    ...    The page should not contain Sent data box. The page should not contain history table row.    
    Step_04_run

Step_05
    [Documentation]    Navigate to API tab. Load "node list" button in customContainer Area.
    ...    Click "node list" icon Plus to add node id. Execute Put operation with valid data.
    ...    Click History tab. Topology id value: t0. Node id value: t0n0.
    ...    Click Sent data button.
    ...    Result
    ...    The page contains: - Sent data box, - api path wrapper, - topology id input
    ...    - copy to clipboard button, - reset parametrized data button, - save parametrized data.
    ...    Click Close button to close Sent data box.
    ...    Click Clear history data to delete history data.
    ...    Result
    ...    The page should not contain Sent data box. The page should not contain history table row.    
    Step_05_run

Step_06
    [Documentation]    Navigate to API tab. Load "link list" button in customContainer Area.
    ...    Click "link list" icon Plus to add link id. Click source expander to input
    ...    source-node and destination arrow expander to insert destination node.
    ...    Execute Put operation with valid data. Click History tab. Topology id value: t0,
    ...    Link id value: t0l0, Source-node: s0, Dest-node: d0.
    ...    Click Sent data button.
    ...    Result
    ...    The page contains: - Sent data box, - api path wrapper, - topology id input
    ...    - copy to clipboard button, - reset parametrized data button, - save parametrized data.
    ...    Click Close button to close Sent data box.
    ...    Click Clear history data to delete history data.
    ...    Result
    ...    The page should not contain Sent data box. The page should not contain history table row.    
    Step_06_run

Step_07
    [Documentation]    Close Dlux.
    Step_07_run

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
    Click Element    ${HISTORY_TAB}
    If History Table Contains Data Then Clear History Data
    Click Element    ${Testing_Root_API_Topology_List_Plus_BUTTON}
    PUT ID    ${Testing_Root_API_Topology_List_Topology_Id_INPUT}    ${Topology_Id_0}    ${Topology_ID}    ${Testing_Root_API_Topology_List_NAME}
    Verify History Table Row Content    ${row_number_1}    ${Put_Method_NAME}    ${Success_STATUS}    
    Verify Sent Data Elements Presence In History Table Row    ${row_number_1}
    
    Verify History Sent Data Box Elements    ${row_number_1}
    Close History Sent Data Box And Clear History Data    ${row_number_1}    
    

Step_05_run
    Click Element    ${API_TAB}
    Wait Until Page Contains Element    ${Testing_Root_API_Topology_Topology_Id_Plus_EXPANDER}
    Load Node List Button In CustomContainer Area
    Click Element    ${Testing_Root_API_Node_List_Plus_BUTTON}
    Wait Until Page Contains Element    ${Testing_Root_API_Node_List_Node_Id_INPUT}    
    Insert Text To Input Field    ${Topology_Id_Path_Wrapper_INPUT}    ${Topology_Id_0}    
    Insert Text To Input Field    ${Node_Id_Path_Wrapper_INPUT}    ${Node_Id_0}
    Execute Chosen Operation    ${Put_OPERATION}    ${Request_sent_successfully_ALERT}
    
    Click Element    ${HISTORY_TAB}
    Verify History Table Row Content    ${row_number_1}    ${Put_Method_NAME}    ${Success_STATUS}
    Verify Sent Data Elements Presence In History Table Row    ${row_number_1}
    Verify History Sent Data Box Elements    ${row_number_1}
    Close History Sent Data Box And Clear History Data    ${row_number_1}    


Step_06_run
    Click Element    ${API_TAB}
    Wait Until Page Contains Element    ${Testing_Root_API_Node_Node_Id_Plus_EXPANDER}
    Load Link List Button In CustomContainer Area
    Click Element    ${Testing_Root_API_Link_List_Plus_BUTTON}
    Wait Until Page Contains Element    ${Testing_Root_API_Link_List_Link_Id_INPUT}        
    Insert Text To Input Field    ${Topology_Id_Path_Wrapper_INPUT}    ${Topology_Id_0}    
    Insert Link Id In Form    ${Link_Id_0}    ${Source-node}    ${Destination-node}
    Execute Chosen Operation    ${Put_OPERATION}    ${Request_sent_successfully_ALERT}
    
    Click Element    ${HISTORY_TAB}
    Verify History Table Row Content    ${row_number_1}    ${Put_Method_NAME}    ${Success_STATUS}
    Verify Sent Data Elements Presence In History Table Row    ${row_number_1}
    Verify History Sent Data Box Elements    ${row_number_1}
    Close History Sent Data Box And Clear History Data    ${row_number_1}    


Step_07_run
    Close DLUX
