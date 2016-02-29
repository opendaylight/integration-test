*** Settings ***
Documentation     Verification that button "Delete" in a parameter row deletes 
...    only the parameter in the same row. 
#Library           Selenium2Library    timeout=10    implicit_wait=10     run_on_failure=Log Source
Library           Selenium2Library    timeout=10    implicit_wait=10
Resource          ../../../libraries/GUIKeywords.robot
Resource          ../../../libraries/Utils.robot
Resource          ../../../libraries/YangUIKeywords.robot
#Suite Teardown    Close Browser


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
    [Documentation]    Click Parameters tab. Add new parameters.
    ...    Names: Param1 Param2; Value: Value1 ${EMPTY}
    [Template]    Add New Parameter
    ${Param_Name_1}    ${Param_Value_1}    Verify Add_New_Parameter_Box NONVisibility
    ${Param_Name_2}    ${EMPTY}    Verify Add_New_Parameter_Box NONVisibility

Step_04
    [Documentation]    Verify the occurrence of input parameter names and values 
    ...    on the page.
    ...    Result
    ...    The page contains: - Parameter name <<Param1>>, - Parameter value "Value1"
    ...    - Edit button, - Delete button, - Parameter name <<Param1>>, - Parameter value ""
    ...    - Edit button, - Delete button             
    [Template]    Verify Added Parameter Presence On The Page
    ${row_number_1}    ${Param_Name_1}    ${Param_Value_1}
    ${row_number_2}    ${Param_Name_2}    ${EMPTY}

Step_05
    [Documentation]    Click "Delete" button in the row containing parameter Param1.
    ...    Result
    ...    The page does not contain: - Parameter name <<Param1>>, - Parameter value "Value1",
    ...    - Edit button, - Delete button.    
    Step_05_run
    
Step_06
    [Documentation]    Click "Delete" button in the row containing parameter Param2.
    ...    Value: Value1edited
    ...    Result 
    ...    The page does not contain: - Parameter name <<Param2>>, - Parameter value "",
    ...    - Edit button, - Delete button 
    Step_06_run
    
Step_07
    [Documentation]    Close DLUX.
    Step_07_run  

*** Keywords ***
Step_01_run
    Launch Or Open DLUX Page And Login DLUX


Step_02_run
    Navigate To Yang UI Submenu
    Click Element    ${PARAMETERS_TAB}

Step_05_run
    Click Parameter Table Delete Parameter Button In Row    ${row_number_1}
    Verify Deleted Parameter NONPresence On The Page    ${row_number_1}    ${Param_Name_1}    ${Param_Value_1}
    
Step_06_run
    Click Parameter Table Delete Parameter Button In Row    ${row_number_1}
    Verify Deleted Parameter NONPresence On The Page    ${row_number_1}    ${Param_Name_2}    ${EMPTY}
   
Step_07_run
    Close DLUX        
                               
    
