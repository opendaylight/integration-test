*** Settings ***
Documentation     Verification that multiple operations are added to request history list. 
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
${Topology_Id_2}    t2
${Topology_Id_3}    t3
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
    [Documentation]    Execute DELETE operation. Expand network-topology arrow expander
    ...    in custom Container area. Click + button to add new topology id.
    ...    Execute POST operation. Topology id = t0, Topology id = t1
    ...    Execute this step 2times, once with each input value.
    Step_06_run

Step_07
    [Documentation]    Click + button to add new topology id. Execute PUT operation.
    ...    Topology id = t2, Topology id = t3. Execute this step 2times, once with 
    ...    each input value.

    Step_07_run

Step_08
    [Documentation]    Execute GET operation. Execute this step 2times.
    Step_08_run

Step_09
    [Documentation]    Verify, that History table contains all requests that have 
    ...    been executed in previous steps.
    ...    Result
    ...    The page contains 8 requests in History table and Order of the requests is
    ...    [REMOVE | POST | REMOVE | POST | PUT | PUT | GET | GET]"
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
    @{ITEMS}    Create List    ${Topology_Id_0}    ${Topology_Id_1}        
    :FOR    ${ELEMENT}    IN    @{ITEMS}
    \    Execute Chosen Operation    ${Delete_OPERATION}    ${Request_sent_successfully_ALERT}
    \    ${status}=    Run Keyword And Return Status    Page Should Contain Element    ${Testing_Root_API_Topology_List_Plus_BUTTON}
    \    Run Keyword If    "${status}"=="False"    Click Element    ${Testing_Root_API_Network_Topology_Arrow_EXPANDER}
    \    Click Element    ${Testing_Root_API_Topology_List_Plus_BUTTON}      
    \    Wait Until Page Contains Element    ${Testing_Root_API_Topology_List_Topology_Id_INPUT}
    \    POST ID    ${Testing_Root_API_Topology_List_Topology_Id_INPUT}    ${ELEMENT}    ${Topology_ID}    ${Testing_Root_API_Topology_List_NAME}
  
  
Step_07_run
    @{ITEMS}    Create List    ${Topology_Id_2}    ${Topology_Id_3}        
    :FOR    ${ELEMENT}    IN    @{ITEMS}
    \    Click Element    ${Testing_Root_API_Topology_List_Plus_BUTTON}
    \    Wait Until Page Contains Element    ${Testing_Root_API_Topology_List_Topology_Id_INPUT}    
    \    PUT ID    ${Testing_Root_API_Topology_List_Topology_Id_INPUT}    ${ELEMENT}    ${Topology_ID}    ${Testing_Root_API_Topology_List_NAME}               


Step_08_run
     Repeat Keyword    2 times    Execute Chosen Operation    ${GET_OPERATION}    ${Request_sent_successfully_ALERT}


Step_09_run
     ${sum_of_operations_executed}=    Set Variable    8
     ${sum_of_rows}=     Get Matching Xpath Count    ${History_Table_List_Row_ENUM}
     Should Be Equal As Integers    ${sum_of_operations_executed}    ${sum_of_rows}
     @{ITEMS}    Create List    ${Remove_Method_NAME}    ${Post_Method_NAME}    ${Remove_Method_NAME}    ${Post_Method_NAME}
     ...    ${Put_Method_NAME}    ${Put_Method_NAME}   ${Get_Method_NAME}    ${Get_Method_NAME}
     :FOR    ${INDEX}    IN RANGE    1    ${sum_of_rows}
     \    ${Row_NUMBER}=    Set Variable    ${INDEX}
     \    ${History_Table_List_ROW}=    Set Variable    //div[@ng-repeat="req in requestList.list track by $index"][${Row_NUMBER}]
     \    ${History_Table_Row_Method_XPATH}=    Set Variable    ${History_Table_List_ROW}//div[@class="tddiv rh-col2"]/span
     \    ${method}=    Get Text    ${History_Table_Row_Method_XPATH}
     \    ${index}=    Evaluate    ${INDEX}-1    
     \    ${item}=    Get From List    ${ITEMS}    ${index}               
     \    Should Be Equal As Strings    ${item}    ${method}                             
     

Step_10_run
    Close DLUX 
    

        


    
           
    
                  