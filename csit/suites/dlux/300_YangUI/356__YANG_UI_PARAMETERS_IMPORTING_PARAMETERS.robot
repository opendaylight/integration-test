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
    [Documentation]    Click PARAMETERS tab. If the tab contains any data, clear the data.
    ...    Import parameters from the given .json file.
    ...    Result
    ...    The page contains:
    ...    - Row1: Parameter name <<p1>>,  Parameter value "v1", Edit button, Delete button.
    ...    - Row1: Parameter name <<p2>>,  Parameter value "${EMPTY}", Edit button, Delete button.
    ...    - Row1: Parameter name <<p3>>,  Parameter value "v3", Edit button, Delete button.
    ...    - Row1: Parameter name <<p4>>,  Parameter value "${EMPTY}", Edit button, Delete button.
    Step_03_run
    Verify Imported Parameters Presence In Parameters Table

Step_04
    [Documentation]    Delete parameters p2, p3. Import parameters from the given .json file.
    ...    Result
    ...    The page contains:
    ...    - Row1: Parameter name <<p1>>,  Parameter value "v1", Edit button, Delete button.
    ...    - Row1: Parameter name <<p2>>,  Parameter value "${EMPTY}", Edit button, Delete button.
    ...    - Row1: Parameter name <<p3>>,  Parameter value "v3", Edit button, Delete button.
    ...    - Row1: Parameter name <<p4>>,  Parameter value "${EMPTY}", Edit button, Delete button.
    Step_04_run

Step_05
    [Documentation]    Close DLUX.
    Step_05_run  

*** Keywords ***
Step_01_run
    Launch Or Open DLUX Page And Login DLUX


Step_02_run
    Navigate To Yang UI Submenu


Step_03_run
    Click Element    ${PARAMETERS_TAB}
    Wait Until Page Contains Element    ${Import_Parameters_INPUT}
    If Parameters Table Contains Data Then Clear Parameters Data
                                                           
    Choose File    ${Import_Parameters_INPUT}    ${Parameters_To_Import_File_Path}

Verify Imported Parameters Presence In Parameters Table    
    ${param_1_data}=    Create List    ${row_number_1}    ${Param_Value_1}
    ${param_2_data}=    Create List    ${row_number_2}    ${Empty}
    ${param_3_data}=    Create List    ${row_number_3}    ${Param_Value_3}
    ${param_4_data}=    Create List    ${row_number_4}    ${EMPTY}
    ${dict}=    Create Dictionary    ${Param_Name_1}=${param_1_data}    ${Param_Name_2}=${param_2_data}    ${Param_Name_3}=${param_3_data}    ${Param_Name_4}=${param_4_data}
    @{param_names}=    Create List    ${Param_Name_1}    ${Param_Name_2}    ${Param_Name_3}    ${Param_Name_4}
    : FOR     ${param_name}    IN    @{param_names}
    \    ${index}=    Evaluate    0   
    \    ${value}=    Get From Dictionary    ${dict}    ${param_name}
    \    ${row}=    Get From List    ${value}    ${index}
    \    ${index}=    Evaluate    ${index}+1
    \    ${param_value}=    Get From List    ${value}    ${index}        
    \    Verify Added Parameter Presence On The Page    ${row}    ${param_name}    ${param_value}
  
       
Step_04_run
    Click Parameter Table Delete Parameter Button In Row    ${row_number_2}    
    Click Parameter Table Delete Parameter Button In Row    ${row_number_2}
    Verify Deleted Parameter NONPresence On The Page    ${row_number_2}    ${Param_Name_2}    ${Empty}
    Verify Deleted Parameter NONPresence On The Page    ${row_number_2}    ${Param_Name_3}    ${Param_Value_3}
    Verify Added Parameter Presence On The Page    ${row_number_1}    ${Param_Name_1}    ${Param_Value_1}
    Verify Added Parameter Presence On The Page    ${row_number_2}    ${Param_Name_4}    ${Empty}
    
    Choose File    ${Import_Parameters_INPUT}    ${Parameters_To_Import_File_Path}
    Verify Imported Parameters Presence In Parameters Table

    
Step_05_run
    Close DLUX        
                               
    
