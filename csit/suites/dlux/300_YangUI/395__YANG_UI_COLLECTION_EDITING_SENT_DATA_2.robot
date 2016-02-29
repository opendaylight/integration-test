*** Settings ***
Documentation     Verification that Collection tab group row contains box with tools that
...               enable to modify sent data wih parameters.
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
    ...    Name value: N1. Add request to collection with goup. Group: G1. Navigate to COLLECTION tab.
    ...    Result
    ...    The page does not contain History table row. The page should contain:
    ...    - name N1, - group G1, - success sent data elements. 
    Step_04_run

Step_05
    [Documentation]    Click Sent data button. Click Close button to close Sent data box.
    ...    Result
    ...    The page contains: - Sent data box, - api path wrapper, - topology id input
    ...    - copy to clipboard button, - reset parametrized data button, - save parametrized data.
    ...    The page should not contain Sent data box.  
    Step_05_run

Step_06
    [Documentation]    Navigate to API tab. Load "node list" button in customContainer Area.
    ...    Click "node list" icon Plus to add node id. Execute Put operation with valid data.
    ...    Click History tab. Add request to collection with name and group.
    ...    Navigate to collection tab. Topology id value: t0. Node id value: t0n0. Group: G1
    ...    Name value: N2
    ...    Result
    ...    The page should contain: - name N2, - group G1, - success sent data elements
    Step_06_run

Step_07
    [Documentation]    Click Sent data button. Click Close button to close Sent data box.
    ...    Result
    ...    The page contains: - Sent data box, - api path wrapper, - topology id input, - node id input
    ...    - copy to clipboard button, - reset parametrized data button, - save parametrized data.
    ...    The page should not contain Sent data box.   
    Step_07_run


Step_08
    [Documentation]    Navigate to API tab. Load "link list" button in customContainer Area.
    ...    Click "link list" icon Plus to add link id. Click source expander to input
    ...    source-node and destination arrow expander to insert destination node.
    ...    Execute Put operation with valid data. Click History tab. Add request to collection 
    ...    with name and new group. Navigate to collection tab. Topology id value: t0,
    ...    Link id value: t0l0, Source-node: s0, Dest-node: d0, Name value: N3, Group value: G2
    ...    Result
    ...    The page should contain: - name N3, -group G2, - success sent data elements
    Step_08_run

Step_09
    [Documentation]    Click Sent data button. Click Close button to close Sent data box.
    ...    Click Clear collection data to delete collection data.
    ...    Result
    ...    The page contains: - Sent data box, - api path wrapper, - topology id input, - link id input
    ...    - copy to clipboard button, - reset parametrized data button, - save parametrized data.
    ...    The page should not contain Sent data box. The page should not contain collection table row.
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


Step_04_run
    Click Element    ${HISTORY_TAB}
    If History Table Contains Data Then Clear History Data
    Click Element    ${Testing_Root_API_Topology_List_Plus_BUTTON}
    PUT ID    ${Testing_Root_API_Topology_List_Topology_Id_INPUT}    ${Topology_Id_0}    ${Topology_ID}    ${Testing_Root_API_Topology_List_NAME}
    Verify Sent Data Elements Presence In History Table Row    1
    Add Request To Collection    1    ${Name_1}     ${Select_Option}    ${Group_1}    
    Click Element    ${Add_To_Collection_Box_Add_BUTTON}
    If History Table Contains Data Then Clear History Data
    Click Element    ${COLLECTION_TAB}  
    Expand Collection Table Group Expander    1    ${Group_1}    1
    Verify Collection Table Group Row Content    1    1    ${Put_Method_NAME}    ${Name_1}    ${Success_STATUS}
    Verify Sent Data Elements Presence In Collection Table Group Row    1    1


Step_05_run
    ${Collection_Table_List_Group_ROW}=    Return Collection Table Group Row Number    1    1
    Verify Elements Of Group Row Sent Data Box    1    1
    ${Collection_Table_Group_Row_Sent_Data_BOX}=    Set Variable    ${Collection_Table_List_Group_ROW}${Sent_Data_BOX}
    ${Collection_Table_Group_Row_Sent_Data_Box_Path_WRAPPER}=    Set Variable    ${Collection_Table_Group_Row_Sent_Data_BOX}${Sent_Data_Box_Path_WRAPPER}    
    ${Collection_Table_Group_Row_Sent_Data_Box_Topology_Id_Path_Wrapper_INPUT}=    Set Variable    ${Collection_Table_Group_Row_Sent_Data_Box_Path_WRAPPER}${Sent_Data_Box_Topology_Id_Path_Wrapper_INPUT}    
    Page Should Contain Element    ${Collection_Table_Group_Row_Sent_Data_Box_Topology_Id_Path_Wrapper_INPUT}
    Close Collection Group Sent Box    1    1       
    
    
Step_06_run
    Click Element    ${API_TAB}
    Wait Until Page Contains Element    ${Testing_Root_API_Topology_Topology_Id_Plus_EXPANDER}
    Load Node List Button In CustomContainer Area
    Click Element    ${Testing_Root_API_Node_List_Plus_BUTTON}
    Wait Until Page Contains Element    ${Testing_Root_API_Node_List_Node_Id_INPUT}    
    Insert Text To Input Field    ${Topology_Id_Path_Wrapper_INPUT}    ${Topology_Id_0}    
    Insert Text To Input Field    ${Node_Id_Path_Wrapper_INPUT}    ${Node_Id_0}
    Execute Chosen Operation    ${Put_OPERATION}    ${Request_sent_successfully_ALERT}
    Click Element    ${HISTORY_TAB}
    Verify Sent Data Elements Presence In History Table Row    1        
    Add Request To Collection    1    ${Name_2}    ${Group_1}    ${EMPTY}
    Click Element    ${Add_To_Collection_Box_Add_BUTTON}
    If History Table Contains Data Then Clear History Data
    Click Element    ${COLLECTION_TAB}  
    Expand Collection Table Group Expander    1    ${Group_1}    1
    Verify Collection Table Group Row Content    1    2    ${Put_Method_NAME}    ${Name_2}    ${Success_STATUS}
    Verify Sent Data Elements Presence In Collection Table Group Row    1    2


Step_07_run
    ${Collection_Table_List_Group_ROW}=    Return Collection Table Group Row Number    1    2
    Verify Elements Of Group Row Sent Data Box    1    2
    ${Collection_Table_Group_Row_Sent_Data_BOX}=    Set Variable    ${Collection_Table_List_Group_ROW}${Sent_Data_BOX}
    ${Collection_Table_Group_Row_Sent_Data_Box_Path_WRAPPER}=    Set Variable    ${Collection_Table_Group_Row_Sent_Data_BOX}${Sent_Data_Box_Path_WRAPPER}    
    ${Collection_Table_Group_Row_Sent_Data_Box_Topology_Id_Path_Wrapper_INPUT}=    Set Variable    ${Collection_Table_Group_Row_Sent_Data_Box_Path_WRAPPER}${Sent_Data_Box_Topology_Id_Path_Wrapper_INPUT} 
    ${Collection_Table_Group_Row_Sent_Data_Box_Node_Id_Path_Wrapper_INPUT}=    Set Variable    ${Collection_Table_Group_Row_Sent_Data_Box_Path_WRAPPER}${Sent_Data_Box_Node_Id_Path_Wrapper_INPUT}
    Page Should Contain Element    ${Collection_Table_Group_Row_Sent_Data_Box_Topology_Id_Path_Wrapper_INPUT}
    Page Should Contain Element    ${Collection_Table_Group_Row_Sent_Data_Box_Node_Id_Path_Wrapper_INPUT}
    Close Collection Group Sent Box    1    2       
    

Step_08_run
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
    Verify Sent Data Elements Presence In History Table Row    1        
    Add Request To Collection    1    ${Name_3}    ${Select_Option}    ${Group_2}
    Click Element    ${Add_To_Collection_Box_Add_BUTTON}
    If History Table Contains Data Then Clear History Data
    Click Element    ${COLLECTION_TAB}  
    Expand Collection Table Group Expander    2    ${Group_2}    1
    Verify Collection Table Group Row Content    2    1    ${Put_Method_NAME}    ${Name_3}    ${Success_STATUS}
    Verify Sent Data Elements Presence In Collection Table Group Row    2    1


Step_09_run
    ${Collection_Table_List_Group_ROW}=    Return Collection Table Group Row Number    2    1
    Verify Elements Of Group Row Sent Data Box    2    1
    ${Collection_Table_Group_Row_Sent_Data_BOX}=    Set Variable    ${Collection_Table_List_Group_ROW}${Sent_Data_BOX}
    ${Collection_Table_Group_Row_Sent_Data_Box_Path_WRAPPER}=    Set Variable    ${Collection_Table_Group_Row_Sent_Data_BOX}${Sent_Data_Box_Path_WRAPPER}    
    ${Collection_Table_Group_Row_Sent_Data_Box_Topology_Id_Path_Wrapper_INPUT}=    Set Variable    ${Collection_Table_Group_Row_Sent_Data_Box_Path_WRAPPER}${Sent_Data_Box_Topology_Id_Path_Wrapper_INPUT} 
    ${Collection_Table_Group_Row_Sent_Data_Box_Link_Id_Path_Wrapper_INPUT}=    Set Variable    ${Collection_Table_Group_Row_Sent_Data_Box_Path_WRAPPER}${Sent_Data_Box_Link_Id_Path_Wrapper_INPUT}
    Page Should Contain Element    ${Collection_Table_Group_Row_Sent_Data_Box_Topology_Id_Path_Wrapper_INPUT}
    Page Should Contain Element    ${Collection_Table_Group_Row_Sent_Data_Box_Link_Id_Path_Wrapper_INPUT}
    Close Collection Group Sent Box    2    1       

    If Collection Table Contains Data Then Clear Collection Data
    

Step_10_run
    Close DLUX
