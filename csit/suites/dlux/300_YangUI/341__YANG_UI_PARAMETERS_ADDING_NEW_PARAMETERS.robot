*** Settings ***
Documentation     Verification that "Add new parameters" button enables adding 
...    new parameters. Verification, that only a correct format of the parameter name is accepted.
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
${Param_Name_Incorrect}    ?    
${Param_Value_1}    Value1

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
    [Documentation]    Click PARAMETERS tab. Click "Add new parameter" button.
    ...    Result
    ...    The page contains: - Add new parameter button, - Add new parameter box,
    ...    - Add new parameter box close button, - Add new parameter form Name label,
    ...    - Add new parameter form Name Input field, - Add new parameter form Value label,
    ...    - Add new parameter form Value Input field, - Add new parameter form Save button.
    Step_04_run

Step_05
    [Documentation]    Close "Add new parameter" box.
    ...    Result
    ...    The page does not contain "Add new parameter" box.     
    Step_05_run
    
Step_06
    [Documentation]    Click "Add new parameter" button. Insert incorrect values 
    ...    into Name input field and any value into Value input field. Click Save button. 
    ...    Close "Add new parameter" box.  
    ...    Iterate through pairs of values: 
    ...    Name: ${EMPTY} ${EMPTY} Incorrect Incorrect; Value: ${EMPTY} Value ${EMPTY} Value.
    ...    Result after each iteration:
    ...    The page contains "Add new parameter" box.
    [Template]    Add New Parameter
    ${EMPTY}    ${EMPTY}    Verify Add_New_Parameter_Box Visibility
    ${EMPTY}    ${Param_Value_1}    Verify Add_New_Parameter_Box Visibility
    ${Param_Name_Incorrect}    ${EMPTY}    Verify Add_New_Parameter_Box Visibility
    ${Param_Name_Incorrect}    ${Param_Value_1}    Verify Add_New_Parameter_Box Visibility
    
Step_07
    [Documentation]    Click "Add new parameter" button. Insert correct values into 
    ...    Name input field and any value into Value input field. Click Save button. 
    ...    Iterate through pairs of values:
    ...    Name: Param1 Param2; Value: Value1 ${EMPTY}
    ...    Result
    ...    The page does not contain "Add new parameter" box.
    [Template]    Add New Parameter    
    ${Param_Name_1}    ${Param_Value_1}    Verify Add_New_Parameter_Box NONVisibility
    ${Param_Name_2}    ${EMPTY}    Verify Add_New_Parameter_Box NONVisibility
   
Step_08
    [Documentation]    Verify the occurrence of input parameter names and values 
    ...    on the page.
    ...    Result
    ...    The page contains: - Parameter name <<Param1>>, - Parameter value "Value1"
    ...    - Edit button, - Delete button, - Parameter name <<Param1>>, - Parameter value ""
    ...    - Edit button, - Delete button             
    [Template]    Verify Added Parameter Presence On The Page
    ${Param_Name_1}    ${Param_Value_1}
    ${Param_Name_2}    ${EMPTY}
    
Step_09
    [Documentation]    Close DLUX.
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
    Location Should Be    ${Yang_UI_Submenu_URL}
    Wait Until Page Contains Element    ${Loading_completed_successfully_ALERT}
    
Step_04_run
    Click Element    ${PARAMETERS_TAB}
    Wait Until PAge Contains Element    ${Add_New_Parameter_BUTTON}

    Click Element    ${Add_New_Parameter_BUTTON}
    Wait Until Page Contains Element    ${Add_New_Parameter_Showed_BOX}
    Page Should Contain Element    ${Add_New_Parameter_Box_Close_BUTTON}   
    Page Should Contain Element    ${Add_New_Parameter_Form_Name_LABEL}
    Page Should Contain Element    ${Add_New_Parameter_Form_Name_INPUT}
    Page Should Contain Element    ${Add_New_Parameter_Form_Value_LABEL}
    Page Should Contain Element    ${Add_New_Parameter_Form_Value_INPUT}
    Page Should Contain Element    ${Add_New_Parameter_Form_Save_BUTTON}
    
Step_05_run
    Click Element    ${Add_New_Parameter_Box_Close_BUTTON}
    
Step_09_run
    Close DLUX        
                               
    
