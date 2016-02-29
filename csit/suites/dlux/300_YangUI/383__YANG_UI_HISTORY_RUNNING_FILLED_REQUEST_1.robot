*** Settings ***
Documentation     Verification that it is possible to run filled request with the 
...               same data as original request.
Library           Selenium2Library    timeout=10    implicit_wait=10    
#Library    Selenium2Library    timeout=10    implicit_wait=10    run_on_failure=Log Source
Resource          ../../../libraries/GUIKeywords.robot
Resource          ../../../libraries/Utils.robot
Resource          ../../../libraries/YangUIKeywords.robot 
#Suite Teardown    Close Browser    
#Suite Teardown    Run Keywords    Delete All Existing Topologies    Close Browser

*** Variables ***
${verify_sent_data_function}    Verify Sent Data Elements Presence In History Table Row
${verify_received_data_function}    Verify Received Data Elements Presence In History Table Row

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
    [Documentation]    Execute [PUT, GET, DELETE] operation with valid data. 
    ...    Close topology form in customContainer area.Navigate to History tab,
    ...    verify [PUT, GET, REMOVE] method presence in row [1, 3, 5], verify success status and
    ...    [sent, received, sent] data elements presence in History tab row. Fill the request to form and
    ...    execute the request by clicking Send button.     
    ...    Valid data: Topology id value: t0, Node id value: t0n0, List id value: t0l0.
    ...    Result
    ...    The History tab page should contain: 
    ...    row2 - Success Sent Data Elements In History Table Row.
    ...    row4 - Success Received Data Elements In History Table Row.
    ...    row6 - Success Sent Data Elements In History Table Row.
    Step_04_run

Step_05
    [Documentation]    Load "network-topology" button in customContainer Area. Delete 
    ...    all existing topologies. Load "link-list" in customContainer Area. Click HISTORY tab.
    ...    If the page contains any request in history list, click Clear history data. 
    Step_05_run

Step_06
    [Documentation]    Execute [PUT, GET, DELETE] operation with valid data. 
    ...    Close link form in customContainer area. Navigate to History tab,
    ...    verify [PUT, GET, REMOVE] method presence in row [1, 3, 5], verify success status and
    ...    [sent, received, sent] data elements presence in History tab row. Fill the request to form and
    ...    execute the request by clicking Send button.     
    ...    Valid data: List id value: t0l0, Source-node: s0, Destination-node: d0.
    ...    Result
    ...    The History tab page should contain: 
    ...    row2 - Success Sent Data Elements In History Table Row.
    ...    row4 - Success Received Data Elements In History Table Row.
    ...    row6 - Success Sent Data Elements In History Table Row.
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
    Click Element    ${HISTORY_TAB}
    If History Table Contains Data Then Clear History Data


Step_04_run
    @{req_1_data}=    Create List    ${Put_Method_NAME}    ${Success_STATUS}    ${row_number_1}    ${row_number_2}    ${verify_sent_data_function}   
    Set Suite Variable    @{req_1_data}             
    @{req_2_data}=    Create List    ${Get_Method_NAME}    ${Success_STATUS}    ${row_number_3}    ${row_number_4}    ${verify_received_data_function}    
    Set Suite Variable    @{req_2_data}        
    @{req_3_data}=    Create List    ${Remove_Method_NAME}    ${Success_STATUS}    ${row_number_5}    ${row_number_6}    ${verify_sent_data_function}    
    Set Suite Variable    @{req_3_data}
    @{operations}=    Create List    ${Put_OPERATION}    ${Get_OPERATION}    ${Delete_OPERATION}
    Set Suite Variable    @{operations}    
    ${dict_1}=    Create Dictionary    ${Put_OPERATION}=@{req_1_data}    ${Get_OPERATION}=@{req_2_data}    ${Delete_OPERATION}=@{req_3_data}
    Set Suite Variable    ${dict_1}
    : FOR    ${operation}    IN    @{operations}
    \    ${index}    Evaluate    0
    \    ${values}=    Get From Dictionary    ${dict_1}    ${operation}
    \    ${method}=    Get From List    ${values}    ${index}
    \    Set Suite Variable    ${method_index}    ${index}
    \    ${index}    Evaluate    ${index}+1
    \    ${status}=    Get From List    ${values}    ${index}
    \    Set Suite Variable    ${status_index}    ${index}
    \    ${index}    Evaluate    ${index}+1
    \    ${row}=    Get From List    ${values}    ${index}
    \    Set Suite Variable    ${row_index}    ${index}
    \    ${index}    Evaluate    ${index}+1
    \    ${run_req_row}=    Get From List    ${values}    ${index}
    \    Set Suite Variable    ${run_req_row_index}    ${index}
    \    ${index}    Evaluate    ${index}+1
    \    ${verify_function}=    Get From List    ${values}    ${index}
    \    Set Suite Variable    ${verify_function_index}    ${index}
    \    ${index}    Evaluate    ${index}+1
    \    Insert Topology Or Node Or Link Id In Form    ${Topology_Id_0}    ${Node_Id_0}    ${Link_Id_0}    
    \    Execute Chosen Operation    ${operation}    ${Request_sent_successfully_ALERT}
    \    Close Form In CustomContainer Area    ${Testing_Root_API_Topology_List_Topology_Delete_BUTTON}    ${Testing_Root_API_Topology_List_Topology_Id_INPUT}
    \    Click Element    ${HISTORY_TAB} 
    \    Verify History Table Row Content    ${row}    ${method}    ${status}
    \    Run Keyword    ${verify_function}    ${row}
    \    Fill History Table Row Request To Form    ${row}
    \    Verify Topology And Node And Link Id Presence In Form    ${Topology_Id_0}    ${Node_Id_0}    ${Link_Id_0}      
    \    Patient Click Element    ${Send_BUTTON}    4
    \    Verify History Table Row Content    ${run_req_row}    ${method}    ${status}
    \    Run Keyword    ${verify_function}    ${run_req_row}
    \    Close Form In CustomContainer Area    ${Testing_Root_API_Topology_List_Topology_Delete_BUTTON}    ${Testing_Root_API_Topology_List_Topology_Id_INPUT}    
    \    ${url_1}=    Return History Table Row Url    ${row}
    \    ${url_2}=    Return History Table Row Url    ${run_req_row}
    \    Should Be Equal As Strings    ${url_1}   ${url_2}    
    \    Click Element    ${API_TAB}    


Step_05_run
    Load Network-topology Button In CustomContainer Area
    Delete All Existing Topologies
    Load Topology List Button In CustomContainer Area
    Load Node List Button In CustomContainer Area
    Load Link List Button In CustomContainer Area
    Click Element    ${HISTORY_TAB}
    If History Table Contains Data Then Clear History Data


Step_06_run
    : FOR    ${operation}    IN    @{operations}
    \    ${values}=    Get From Dictionary    ${dict_1}    ${operation}
    \    ${method}=    Get From List    ${values}    ${method_index}
    \    ${status}=    Get From List    ${values}    ${status_index}
    \    ${row}=    Get From List    ${values}    ${row_index}
    \    ${run_req_row}=    Get From List    ${values}    ${run_req_row_index}
    \    ${verify_function}=    Get From List    ${values}    ${verify_function_index}
    \    Click Element    ${Testing_Root_API_Link_List_Plus_BUTTON}
    \    Insert Text To Input Field    ${Topology_Id_Path_Wrapper_INPUT}    ${Topology_Id_0}
    \    Insert Link Id In Form    ${Link_Id_0}    ${Source-node}    ${Destination-node}    
    \    Execute Chosen Operation    ${operation}    ${Request_sent_successfully_ALERT}
    \    Close Form In CustomContainer Area    ${Testing_Root_API_Link_List_Link_Delete_BUTTON}    ${Testing_Root_API_Link_List_Link_Id_INPUT}
    \    Click Element    ${HISTORY_TAB} 
    \    Verify History Table Row Content    ${row}    ${method}    ${status}
    \    Run Keyword    ${verify_function}    ${row}
    \    Fill History Table Row Request To Form    ${row}
    \    Verify Topology And Node And Link Id Presence In Form    ${EMPTY}    ${EMPTY}    ${Link_Id_0}      
    \    Patient Click Element    ${Send_BUTTON}    4
    \    Verify History Table Row Content    ${run_req_row}    ${method}    ${status}
    \    Run Keyword    ${verify_function}    ${run_req_row}
    \    Close Form In CustomContainer Area    ${Testing_Root_API_Topology_List_Topology_Delete_BUTTON}    ${Testing_Root_API_Topology_List_Topology_Id_INPUT}    
    \    ${url_1}=    Return History Table Row Url    ${row}
    \    ${url_2}=    Return History Table Row Url    ${run_req_row}
    \    Should Be Equal As Strings    ${url_1}   ${url_2}
    \    Click Element    ${API_TAB}   
     
    Click Element    ${HISTORY_TAB}
    If History Table Contains Data Then Clear History Data

Step_07_run
    Close DLUX
