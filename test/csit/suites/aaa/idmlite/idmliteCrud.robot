*** Settings ***
Documentation     AAA IdmLite System Tests
Suite Setup       Delete All Sessions
Suite Teardown    Delete All Sessions
Library           Collections
Library           OperatingSystem
Library           String
Library           RequestsLibrary
Library           RequestsLibrary
Library           ../../../libraries/Common.py
Resource          ../../../libraries/Utils.robot
Variables         ../../../variables/Variables.py
Resource          ../../../libraries/AAAKeywords.robot

*** Variables ***
${idmurl}    /auth/v1

*** Test Cases ***
Get Users
    [Documentation]    Get Users from H2 Database
    ${resp}=    Get User From IDM DB
    Log    ${resp.content}
    Should Not Be Empty    ${resp.content}

Create User and Verify
    ${resp}=    Create User    {"name":"testuser","description":"robot test user","enabled":"true","email":"user1@gmail.com","password":"foobar"}
    ${userId}=    Get Json Value    ${resp.content}    /userid
    ${resp}=    Get User From IDM DB    ${userId}
    ${name}=    Get Json Value    ${resp.content}    /name
    ${email}=    Get Json Value    ${resp.content}    /email
    ${description}=    Get Json Value    ${resp.content}   /description
    Should Be Equal As Strings    ${name}    "testuser"
    Should Be Equal As Strings    ${email}    "user1@gmail.com"
    Should Be Equal As Strings    ${description}    "robot test user"
