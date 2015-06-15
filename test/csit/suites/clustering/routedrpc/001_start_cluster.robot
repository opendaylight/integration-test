*** Settings ***
Documentation     Start the controllers
Library           Collections
Library           ../../../libraries/RequestsLibrary.py
Library           ../../../libraries/Common.py
Library           ../../../libraries/CrudLibrary.py
Library           ../../../libraries/SettingsLibrary.py
Library           ../../../libraries/UtilLibrary.py
Variables         ../../../variables/Variables.py

*** Variables ***
${REST_CONTEXT}    /restconf/config/

*** Test Cases ***
Stop All Controllers
    [Documentation]    Stop all the controllers in the cluster
    Stopcontroller    ${MEMBER1}    ${USER_NAME}    ${PASSWORD}    ${KARAF_HOME}
    Stopcontroller    ${MEMBER2}    ${USER_NAME}    ${PASSWORD}    ${KARAF_HOME}
    Stopcontroller    ${MEMBER3}    ${USER_NAME}    ${PASSWORD}    ${KARAF_HOME}
    Sleep    30
    KillController    ${MEMBER1}    ${USER_NAME}    ${PASSWORD}    ${KARAF_HOME}
    KillController    ${MEMBER2}    ${USER_NAME}    ${PASSWORD}    ${KARAF_HOME}
    KillController    ${MEMBER3}    ${USER_NAME}    ${PASSWORD}    ${KARAF_HOME}

Clean All Journals
    [Documentation]    Clean the journals of all the controllers in the cluster
    CleanJournal    ${MEMBER1}    ${USER_NAME}    ${PASSWORD}    ${KARAF_HOME}
    CleanJournal    ${MEMBER2}    ${USER_NAME}    ${PASSWORD}    ${KARAF_HOME}
    CleanJournal    ${MEMBER3}    ${USER_NAME}    ${PASSWORD}    ${KARAF_HOME}
    Sleep    5

Start All Controllers
    [Documentation]    Start all the controllers in the cluster
    Startcontroller    ${MEMBER1}    ${USER_NAME}    ${PASSWORD}    ${KARAF_HOME}
    Startcontroller    ${MEMBER2}    ${USER_NAME}    ${PASSWORD}    ${KARAF_HOME}
    Startcontroller    ${MEMBER3}    ${USER_NAME}    ${PASSWORD}    ${KARAF_HOME}
    Sleep    120
