*** Settings ***
Documentation     Verification that "PUT" operation rewrites an ID by the same ID
...    and does not return any error message. 
#Library           Selenium2Library    timeout=10    implicit_wait=10     run_on_failure=Log Source
Library           Selenium2Library    timeout=10    implicit_wait=10     
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
${Node_Id_0}    t0n0
${Link_Id_0}    t0l0
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
    [Documentation]   Load "network-topology" button in customContainer Area.
    ...    Result
    ...    The page contains "network topology" arrow expander and "network topology"
    ...    button in customContainer Area.
    Step_04_run

Step_05
    [Documentation]    Execute PUT operation.
    ...    Result
    ...    The page contains Error sending request - : Input is required. 
    Step_05_run    

Step_06
    [Documentation]    Click "network topology" arrow expander in customContainer Area.
    ...    Result
    ...    The page contains "topology list" arrow expander and "topology list"
    ...    button and iconPlus button in the customContainer Area.
    Step_06_run 


Step_07
    [Documentation]   Click "topology list" iconPlus to add new topolgy.
    ...    Area.
    ...    Result
    ...    "The page contains: - "topology [0]" button, - iconClose button (X button),
    ...    - input field (for topology id)."
    Step_07_run

Step_08
    [Documentation]   Insert topolgy-id, choose PUT operation and hit "Send" button.
    ...    Topology-id value: ${EMPTY}
    ...    Result
    ...    The page contains "RError sending request - : Error parsing input: 
    ...    Input is missing some of the keys of" message and "topology [0]" button 
    ...    and iconClose button.
    Step_08_run

Step_09
    [Documentation]    Close Dlux or Close Browser.
    Step_09_run


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
    Execute Chosen Operation    ${Put_OPERATION}    ${Error_sending_request_Input_is_required_ALERT}
    
        
Step_06_run    
    Click Element    ${Testing_Root_API_Network_Topology_Arrow_EXPANDER}
    Wait Until Page Contains Element    ${Testing_Root_API_Topology_List_BUTTON}
    Page Should Contain Element    ${Testing_Root_API_Topology_List_Arrow_EXPANDER}
    Page Should Contain Element    ${Testing_Root_API_Topology_List_Plus_BUTTON}

    
Step_07_run
    Click Element    ${Testing_Root_API_Topology_List_Plus_BUTTON}
    ${Topology_ID}=    Set Variable    ${Default_ID}     
    
    Wait Until Page Contains Element    ${Testing_Root_API_Topology_List_Topology_Id_BUTTON}    
    Page Should Contain Element    ${Testing_Root_API_Topology_List_Topology_Delete_BUTTON}
    Page Should Contain Element    ${Testing_Root_API_Topology_List_Topology_Id_INPUT}
    
  
Step_08_run
    Focus    ${Testing_Root_API_Topology_List_Topology_Id_INPUT}
    Clear Element Text    ${Testing_Root_API_Topology_List_Topology_Id_INPUT}    
    Input Text    ${Testing_Root_API_Topology_List_Topology_Id_INPUT}    ${EMPTY}
    Sleep    1
    Execute Chosen Operation    ${Put_OPERATION}    ${Error_sending_request_Error_parsing_input_missing_keys_ALERT}
  
          
Step_09_run    
    Close DLUX

                  