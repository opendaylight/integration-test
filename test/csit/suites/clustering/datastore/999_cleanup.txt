*** Settings ***
Documentation  Test cleanup
Default Tags  3-node-cluster

Library           ../../../libraries/UtilLibrary.py
Variables         ../../../variables/Variables.py

*** Test Cases ***
Kill All Controllers
    KillController    ${MEMBER1}   ${USER_NAME}    ${PASSWORD}    ${KARAF_HOME}
    KillController    ${MEMBER2}   ${USER_NAME}    ${PASSWORD}    ${KARAF_HOME}
    KillController    ${MEMBER3}   ${USER_NAME}    ${PASSWORD}    ${KARAF_HOME}

Clean All Journals
    CleanJournal    ${MEMBER1}    ${USER_NAME}    ${PASSWORD}    ${KARAF_HOME}
    CleanJournal    ${MEMBER2}    ${USER_NAME}    ${PASSWORD}    ${KARAF_HOME}
    CleanJournal    ${MEMBER3}    ${USER_NAME}    ${PASSWORD}    ${KARAF_HOME}
