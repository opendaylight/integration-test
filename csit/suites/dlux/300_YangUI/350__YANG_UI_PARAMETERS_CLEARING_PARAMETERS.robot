*** Settings ***
Documentation     Verification that it is possible to Edit value of a parameter. 
#Library           Selenium2Library    timeout=10    implicit_wait=10     run_on_failure=Log Source
Library           Selenium2Library    timeout=10    implicit_wait=10
Resource          ../../../libraries/GUIKeywords.robot
Resource          ../../../libraries/Utils.robot
Resource          ../../../libraries/YangUIKeywords.robot
#Suite Teardown    Close Browser


*** Variables ***
${LOGIN_USERNAME}    admin
${LOGIN_PASSWORD}    admin
${Param_Name_1}    Param1
${Param_Name_2}    Param2
${Param_Value_1}    Value1
${Param_Value_1_Edited}    Value1edited
${Param_Value_2}    Value2

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
    [Documentation]    Navigate to Yang UI. Click PARAMETERS tab. 
    ...    Result
    ...    Location should be http://127.0.0.1:8181/index.html#/yangui/index.
    Step_03_run

Step_04
    [Documentation]    Add new parameters.
    ...    Names: Param1 Param2; Value: Value1 ${EMPTY}
    [Template]    Add New Parameter
    ${Param_Name_1}    ${Param_Value_1}    Verify Add_New_Parameter_Box NONVisibility
    ${Param_Name_2}    ${EMPTY}    Verify Add_New_Parameter_Box NONVisibility

Step_05
    [Documentation]    Verify the occurrence of input parameter names and values 
    ...    on the page.
    ...    Result
    ...    The page contains: - Parameter name <<Param1>>, - Parameter value "Value1"
    ...    - Edit button, - Delete button, - Parameter name <<Param1>>, - Parameter value ""
    ...    - Edit button, - Delete button             
    [Template]    Verify Added Parameter Presence On The Page
    ${Param_Name_1}    ${Param_Value_1}
    ${Param_Name_2}    ${EMPTY}

Step_06
    [Documentation]    Click "Clear parameters" button to clear parameters.
    ...    Result
    ...    The page does not contain: - Parameter name <<Param1>>, - Parameter value "Value1",
    ...    - Edit button, - Delete button, - Parameter name <<Param2>>, - Parameter value "",
    ...    - Edit button, - Delete button.  
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
    Location Should Be    ${Yang_UI_Submenu_URL}
    Wait Until Page Contains Element    ${Loading_completed_successfully_ALERT}
    Click Element    ${PARAMETERS_TAB}

Step_06_run
    Focus    ${Clear_Parameters_BUTTON}
    Sleep    5
    Click Element    ${Clear_Parameters_BUTTON}
    Sleep    5
    Verify Deleted Parameter NONPresence On The Page    ${Param_Name_1}    ${Param_Value_1}
    Verify Deleted Parameter NONPresence On The Page    ${Param_Name_2}    ${EMPTY}
    
Step_07_run
    Close DLUX        
                               
    
