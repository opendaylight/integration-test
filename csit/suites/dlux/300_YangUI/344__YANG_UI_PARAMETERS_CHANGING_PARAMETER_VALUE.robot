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
    [Documentation]    Click Edit button to edit parameter Param1 value.
    ...    Result
    ...    The page does not contain "Add new parameter" box.     
    Step_06_run
    
Step_07
    [Documentation]    Clear Value input field and insert new value. Click Save button.
    ...    Value: Value1edited
    ...    Result 
    ...    The page contains: - Parameter name <<Param1>>, - Parameter value "Value1edited",
    ...    - Edit button, - Delete button.
    Step_07_run
    
Step_08
    [Documentation]    Click Edit button to edit parameter Param2 value. Clear 
    ...    Value input field and insert new value. Click Save button. 
    ...    Value: Value2
    ...    Result
    ...    The page contains: - Parameter name <<Param2>>, - Parameter value "Value2",
    ...    - Edit button, - Delete button.
    Step_08_run
   
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
    Click Element    ${PARAMETERS_TAB}

Step_06_run
    ${Parameter_Name}=    Set Variable    ${Param_Name_1}    
    ${Parameter_List_Parameter_Name_XPATH}=    Set Variable    ${Parameter_List_ROW}//span[text()="<<${Parameter_Name}>>"]
    ${Parameter_LIST_Edit_BUTTON}=    Set Variable    ${Parameter_List_Parameter_Name_XPATH}/following::button[@class="yangButton iconEdit"]
    Focus    ${Parameter_LIST_Edit_BUTTON}
    Sleep    5
    Click Element    ${Parameter_LIST_Edit_BUTTON}
    
    Wait Until Page Contains Element    ${Add_New_Parameter_Showed_BOX}
    Page Should Contain Element    ${Add_New_Parameter_Box_Close_BUTTON}   
    Page Should Contain Element    ${Add_New_Parameter_Form_Name_LABEL}
    Page Should Contain Element    ${Add_New_Parameter_Form_Name_INPUT}
    Page Should Contain Element    ${Add_New_Parameter_Form_Value_LABEL}
    Page Should Contain Element    ${Add_New_Parameter_Form_Value_INPUT}
    Page Should Contain Element    ${Add_New_Parameter_Form_Save_BUTTON}
    
Step_07_run
    Clear Element Text    ${Add_New_Parameter_Form_Value_INPUT}
    Input Text    ${Add_New_Parameter_Form_Value_INPUT}    ${Param_Value_1_Edited}
    Click Element    ${Add_New_Parameter_Form_Save_BUTTON}
    Verify Added Parameter Presence On The Page    ${Param_Name_1}    ${Param_Value_1_Edited}
    
Step_08_run
    ${Parameter_Name}=    Set Variable    ${Param_Name_2}    
    ${Parameter_List_Parameter_Name_XPATH}=    Set Variable    ${Parameter_List_ROW}//span[text()="<<${Parameter_Name}>>"]
    ${Parameter_LIST_Edit_BUTTON}=    Set Variable    ${Parameter_List_Parameter_Name_XPATH}/following::button[@class="yangButton iconEdit"]
    Focus     ${Parameter_LIST_Edit_BUTTON}
    Sleep    5
    Click Element    ${Parameter_LIST_Edit_BUTTON}                
    
    Wait Until Page Contains Element    ${Add_New_Parameter_Showed_BOX}
    Clear Element Text    ${Add_New_Parameter_Form_Value_INPUT}
    Input Text    ${Add_New_Parameter_Form_Value_INPUT}    ${Param_Value_2}
    Click Element    ${Add_New_Parameter_Form_Save_BUTTON}
    Verify Added Parameter Presence On The Page    ${Param_Name_2}    ${Param_Value_2}
    
Step_09_run
    Close DLUX        
                               
    
