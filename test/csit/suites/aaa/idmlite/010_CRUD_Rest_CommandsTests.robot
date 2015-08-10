*** Settings ***
Documentation     Basic REST AAA Tests for IdMLight
...
...               Copyright (c) 2015 Hewlett-Packard Development Company, L.P. and others. All rights reserved.
...
...               This program and the accompanying materials are made available under the
...               terms of the Eclipse Public License v1.0 which accompanies this distribution,
...               and is available at http://www.eclipse.org/legal/ep1-v10.html
Suite Setup       IdMLight Suite Setup
Suite Teardown    IdMLight Suite Teardown
Library           Collections
Library           RequestsLibrary
Library           OperatingSystem
Library           String
Library           HttpLibrary.HTTP
Library           DateTime
Library           ../../../libraries/Common.py
Library           ../../../libraries/AAAJsonUtils.py
Resource          ../../../libraries/Utils.robot
Variables         ../../../variables/Variables.py
Resource          ../../../libraries/AAAKeywords.robot

*** Variables ***
# port is fixed in Jetty configuration, as well
${URI}            http://${CONTROLLER}:8282
# create lists for Domains, Roles and Users - that can be cleaned up upon Teardown
@{cleanup_domain_list}
@{cleanup_role_list}
@{cleanup_user_list}
@{cleanup_grant_list}
# will modify value in Setup and use throughout the code
${HEADERS}        ${EMPTY}

*** Test Cases ***
Test Post New Domain
    [Documentation]    Create a domain using REST POST command.
    # create a temp name, set it to domainName
    ${domainName}=    Create Random Name    domain-Other
    # Create the new domain, initialize some values to test against
    ${domaindesc}=    Set Variable    "testdomain other"
    ${domainstatus}=    Set Variable    "true"

    # Have to escape the quotes, need quotes to make the POST work properly
    ${data}=    Set Variable    {"description":${domaindesc},"domainid":"7","name":\"${domainName}\","enabled":${domainstatus}}
    Log    ${data}
    # now post it
    ${domain}=    Post New Domain    ${domainName}    ${data}
    Log    ${domain}

    ${domainid}=    Parse Item From Blob By Offset    ${domain}    0
    Log    ${domainid}

    # get the domain to verify
    ${fetched_domain}=    Get Specific Domain    ${domainid}
    # add new domain json string to the cleanup list for later cleanup
    Append To List    ${cleanup_domain_list}    ${fetched_domain}
    # count the number of domainid's that appear in this block of JSON
    ${depth}=    Fieldcount    ${fetched_domain}    "domainid"
    ${fetchedDomStatus}=    Get Domain State By Domainid    ${domain}    ${domainid}    ${depth}
    ${fetchedDomDesc}=    Get Domain Description By Domainid    ${domain}    ${domainid}    ${depth}
    # Set Test Disposition based on comparison of what was posted and what was fetched
    ${testdisposition}=    Set Variable If    '${fetched_domain}' == '${domain}'    '${fetchedDomStatus}' == '${domainstatus}'    '${fetchedDomDesc}' == '${domaindesc}'
    Log    ${testdisposition}

Test Get Domains
    [Documentation]    Exercise REST GET command to get all domains.
    # rely on the creation of a test role in the Setup routine
    # pop item off of end of the cleanup list, for use (does not alter list)
    Log    ${cleanup_domain_list}
    ${domain_item}=    Get From List    ${cleanup_domain_list}    -1
    Log    ${domain_item}

    # parse out the domainid from the domain info we just grabbed
    ${domainid}=    Parse Item From Blob By Offset    ${domain_item}    0
    Log    ${domainid}

    # parse out the name from the same info
    ${domainname}=    Parse Item From Blob By Offset    ${domain_item}    1
    Log    ${domainname}

    # get the entire dump of created domains
    ${content}=    Get Domains

    # parse through that massive blob and get the individual name created in Setup
    ${node_count}=    Nodecount    ${content}    domains    domainid
    ${domainid}=    Convert To Integer    ${domainid}

    # Get the domain name from the database, looking it up by its domainid
    ${domainentry}=    Get Domain Name By Domainid    ${content}    ${domainid}    ${node_count}

    Log    ${domainentry}
    # compare to see if the parsed user id matches the one we grabbed from list
    Should Be Equal    ${domainentry}    ${domainname}

Test Get Specific Domain
    [Documentation]    Get a specific domain using REST GET command.
    # from the pre-created (see Setup routine) list, grab a domain id for testing
    ${listlength}=    Get Length    ${cleanup_domain_list}
    # pop item off of end of the list, for use (does not alter list)
    Log    ${cleanup_domain_list}
    ${domain_item}=    Get From List    ${cleanup_domain_list}    -1
    ${item}=    Pop Name Off Json    ${domain_item}
    # convert this crap to unicode
    # ${item}=    Convert To String    ${item}
    Log    ${item}
    # make a GET call to find the material we want to delete
    ${domains}=    Get Domains
    # convert name on the list to an ID, by which we delete this stuff
    ${node_count}=    Nodecount    ${domains}    domains    domainid
    ${node_count}=    Convert To Integer    ${node_count}
    ${domainid}=    Get Domain Id By Domainname    ${domains}    ${item}    ${node_count}
    # now, get the specific domain by it's domainid
    ${domaininfo}=    Get Specific Domain    ${domainid}
    Should Contain    ${domaininfo}    ${item}
    Log    ${domaininfo}

Test Update Specific Domain
    [Documentation]    Update a specific domain using REST PUT command.
    # rely on the creation of a test domain in the Setup routine
    # pop item off of end of the list, for use (does not alter list)
    Log    ${cleanup_domain_list}
    ${domain_item}=    Get From List    ${cleanup_domain_list}    -1
    Log    ${domain_item}

    # parse out the domain id from the domain info we just grabbed
    ${domid}=    Parse Item From Blob By Offset    ${domain_item}    0
    Log    ${domid}

    # parse out the name from the same info
    ${domname}=    Parse Item From Blob By Offset    ${domain_item}    1
    Log    ${domname}

    ${data}=    Set Variable    {"name":"MasterTest Domain"}
    Update Specific Domain    ${data}    ${domid}
    ${domname}=    Get Specific Domain Name    ${domid}
    Log    ${domname}
    ${z}=    Split String    ${data}    :
    ${dname}=    Get From List    ${z}    1
    ${dname}=    Replace String    ${dname}    "    ${EMPTY}
    ${dname}=    Replace String    ${dname}    }    ${EMPTY}
    Log    ${dname}
    ${modified_name}=    Pop Name Off Json    ${domname}
    Log    ${modified_name}
    Should Be Equal    ${dname}    ${modified_name}

Test Delete Domain
    [Documentation]    Delete a specific domain using REST DELETE command.
    # create a temporary test domain
    ${tempdomain}=    Create Random Name    temp-domain-name
    ${domaindata}=    Set Variable    {"description":"temporary test domain","domainid":"1","name":"${tempdomain}","enabled":"true"}
    # Post that temp domain
    ${newdomain}=    Post New Domain    ${tempdomain}    ${domaindata}
    Log    ${newdomain}
    # parse out the domain-id from the domain info we just created
    ${domainid}=    Parse Item From Blob By Offset    ${newdomain}    0
    Log    ${domainid}

    # now wipe if off the map
    Delete Domain    ${domainid}
    # we should not be able to fetch this domain from the database of domains...should fail...
    ${content}=    Check Specific Id Does Not Exist    domain    ${domainid}
    Log    ${content}

Test Get Users
    [Documentation]    Exercise REST GET command for obtaining all users.
    # rely on the creation of a test user in the Setup routine
    # pop item off of end of the list, for use (does not alter list)
    Log    ${cleanup_user_list}
    ${user_item}=    Get From List    ${cleanup_user_list}    -1
    Log    ${user_item}

    # parse out the userid from the user info we just grabbed
    ${userid}=    Parse Item From Blob By Offset    ${user_item}    0
    Log    ${userid}

    # parse out the name from the same info
    ${username}=    Parse Item From Blob By Offset    ${user_item}    1
    Log    ${username}

    # get the entire blob of users
    ${content}=    Get Users
    # parse through that massive blob and get the individual name
    ${node_count}=    Nodecount    ${content}    users    userid
    ${userid}=    Convert To Integer    ${userid}
    ${userentry}=    Get User Name By Userid    ${content}    ${userid}    ${node_count}
    Log    ${userentry}
    # compare to see if the parsed user id matches the one we grabbed from list
    Should Be Equal    ${userentry}    ${username}

Test Get Specific User
    [Documentation]    Exercise REST GET command to obtain a specific user.
    # from the pre-created (see Setup routine) list, grab a user id for testing
    ${listlength}=    Get Length    ${cleanup_user_list}
    # pop item off of end of the list, for use (does not alter list)
    Log    ${cleanup_user_list}
    ${user_item}=    Get From List    ${cleanup_user_list}    -1
    ${item}=    Pop Name Off Json    ${user_item}
    # convert this to unicode
    # ${item}=    Convert To String    ${item}
    Log    ${item}

    # parse out the userid from the user info we just grabbed
    ${userid}=    Parse Item From Blob By Offset    ${user_item}    0
    Log    ${userid}

    # parse out the name from the same info
    ${username}=    Parse Item From Blob By Offset    ${user_item}    1
    Log    ${username}

    # make a GET call to find the material we want
    ${content}=    Get Specific User    ${userid}

    # parse out the user name from the content we just fetched
    ${fetched_username}=    Parse Item From Blob By Offset    ${content}    1
    Log    ${fetched_username}

    # compare to see if the parsed user name matches the one we grabbed from list
    Should Contain    ${fetched_username}    ${username}

Test Update User
    [Documentation]    Exercise PUT command against an existing User ID.
    # pop item off of end of the list, for use (does not alter list)
    Log    ${cleanup_user_list}
    ${user_item}=    Get From List    ${cleanup_user_list}    -1
    Log    ${user_item}

    # parse out the user-id from the user info we just created
    ${userid}=    Parse Item From Blob By Offset    ${user_item}    0
    Log    ${userid}

    # update the information for the userid
    ${testusername}=    Create Random Name    force-accomplish
    ${data}=    Set Variable    {"description":"sample test description", "name":"${testusername}"}
    ${content}=    Update Specific User    ${data}    ${userid}
    Log    ${testusername}
    # now, make a GET call to find the material we modified
    ${existing_useritem}=    Get Specific User    ${userid}

    # parse out the name from the existing userinfo
    ${expected_username}=    Parse Item From Blob By Offset    ${existing_useritem}    1
    Log    ${expected_username}

    # compare to see if the GOTTEN user id matches the one we grabbed from list
    Should Be Equal    ${expected_username}    ${testusername}

Test Post New User
    [Documentation]    Test the POST command to create a new user.
    # create information for a new role (for the test)
    ${testusername}=    Create Random Name    Darth-Maul
    ${data}=    Set Variable    {"description":"sample user description", "name":"${testusername}", "userid":1}
    Log    ${testusername}

    # Post this puppy
    ${content}=    Post New User    ${testusername}    ${data}
    # parse out the userid from the content we just created
    ${userid}=    Parse Item From Blob By Offset    ${content}    0
    Log    ${userid}

    # now go GET the userid info and compare to the name we fabricated
    ${existing_useritem}=    Get Specific User    ${userid}

    ${expected_username}=    Parse Item From Blob By Offset    ${existing_useritem}    1
    Log    ${expected_username}

    # compare to see if the GOTTEN role id matches the one we grabbed from list
    Should Be Equal    ${expected_username}    ${testusername}

Test Delete User
    [Documentation]    Exercise REST command for DELETE user command.
    # create a user and then delete it.    Use Get to verify it's gone
    # create information for a new user (for the test)
    ${testusername}=    Create Random Name    force-user
    ${data}=    Set Variable    {"description":"sample test description", "name":"${testusername}", "userid":1}
    Log    ${testusername}
    # Post this disposable user
    ${content}=    Post New User    ${testusername}    ${data}
    # parse out the user-id from the content we just created
    ${userid}=    Parse Item From Blob By Offset    ${content}    0
    Log    ${userid}

    # now delete it...
    ${content2}=    Delete User    ${userid}
    # should fail...
    ${content}=    Check Specific Id Does Not Exist    user    ${userid}
    Log    ${content}

Test Get Specific Role
    [Documentation]    Exercise REST command for roles GET command.
    # from the pre-created (see Setup routine) list, grab a role id for testing
    ${listlength}=    Get Length    ${cleanup_role_list}
    # pop item off of end of the list, for use (does not alter list)
    Log    ${cleanup_role_list}
    ${role_item}=    Get From List    ${cleanup_role_list}    -1
    Log    ${role_item}
    # parse out the role-id from the role info we just created
    ${roleid}=    Parse Item From Blob By Offset    ${roleitem}    0
    Log    ${roleid}

    # make a GET call to find the material we want
    ${existing_roleitem}=    Get Specific Role    ${roleid}

    # parse out the expected role-id from the content we just created
    ${eroleid}=    Parse Item From Blob By Offset    ${existing_roleitem}    0
    Log    ${eroleid}
    # compare to see if the GOTTEN role id matches the one we grabbed from list
    Should Be Equal    ${eroleid}    ${roleid}

Test Get Roles
    [Documentation]    Exercise REST command for roles GET command.
    # rely on the creation of a test role in the Setup routine
    # pop item off of end of the list, for use (does not alter list)
    Log    ${cleanup_role_list}
    ${role_item}=    Get From List    ${cleanup_role_list}    -1
    Log    ${role_item}

    # parse out the role-id from the info we just grabbed
    ${roleid}=    Parse Item From Blob By Offset    ${role_item}    0
    Log    ${roleid}
    # parse out the name from the same info
    ${rolename}=    Parse Item From Blob By Offset    ${role_item}    1
    Log    ${rolename}

    # get the entire blob of roles
    ${content}=    Get Roles
    # parse through that massive blob and get the individual name
    ${node_count}=    Nodecount    ${content}    roles    roleid
    ${roleid}=    Convert To Integer    ${roleid}
    ${roleentry}=    Get Role Name By Roleid    ${content}    ${roleid}    ${node_count}
    Log    ${roleentry}
    # compare to see if the parsed user id matches the one we grabbed from list
    Should Be Equal    ${roleentry}    ${rolename}

Test Update Role
    [Documentation]    Exercise PUT command against an existing Role ID.
    # pop item off of end of the list, for use (does not alter list)
    Log    ${cleanup_role_list}
    ${role_item}=    Get From List    ${cleanup_role_list}    -1
    Log    ${role_item}
    # parse out the role-id from the role info we just created
    ${roleid}=    Parse Item From Blob By Offset    ${role_item}    0
    Log    ${roleid}

    # update the information for the roleid
    ${testrolename}=    Create Random Name    force-accomplish
    ${data}=    Set Variable    {"description":"sample test description", "name":"${testrolename}"}
    ${content}=    Update Specific Role    ${data}    ${roleid}
    Log    ${testrolename}
    # now, make a GET call to find the material we modified
    ${existing_roleitem}=    Get Specific Role    ${roleid}

    # parse out the name from the same info
    ${expected_rolename}=    Parse Item From Blob By Offset    ${existing_roleitem}    1
    Log    ${expected_rolename}

    # compare to see if the GOTTEN role id matches the one we grabbed from list
    Should Be Equal    ${expected_rolename}    ${testrolename}

Test Post New Role
    [Documentation]    Exercise POST command to create a new Role.
    # create information for a new role (for the test)
    ${testrolename}=    Create Random Name    force-brother-cousin
    ${data}=    Set Variable    {"description":"sample test description", "name":"${testrolename}", "roleid":1}
    Log    ${testrolename}
    # Post this puppy
    ${content}=    Post New Role    ${data}
    # parse out the role-id from the content we just created
    ${roleid}=    Parse Item From Blob By Offset    ${content}    0
    Log    ${roleid}

    # now got GET the roleid info and compare to the name we fabricated
    # and parse out role name
    ${existing_roleitem}=    Get Specific Role    ${roleid}
    ${expected_rolename}=    Parse Item From Blob By Offset    ${content}    1
    Log    ${expected_rolename}

    # compare to see if the GOTTEN role id matches the one we grabbed from list
    Should Be Equal    ${expected_rolename}    ${testrolename}

Test Delete Role
    [Documentation]    Exercise REST command for DELETE role command.
    # create a role and then delete it.    Use Get to verify it's gone
    # create information for a new role (for the test)
    ${testrolename}=    Create Random Name    force-usurper
    ${data}=    Set Variable    {"description":"sample test description", "name":"${testrolename}", "roleid":1}
    Log    ${testrolename}
    # Post this disposable role
    ${content}=    Post New Role    ${data}
    # parse out the role-id from the content we just created
    ${roleid}=    Parse Item From Blob By Offset    ${content}    0
    Log    ${roleid}

    # now delete it...
    ${content2}=    Delete Role    ${roleid}
    # should fail...
    ${content}=    Check Specific Id Does Not Exist    role    ${roleid}
    Log    ${content}

Test Grant Role To Domain And User
    [Documentation]    Test the POST of a Role to Domain and User

    # rely on the creation of a test role, user and domain in the Setup routine
    # pop item off of end of the list, for use (does not alter list)
    ${role_item}=    Get From List    ${cleanup_role_list}    -1
    Log    ${role_item}
    ${user_item}=    Get From List    ${cleanup_user_list}    -1
    Log    ${user_item}
    ${domain_item}=    Get From List    ${cleanup_domain_list}    -1
    Log    ${domain_item}

    # parse out the roleid from the role info we just grabbed
    ${roleid}=    Parse Item From Blob By Offset    ${role_item}    0
    Log    ${roleid}

    # parse out the name from the same info
    ${rolename}=    Parse Item From Blob By Offset   ${role_item}    1
    Log    ${rolename}

    # parse out the userid from the user info we just grabbed
    ${userid}=    Parse Item From Blob By Offset    ${user_item}    0
    Log    ${userid}

    # parse out the name from the same info
    ${username}=    Parse Item From Blob By Offset    ${user_item}    1
    Log    ${username}

    # parse out the domain-id from the domain info we just grabbed
    ${domainid}=    Parse Item From Blob By Offset    ${domain_item}    0
    Log    ${domainid}

    # parse out the name from the same info
    ${domainname}=    Parse Item From Blob By Offset    ${domain_item}    1
    Log    ${domainname}

    # generate the data payload that we wish to post
    ${data}=    Set Variable    {"roleid":"${roleid}", "description":"fabricated test roleid"}
    # post this monster
    ${content}=    Post Role To Domain And User    ${data}    ${domainid}    ${userid}
    # add new json string to the cleanup list for later cleanup
    Append To List    ${cleanup_grant_list}    ${content}
    Should Contain    ${content}    ${domainid}
    Should Contain    ${content}    ${roleid}
    Should Contain    ${content}    ${userid}


*** Keywords ***
IdMLight Suite Setup
    Log    Suite Setup
    # create a domain, role and user for testing.
    ${HEADERS}=    Create Dictionary    Content-Type=application/json
    Log    ${HEADERS}
    Set Global Variable    ${HEADERS}
    # create a name to use in each case
    ${testdomain}=    Create Random Name    Alderaan
    Log    ${testdomain}
    ${testuser}=    Create Random Name    Leia
    Log    ${testuser}
    ${testrole}=    Create Random Name    Force-User
    Log    ${testrole}
    # now create the domain, role and userid

    # create the test domain
    Create Session    httpbin    ${URI}
    ${domaindata}=    Set Variable    {"description":"planetary domain","domainid":"7","name":"${testdomain}","enabled":"true"}
    ${newdomain}=    Post New Domain    ${testdomain}    ${domaindata}
    Log    ${newdomain}
    # add new domain name to the cleanup list for later cleanup
    Append To List    ${cleanup_domain_list}    ${newdomain}
    # now create the test user
    ${userdata}=    Set Variable    {"description":"User-of-the-Force","name":"${testuser}","enabled":"true"}
    ${newuser}=    Post New User    ${testuser}    ${userdata}
    Log    ${newuser}
    # add new user name to the cleanup list for later cleanup
    Append To List    ${cleanup_user_list}    ${newuser}
    # now create the test role
    ${roledata}=    Set Variable    {"name":"${testrole}","description":"Force User"}
    ${newrole}=    Post New Role    ${roledata}
    # add new role name to the cleanup list for later cleanup
    Append To List    ${cleanup_role_list}    ${newrole}
    #
    # return the three item names to the caller of setup
    [Return]    ${newdomain}    ${newuser}    ${newrole}

IdMLight Suite Teardown
    Log    Suite Teardown
    ${ELEMENT}=    Create Session    httpbin    ${URI}
    # if the test domain, role or user exists, wipe it out.
    : FOR    ${ELEMENT}    IN    @{cleanup_domain_list}
    \    ${ELEMENT}    Replace String    ${ELEMENT}    ${SPACE}    ${EMPTY}
    \    Log    ${ELEMENT}
    \    # split it up to get the domainid
    \    ${x}=    Split String    ${ELEMENT}    ,
    \    ${y}=    Get From List    ${x}    0
    \    ${z}=    Split String    ${y}    :
    \    ${domainid}=    Get From List    ${z}    1
    \    Log    ${domainid}
    \    # convert name on the list to an ID, by which we delete this stuff
    \    Delete Domain    ${domainid}
    Log    ${cleanup_domain_list}
    # Cleanup roles that were created during testing
    : FOR    ${ELEMENT}    IN    @{cleanup_role_list}
    \    Log    ${ELEMENT}
    \    ${ELEMENT}    Replace String    ${ELEMENT}    ${SPACE}    ${EMPTY}
    \    Log    ${ELEMENT}
    \    # split it up to get the roleid
    \    ${x}=    Split String    ${ELEMENT}    ,
    \    ${y}=    Get From List    ${x}    0
    \    ${z}=    Split String    ${y}    :
    \    ${roleid}=    Get From List    ${z}    1
    \    Log    ${roleid}
    \    # convert name on the list to an ID, by which we delete this stuff
    \    Delete Role    ${roleid}
    Log    ${cleanup_role_list}
    # Cleanup users that were created during testing
    : FOR    ${ELEMENT}    IN    @{cleanup_user_list}
    \    Log    ${ELEMENT}
    \    ${ELEMENT}    Replace String    ${ELEMENT}    ${SPACE}    ${EMPTY}
    \    Log    ${ELEMENT}
    \    # split it up to get the roleid
    \    ${x}=    Split String    ${ELEMENT}    ,
    \    ${y}=    Get From List    ${x}    0
    \    ${z}=    Split String    ${y}    :
    \    ${userid}=    Get From List    ${z}    1
    \    Log    ${userid}
    \    Delete User    ${userid}
    Log    ${cleanup_user_list}
    
    Delete All Sessions

Check Specific Id Does Not Exist
    [Arguments]    ${area_to_look}    ${id}
    [Documentation]    Execute GET command on specified single id
    # the ITEM is the area to look under...    users, domains, roles, etc
    ${n1}=    Set Variable    auth/v1/${area_to_look}/${id}
    # do the actual get
    ${resp}    RequestsLibrary.Get    httpbin    ${n1}    headers=${HEADERS}
    Should Be Equal As Strings    ${resp.status_code}    404
    ${id_string}=    Convert To String    ${id}
    Should Contain    ${resp.content}    ${id_string}
    [Return]    ${resp.content}

Get Specific Domain
    [Arguments]    ${domainid}
    [Documentation]    Execute GET command on specified single domain
    ${n1}=    Set Variable    auth/v1/domains/${domainid}
    ${resp}    RequestsLibrary.Get    httpbin    ${n1}    headers=${HEADERS}
    Should Be Equal As Strings    ${resp.status_code}    200
    ${domainid_string}=    Convert To String    ${domainid}
    Should Contain    ${resp.content}    ${domainid_string}
    [Return]    ${resp.content}

Get Specific Domain Name
    [Arguments]    ${domainid}
    [Documentation]    Execute GET command on specified single domain
    ${n1}=    Set Variable    auth/v1/domains/${domainid}
    ${resp}    RequestsLibrary.Get    httpbin    ${n1}    headers=${HEADERS}
    Should Contain    ${resp.content}    ${domainid}
    Log    ${resp.content}
    [Return]    ${resp.content}

Get Specific Role
    [Arguments]    ${roleid}
    [Documentation]    Exercise REST command to GET a specific role, based on role-id
    ${n1}=    Set Variable    auth/v1/roles/${roleid}
    ${resp}    RequestsLibrary.Get    httpbin    ${n1}    headers=${HEADERS}
    Should Be Equal As Strings    ${resp.status_code}    200
    Should Contain    ${resp.content}    ${roleid}
    [Return]    ${resp.content}

Get Domains
    [Documentation]    Execute getdomains GET command.
    ${n1}=    Set Variable    auth/v1/domains
    ${resp}    RequestsLibrary.Get    httpbin    ${n1}    headers=${HEADERS}
    Should Be Equal As Strings    ${resp.status_code}    200
    Should Contain    ${resp.content}    "domains"
    [Return]    ${resp.content}

Get Roles
    [Documentation]    Execute GET command to obtain list of roles.
    ${n1}=    Set Variable    auth/v1/roles
    ${resp}    RequestsLibrary.Get    httpbin    ${n1}    headers=${HEADERS}
    Should Be Equal As Strings    ${resp.status_code}    200
    Should Contain    ${resp.content}    "roles"
    [Return]    ${resp.content}

Get Specific User
    [Arguments]    ${user}
    [Documentation]    Exercise REST command for users GET command.
    ${n1}=    Set Variable    auth/v1/users/${user}
    ${resp}    RequestsLibrary.Get    httpbin    ${n1}    headers=${HEADERS}
    Should Be Equal As Strings    ${resp.status_code}    200
    Should Contain    ${resp.content}    ${user}
    [Return]    ${resp.content}

Get Users
    [Documentation]    GET the complete set of users.
    ${n1}=    Set Variable    auth/v1/users
    ${resp}    RequestsLibrary.Get    httpbin    ${n1}    headers=${HEADERS}
    Should Be Equal As Strings    ${resp.status_code}    200
    Should Contain    ${resp.content}    ${user}
    [Return]    ${resp.content}

Post New Domain
    [Arguments]    ${domain}    ${data}
    [Documentation]    Exercise REST command for domains POST command.
    ${n1}=    Set Variable    auth/v1/domains
    ${resp}    RequestsLibrary.Post    httpbin    ${n1}    headers=${HEADERS}    data=${data}
    Should Be Equal As Strings    ${resp.status_code}    201
    Should Contain    ${resp.content}    ${domain}
    [Return]    ${resp.content}

Post New Role
    [Arguments]    ${data}
    [Documentation]    Use POST REST command to create specified Role.
    ${n1}=    Set Variable    auth/v1/roles
    ${resp}    RequestsLibrary.Post    httpbin    ${n1}    headers=${HEADERS}    data=${data}
    #    HTTP/1.1 201 Created
    Should Be Equal As Strings    ${resp.status_code}    201
    [Return]    ${resp.content}

Post New User
    [Arguments]    ${username}    ${data}
    [Documentation]    Exercise REST command for users POST command.
    ${n1}=    Set Variable    auth/v1/users
    ${resp}    RequestsLibrary.Post    httpbin    ${n1}    headers=${HEADERS}    data=${data}
    # grab the list of users, count the list, and then search the list for the specific user id
    ${users}=    Get Users
    ${depth}=    Nodecount    ${users}    users    userid
    ${abc}=    Get User Id By Username    ${users}    ${username}    ${depth}
    Should Be Equal As Strings    ${resp.status_code}    201
    Should Contain    ${resp.content}    ${username}
    [Return]    ${resp.content}

Get User By Name
    [Arguments]    ${jsonblock}    ${property}
    [Documentation]    hand this function a block of Json, and it will find your
    ...    user by name and return userid
    ${foundit}=    Get From Dictionary    ${jsonblock}    ${property}

Update Specific Domain
    [Arguments]    ${data}    ${domainid}
    [Documentation]    Update the specified domainid with a new name specified in domain-name
    ${n1}=    Set Variable    auth/v1/domains/${domainid}
    ${resp}    RequestsLibrary.Put    httpbin    ${n1}    headers=${HEADERS}    data=${data}
    # Should Be Equal As Strings    ${resp.status_code}    201
    Log    ${resp.content}

Update Specific Role
    [Arguments]    ${data}    ${roleid}
    [Documentation]    Update the specified roleid with a new information name specified
    ${n1}=    Set Variable    auth/v1/roles/${roleid}
    ${resp}    RequestsLibrary.Put    httpbin    ${n1}    headers=${HEADERS}    data=${data}
    # Should Be Equal As Strings    ${resp.status_code}    201
    Log    ${resp.content}

Update Specific User
    [Arguments]    ${data}    ${userid}
    [Documentation]    Update the specified userid with a new information name specified
    ${n1}=    Set Variable    auth/v1/users/${userid}
    ${resp}    RequestsLibrary.Put    httpbin    ${n1}    headers=${HEADERS}    data=${data}
    # Should Be Equal As Strings    ${resp.status_code}    201
    Log    ${resp.content}

Delete Domain
    [Arguments]    ${domainid}
    [Documentation]    Delete the specified domain, by id
    ${n1}=    Set Variable    auth/v1/domains/${domainid}
    Log    ${n1}
    ${resp}    RequestsLibrary.Delete    httpbin    ${n1}    headers=${HEADERS}
    Should Be Equal As Strings    ${resp.status_code}    204
    Log    ${resp.content}

Delete User
    [Arguments]    ${userid}
    [Documentation]    Delete the specified user, by id
    ${n1}=    Set Variable    auth/v1/users/${userid}
    ${resp}    RequestsLibrary.Delete    httpbin    ${n1}    headers=${HEADERS}
    Should Be Equal As Strings    ${resp.status_code}    204
    Log    ${resp.content}

Delete Role
    [Arguments]    ${roleid}
    [Documentation]    Use DELETE REST command to wipe out a Role created for testing.
    ${n1}=    Set Variable    auth/v1/roles/${roleid}
    ${resp}    RequestsLibrary.Delete    httpbin    ${n1}    headers=${HEADERS}
    Should Be Equal As Strings    ${resp.status_code}    204
    #Should NOT Contain    ${resp.content}    ${roleid}
    [Return]    ${resp.content}

Post Role To Domain And User
    [Arguments]    ${data}    ${domainid}    ${userid}
    [Documentation]    Exercise REST POST command for posting a role to particular domain and user
    ${n1}=    Set Variable    auth/v1/domains/${domainid}/users/${userid}/roles
    # now post it
    ${resp}    RequestsLibrary.Post    httpbin    ${n1}    headers=${HEADERS}    data=${data}
    Should Be Equal As Strings    ${resp.status_code}    201
    [Return]    ${resp.content}

Get Roles For Specific Domain And User
    [Arguments]    ${domainid}    ${userid}
    [Documentation]    Exercise REST GET command for roles in a specific domain and user
    ${n1}=    Set Variable    auth/v1/domains/${domainid}/users/${userid}/roles
    # now get it
    ${resp}    RequestsLibrary.Get    httpbin    ${n1}    headers=${HEADERS}
    Should Be Equal As Strings    ${resp.status_code}    200
    [Return]    ${resp.content}

Delete Specific Grant
    [Arguments]    ${domainid}    ${userid}    ${roleid}
    [Documentation]    Exercise REST DELETE command for a grant by roleid
    ${n1}=    Set Variable    auth/v1/domains/${domainid}/users/${userid}/roles/${roleid}
    # now delete it
    ${resp}    RequestsLibrary.Delete    httpbin    ${n1}    headers=${HEADERS}
    Should Be Equal As Strings    ${resp.status_code}    204
    [Return]    ${resp.content}

Parse Item From Blob By Offset
    [Documentation]    Parse out a field from JSON structure
    [Arguments]    ${item}    ${offset}
    ${x}=    Split String    ${item}    ,
    ${y}=    Get From List    ${x}    ${offset}
    ${z}=    Split String    ${y}    :

    # offset is one in next line because you are looking at a key:value pair
    ${return_item_}=    Get From List    ${z}    1
    ${return_item}=    Replace String    ${return_item_}    "    ${EMPTY}
    [Return]    ${return_item}

Create Random Name
    [Arguments]    ${basename}
    [Documentation]    Take the basename given and return a new name with date-time-stamp appended.
    ${datetime}=    Get Current Date    result_format=%Y-%m-%d-%H-%M
    Log    ${datetime}
    ${newname}=    Catenate    SEPARATOR=-    ${basename}    ${datetime}
    [Return]    ${newname}

Pop Name Off Json
    [Arguments]    ${jsonstring}
    [Documentation]    Pop the name item out of the Json string
    # split it up to get the id
    ${x}=    Split String    ${jsonstring}    ,
    ${y}=    Get From List    ${x}    1
    ${z}=    Split String    ${y}    :
    ${name}=    Get From List    ${z}    1
    ${name}=    Replace String    ${name}    "    ${EMPTY}
    Log    ${name}
    [Return]    ${name}

Verify Contents
    [Arguments]    ${content_block}    ${keyvar}
    [Documentation]    Verify that the content block passed in, contains the variable identified in second argument
    Should Contain    ${content_block}    ${keyvar}

Rough Clean
    [Documentation]    Clean up domains, users, roles in db, keep original 4 of each
    ${domains}=    Get Domains
    ${roles}=    Get Roles
    ${users}=    Get Users
    ${domcount}=    Nodecount    ${domains}    domains    "domainid"
    ${rolecount}=    Nodecount    ${roles}    roles    "roleid"
    ${usercount}=    Nodecount    ${users}    users    "userid"
    : FOR    ${index}    IN RANGE    5    ${domains}
    \    Delete Domain    ${index}
    : FOR    ${index}    IN RANGE    5    ${roles}
    \    Delete Role    ${index}
    : FOR    ${index}    IN RANGE    5    ${users}
    \    Delete User    ${index}
