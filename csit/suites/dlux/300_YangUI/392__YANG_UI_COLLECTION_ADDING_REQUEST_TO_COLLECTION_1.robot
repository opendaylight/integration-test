*** Settings ***
Documentation     Verification that add request to collection box contains certain elements.
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
    ...    history list, click Clear history data
    ...    Result
    ...    The page does not contain History table row.
    Step_04_run
    
Step_05
    [Documentation]    Select DELETE operation and click Send button. Click add request to Collection button.
    ...    Result
    ...    The page should contain:- Request sent successfully msg, - Remove method,
    ...    - URL identical to one in preview box, - status success, - disabled "Sent data" button,
    ...    - disabled "Received data" button, - "Execute request" button, - Add to collection button,
    ...    - disabled "Fill data"  button, - "Delete" button.    
    Step_05_run

Step_06
    [Documentation]    Close add to collection box. If the page contains any request in history list, 
    ...    click Clear history data 
    ...    Result
    ...    The page should not contain any record in History table.
    Step_06_run

Step_07
    [Documentation]    Close DLUX.
    Step_07_run

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
    Click Add To Collection Button    1
    Wait Until Page Contains Element    ${Add_To_Collection_Showed_BOX}
    Page Should Contain Element    ${Add_To_Collection_Box_Close_BUTTON}
    Page Should Contain Element    ${Add_To_Collection_Box_Name_LABEL}
    Page Should Contain Element    ${Add_To_Collection_Box_Name_INPUT}
    Page Should Contain Element    ${Add_To_Collection_Box_Select_Group_LABEL}
    Page Should Contain Element    ${Add_To_Collection_Box_Select_Group_SELECT}
    Page Should Contain Element    ${Add_To_Collection_Box_Group_Name_New_LABEL}
    Page Should Contain Element    ${Add_To_Collection_Box_Group_Name_New_INPUT}
    Page Should Contain Element    ${Add_To_Collection_Box_Add_BUTTON}
    

Step_06_run
    Click Element    ${Add_To_Collection_Box_Close_BUTTON}
    Wait Until Page Contains Element    ${Add_To_Collection_Hidden_BOX}
    If History Table Contains Data Then Clear History Data

    
Step_07_run
    Close DLUX 
    

        


    
           
    
                  