*** Settings ***
Documentation     Verification that "GET" operation is executed successfully
...    on selected levels of a network-topology. 
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
    [Documentation]   Expand chosen testing root API. Expand "config" plus 
    ...    expander under chosen testing root API.
    ...    Result
    ...    The page contains "network-tolopogy" plus expander (3rd level
    ...    of tree rows) and "network-tpology" element in API tree.
    Step_04_run

Step_05
    [Documentation]    Click "network-topology" element in API tree.
    ...    Result
    ...    The page contains "network-topology" arrow expander and "network-topology"  
    ...    button in customContainer Area. 
    Step_05_run    

Step_06
    [Documentation]    Choose GET operation and hit "Send" button.
    ...    Result
    ...    The page contains:
    ...    - "topology <topology-id: t0>" button and iconClose button;
    ...    - "node <node-id: t1n0>" button and iconClose button;
    ...    - "link <link-id: t1l0>" button and iconClose button;
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

Step_03_run
    Click Element    ${Yang_UI_SUBMENU}
    Wait Until Page Contains Element    ${Loading_completed_successfully_ALERT}
    Click Element    ${Alert_Close_BUTTON}    
    Location Should Be    ${Yang_UI_Submenu_URL}

Step_04_run
    Click Element    ${Testing_Root_API_EXPANDER}
    Wait Until Page Contains Element    ${Testing_Root_API_Config_EXPANDER}
    Click Element    ${Testing_Root_API_Config_EXPANDER}
    Wait Until Page Contains Element    ${Testing_Root_API_Network_Topology_Plus_EXPANDER}
    
Step_05_run
    Click Element    ${Testing_Root_API_Network_Topology_XPATH}
    Wait Until Page Contains Element    ${Testing_Root_API_Network_Topology_BUTTON}
    Page Should Contain Button    ${Testing_Root_API_Network_Topology_Arrow_EXPANDER}
    
Step_06_run 
    Click Element    ${Operation_Select_BOX}
    Wait Until Page Contains Element    ${Get_OPERATION}
    Click Element    ${Get_OPERATION}
    Click Element    ${Action_Buttons_DIV}
    Focus    ${Send_BUTTON}
    Click Element    ${Send_BUTTON}
    
    Verify Chosen_Id Presence On The Page    ${Topology_Id_0}    ${Topology_ID}    ${Testing_Root_API_Topology_List_NAME}
    
    Verify Chosen_Id Presence On The Page    ${Node_Id_0}    ${Node_ID}    ${Testing_Root_API_Node_List_NAME}
        
    Verify Chosen_Id Presence On The Page    ${Link_Id_0}    ${Link_ID}    ${Testing_Root_API_Link_List_NAME}
        
Step_07_run
    Close DLUX
    
           
    
                  