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
    [Documentation]   Load "netowork-topology" button in customContainer Area.
    ...    Result
    ...    The page contains "network-tolopogy" plus expander (3rd level
    ...    of tree rows) and "network-tpology" element in API tree. The page contains
    ...    "network-topology" arrow expander and "network-topology" button in customContainer Area. 
    Step_03_run

Step_04
    [Documentation]    Click HISTORY tab. If the page contains any request in 
    ...    history list, click Clear history data
    ...    Result
    ...    The page does not contain History table row.
    Step_04_run

    
Step_05
    [Documentation]    Execute DELETE operation. Expand network-topology arrow expander
    ...    in custom Container area. Click + button to add new topology id.
    ...    Execute POST operation. Topology id = t0, Topology id = t1
    ...    Execute this step 2times, once with each input value.
    Step_05_run

Step_06
    [Documentation]    Click + button to add new topology id. Execute PUT operation.
    ...    Topology id = t2, Topology id = t3. Execute this step 2times, once with 
    ...    each input value.
    Step_06_run

Step_07
    [Documentation]    Execute GET operation. Execute this step 2times.
    Step_07_run

Step_08
    [Documentation]    Verify, that History table contains all requests that have 
    ...    been executed in previous steps.
    ...    Result
    ...    The page contains 8 requests in History table and Order of the requests is
    ...    [REMOVE | POST | REMOVE | POST | PUT | PUT | GET | GET]"
    Step_08_run    

Step_09
    [Documentation]    Close DLUX.
    Step_09_run

*** Keywords ***
Step_01_run
    Launch Or Open DLUX Page And Login DLUX


Step_02_run
    Navigate To Yang UI Submenu


Step_03_run
    Load Network-topology Button In CustomContainer Area
    
    
Step_04_run 
    Click Element    ${HISTORY_TAB}
    If History Table Contains Data Then Clear History Data


Step_05_run
    @{ITEMS}    Create List    ${Topology_Id_0}    ${Topology_Id_1}        
    :FOR    ${ELEMENT}    IN    @{ITEMS}
    \    Execute Chosen Operation    ${Delete_OPERATION}    ${Request_sent_successfully_ALERT}
    \    ${status}=    Run Keyword And Return Status    Page Should Contain Element    ${Testing_Root_API_Topology_List_Plus_BUTTON}
    \    Run Keyword If    "${status}"=="False"    Click Element    ${Testing_Root_API_Network_Topology_Arrow_EXPANDER}
    \    Click Element    ${Testing_Root_API_Topology_List_Plus_BUTTON}      
    \    Wait Until Page Contains Element    ${Testing_Root_API_Topology_List_Topology_Id_INPUT}
    \    POST ID    ${Testing_Root_API_Topology_List_Topology_Id_INPUT}    ${ELEMENT}    ${Topology_ID}    ${Testing_Root_API_Topology_List_NAME}
  
  
Step_06_run
    @{ITEMS}    Create List    ${Topology_Id_2}    ${Topology_Id_3}        
    :FOR    ${ELEMENT}    IN    @{ITEMS}
    \    Click Element    ${Testing_Root_API_Topology_List_Plus_BUTTON}
    \    Wait Until Page Contains Element    ${Testing_Root_API_Topology_List_Topology_Id_INPUT}    
    \    PUT ID    ${Testing_Root_API_Topology_List_Topology_Id_INPUT}    ${ELEMENT}    ${Topology_ID}    ${Testing_Root_API_Topology_List_NAME}               


Step_07_run
     Repeat Keyword    2 times    Execute Chosen Operation    ${GET_OPERATION}    ${Request_sent_successfully_ALERT}


Step_08_run
     ${sum_of_operations_executed}=    Set Variable    8
     ${sum_of_rows}=     Get Matching Xpath Count    ${History_Table_List_Row_ENUM}
     Should Be Equal As Integers    ${sum_of_operations_executed}    ${sum_of_rows}
     @{ITEMS}    Create List    ${Remove_Method_NAME}    ${Post_Method_NAME}    ${Remove_Method_NAME}    ${Post_Method_NAME}
     ...    ${Put_Method_NAME}    ${Put_Method_NAME}   ${Get_Method_NAME}    ${Get_Method_NAME}
     :FOR    ${INDEX}    IN RANGE    1    ${sum_of_rows}
     \    ${Row_NUMBER}=    Set Variable    ${INDEX}
     \    ${History_Table_List_ROW}=    Set Variable    ${History_TABLE}//div[@ng-repeat="req in requestList.list track by $index"][${Row_NUMBER}]
     \    ${History_Table_Row_Method_XPATH}=    Set Variable    ${History_Table_List_ROW}//div[@class="tddiv rh-col2"]/span
     \    ${method}=    Get Text    ${History_Table_Row_Method_XPATH}
     \    ${index}=    Evaluate    ${INDEX}-1    
     \    ${item}=    Get From List    ${ITEMS}    ${index}               
     \    Should Be Equal As Strings    ${item}    ${method}                             
     

Step_09_run
    Close DLUX 
    

        


    
           
    
                  