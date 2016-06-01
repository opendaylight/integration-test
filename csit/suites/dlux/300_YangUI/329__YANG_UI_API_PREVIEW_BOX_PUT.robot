*** Settings ***
Documentation     Verification that there is correct content showed in Preview
...    box in case of PUT operation.
Library           Selenium2Library    timeout=10    implicit_wait=10    
#Library    Selenium2Library    timeout=10    implicit_wait=10
...               #run_on_failure=Log Source
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
    [Documentation]    Load Network-topology Button in customContainer Area
    ...    Result
    ...    The page contains "network topology" arrow expander and
    ...    "network topology " button in customContainer Area.
    Step_03_run

Step_04
    [Documentation]    Select "Put" operation and click "Show preview" button.
    ...    Result
    ...    The page contains: - preview box, - preview box close button,
    ...    - Previewed API http://localhost:8181/restconf/config/network-topology:network-topology,
    ...    - {}.
    Step_04_run

Step_05
    [Documentation]    Close preview box. Click "network topology" plus expander.
    ...    Result
    ...    The page contains "topology {topology-id}" plus expander and
    ...    "topology {topology-id}" element in API tree.
    Step_05_run

Step_06
    [Documentation]    Click "topology {topology-id}" element in API tree. Click
    ...    "topology list" iconPlus, insert Chosen topology Id, select Put operation
    ...    and click "Show preview" button. Topology Id: t0
    ...    Result
    ...    The page contains: - preview box, - previewed API
    ...    http://localhost:8181/restconf/config/network-topology:network-topology/topology/t0,
    ...    - { "topology": [ {  "topology-id": "t0",
    Step_06_run

Step_07
    [Documentation]    Close preview box. Click "topology {topology-id}" plus 
    ...    expander in API tree. Click "node {node-id}" element in API tree.
    ...    Click "node list" iconPlus, insert topology id and Chosen node Id into
    ...    path wrapper input fields. , select Put operation and click "Show preview" button.
    ...    Topology Id: "" (Empty string), Node Id: t0n0
    ...    Result
    ...    The page contains: - preview box, - previewed API
    ...    http://localhost:8181/restconf/config/network-topology:network-topology/topology//node/t0n0
    ...    - { "node": [ { "node-id": "t0n0" } 
    Step_07_run

Step_08
    [Documentation]    Close preview box. Click "link {link-id}" element in API tree.
    ...    Click "link list" iconPlus, insert topology id and Chosen link Id into
    ...    path wrapper input fields. Select Put operation and click "Show preview" button.
    ...    Topology Id: "" (Empty string), Link Id: t0l0
    ...    Result
    ...    The page contains: - preview box, - previewed API
    ...    http://localhost:8181/restconf/config/network-topology:network-topology/topology//link/t0l0
    Step_08_run

Step_09
    [Documentation]    Close preview box. Click "node {node-id}" element in API tree.
    ...    Click "node list" iconPlus, insert topology id and node id into path
    ...    wrapper input fields. Select Put operation and click "Show preview" button.
    ...    Topology Id: t0, Node Id: t0n0
    ...    Result
    ...    The page contains: - preview box, - previewed API
    ...    http://localhost:8181/restconf/config/network-topology:network-topology/topology/t0/node/t0n0
    ...    - { "node": [ { "node-id": "t0n0" }
    Step_09_run

Step_10
    [Documentation]    Close preview box. Click "link {link-id}" element in API tree.
    ...    Click "link list" iconPlus, insert topology id and link id into path
    ...    wrapper input fields. Select Put operation and click "Show preview" button.
    ...    Topology Id: t0, Link Id: t0n0
    ...    Result
    ...    The page contains: - preview box, - previewed API
    ...    http://localhost:8181/restconf/config/network-topology:network-topology/topology/t0/link/t0l0
    ...    - { "link": [ { "link-id": "t0l0" }
    Step_10_run

Step_11
    [Documentation]    Close DLUX.
    Step_11_run

*** Keywords ***
Step_01_run
    Launch Or Open DLUX Page And Login DLUX


Step_02_run
    Navigate To Yang UI Submenu

Step_03_run
    Load Network-topology Button In CustomContainer Area

Step_04_run
    Select Chosen Operation    ${Put_OPERATION}
    Click Element    ${Show_Preview_BUTTON}
    Wait Until Page Contains Element    ${Preview_BOX}
    Page Should Contain Element    ${Preview_Box_Close_BUTTON}
    ${Previewed_API}=    Set Variable    ${CONFIG_TOPO_API}
    ${Preview_Box_Displayed_API}    Set Variable    ${Preview_BOX}/div/pre[contains(text(),"${Previewed_API}")]    # Redundant setting of variable; value of variable set in variables resource document is not somehow recognized by robot framework
    Page Should Contain Element    ${Preview_Box_Displayed_API}
    ${Previewed_LIST}=    Set Variable    ${Network_Topology_Put_Preview_LIST}
    ${Preview_Box_Displayed_LIST}=    Set Variable    ${Preview_BOX}/div/pre[${Previewed_LIST}]        
    Page Should Contain Element    ${Preview_Box_Displayed_LIST}            

Step_05_run
    Click Element    ${Preview_Box_Close_BUTTON}
    Click Element    ${Testing_Root_API_Network_Topology_Plus_EXPANDER}
    Wait Until Page Contains Element    ${Testing_Root_API_Topology_Topology_Id_Plus_EXPANDER}

Step_06_run
    Click Element    ${Testing_Root_API_Topology_Topology_Id_XPATH}
    Wait Until Page Contains Element    ${Testing_Root_API_Topology_List_Plus_BUTTON}
    Click Element    ${Testing_Root_API_Topology_List_Plus_BUTTON}
    Input Text     ${Testing_Root_API_Topology_List_Topology_Id_INPUT}    ${Topology_Id_0}
    Select Chosen Operation    ${Put_OPERATION}
    Click Element    ${Show_Preview_BUTTON}
    Wait Until Page Contains Element    ${Preview_BOX}
    Page Should Contain Element    ${Preview_Box_Close_BUTTON}
    
    ${Topology_ID}=   Set Variable    ${Topology_Id_0}
    ${CONFIG_TOPO_TOPOLOGY_ID_API}=    Set Variable    :${RESTCONFPORT}${CONFIG_TOPO_API}/${Testing_Root_API_Topology_NAME}/${Topology_ID}
    ${Previewed_API}=    Set Variable    ${CONFIG_TOPO_TOPOLOGY_ID_API}    
    ${Preview_Box_Displayed_API}    Set Variable    ${Preview_BOX}/div/pre[contains(text(),"${Previewed_API}")]    
    Page Should Contain Element    ${Preview_Box_Displayed_API}
    ${Topology_Put_Preview_LIST}=    Set Variable    contains(text(), "${Testing_Root_API_Topology_NAME}") and contains(text(), "${Testing_Root_API_Topology_Id_NAME}") and contains(text(), "${Topology_ID}")    
    ${Previewed_LIST}=    Set Variable    ${Topology_Put_Preview_LIST}
    ${Preview_Box_Displayed_LIST}=    Set Variable    ${Preview_BOX}/div/pre[${Previewed_LIST}]        
    Page Should Contain Element    ${Preview_Box_Displayed_LIST}       

Step_07_run
    Click Element    ${Preview_Box_Close_BUTTON}
    Click Element    ${Testing_Root_API_Topology_Topology_Id_Plus_EXPANDER}
    Wait Until Page Contains Element    ${Testing_Root_API_Node_Node_Id_Plus_EXPANDER}
    Click Element    ${Testing_Root_API_Node_Node_Id_XPATH}
    Wait Until Page Contains Element    ${Testing_Root_API_Node_List_Plus_BUTTON}
    Click Element    ${Testing_Root_API_Node_List_Plus_BUTTON}
    Input Text    ${Topology_Id_Path_Wrapper_INPUT}    ${EMPTY}
    Input Text    ${Node_Id_Path_Wrapper_INPUT}    ${Node_Id_0}
    Select Chosen Operation    ${Put_OPERATION}
    Click Element    ${Show_Preview_BUTTON}
    Wait Until Page Contains Element    ${Preview_BOX}
    Page Should Contain Element    ${Preview_Box_Close_BUTTON}
    
    ${Topology_ID}=    Set Variable    ${EMPTY}
    ${Node_ID}=   Set Variable    ${Node_Id_0}
    ${CONFIG_TOPO_NODE_ID_API}=    Set Variable    :${RESTCONFPORT}${CONFIG_TOPO_API}/${Testing_Root_API_Topology_NAME}/${Topology_ID}/${Testing_Root_API_Node_NAME}/${Node_ID}
    ${Previewed_API}=    Set Variable    ${CONFIG_TOPO_NODE_ID_API}    
    ${Preview_Box_Displayed_API}    Set Variable    ${Preview_BOX}/div/pre[contains(text(),"${Previewed_API}")]    
    Page Should Contain Element    ${Preview_Box_Displayed_API}
    ${Node_Put_Preview_LIST}=    Set Variable    contains(text(), "${Testing_Root_API_Node_NAME}") and contains(text(), "${Testing_Root_API_Node_Id_NAME}") and contains(text(), "${Node_ID}")    
    ${Previewed_LIST}=    Set Variable    ${Node_Put_Preview_LIST}
    ${Preview_Box_Displayed_LIST}=    Set Variable    ${Preview_BOX}/div/pre[${Previewed_LIST}]        
    Page Should Contain Element    ${Preview_Box_Displayed_LIST}
    
    
Step_08_run
    Click Element    ${Preview_Box_Close_BUTTON}
    Click Element    ${Testing_Root_API_LinkLink_Id_XPATH}
    Wait Until Page Contains Element    ${Testing_Root_API_Link_List_Plus_BUTTON}
    Click Element    ${Testing_Root_API_Link_List_Plus_BUTTON}
    Input Text     ${Testing_Root_API_Link_List_Link_Id_INPUT}    ${Link_Id_0}
    Select Chosen Operation    ${Put_OPERATION}
    Click Element    ${Show_Preview_BUTTON}
    Wait Until Page Contains Element    ${Preview_BOX}
    Page Should Contain Element    ${Preview_Box_Close_BUTTON}
    
    ${Topology_ID}=    Set Variable    ${EMPTY}
    ${Link_ID}=   Set Variable    ${Link_Id_0}
    ${CONFIG_TOPO_LINK_ID_API}=    Set Variable    :${RESTCONFPORT}${CONFIG_TOPO_API}/${Testing_Root_API_Topology_NAME}/${Topology_ID}/${Testing_Root_API_Link_NAME}/${Link_ID}
    ${Previewed_API}=    Set Variable    ${CONFIG_TOPO_LINK_ID_API}    
    ${Preview_Box_Displayed_API}    Set Variable    ${Preview_BOX}/div/pre[contains(text(),"${Previewed_API}")]    
    Page Should Contain Element    ${Preview_Box_Displayed_API}
    ${Link_Put_Preview_LIST}=    Set Variable    contains(text(), "${Testing_Root_API_Link_NAME}") and contains(text(), "${Testing_Root_API_Link_Id_NAME}") and contains(text(), "${Link_ID}")    
    ${Previewed_LIST}=    Set Variable    ${Link_Put_Preview_LIST}
    ${Preview_Box_Displayed_LIST}=    Set Variable    ${Preview_BOX}/div/pre[${Previewed_LIST}]        
    Page Should Contain Element    ${Preview_Box_Displayed_LIST}

Step_09_run
    Click Element    ${Preview_Box_Close_BUTTON}
    Click Element    ${Testing_Root_API_Node_Node_Id_XPATH}
    Wait Until Page Contains Element    ${Testing_Root_API_Node_List_Plus_BUTTON}
    Click Element    ${Testing_Root_API_Node_List_Plus_BUTTON}    
    Input Text    ${Topology_Id_Path_Wrapper_INPUT}    ${Topology_Id_0}
    Input Text    ${Node_Id_Path_Wrapper_INPUT}    ${Node_Id_0}
    Select Chosen Operation    ${Put_OPERATION}
    Click Element    ${Show_Preview_BUTTON}
    Wait Until Page Contains Element    ${Preview_BOX}
    Page Should Contain Element    ${Preview_Box_Close_BUTTON}
    
    ${Topology_ID}=    Set Variable    ${Topology_Id_0}
    ${Node_ID}=   Set Variable    ${Node_Id_0}
    ${CONFIG_TOPO_NODE_ID_API}=    Set Variable    :${RESTCONFPORT}${CONFIG_TOPO_API}/${Testing_Root_API_Topology_NAME}/${Topology_ID}/${Testing_Root_API_Node_NAME}/${Node_ID}
    ${Previewed_API}=    Set Variable    ${CONFIG_TOPO_NODE_ID_API}    
    ${Preview_Box_Displayed_API}    Set Variable    ${Preview_BOX}/div/pre[contains(text(),"${Previewed_API}")]    
    Page Should Contain Element    ${Preview_Box_Displayed_API}
    ${Node_Put_Preview_LIST}=    Set Variable    contains(text(), "${Testing_Root_API_Node_NAME}") and contains(text(), "${Testing_Root_API_Node_Id_NAME}") and contains(text(), "${Node_ID}")    
    ${Previewed_LIST}=    Set Variable    ${Node_Put_Preview_LIST}
    ${Preview_Box_Displayed_LIST}=    Set Variable    ${Preview_BOX}/div/pre[${Previewed_LIST}]        
    Page Should Contain Element    ${Preview_Box_Displayed_LIST}    

Step_10_run
    Click Element    ${Preview_Box_Close_BUTTON}
    Click Element    ${Testing_Root_API_Link_Link_Id_XPATH}
    Wait Until Page Contains Element    ${Testing_Root_API_Link_List_Plus_BUTTON}
    Click Element    ${Testing_Root_API_Link_List_Plus_BUTTON}
    Input Text    ${Topology_Id_Path_Wrapper_INPUT}    ${Topology_Id_0}
    Input Text    ${Link_Id_Path_Wrapper_INPUT}    ${Link_Id_0}
    Select Chosen Operation    ${Put_OPERATION}
    Click Element    ${Show_Preview_BUTTON}
    Wait Until Page Contains Element    ${Preview_BOX}
    Page Should Contain Element    ${Preview_Box_Close_BUTTON}
    
    ${Topology_ID}=    Set Variable    ${Topology_Id_0}
    ${Link_ID}=   Set Variable    ${Link_Id_0}
    ${CONFIG_TOPO_LINK_ID_API}=    Set Variable    :${RESTCONFPORT}${CONFIG_TOPO_API}/${Testing_Root_API_Topology_NAME}/${Topology_ID}/${Testing_Root_API_Link_NAME}/${Link_ID}
    ${Previewed_API}=    Set Variable    ${CONFIG_TOPO_LINK_ID_API}    
    ${Preview_Box_Displayed_API}    Set Variable    ${Preview_BOX}/div/pre[contains(text(),"${Previewed_API}")]    
    Page Should Contain Element    ${Preview_Box_Displayed_API}
    ${Link_Put_Preview_LIST}=    Set Variable    contains(text(), "${Testing_Root_API_Link_NAME}") and contains(text(), "${Testing_Root_API_Link_Id_NAME}") and contains(text(), "${Link_ID}")    
    ${Previewed_LIST}=    Set Variable    ${Link_Put_Preview_LIST}
    ${Preview_Box_Displayed_LIST}=    Set Variable    ${Preview_BOX}/div/pre[${Previewed_LIST}]        
    Page Should Contain Element    ${Preview_Box_Displayed_LIST}
    

Step_11_run
    Close DLUX
