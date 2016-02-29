*** Settings ***
Documentation     Verification that various operations are added to request history list. 
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
${Topology_Id_1}    t1
${Node_Id_0}    t0n0
${Node_Id_1}    t0n1
${Node_Id_2}    t0n2
${Link_Id_0}    t0l0
${Link_Id_1}    t0l1
${Link_Id_2}    t0l2
${Topology_ID}
${Node_ID}
${Link_ID}


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
    [Documentation]   Load "netowork-topology" button in customContainer Area.
    ...    Result
    ...    The page contains "network-tolopogy" plus expander (3rd level
    ...    of tree rows) and "network-tpology" element in API tree. The page contains
    ...    "network-topology" arrow expander and "network-topology" button in customContainer Area. 
    Step_04_run

Step_05
    [Documentation]    Click HISTORY tab. If the page contains any request in 
    ...    history list, click Clear history data
    ...    Result
    ...    The page does not contain History table row.
    Step_05_run

    
Step_06
    [Documentation]    Select DELETE operation and click Send button.
    ...    Result
    ...    The page should contain:- Request sent successfully msg, - Remove method,
    ...    - URL identical to one in preview box, - status success, - disabled "Sent data" button,
    ...    - disabled "Received data" button, - "Execute request" button, - Add to collection button,
    ...    - disabled "Fill data"  button, - "Delete" button.    
    Step_06_run

Step_07
    [Documentation]    If the page contains any request in history list, click Clear history data.
    ...    Expand network-topology arrow expander in custom Container area. Click + button and add new topology id.
    ...    Topology id: t0. Execute POST operation.
    ...    The page should contain:- Request sent successfully msg, - POST method,
    ...    - URL identical to one in preview box, - status success, - enabled "Sent data" button,
    ...    - disabled "Received data" button, - "Execute request" button, - Add to collection button,
    ...    - enabled "Fill data"  button, - "Delete" button.
    Step_07_run

Step_08
    [Documentation]    If the page contains any request in history list, click Clear history data.
    ...    If the page does not contain network-topology arrow expander, expand network-topology arrow expander in custom Container area. Click + button and add new topology id.
    ...    Topology id: t1. Execute PUT operation.
    ...    The page should contain:- Request sent successfully msg, - POST method,
    ...    - URL identical to one in preview box, - status success, - enabled "Sent data" button,
    ...    - disabled "Received data" button, - "Execute request" button, - Add to collection button,
    ...    - enabled "Fill data"  button, - "Delete" button.
    Step_08_run

Step_09
    [Documentation]    If the page contains any request in history list, click Clear history data.
    ...    If the page does not contain network-topology arrow expander, expand network-topology arrow expander in custom Container area.
    ...    Execute GET operation.
    ...    The page should contain:- Request sent successfully msg, - GET method,
    ...    - URL identical to one in preview box, - status success, - disabled "Sent data" button,
    ...    - enabled "Received data" button, - "Execute request" button, - Add to collection button,
    ...    - enabled "Fill data"  button, - "Delete" button.
    Step_09_run    

Step_10
    [Documentation]    Close DLUX.
    Step_10_run

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
    ${Row_NUMBER}=    Set Variable    1
    ${History_Table_List_ROW}=    Set Variable    //div[@ng-repeat="req in requestList.list track by $index"][${Row_NUMBER}]
    ${status}=    Run Keyword And Return Status    Page Should Contain Element    ${History_Table_List_ROW}    
    Run Keyword If    "${status}"=="True"    Click Element    ${Clear_History_Data_BUTTON}
    

Step_06_run
    Execute Chosen Operation    ${Delete_OPERATION}    ${Request_sent_successfully_ALERT}
    
    ${Row_NUMBER}=    Set Variable    1    
    ${History_Table_List_ROW}=    Set Variable    //div[@ng-repeat="req in requestList.list track by $index"][${Row_NUMBER}] 
    Verify History Table Row Content    1    ${Remove_Method_NAME}    ${Success_STATUS}
    
    ${dict}=    Create Dictionary    
    ...    ${History_Table_Row_Sent_Data_Disabled_BUTTON}=${History_Table_List_ROW}//div[@class="tddiv rh-col5"]//button[@class="btn btn-primary ng-scope btn-slim disabled"]
    ...    ${History_Table_Row_Received_Data_Disabled_BUTTON}=${History_Table_List_ROW}//div[@class="tddiv rh-col6"]//button[@class="btn btn-primary ng-scope btn-slim disabled"]
    ...    ${History_Table_Row_Execute_Request_BUTTON}=${History_Table_List_ROW}//div[@class="tddiv rh-col7"]//button[@ng-click="executeRequest()"]
    ...    ${History_Table_Row_Add_To_Collection_BUTTON}=${History_Table_List_ROW}//div[@class="tddiv rh-col7"]//div[@ng-click="showCollBox(req)"]
    ...    ${History_Table_Row_Fill_Data_Disabled_BUTTON}=${History_Table_List_ROW}//div[@class="tddiv rh-col7"]//button[@class="yangButton iconFillData disabled"]
    ...    ${History_Table_Row_Delete_BUTTON}=${History_Table_List_ROW}//div[@class="tddiv rh-col7"]//button[@class="yangButton iconClose"]
    @{keys}=    Get Dictionary Keys    ${dict}
    :FOR    ${key}    IN    @{keys}      
    \    ${value}=    Get From Dictionary    ${dict}    ${key}
    \    Run Keyword    Verify Element Presence In History Table Row    ${key}     ${value}                 

Step_07_run
    ${Row_NUMBER}=    Set Variable    1
    ${History_Table_List_ROW}=    Set Variable    //div[@ng-repeat="req in requestList.list track by $index"][${Row_NUMBER}]
    ${status}=    Run Keyword And Return Status    Page Should Contain Element    ${History_Table_List_ROW}    
    Run Keyword If    "${status}"=="True"    Click Element    ${Clear_History_Data_BUTTON}
    
    ${status}=    Run Keyword And Return Status    Page Should Contain Element    ${Testing_Root_API_Topology_List_Plus_BUTTON}
    Run Keyword If    "${status}"=="False"    Click Element    ${Testing_Root_API_Network_Topology_Arrow_EXPANDER}
    Wait Until Page Contains Element    ${Testing_Root_API_Topology_List_Plus_BUTTON}    
    Click Element    ${Testing_Root_API_Topology_List_Plus_BUTTON}
    Wait Until Page Contains Element    ${Testing_Root_API_Topology_List_Topology_Id_INPUT}    
    POST ID    ${Testing_Root_API_Topology_List_Topology_Id_INPUT}    ${Topology_Id_0}    ${Topology_ID}    ${Testing_Root_API_Topology_List_NAME}
    
    ${Row_NUMBER}=    Set Variable    1    
    ${History_Table_List_ROW}=    Set Variable    //div[@ng-repeat="req in requestList.list track by $index"][${Row_NUMBER}]
    Verify History Table Row Content    1    ${Post_Method_NAME}    ${Success_STATUS}
    
    ${dict}=    Create Dictionary    
    ...    ${History_Table_Row_Sent_Data_Enabled_BUTTON}=${History_Table_List_ROW}//div[@class="tddiv rh-col5"]//button[@class="btn btn-primary ng-scope btn-slim "]
    ...    ${History_Table_Row_Received_Data_Disabled_BUTTON}=${History_Table_List_ROW}//div[@class="tddiv rh-col6"]//button[@class="btn btn-primary ng-scope btn-slim disabled"]
    ...    ${History_Table_Row_Execute_Request_BUTTON}=${History_Table_List_ROW}//div[@class="tddiv rh-col7"]//button[@ng-click="executeRequest()"]
    ...    ${History_Table_Row_Add_To_Collection_BUTTON}=${History_Table_List_ROW}//div[@class="tddiv rh-col7"]//div[@ng-click="showCollBox(req)"]
    ...    ${History_Table_Row_Fill_Data_Enabled_BUTTON}=${History_Table_List_ROW}//div[@class="tddiv rh-col7"]//button[@class="yangButton iconFillData "]
    ...    ${History_Table_Row_Delete_BUTTON}=${History_Table_List_ROW}//div[@class="tddiv rh-col7"]//button[@class="yangButton iconClose"]
    @{keys}=    Get Dictionary Keys    ${dict}
    :FOR    ${key}    IN    @{keys}      
    \    ${value}=    Get From Dictionary    ${dict}    ${key}
    \    Run Keyword    Verify Element Presence In History Table Row    ${key}     ${value}

Step_08_run
    ${Row_NUMBER}=    Set Variable    1
    ${History_Table_List_ROW}=    Set Variable    //div[@ng-repeat="req in requestList.list track by $index"][${Row_NUMBER}]
    ${status}=    Run Keyword And Return Status    Page Should Contain Element    ${History_Table_List_ROW}    
    Run Keyword If    "${status}"=="True"    Click Element    ${Clear_History_Data_BUTTON}
    
    ${status}=    Run Keyword And Return Status    Page Should Contain Element    ${Testing_Root_API_Topology_List_Plus_BUTTON}
    Run Keyword If    "${status}"=="False"    Click Element    ${Testing_Root_API_Network_Topology_Arrow_EXPANDER}
    
    Wait Until Page Contains Element    ${Testing_Root_API_Topology_List_Plus_BUTTON}    
    Click Element    ${Testing_Root_API_Topology_List_Plus_BUTTON}
    Wait Until Page Contains Element    ${Testing_Root_API_Topology_List_Topology_Id_INPUT}    
    PUT ID    ${Testing_Root_API_Topology_List_Topology_Id_INPUT}    ${Topology_Id_1}    ${Topology_ID}    ${Testing_Root_API_Topology_List_NAME}
    
    ${Row_NUMBER}=    Set Variable    1    
    ${History_Table_List_ROW}=    Set Variable    //div[@ng-repeat="req in requestList.list track by $index"][${Row_NUMBER}]
    Verify History Table Row Content    1    ${Put_Method_NAME}    ${Success_STATUS}
    
    ${dict}=    Create Dictionary    
    ...    ${History_Table_Row_Sent_Data_Enabled_BUTTON}=${History_Table_List_ROW}//div[@class="tddiv rh-col5"]//button[@class="btn btn-primary ng-scope btn-slim "]
    ...    ${History_Table_Row_Received_Data_Disabled_BUTTON}=${History_Table_List_ROW}//div[@class="tddiv rh-col6"]//button[@class="btn btn-primary ng-scope btn-slim disabled"]
    ...    ${History_Table_Row_Execute_Request_BUTTON}=${History_Table_List_ROW}//div[@class="tddiv rh-col7"]//button[@ng-click="executeRequest()"]
    ...    ${History_Table_Row_Add_To_Collection_BUTTON}=${History_Table_List_ROW}//div[@class="tddiv rh-col7"]//div[@ng-click="showCollBox(req)"]
    ...    ${History_Table_Row_Fill_Data_Enabled_BUTTON}=${History_Table_List_ROW}//div[@class="tddiv rh-col7"]//button[@class="yangButton iconFillData "]
    ...    ${History_Table_Row_Delete_BUTTON}=${History_Table_List_ROW}//div[@class="tddiv rh-col7"]//button[@class="yangButton iconClose"]
    @{keys}=    Get Dictionary Keys    ${dict}
    :FOR    ${key}    IN    @{keys}      
    \    ${value}=    Get From Dictionary    ${dict}    ${key}
    \    Run Keyword    Verify Element Presence In History Table Row    ${key}     ${value}               

Step_09_run
    ${Row_NUMBER}=    Set Variable    1
    ${History_Table_List_ROW}=    Set Variable    //div[@ng-repeat="req in requestList.list track by $index"][${Row_NUMBER}]
    ${status}=    Run Keyword And Return Status    Page Should Contain Element    ${History_Table_List_ROW}    
    Run Keyword If    "${status}"=="True"    Click Element    ${Clear_History_Data_BUTTON}
    
    Page Should Contain Element    ${Testing_Root_API_Network_Topology_BUTTON}
    
    Execute Chosen Operation    ${Get_OPERATION}    ${Request_sent_successfully_ALERT}
    
    ${Row_NUMBER}=    Set Variable    1    
    ${History_Table_List_ROW}=    Set Variable    //div[@ng-repeat="req in requestList.list track by $index"][${Row_NUMBER}]
    Verify History Table Row Content    1    ${Get_Method_NAME}    ${Success_STATUS}
    
    ${dict}=    Create Dictionary    
    ...    ${History_Table_Row_Sent_Data_Disabled_BUTTON}=${History_Table_List_ROW}//div[@class="tddiv rh-col5"]//button[@class="btn btn-primary ng-scope btn-slim disabled"]
    ...    ${History_Table_Row_Received_Data_Disabled_BUTTON}=${History_Table_List_ROW}//div[@class="tddiv rh-col6"]//button[@class="btn btn-primary ng-scope btn-slim "]
    ...    ${History_Table_Row_Execute_Request_BUTTON}=${History_Table_List_ROW}//div[@class="tddiv rh-col7"]//button[@ng-click="executeRequest()"]
    ...    ${History_Table_Row_Add_To_Collection_BUTTON}=${History_Table_List_ROW}//div[@class="tddiv rh-col7"]//div[@ng-click="showCollBox(req)"]
    ...    ${History_Table_Row_Fill_Data_Enabled_BUTTON}=${History_Table_List_ROW}//div[@class="tddiv rh-col7"]//button[@class="yangButton iconFillData "]
    ...    ${History_Table_Row_Delete_BUTTON}=${History_Table_List_ROW}//div[@class="tddiv rh-col7"]//button[@class="yangButton iconClose"]
    @{keys}=    Get Dictionary Keys    ${dict}
    :FOR    ${key}    IN    @{keys}      
    \    ${value}=    Get From Dictionary    ${dict}    ${key}
    \    Run Keyword    Verify Element Presence In History Table Row    ${key}     ${value}
    
Step_10_run
    Close DLUX 
    

        


    
           
    
                  