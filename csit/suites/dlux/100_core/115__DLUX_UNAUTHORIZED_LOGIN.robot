*** Settings ***
Documentation     Try whether it is possible to access pages available
...               only after logging in without being logged in.
Suite Teardown    Close Browser
#Library           Selenium2Library    timeout=10    implicit_wait=10     run_on_failure=Log Source
Library           Selenium2Library    timeout=10    implicit_wait=10 
Resource          ../../../libraries/GUIKeywords.robot
Resource          ../../../libraries/Utils.robot

*** Variables ***
${LOGIN_USERNAME}    admin
${LOGIN_PASSWORD}    admin

*** Test Cases ***
Step_01
    [Documentation]    Open DLUX login page.
    ...    Result
    ...    Page http://127.0.0.1:8181/index.html#/login opened.
    ...    Login formular present on the page.
    Step_01_run

Step_02
    [Documentation]    Insert valid credentials and hit "Login" button.
    ...    Result
    ...    Location is http://127.0.0.1:8181/index.html#/topology.
    Step_02_run

Step_03
    [Documentation]    Copy url of current location and close the browser.
    ...    Open browser and go to the URL you have copied.
    ...    Result
    ...    Login page http://127.0.0.1:8181/index.html#/login is opened.
    ...    Login formular is present on the page.
    Step_03_run

Step_04
    [Documentation]    Insert valid credentials and hit “Login” button.
    ...    Result
    ...    Location is http://127.0.0.1:8181/index.html#/topology.
    Step_04_run

Step_05
    [Documentation]    Go to the "Nodes" submenu and copy the URL
    ...    of the current location and close the browser.
    ...    Open browser and go to the URL you have copied.
    ...    Result
    ...    Login page http://127.0.0.1:8181/index.html#/login is opened.
    ...    Login formular is present on the page.
    Step_05_run

Step_06
    [Documentation]    Insert valid credentials and hit “Login” button.
    ...    Result
    ...    Location is http://127.0.0.1:8181/index.html#/topology.
    Step_06_run

Step_07
    [Documentation]    Go to the "Yang UI" submenu and copy the URL
    ...    of the current location and close the browser.
    ...    Open browser and go to the URL you have copied.
    ...    Result
    ...    Login page http://127.0.0.1:8181/index.html#/login is opened.
    ...    Login formular is present on the page.
    Step_07_run

Step_08
    [Documentation]    Insert valid credentials and hit “Login” button.
    ...    Result
    ...    Location is http://127.0.0.1:8181/index.html#/topology.
    Step_08_run

Step_09
    [Documentation]    Go to the "Yang Visualizer" submenu and copy the URL
    ...    of the current location and close the browser.
    ...    Open browser and go to the URL you have copied.
    ...    Result
    ...    Login page http://127.0.0.1:8181/index.html#/login is opened.
    ...    Login formular is present on the page.
    Step_09_run
    
Step_10 
    [Documentation]    Close Dlux.
    Step_10_run

*** Keywords ***
Step_01_run
    Launch DLUX
    #Open DLUX Login Page    ${LOGIN URL}
    Verify Elements Of DLUX Login Page

Step_02_run
    Login DLUX    ${LOGIN_USERNAME}    ${LOGIN_PASSWORD}
    Verify Elements of DLUX Home Page

Step_03_run
    ${current_location}=    Get Location
    Should Be Equal    ${current_location}    ${LOGGED URL}
    Close Browser
    Sleep    5
    Launch DLUX
    Go To    ${current_location}
    #Open Browser    ${current_location}    ${BROWSER}
    Sleep    5
    Location Should Be    ${LOGIN URL}
    Verify Elements Of DLUX Login Page

Step_04_run
    Login DLUX    ${LOGIN_USERNAME}    ${LOGIN_PASSWORD}
    Verify Elements of DLUX Home Page

Step_05_run
    Go To    ${Nodes_Submenu_URL}
    ${current_location}=    Get Location
    Close Browser
    Sleep    5
    Launch DLUX
    Go To    ${current_location}
    #Open Browser    ${current_location}    ${BROWSER}
    Sleep    5
    Location Should Be    ${LOGIN URL}
    Verify Elements Of DLUX Login Page

Step_06_run
    Login DLUX    ${LOGIN_USERNAME}    ${LOGIN_PASSWORD}
    Verify Elements of DLUX Home Page
    
Step_07_run
    Go To    ${Yang_UI_Submenu_URL}
    ${current_location}=    Get Location
    Close Browser
    Sleep    5
    Launch DLUX
    Go To    ${current_location}
    #Open Browser    ${current_location}    ${BROWSER}
    Sleep    5
    Location Should Be    ${LOGIN URL}
    Verify Elements Of DLUX Login Page

Step_08_run
    Login DLUX    ${LOGIN_USERNAME}    ${LOGIN_PASSWORD}
    Verify Elements of DLUX Home Page

Step_09_run
    Go To    ${Yang_Visualizer_Submenu_URL}
    ${current_location}=    Get Location
    Close Browser
    Sleep    5
    Launch DLUX
    Go To    ${current_location}    
    #Open Browser    ${current_location}    ${BROWSER}
    Sleep    5
    Location Should Be    ${LOGIN URL}
    Verify Elements Of DLUX Login Page
    
Step_10_run
    Close DLUX