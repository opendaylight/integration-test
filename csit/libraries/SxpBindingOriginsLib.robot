*** Settings ***
Documentation     Library containing Keywords used for SXP testing
Library           Collections
Library           RequestsLibrary
Library           SSHLibrary
Library           String
Library           ./Sxp.py

*** Variables ***
${REST_CONTEXT}    /restconf/operations/sxp-controller

*** Keywords ***
Clean Binding Origins
    [Documentation]    Remove all custom binding origins added during the tests
