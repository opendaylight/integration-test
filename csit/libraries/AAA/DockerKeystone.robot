*** Settings ***
Documentation     DockerKeystone library. This library is useful to deal with Openstack Keystone service which provides API client authentication.
...
...               It consists of three main groups of keywords:
...
...               - Start/Stop keystone node in SYSTEM TOOLS VM:
...               - Run Docker Keystone
...               - Destroy Docker Keystone
...
...               - Provision keystone node:
...               - Create Keystone session
...               - Get Keystone Token
...               - Create Keystone Domain
...               - Create Keystone User in a Domain
...               - Set Domain To False
...               - Get Admin Role Id
...               - Grant Admin Role
...               - Delete Keystone Domain
...
...               - Provision ODL node for secure communication with Keystone node:
...               - Set Keystone Certificate into ODL
Library           SSHLibrary
Library           RequestsLibrary

*** Variables ***

*** Keywords ***
Get Keystone Token
    [Arguments]    ${TOOLS_SYSTEM_NAME}    ${CREATE_TOKEN_FILE}
    [Documentation]    Get Keystone token for a particular user and domain
    Set Suite Variable    ${CREATE_TOKEN_URI}    /v3/auth/tokens/
    ${body}    OperatingSystem.Get File    ${CREATE_TOKEN_FILE}
    Log    ${HEADERS}
    ${resp}=    RequestsLibrary.Post Request    session_keystone    ${CREATE_TOKEN_URI}    data=${body}    headers=${HEADERS}    allow_redirects=${true}
    Should Contain    ${ALLOWED_STATUS_CODES}    ${resp.status_code}
    ${token}    Get From Dictionary    ${resp.headers}    x-subject-token
    [Return]    ${token}

Create Keystone session
    [Arguments]    ${TOOLS_SYSTEM_NAME}
    [Documentation]    Create a https session with Keystone for provisioning new domains, users, projects ...
    Log    ${HEADERS}
    Create Session    session_keystone    https://${TOOLS_SYSTEM_NAME}:35357    auth=${AUTH_ADMIN_SDN}    headers=${HEADERS}    debug=3

Create Keystone Domain
    [Arguments]    ${HEADERS}    ${CREATE_DOMAIN_FILE}
    [Documentation]    Provision a domain in Keystone
    Set Suite Variable    ${CREATE_DOMAIN_URI}    /v3/domains/
    ${body}    OperatingSystem.Get File    ${CREATE_DOMAIN_FILE}
    ${resp}    RequestsLibrary.Post Request    session_keystone    ${CREATE_DOMAIN_URI}    data=${body}    headers=${HEADERS}
    Should Contain    ${ALLOWED_STATUS_CODES}    ${resp.status_code}
    ${domain_id}    Convert To String    ${resp.json()['domain']['id']}
    [Return]    ${domain_id}

Create Keystone User in a Domain
    [Arguments]    ${HEADERS}    ${CREATE_USERS_FILE}
    [Documentation]    Provision an user associated to a domain in \ Keystone
    Set Suite Variable    ${CREATE_USERS_URI}    /v3/users/
    ${body}    OperatingSystem.Get File    ${CREATE_USERS_FILE}
    ${resp}    RequestsLibrary.Post Request    session_keystone    ${CREATE_USERS_URI}    data=${body}    headers=${HEADERS}
    Should Contain    ${ALLOWED_STATUS_CODES}    ${resp.status_code}
    ${user_id}    Convert To String    ${resp.json()['user']['id']}
    [Return]    ${user_id}

Grant Admin Role
    [Arguments]    ${domain}    ${user}    ${roleid}    ${HEADERS}
    [Documentation]    Grant a role to an user in a domain in \ Keystone
    Set Suite Variable    ${GRANT_ADMIN_ROLE_URI}    /v3/domains/${domain}/users/${user}/roles/${roleid}
    ${resp}    RequestsLibrary.Put Request    session_keystone    ${GRANT_ADMIN_ROLE_URI}    headers=${HEADERS}
    Should Contain    ${ALLOWED_STATUS_CODES}    ${resp.status_code}

Get Admin Role Id
    [Arguments]    ${HEADERS}
    [Documentation]    Get admin role id from Keystone
    Set Suite Variable    ${GET_ADMIN_ROLE_URI}    /v3/roles?name=admin
    ${resp}=    RequestsLibrary.Get Request    session_keystone    ${GET_ADMIN_ROLE_URI}    headers=${HEADERS}
    Should Contain    ${ALLOWED_STATUS_CODES}    ${resp.status_code}
    ${admin_role_id}    Convert To String    ${resp.json()['roles'][0]['id']}
    Log    ${admin_role_id}
    [Return]    ${admin_role_id}

Run Docker Keystone
    [Documentation]    Run Keystone in a docker container hosted in the SYSTEM TOOL server and define "CSC_user" and "CSC_user_no_admin" users, the former with "admin" role and the latter with "user" role
    ${output}    SSHLibrary.Open_Connection    ${TOOLS_SYSTEM_IP}    timeout=20s
    Utils.Flexible_Controller_Login
    SSHLibrary.Put File    ${CURDIR}/../../suites/aaa/keystone/start_keystone.sh
    SSHLibrary.Execute Command    ./start_keystone.sh    return_stdout=True    return_stderr=True    return_rc=True
    :FOR    ${count}    IN RANGE    10
    \    BuiltIn.Sleep    15s
    \    ${status}    SSHLibrary.Execute Command    docker exec -it keystone bash -c "grep /v3/roles?name=user /var/log/nginx-access.log|grep GET|wc -l"    return_stdout=False    return_stderr=False    return_rc=True
    \    Exit For Loop If    '${status}' == '1'
    : FOR    ${count}    IN RANGE    10
    \    ${status}    SSHLibrary.Execute Command    docker exec -t keystone bash -c "source openrc;openstack user create --password cscuser CSC_user;openstack user set --project admin CSC_user;openstack role add --project admin --user CSC_user admin;openstack role add --domain default --user CSC_user admin;openstack user list"    return_stdout=False    return_stderr=False    return_rc=True
    \    Exit For Loop If    '${status}' == '0'
    \    BuiltIn.Sleep    5s
    SSHLibrary.Execute Command    docker exec -t keystone bash -c "source openrc;openstack user create --password cscusernoadmin CSC_user_no_admin;openstack user set --project admin CSC_user_no_admin;openstack role add --project admin --user CSC_user_no_admin user;openstack user list"    return_stdout=True    return_stderr=True    return_rc=True
    [Return]    ${output}

Destroy Docker Keystone
    [Documentation]    Destroy keystone container and remove mysql database
    ${output}    SSHLibrary.Execute Command    docker stop keystone;docker rm keystone    return_stdout=True    return_stderr=True    return_rc=True
    ${output}    SSHLibrary.Execute Command    sudo rm -rf /var/lib/mysql/    return_stdout=True    return_stderr=True    return_rc=True
    [Return]    ${output}

Set Domain To False
    [Arguments]    ${domain}    ${HEADERS}
    [Documentation]    Disable domain in keystone
    Set Suite Variable    ${PATCH_DOMAIN_URI}    /v3/domains/${domain}
    Set Suite Variable    ${PATCH_DOMAIN_FILE}    ${CURDIR}/../../variables/aaa/patch-domain.json
    ${body}    OperatingSystem.Get File    ${PATCH_DOMAIN_FILE}
    ${resp}    RequestsLibrary.Patch Request    session_keystone    ${PATCH_DOMAIN_URI}    data=${body}    headers=${HEADERS}
    Should Contain    ${ALLOWED_STATUS_CODES}    ${resp.status_code}

Delete Keystone Domain
    [Arguments]    ${domain}    ${HEADERS}
    [Documentation]    Delete domain in \ Keystone
    Set Suite Variable    ${DELETE_DOMAIN_URI}    /v3/domains/${domain}
    ${resp}    RequestsLibrary.Delete Request    session_keystone    ${DELETE_DOMAIN_URI}    headers=${HEADERS}
    Should Contain    ${ALLOWED_STATUS_CODES}    ${resp.status_code}

Set Keystone Certificate into ODL
    [Arguments]    ${PUT_KEYSTONE_CERT_FILE}    ${TOOLS_SYSTEM_NAME}
    [Documentation]    Install Keystone Certificate into ODL
    SSHLibrary.Get File    ${USER_HOME}${/}keystone_cert.pem    ${USER_HOME}${/}key_cert.pem
    ${keystone_certificate}    ${rc}    SSHLibrary.Execute Command    cat keystone_cert.pem|grep -v CERTIFICATE|tr -d '\n'    return_stdout=True    return_stderr=False    return_rc=True
    Create Session    session_admin    http://${ODL_SYSTEM_IP}:${RESTCONFPORT}    auth=${AUTH}    headers=${HEADERS}
    Set Suite Variable    ${PUT_CERTIFICATE_URI}    /restconf/operations/aaa-cert-rpc:setNodeCertifcate
    ${normalized_file}=    OperatingSystem.Normalize Path    ${PUT_KEYSTONE_CERT_FILE}
    ${output}    OperatingSystem.Run    sed -i 's#\"node-cert\".*#\"node-cert\"\: \"${keystone_certificate}\",#g' ${PUT_KEYSTONE_CERT_FILE}
    ${output}    OperatingSystem.Run    sed -i 's#\"node-alias\".*#\"node-alias\"\: \"${TOOLS_SYSTEM_NAME}\"#g' ${PUT_KEYSTONE_CERT_FILE}
    ${body_cert}    OperatingSystem.Get File    ${PUT_KEYSTONE_CERT_FILE}
    ${resp}    RequestsLibrary.Post Request    session_admin    ${PUT_CERTIFICATE_URI}    data=${body_cert}    headers=${HEADERS}
    Should Contain    ${ALLOWED_STATUS_CODES}    ${resp.status_code}
