*** Settings ***
Documentation     Verification that Custom API data enables a user to fill whole
...    yang form in customContainer Area at once by inserting data into Custom API Request table.
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
    [Documentation]   Load "network-topology" button in customContainer Area.
    ...    Result
    ...    The page contains "network topology" arrow expander and 
    ...    "network topology " button in customContainer Area. 
    Step_04_run

Step_05
    [Documentation]    Click "network topology" arrow expander in customContainer Area.
    ...    Result
    ...    The page contains "topology list" arrow expander and "topology list" 
    ...    button and iconPlus button in the customContainer Area.  
    Step_05_run    

Step_06
    [Documentation]    Click "topology list" iconPlus to add new topolgy.
    ...    Insert topology-id. Topology-id value: t0 
    ...    Area.
    ...    Result
    ...    The page contains "topology <topology-id: t0>" button and iconClose button.
    Step_06_run

Step_07
    [Documentation]   Click "node list" iconPlus to add new node.
    ...    Insert node-id into input field, choose PUT operation and hit "Send" 
    ...    button. Node-id value: t0n0. Repeat 2 more times with Node-ide 
    ...    values: t0n1, t0n2
    ...    Result
    ...    The page contains "node <node-id: t1n0>" button and iconClose button.
    ...    The page contains "node <node-id: t1n1>" button and iconClose button.
    ...    The page contains "node <node-id: t1n2>" button and iconClose button.
    Step_07_run

Step_08
    [Documentation]   Click "link list" iconPlus to add new link. Insert link-id
    ...    into input field, choose PUT operation and hit "Send" button. 
    ...    Link-ide value: t0l0. Repeat 2 more times with Link-ide values: t0l1, t0l2
    ...    Result
    ...    The page contains "link <link-id: t1l0>" button and iconClose button.
    ...    The page contains "link <link-id: t1l1>" button and iconClose button.
    ...    The page contains "link <link-id: t1l2>" button and iconClose button. 
    Step_08_run  

Step_09
    [Documentation]   Choose PUT operation and click "Show preview" button.
    ...    The page contains: - preview box, - preview box close button,
    ...    - Previewed API http://localhost:8181/restconf/config/network-topology:network-topology
    Step_09_run
    
Step_10
    [Documentation]    Get the content of Preview box. Split the content into 
    ...    lines, first line being the API path, other lines being the API data.
    ...    Close Preview box and click "topology <topology-id: t0>" iconClose button. 
    ...    Result
    ...    Page does not contain topology-id input, node-id input and link-id input.   
    Step_10_run
    
Step_11
    [Documentation]    Click "Custom API request" button.
    ...    Result
    ...    The page contains: - custom api request box, - api path input, - api data input.   
    Step_11_run

Step_12
    [Documentation]    Insert API path line from step 10 to API to api path input
    ...    field. Insert API data lines from step 10 to api data input field.
    ...    Click "Push config" button. Click Close Custom API request box.
    ...    Result
    ...    The page contains: 
    ...    - "topology <topology-id: t0>" button and iconClose button;
    ...    - "node <node-id: t1n0>" button and iconClose button;
    ...    - "node <node-id: t1n1>" button and iconClose button;
    ...    - "node <node-id: t1n2>" button and iconClose button;
    ...    - "link <link-id: t1l0>" button and iconClose button;
    ...    - "link <link-id: t1l1>" button and iconClose button;
    ...    - "link <link-id: t1l2>" button and iconClose button.
    Step_12_run    

Step_13
    [Documentation]    Close Dlux.
    Step_13_run


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
    Click Element    ${Testing_Root_API_Network_Topology_Arrow_EXPANDER}
    Wait Until Page Contains Element    ${Testing_Root_API_Topology_List_BUTTON}
    Page Should Contain Element    ${Testing_Root_API_Topology_List_Arrow_EXPANDER}
    Page Should Contain Element    ${Testing_Root_API_Topology_List_Plus_BUTTON}
    
Step_06_run
    Click Element    ${Testing_Root_API_Topology_List_Plus_BUTTON}
    Page Should Contain Element    ${Testing_Root_API_Topology_List_Topology_Id_INPUT}        
    ${input_field}=    Set Variable    ${Testing_Root_API_Topology_List_Topology_Id_INPUT}
    ${Chosen_Id}=    Set Variable    ${Topology_Id_0}    
    Focus    ${input_field}
    Clear Element Text    ${input_field}    
    Input Text    ${input_field}    ${Chosen_Id}
    ${Topology_ID}=    Set Variable    ${Chosen_Id}
    ${Testing_Root_API_Topology_List_Topology_Id_BUTTON}=    Set Variable    //button[contains(text(), "${Testing_Root_API_Topology_List_NAME}") and contains(text(),"${Topology_ID}")]    
    Page Should Contain Element    ${Testing_Root_API_Topology_List_Topology_Id_BUTTON}
    ${Testing_Root_API_Topology_List_Topology_Delete_BUTTON}=     Set Variable    ${Testing_Root_API_Topology_List_Topology_Id_BUTTON}/following::${Delete_BUTTON}
    Page Should Contain Element    ${Testing_Root_API_Topology_List_Topology_Delete_BUTTON}

Step_07_run
    ${input_field}=    Set Variable    ${Testing_Root_API_Node_List_Node_Id_INPUT}
    @{node_ids_list}    Create List    ${Node_Id_0}    ${Node_Id_1}    ${Node_Id_2}
    :FOR    ${ELEMENT}   IN    @{node_ids_list}
    \    Click Element    ${Testing_Root_API_Node_List_Plus_BUTTON}
    \    Page Should Contain Element    ${Testing_Root_API_Node_List_Node_Id_INPUT}
    \    ${Chosen_Id}=    Set Variable    ${ELEMENT}
    \    Focus    ${input_field}
    \    Clear Element Text    ${input_field}
    \    Input Text    ${input_field}    ${Chosen_Id}
    \    ${Node_ID}=    Set Variable    ${Chosen_Id}
    \    ${Testing_Root_API_Node_List_Node_Id_BUTTON}=    Set Variable    //button[contains(text(), "${Testing_Root_API_Node_List_NAME}") and contains(text(),"${Node_ID}")]
    \    Page Should Contain Element    ${Testing_Root_API_Node_List_Node_Id_BUTTON}
    \    ${Testing_Root_API_Node_List_Node_Delete_BUTTON}=    Set Variable    ${Testing_Root_API_Node_List_Node_Id_BUTTON}/following::${Delete_BUTTON}
    \    Page Should Contain Element    ${Testing_Root_API_Node_List_Node_Delete_BUTTON}                         
          
Step_08_run
    ${input_field}=    Set Variable    ${Testing_Root_API_Link_List_Link_Id_INPUT}
    @{link_ids_list}    Create List    ${Link_Id_0}    ${Link_Id_1}    ${Link_Id_2}
    :FOR    ${ELEMENT}   IN    @{link_ids_list}
    \    Click Element    ${Testing_Root_API_Link_List_Plus_BUTTON}
    \    Page Should Contain Element    ${Testing_Root_API_Link_List_Link_Id_INPUT}
    \    ${Chosen_Id}=    Set Variable    ${ELEMENT}
    \    Focus    ${input_field}
    \    Clear Element Text    ${input_field}
    \    Input Text    ${input_field}    ${Chosen_Id}
    \    ${Link_ID}=    Set Variable    ${Chosen_Id}
    \    ${Testing_Root_API_Link_List_Link_Id_BUTTON}=    Set Variable    //button[contains(text(), "${Testing_Root_API_Link_List_NAME}") and contains(text(),"${Link_ID}")]
    \    Page Should Contain Element    ${Testing_Root_API_Link_List_Link_Id_BUTTON}
    \    ${Testing_Root_API_Link_List_Link_Delete_BUTTON}=    Set Variable    ${Testing_Root_API_Link_List_Link_Id_BUTTON}/following::${Delete_BUTTON}
    \    Page Should Contain Element    ${Testing_Root_API_Link_List_Link_Delete_BUTTON}

Step_09_run    
    Select Chosen Operation    ${Put_OPERATION}
    Click Element    ${Show_Preview_BUTTON}
    Wait Until Page Contains Element    ${Preview_BOX}
    Page Should Contain Element    ${Preview_Box_Close_BUTTON}
    ${Previewed_API}=    Set Variable    ${CONFIG_TOPO_API}
    ${Preview_Box_Displayed_API}    Set Variable    ${Preview_BOX}/div/pre[contains(text(),"${Previewed_API}")]    # Redundant setting of variable; value of variable set in variables resource document is not somehow recognized by robot framework
    Page Should Contain Element    ${Preview_Box_Displayed_API}

Step_10_run
    ${previewed_content}=    Get Text    ${Preview_Box_Displayed_CONTENT}
    ${api_path}=    Fetch From Left    ${previewed_content}    {
    ${api_data}=    Fetch From Right    ${previewed_content}    ${api_path}
    ${Api_Path}=    Set Suite Variable    ${api_path}
    ${Api_Data}=    Set Suite Variable    ${api_data}        
    Click Element    ${Testing_Root_API_Topology_List_Topology_Delete_BUTTON}
    Page Should Not Contain Element    ${Testing_Root_API_Topology_List_Topology_Id_INPUT}    
    Page Should Not Contain Element    ${Testing_Root_API_Node_List_Node_Id_INPUT}
    Page Should Not Contain Element    ${Testing_Root_API_Link_List_Link_Id_INPUT}
    
Step_11_run
    Click Element    ${Custom_API_request_BUTTON}
    Page Should Contain Element    ${Custom_API_Request_BOX}
    Page Should Contain Element    ${Custom_API_Request_API_Path_INPUT}
    Page Should Contain Element    ${Custom_API_Request_API_Data_INPUT}
    
Step_12_run
    Input Text    ${Custom_API_Request_API_Path_INPUT}    ${Api_Path}
    Input Text    ${Custom_API_Request_API_Data_INPUT}    ${Api_Data}
    Mouse Over    ${Custom_API_Request_Push_Config_BUTTON}    
    Click Element    ${Custom_API_Request_Push_Config_BUTTON}
    
    ${Topology_ID}=    Set Variable    ${Topology_Id_0}
    ${Testing_Root_API_Topology_List_Topology_Id_BUTTON}=    Set Variable    //button[contains(text(), "${Testing_Root_API_Topology_List_NAME}") and contains(text(),"${Topology_ID}")]    
    Wait Until Page Contains Element    ${Testing_Root_API_Topology_List_Topology_Id_BUTTON}
    ${Testing_Root_API_Topology_List_Topology_Delete_BUTTON}=     Set Variable    ${Testing_Root_API_Topology_List_Topology_Id_BUTTON}/following::${Delete_BUTTON}
    Page Should Contain Element    ${Testing_Root_API_Topology_List_Topology_Delete_BUTTON}
    Click Element    ${Custom_API_Request_Box_Close_BUTTON}
    
    @{node_ids_list}    Create List    ${Node_Id_0}    ${Node_Id_1}    ${Node_Id_2}
    :FOR    ${ELEMENT}   IN    @{node_ids_list}
    \    ${Node_ID}=    Set Variable    ${ELEMENT}
    \    ${Testing_Root_API_Node_List_Node_Id_BUTTON}=    Set Variable    //button[contains(text(), "${Testing_Root_API_Node_List_NAME}") and contains(text(),"${Node_ID}")]
    \    Page Should Contain Element    ${Testing_Root_API_Node_List_Node_Id_BUTTON}
    \    ${Testing_Root_API_Node_List_Node_Delete_BUTTON}=    Set Variable    ${Testing_Root_API_Node_List_Node_Id_BUTTON}/following::${Delete_BUTTON}
    \    Page Should Contain Element    ${Testing_Root_API_Node_List_Node_Delete_BUTTON}
    
    @{link_ids_list}    Create List    ${Link_Id_0}    ${Link_Id_1}    ${Link_Id_2}
    :FOR    ${ELEMENT}   IN    @{link_ids_list}
    \    ${Link_ID}=    Set Variable    ${ELEMENT}
    \    ${Testing_Root_API_Link_List_Link_Id_BUTTON}=    Set Variable    //button[contains(text(), "${Testing_Root_API_Link_List_NAME}") and contains(text(),"${Link_ID}")]
    \    Page Should Contain Element    ${Testing_Root_API_Link_List_Link_Id_BUTTON}
    \    ${Testing_Root_API_Link_List_Link_Delete_BUTTON}=    Set Variable    ${Testing_Root_API_Link_List_Link_Id_BUTTON}/following::${Delete_BUTTON}
    \    Page Should Contain Element    ${Testing_Root_API_Link_List_Link_Delete_BUTTON}

Step_13_run
    Close DLUX
                  