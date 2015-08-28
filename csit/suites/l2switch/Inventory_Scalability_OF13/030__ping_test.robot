*** Settings ***
Documentation     Test suite for do pingall test
Library           SSHLibrary
Library           Collections
Library           RequestsLibrary
Library           ../../../libraries/Common.py
Variables         ../../../variables/Variables.py

*** Variables ***

*** Test Cases ***
Ping all
    [Documentation]    Do ping all test, verify no packet loss
    ${TOPO_TREE_DEPTH}    Convert To Integer    ${TOPO_TREE_DEPTH}
    ${TOPO_TREE_FANOUT}    Convert To Integer    ${TOPO_TREE_FANOUT}
    ${numnodes}    Num Of Nodes    ${TOPO_TREE_DEPTH}    ${TOPO_TREE_FANOUT}
    Write    pingall
    Sleep    ${numnodes}
    ${result}    Read
    Should Not Contain    ${result}    X
