*** Settings ***
Documentation     Verification that "GET" operation is not executed when there is no data 
...    in network-topology, and no data is inserted in key input fields.
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
    [Documentation]    Execute Delete operation.
    ...    Result
    ...    "The page contains: - "Request sent successfully" alert
    Step_04_run
    
    
Step_05
    [Documentation]    Execute Get operation.
    ...    Result
    ...    "The page contains ""Data-missing : Request could not be completed 
    ...    because the relevant data model content does not exist." and "- : Request
    ...    could not be completed because the relevant data model content does not exist" alert.
    Step_05_run


Step_06
    [Documentation]    Load "topology list" button in customContainer area.
    ...    Click "icon plus" to insert topology id. Insert topology-id 
    ...    into topology id input, choose GET operation and hit ""Send"" button."
    ...    Topology-id value: ${EMPTY}
    ...    Result
    ...    "The page contains: - " Data-missing : Request could not be completed 
    ...    because the relevant data model content does not exist. - : Missing key for list" alert
    ...    -"topology [0]" button and iconClose button
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


Step_04_run
    Execute Chosen Operation    ${Delete_OPERATION}    ${Request_sent_successfully_ALERT}


Step_05_run
    Execute Chosen Operation    ${Get_OPERATION}    ${Data_missing_Relevant_data_model_not_existing_ALERT}
    
    
Step_06_run    
    Load Topology List Button In CustomContainer Area
    Click Element    ${Testing_Root_API_Topology_List_Plus_BUTTON}    
    Insert Text To Input Field    ${Testing_Root_API_Topology_List_Topology_Id_INPUT}    ${EMPTY}        
    Execute Chosen Operation    ${Get_OPERATION}    ${Data_missing_Missing_key_for_list_ALERT}    
        
    ${Topology_ID}=    Set Variable    ${Default_ID}     
    Page Should Contain Element    ${Testing_Root_API_Topology_List_Topology_Id_BUTTON}
    Page Should Contain Element    ${Testing_Root_API_Topology_List_Topology_Delete_BUTTON}


Step_07_run
    Close DLUX
    
           
    
                  