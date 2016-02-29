*** Settings ***
Documentation     Verification that History tab contains box with tools that 
...               enable to modify sent data wih parameters.
Library           Selenium2Library    timeout=10    implicit_wait=10    #Library    Selenium2Library    timeout=10    implicit_wait=10
...               #run_on_failure=Log Source
Resource          ../../../libraries/GUIKeywords.robot
Resource          ../../../libraries/Utils.robot
Resource          ../../../libraries/YangUIKeywords.robot    
#Suite Teardown    Close Browser    
#Suite Teardown    Run Keywords    Delete All Existing Topologies    Close Browser

*** Variables ***
${LOGIN_USERNAME}    admin
${LOGIN_PASSWORD}    admin
${Default_ID}     [0]
${Topology_Id_0}    t0
${Node_Id_0}      t0n0
${Link_Id_0}      t0l0
${Topology_ID}    ${EMPTY}
${Node_ID}        ${EMPTY}
${Link_ID}        ${EMPTY}
${Row_NUMBER}    1
${History_Table_List_ROW}    ${History_TABLE}//div[@ng-repeat="req in requestList.list track by $index"][${Row_NUMBER}]

*** Test Cases ***
Step_01
    [Documentation]    Open OpenDayLight page.
    ...    Result
    ...    Page http://127.0.0.1:8181/index.html#/login opened.
    ...    Login formular present on the page.
    Step_01_run

Step_02
    [Documentation]    Insert valid credentials and hit "Login" button.
    ...    Result
    ...    Location is http://127.0.0.1:8181/index.html#/topology.
    ...    Verification that the page contains "Controls" and button "Reload",
    ...    and Yang UI Submenu.
    Step_02_run

Step_03
    [Documentation]    Navigate to Yang UI.
    ...    Result
    ...    Location should be http://127.0.0.1:8181/index.html#/yangui/index.
    Step_03_run

Step_04
    [Documentation]    Load "topology list" button in customContainer Area.
    ...    Result
    ...    The page contains "topology list" arrow expander, "topology list" plus button and "topology list"
    ...    button in customContainer Area.
    Step_04_run

Step_05
    [Documentation]    Execute PUT operation with valid data. Topology id value: t0.
    ...    Click HISTORY tab.
    ...    Result
    ...    The page should contain: - Request sent successfully  msg, - PUT method,
    ...    - URL identical to one in preview box, - status success, - enabled "Sent data" button,
    ...    - disabled "Received data" button, - "Execute request" button, - Add to collection button,
    ...    - enabled "Fill data" button, - "Delete" button.    
    Step_05_run

Step_06
    [Documentation]    Click Sent data button.
    ...    Result
    ...    The page contains: - Sent data box, - api path wrapper, - topology id input
    ...    - copy to clipboard button, - reset parametrized data button, - save parametrized data.    
    Step_06_run

Step_07
    [Documentation]    "Click Close button to close Sent data box. Click Clear hist. data
    ...    to delete histroy data."
    ...    Result
    ...    The page should not contain Sent data box. The page should not contain
    ...    History table row.
    Step_07_run

Step_08
    [Documentation]    Click API tab. Navigate to "node {nide-id}" in API tree and 
    ...    load "node list" button in customContainer Area. Click node list iconPlus to add node id.
    ...    Execute Put operation to add new node id with valid data - topology id: t0, 
    ...    node id: t0n0. Click History tab.
    ...    Result
    ...    The page should contain: - Request sent successfully  msg, - PUT method,
    ...    - URL identical to one in preview box, - status success, - enabled "Sent data" button,
    ...    - disabled "Received data" button, - "Execute request" button, - Add to collection button,
    ...    - enabled "Fill data" button, - "Delete" button. 
    Step_08_run

Step_09
    [Documentation]    Click Sent data button.
    ...    Result
    ...    The page contains: - Sent data box, - api path wrapper, - topology id input
    ...    - copy to clipboard button, - reset parametrized data button, - save parametrized data.
    Step_09_run

Step_10
    [Documentation]    Click Close button to close Sent data box. Click Clear history data
    ...    to delete histroy data.
    ...    Result
    ...    The page should not contain Sent data box. The page should not contain
    ...    History table row.
    Step_10_run

Step_11
    [Documentation]    Click API tab. Click link list iconPlus to add link id. 
    ...    Execute Put operation to add new link id with valid data - topology id: t0, 
    ...    link id: l0n0. Click History tab.
    ...    Result
    ...    The page should contain: - Request sent successfully  msg, - PUT method,
    ...    - URL identical to one in preview box, - status success, - enabled "Sent data" button,
    ...    - disabled "Received data" button, - "Execute request" button, - Add to collection button,
    ...    - enabled "Fill data" button, - "Delete" button.
    Step_11_run

Step_12
    [Documentation]    Click Sent data button.
    ...    Result
    ...    The page contains: - Sent data box, - api path wrapper, - topology id input
    ...    - copy to clipboard button, - reset parametrized data button, - save parametrized data.
    Step_12_run

Step_13
    [Documentation]    If the page contains any request in history list, click Clear history data.
    ...    Result
    ...    The page does not contain History table row.
    Step_13_run

Step_14
    [Documentation]    Close Dlux.
    Step_14_run

*** Keywords ***
Step_01_run
    Launch DLUX
    #Open DLUX Login Page    ${LOGIN URL}
    Verify Elements Of DLUX Login Page


Step_02_run
    Login DLUX    ${LOGIN_USERNAME}    ${LOGIN_PASSWORD}
    Verify Elements of DLUX Home Page
    Page Should Contain Element    ${Yang_UI_SUBMENU}


Step_03_run
    Click Element    ${Yang_UI_SUBMENU}
    Wait Until Page Contains Element    ${Loading_completed_successfully_ALERT}
    Click Element    ${Alert_Close_BUTTON}
    Location Should Be    ${Yang_UI_Submenu_URL}


Step_04_run
    Load Network-topology Button In CustomContainer Area
    Load Topology List Button In CustomContainer Area


Step_05_run
    Click Element    ${Testing_Root_API_Topology_List_Plus_BUTTON}
    PUT ID    ${Testing_Root_API_Topology_List_Topology_Id_INPUT}    ${Topology_Id_0}    ${Topology_ID}    ${Testing_Root_API_Topology_List_NAME}
    Click Element    ${HISTORY_TAB}
    Verify Sent Data Elements Presence In History Table Row    1


Step_06_run
    Verify History Sent Data Box Elements    


Step_07_run
    Close History Sent Data Box And Clear History Data    


Step_08_run
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
     

Step_09_run
    Verify History Sent Data Box Elements


Step_10_run
    Close History Sent Data Box And Clear History Data


Step_11_run
    Click Element    ${API_TAB}
    Wait Until Page Contains Element    ${Testing_Root_API_Node_Node_Id_Plus_EXPANDER}
    Page Should Contain Element    ${Testing_Root_API_Link_Link_Id_XPATH}    
    Click Element    ${Testing_Root_API_Link_Link_Id_XPATH}
    Wait Until Page Contains Element    ${Testing_Root_API_Link_List_BUTTON}
    Page Should Contain Button    ${Testing_Root_API_Link_List_Arrow_EXPANDER}
    Page Should Contain Button    ${Testing_Root_API_Link_List_Plus_BUTTON}        
    
    Click Element    ${Testing_Root_API_Link_List_Plus_BUTTON}
    Wait Until Page Contains Element    ${Testing_Root_API_Link_List_Link_Id_INPUT}        
    Insert Text To Input Field    ${Topology_Id_Path_Wrapper_INPUT}    ${Topology_Id_0}    
    Insert Text To Input Field    ${Link_Id_Path_Wrapper_INPUT}    ${Link_Id_0}
    Execute Chosen Operation    ${Put_OPERATION}    ${Server_error_Cancommit_encountered_unexpected_failure_ALERT}
    Click Element    ${HISTORY_TAB}
    Verify Sent Data Elements Presence In History Table Row    1


Step_12_run
    Verify History Sent Data Box Elements

Step_13_run
    If History Table Contains Data Then Clear History Data

Step_14_run
    Close DLUX
