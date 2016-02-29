*** Settings ***
Documentation     Verification that multiple operations are added to request history list.
Library           Selenium2Library    timeout=10    implicit_wait=10    #Library    Selenium2Library    timeout=10    implicit_wait=10
...               #run_on_failure=Log Source
Library           ../../../libraries/YangUILibrary.py
Resource          ../../../libraries/GUIKeywords.robot
Resource          ../../../libraries/Utils.robot
Resource          ../../../libraries/YangUIKeywords.robot    #Suite Teardown    Close Browser    #Suite Teardown    Run Keywords    Delete All Existing Topologies    Close Browser

*** Variables ***
${LOGIN_USERNAME}    admin
${LOGIN_PASSWORD}    admin
${Default_ID}     [0]
${Row_NUMBER}    1
${History_Table_List_ROW}    //div[@ng-repeat="req in requestList.list track by $index"][${Row_NUMBER}]

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
    [Documentation]    Load "netowork-topology" button in customContainer Area.
    ...    Result
    ...    The page contains "network-tolopogy" arrow expander and "network-tpology" button
    ...    in customContainer Area.
    Step_04_run

Step_05
    [Documentation]    Click HISTORY tab. If the page contains any request in
    ...    history list, click Clear history data
    ...    Result
    ...    The page does not contain History table row.
    Step_05_run

Step_06
    [Documentation]    Execute DELETE operation.
    ...    Result
    ...    The page should contain: - Request sent successfully msg, - Remove method,
    ...    - URL identical to one in preview box, - status success, - disabled "Sent data" button,
    ...    - disabled "Received data" button, - "Execute request" button, - Add to collection button,
    ...    - disabled "Fill data" button, - "Delete" button.
    Step_06_run

Step_07
    [Documentation]    If the page contains any request in history list, click Clear history data.
    ...    The page does not contain History table row. Execute PUT operation.
    ...    Result
    ...    The page should contain: - Error sending request - : Input is required. msg, - PUT method,
    ...    - URL identical to one in preview box, - status error, - disabled "Sent data" button,
    ...    - disabled "Received data" button, - "Execute request" button, - Add to collection button,
    ...    - disabled "Fill data" button, - "Delete" button.
    Step_07_run

Step_08
    [Documentation]    If the page contains any request in history list, click Clear history data.
    ...    The page does not contain History table row. Execute GET operation.
    ...    Result
    ...    The page should contain: - "Data-missing : Request could not be completed because
    ...    the relevant data model content does not exist. - : Request could not be completed
    ...    because the relevant data model content does not exist" msg, - GET method,
    ...    - URL identical to one in preview box, - status error, - disabled "Sent data" button,
    ...    - disabled "Received data" button, - "Execute request" button, - Add to collection button,
    ...    - disabled "Fill data" button, - "Delete" button.
    Step_08_run

Step_09
    [Documentation]    If the page contains any request in history list, click Clear history data.
    ...    The page does not contain History table row. Execute POST operation.
    ...    Result
    ...    The page should contain: - "Server Error : The server encountered an unexpected condition
    ...    which prevented it from fulfilling the request. - : Error creating data" msg, - POST method,
    ...    - URL identical to one in preview box, - status error, - disabled "Sent data" button,
    ...    - disabled "Received data" button, - "Execute request" button, - Add to collection button,
    ...    - disabled "Fill data" button, - "Delete" button.
    Step_09_run

Step_10
    [Documentation]    Click API tab. Click + expander to expand "network-topology" in API tree.
    ...    Result
    ...    The page should contain topology {topology-id} element in API tree.
    Step_10_run

Step_11
    [Documentation]    Click topology {topology-id} element in API tree to load topology list button
    ...    in customContainer Area. Click History tab. If the page contains any request in history
    ...    list, click Clear history data.
    ...    Result
    ...    The page contains "topology list" button in customContainer area. The page does not
    ...    contain History table row.
    Step_11_run

Step_12
    [Documentation]    Execute DELETE operation.
    ...    Result
    ...    The page should contain: - "Error sending request - : Missing key for list "topology"." msg,
    ...    - Remove method, - URL identical to one in preview box, - status error,
    ...    - disabled "Sent data" button, - disabled "Received data" button, - "Execute request" button,
    ...    - Add to collection button, - disabled "Fill data" button, - "Delete" button.
    Step_12_run

Step_13
    [Documentation]    If the page contains any request in history list, click Clear history data.
    ...    Execute PUT operation.
    ...    Result
    ...    The page should contain: - "Error sending request - : Missing key for list "topology"." msg,
    ...    - PUT method, - URL identical to one in preview box, - status error,
    ...    - disabled "Sent data" button, - disabled "Received data" button, - "Execute request" button,
    ...    - Add to collection button, - disabled "Fill data" button, - "Delete" button.
    Step_13_run

Step_14
    [Documentation]    If the page contains any request in history list, click Clear history data.
    ...    Execute GET operation.
    ...    Result
    ...    The page should contain: "Data-missing : Request could not be completed because the
    ...    relevant data model content does not exist. - : Missing key for list "topology"." msg,
    ...    - GET method, - URL identical to one in preview box, - status error,
    ...    - disabled "Sent data" button, - disabled "Received data" button, - "Execute request" button,
    ...    - Add to collection button, - disabled "Fill data" button, - "Delete" button.
    Step_14_run

Step_15
    [Documentation]    If the page contains any request in history list, click Clear history data.
    ...    Execute POST operation.
    ...    Result
    ...    The page should contain: - "Error sending request - : Missing key for list "topology"." msg,
    ...    - POST method, - URL identical to one in preview box, - status error,
    ...    - disabled "Sent data" button, - disabled "Received data" button, - "Execute request" button,
    ...    - Add to collection button, - disabled "Fill data" button, - "Delete" button.
    Step_15_run

Step_16
    [Documentation]    If the page contains any request in history list, click Clear history data.
    ...    Execute POST operation.
    ...    Result
    ...    The page does not contain History table row.
    Step_16_run

Step_17
    [Documentation]    Close Dlux.
    Step_17_run

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


Step_05_run
    Click Element    ${HISTORY_TAB}
    If History Table Contains Data Then Clear History Data


Step_06_run
    Execute Chosen Operation    ${Delete_OPERATION}    ${Request_sent_successfully_ALERT}
    Verify No Sent No Received Data Elements Presence In History Table Row    1


Step_07_run
    If History Table Contains Data Then Clear History Data
    
    Execute Chosen Operation    ${Put_OPERATION}    ${Error_sending_request_Input_is_required_ALERT}
    Verify History Table Row Content    1    ${Put_Method_NAME}    ${Error_STATUS}
    Verify No Sent No Received Data Elements Presence In History Table Row    1


Step_08_run
    If History Table Contains Data Then Clear History Data
    
    Execute Chosen Operation    ${Get_OPERATION}    ${Data_missing_Relevant_data_model_not_existing_ALERT}
    Verify History Table Row Content    1    ${Get_Method_NAME}    ${Error_STATUS}
    Verify No Sent No Received Data Elements Presence In History Table Row    1


Step_09_run
    If History Table Contains Data Then Clear History Data
    
    Execute Chosen Operation    ${Post_OPERATION}    ${Server_error_Error_creating_data_ALERT}
    Verify History Table Row Content    1    ${Post_Method_NAME}    ${Error_STATUS}
    Verify No Sent No Received Data Elements Presence In History Table Row    1


Step_10_run
    Click Element    ${API_TAB}
    Wait Until Page Contains Element     ${Testing_Root_API_Network_Topology_XPATH}
    #Page Should Contain Element     ${Testing_Root_API_Network_Topology_XPATH}
    Page Should Contain Element    ${Testing_Root_API_Network_Topology_BUTTON}
    Click Element    ${Testing_Root_API_Network_Topology_Plus_EXPANDER}
    Wait Until Page Contains Element    ${Testing_Root_API_Topology_Topology_Id_XPATH}
    #Page Should Contain Element      ${Testing_Root_API_Topology_Topology_Id_XPATH}


Step_11_run
    Click Element    ${Testing_Root_API_Topology_Topology_Id_XPATH}
    Wait Until Page Contains Element    ${Testing_Root_API_Topology_List_BUTTON}
    #Page Should Contain Element    ${Testing_Root_API_Topology_List_BUTTON}
    Click Element    ${HISTORY_TAB}
    ${status}=    Run Keyword And Return Status    Page Should Contain Element    ${History_Table_List_ROW}
    Run Keyword If    "${status}"=="True"    Click Element    ${Clear_History_Data_BUTTON}
    Page Should Not Contain Element     ${History_Table_List_ROW}    
    ${status}=    Run Keyword And Return Status    Page Should Contain Element    ${History_Table_List_ROW}
    Run Keyword If    "${status}"=="True"    Click Element    ${Clear_History_Data_BUTTON}
    Page Should Not Contain Element     ${History_Table_List_ROW}
    
    
Step_12_run
    Execute Chosen Operation    ${Delete_OPERATION}    ${Error_sending_request_Missing_key_for_list_ALERT}
    Verify History Table Row Content    1    ${Remove_Method_NAME}    ${Error_STATUS}
    Verify No Sent No Received Data Elements Presence In History Table Row    1


Step_13_run
    If History Table Contains Data Then Clear History Data
    
    Execute Chosen Operation    ${Put_OPERATION}    ${Error_sending_request_Missing_key_for_list_ALERT}
    Verify History Table Row Content    1    ${Put_Method_NAME}    ${Error_STATUS}
    Verify No Sent No Received Data Elements Presence In History Table Row    1


Step_14_run
        If History Table Contains Data Then Clear History Data
    
    Execute Chosen Operation    ${Get_OPERATION}    ${Data_missing_Missing_key_for_list_ALERT}
    Verify History Table Row Content    1    ${Get_Method_NAME}    ${Error_STATUS}
    Verify No Sent No Received Data Elements Presence In History Table Row    1


Step_15_run
    If History Table Contains Data Then Clear History Data
    
    Execute Chosen Operation    ${Post_OPERATION}    ${Error_sending_request_Missing_key_for_list_ALERT}
    Verify History Table Row Content    1    ${Post_Method_NAME}    ${Error_STATUS}
    Verify No Sent No Received Data Elements Presence In History Table Row    1


Step_16_run
    If History Table Contains Data Then Clear History Data
    Delete All Existing Topologies

Step_17_run
    Close DLUX
