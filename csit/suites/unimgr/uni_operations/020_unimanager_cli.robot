*** Settings ***
Documentation     Test suite for all Uni Manager operations
Suite Setup       Setup Unimgr Test Environment
Suite Teardown    Delete All Sessions
Library           OperatingSystem
Library           String
Library           Collections
Library           SSHLibrary
Library           RequestsLibrary
Library           ../../../libraries/Common.py
Variables         ../../../variables/Variables.py
Resource          ../../../libraries/Utils.robot
Resource          ../../../libraries/KarafKeywords.robot
Resource          ../../../libraries/UnimgrKeywords.robot

*** Variables ***
${DEFAULT_LINUX_PROMPT}    ${EMPTY}
${Mininet1_IP}    ${TOOLS_SYSTEM_IP}
${Mininet2_IP}    ${TOOLS_SYSTEM_2_IP}
${UNI1_MAC}       68:5b:35:bb:f8:3e
${UNI2_MAC}       52:7b:25:cb:a7:3c

*** Test Cases ***
Create source and destination UNIs at the OVS instances using Restconf API
    [Documentation]    Create source and destination UNIs
    [Tags]    UniMgr UNIs Create
    ${elements}    Create List    ${Mininet1_IP}
    Check For Elements On Karaf Command Output Message    uni-add -ip ${Mininet1_IP} -ma ${UNI1_MAC}    ${elements}
    ${elements}    Create List    ${Mininet2_IP}
    Check For Elements On Karaf Command Output Message    uni-add -ip ${Mininet2_IP} -ma ${UNI2_MAC}    ${elements}

List All UNIs
    [Documentation]    List all existing UNIs in the config data store
    [Tags]    UniMgr
    ${elements}    Create List    ${Mininet1_IP}    ${Mininet2_IP}
    Check For Elements On Karaf Command Output Message    uni-list -c    ${elements}

Show UNI
    [Documentation]    Show the information of the created Unis from the operational data store
    [Tags]    UniMgr
    ${elements}    Create List    ${Mininet1_IP}
    Wait Until Keyword Succeeds    16s    2s    Check For Elements On Karaf Command Output Message    uni-show ${Mininet1_IP}    ${elements}

Update the Unis Speed
    [Documentation]    Update Created Unis speed
    [Tags]    UniMgr
    ${elements}    Create List    ${Mininet1_IP} updated
    Check For Elements On Karaf Command Output Message    uni-update -ip ${Mininet1_IP} -ma ${UNI1_MAC} -s 10G    ${elements}
    ${element}    Create List    Speed10G
    Wait Until Keyword Succeeds    16s    2s    Check For Elements On Karaf Command Output Message    uni-show ${Mininet1_IP}    ${element}

Delete UNIs source and destination
    [Documentation]    Delete both UNIs source and destination.
    [Tags]    UniMgr UNI Delete
    ${elements}    Create List    Uni successfully removed
    Check For Elements On Karaf Command Output Message    uni-remove ${Mininet1_IP}    ${elements}
    Check For Elements On Karaf Command Output Message    uni-remove ${Mininet2_IP}    ${elements}
    ${elements}    Create List    No uni found
    Wait Until Keyword Succeeds    16s    2s    Check For Elements On Karaf Command Output Message    uni-show ${Mininet1_IP}    ${elements}
    Wait Until Keyword Succeeds    16s    2s    Check For Elements On Karaf Command Output Message    uni-show ${Mininet2_IP}    ${elements}
