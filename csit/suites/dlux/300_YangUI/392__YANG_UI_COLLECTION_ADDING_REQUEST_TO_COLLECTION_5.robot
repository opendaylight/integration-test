*** Settings ***
Documentation     Verification that requests are added to collections with name and existing group. 
#Library           Selenium2Library    timeout=10    implicit_wait=10     run_on_failure=Log Source
Library           Selenium2Library    timeout=10    implicit_wait=10
Library           ../../../libraries/YangUILibrary.py     
Resource          ../../../libraries/GUIKeywords.robot
Resource          ../../../libraries/Utils.robot
Resource          ../../../libraries/YangUIKeywords.robot
#Suite Teardown    Close Browser
#Suite Teardown    Run Keywords    Delete All Existing Topologies    Close Browser

*** Variables ***
${LOGIN_USERNAME}    admin
${LOGIN_PASSWORD}    admin
${Default_ID}    [0]
${Topology_Id_0}    t0
${Topology_ID}
${Name_1}    N1
${Name_2}    N2
${Name_3}    N3
${Name_4}    N4
${Name_5}    N5
${Name_6}    N6
${Group_1}    G1
${Group_2}    G2
${Group_3}    G3


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
    ...    and Yang UI Submenu.
    ...    Location should be http://127.0.0.1:8181/index.html#/yangui/index.
    Step_02_run

Step_03
    [Documentation]    Load "network-topology" button in customContainer Area. Delete
    ...    all existing topologies.
    ...    Result
    ...    The page contains "network-topology" arrow expander and button in customContainer Area.
    Step_03_run

Step_04
    [Documentation]    Click HISTORY tab. If the page contains any request in 
    ...    history list, click Clear history data.
    ...    Result
    ...    The page does not contain History table row.
    Step_04_run

Step_05
    [Documentation]    Execute DELETE operation. Add request to Collection with name and new group.
    ...    Name value: N1. Group value: G1. Clear History data. Navigate to COLLECTION tab.
    ...    Result
    ...    The page should contain: -group G1, - name N1, - success no sent no received data elements.  
    Step_05_run

    
Step_06
    [Documentation]    Navigate to HISTORY tab. Execute GET operation. Add request to Collection with name and new group. 
    ...    Name value: N2. Group value: G2. Clear History data. Navigate to COLLECTION tab.
    ...    Result
    ...    The page should contain: -group G2, -name N2, - error no sent no received data elements.  
    Step_06_run

Step_07
    [Documentation]    Navigate to HISTORY tab. POST topology-id with valid data. Topology id = t0.
    ...    Add request to Collection with name and new group. Name value: N3. Group value: G3. 
    ...    Clear History data. Navigate to COLLECTION tab.
    ...    Result
    ...    The page should contain: -group G3, -name N3, - success sent data elements  
    Step_07_run

Step_08
    [Documentation]    Navigate to HISTORY tab. GET data at the level of network-topology.
    ...    Add request to Collection with name to an existing group. Name value: N4. Group value: G3.
    ...    Clear History data. Navigate to COLLECTION tab.
    ...    Result
    ...    The page should contain: -group G3, -name N4, - success received data elements
    Step_08_run

Step_09
    [Documentation]    Navigate to HISTORY tab. PUT topology-id withno data.
    ...    Add request to Collection with name to an existing group. Name value: N5. Group value: G2 
    ...    Clear History data. Navigate to COLLECTION tab.
    ...    Result
    ...    The page should contain: -group G2, - name N5, - error sent data elements
    Step_09_run    

Step_10
    [Documentation]    Navigate to HISTORY tab. PUT topology-id withno data.
    ...    Add request to Collection with name to an existing group. Name value: N6. Group value: G1 
    ...    Clear History data. Navigate to COLLECTION tab.
    ...    Result
    ...    The page should contain: -group G1, - name N6, - success sent data elements
    Step_10_run

Step_11
    [Documentation]    If the page contains any request in collection list, click Clear collection data. 
    Step_11_run
    
Step_12
    [Documentation]    Close DLUX.
    Step_12_run

*** Keywords ***
Step_01_run
    Launch DLUX
    #Open DLUX Login Page    ${LOGIN URL}
    Verify Elements Of DLUX Login Page


Step_02_run
    Login DLUX    ${LOGIN_USERNAME}    ${LOGIN_PASSWORD}
    Verify Elements of DLUX Home Page
    Page Should Contain Element    ${Yang_UI_SUBMENU}
    Navigate To Yang UI Submenu


Step_03_run
    Load Network-topology Button In CustomContainer Area
    Delete All Existing Topologies


Step_04_run
    Click Element    ${HISTORY_TAB}
    If History Table Contains Data Then Clear History Data
  

Step_05_run
    Execute Chosen Operation    ${Delete_OPERATION}    ${Request_sent_successfully_ALERT}
    Add Request To Collection    1    ${Name_1}    ${Select_Option}    ${Group_1}
    Click Element    ${Add_To_Collection_Box_Add_BUTTON}    
    If History Table Contains Data Then Clear History Data
    Click Element    ${COLLECTION_TAB}
    Expand Collection Table Group Expander    1    ${Group_1}    1
    Verify Collection Table Group Row Content    1    1    ${Remove_Method_NAME}    ${Name_1}    ${Success_STATUS}                
    Verify No Sent No Received Data Elements Presence In Collection Table Group Row    1    1


Step_06_run
    Click Element    ${HISTORY_TAB}
    Execute Chosen Operation    ${Get_OPERATION}    ${Data_missing_Relevant_data_model_not_existing_ALERT}
    Add Request To Collection    1    ${Name_2}    ${Select_Option}   ${Group_2}
    Click Element    ${Add_To_Collection_Box_Add_BUTTON}    
    If History Table Contains Data Then Clear History Data
    Click Element    ${COLLECTION_TAB}
    Expand Collection Table Group Expander    2    ${Group_2}    1
    Verify Collection Table Group Row Content    2    1    ${Get_Method_NAME}    ${Name_2}    ${Error_STATUS}
    Verify No Sent No Received Data Elements Presence In Collection Table Group Row    2    1


Step_07_run
    Click Element    ${HISTORY_TAB}
    Expand Network Topology Arrow Expander
    Click Element    ${Testing_Root_API_Topology_List_Plus_BUTTON}
    POST ID    ${Testing_Root_API_Topology_List_Topology_Id_INPUT}    ${Topology_Id_0}    ${Topology_ID}    ${Testing_Root_API_Topology_List_NAME}    
    Add Request To Collection    1    ${Name_3}    ${Select_Option}    ${Group_3}
    Click Element    ${Add_To_Collection_Box_Add_BUTTON}    
    If History Table Contains Data Then Clear History Data
    Close Form In CustomContainer Area    ${Testing_Root_API_Topology_List_Topology_Delete_BUTTON}    ${Testing_Root_API_Topology_List_Topology_Id_INPUT}
    Click Element    ${COLLECTION_TAB}
    Expand Collection Table Group Expander    3    ${Group_3}    1
    Verify Collection Table Group Row Content    3    1    ${Post_Method_NAME}    ${Name_3}    ${Success_STATUS}
    Verify Sent Data Elements Presence In Collection Table Group Row    3    1


Step_08_run
    Click Element    ${HISTORY_TAB}
    Execute Chosen Operation    ${Get_OPERATION}    ${Request_sent_successfully_ALERT}    
    Add Request To Collection    1    ${Name_4}    ${Group_3}    ${EMPTY}
    Click Element    ${Add_To_Collection_Box_Add_BUTTON}    
    If History Table Contains Data Then Clear History Data
    Close Form In CustomContainer Area    ${Testing_Root_API_Topology_List_Topology_Delete_BUTTON}    ${Testing_Root_API_Topology_List_Topology_Id_INPUT}
    Click Element    ${COLLECTION_TAB}
    Expand Collection Table Group Expander    3    ${Group_3}    2
    Verify Collection Table Group Row Content    3    2    ${Get_Method_NAME}    ${Name_4}    ${Success_STATUS}
    Verify Received Data Elements Presence In Collection Table Group Row    3    2


Step_09_run
    Click Element    ${HISTORY_TAB}
    Execute Chosen Operation    ${Put_OPERATION}    ${Error_sending_request_Input_is_required_ALERT}    
    Add Request To Collection    1    ${Name_5}    ${Group_2}    ${EMPTY}
    Click Element    ${Add_To_Collection_Box_Add_BUTTON}    
    If History Table Contains Data Then Clear History Data
    Click Element    ${COLLECTION_TAB}
    Expand Collection Table Group Expander    2    ${Group_2}    2
    Verify Collection Table Group Row Content    2    2    ${Put_Method_NAME}    ${Name_5}    ${Error_STATUS}
    Verify No Sent No Received Data Elements Presence In Collection Table Group Row    2    2


Step_10_run
    Click Element    ${HISTORY_TAB}
    Expand Network Topology Arrow Expander
    Click Element    ${Testing_Root_API_Topology_List_Plus_BUTTON}
    PUT ID    ${Testing_Root_API_Topology_List_Topology_Id_INPUT}    ${Topology_Id_0}    ${Topology_ID}    ${Testing_Root_API_Topology_List_NAME}
    Add Request To Collection    1    ${Name_6}    ${Group_1}    ${EMPTY}
    Click Element    ${Add_To_Collection_Box_Add_BUTTON}    
    If History Table Contains Data Then Clear History Data
    Close Form In CustomContainer Area    ${Testing_Root_API_Topology_List_Topology_Delete_BUTTON}    ${Testing_Root_API_Topology_List_Topology_Id_INPUT}
    Click Element    ${COLLECTION_TAB}
    Expand Collection Table Group Expander    1    ${Group_1}    2
    Verify Collection Table Group Row Content    1    2    ${Put_Method_NAME}    ${Name_6}    ${Success_STATUS}
    Verify Sent Data Elements Presence In Collection Table Group Row    1    2
    

Step_11_run    
    If Collection Table Contains Data Then Clear Collection Data


Step_12_run
    Close DLUX 
    

        


    
           
    
                  