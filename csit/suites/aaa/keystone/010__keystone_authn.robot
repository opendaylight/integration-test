*** Settings ***
Documentation     Test suite: Authentication Support for Keystone
...
...               This feature implements the user management for ODL NBI REST APIs integrated with OpenStack, so that the authentication functionality provided by Keystone can be used. This allows consuming ODL NBI REST APIs using the same authentication procedures as any OpenStack project, such as Nova, Neutron, etc. bringing the benefits of a centralized / unified user management framework.
...
...               As a first step, It shall be possible to authenticate users against Keystone by using passwords provided by the users.
Suite Setup       Init Suite
Suite Teardown    Cleanup Suite
Test Timeout
Library           SSHLibrary
Library           Collections
Library           OperatingSystem
Library           RequestsLibrary
Resource          ../../../libraries/Utils.robot
Resource          ../../../libraries/TemplatedRequests.robot
Resource          ../../../libraries/KarafKeywords.robot
Resource          ../../../libraries/ClusterManagement.robot
Resource          ../../../variables/Variables.robot
Resource          ../../../libraries/AAA/DockerKeystone.robot

*** Variables ***

*** Test Cases ***
Successful Authentication Including Domain
    [Documentation]    *Test Case: Successful Authentication with user@domain/password credentials*
    ...
    ...    Steps:
    ...
    ...    - Create an HTTP session with ODL as "sdnadmin" user in "sdn" domain
    ...    - Check that the access to URLs of ODL NBI is allowed \ because "sdnadmin" user is associated to domain "sdn" in Keystone and the provided password is the right one.
    ...
    ...    Note:
    ...
    ...    - URL "/restconf/operations/aaa-cert-rpc:getODLCertificate" ia authorized just for "admin" roles according to shiro.ini configuration. As "sdnadmin" has "admin" role in keystone the access is authorized too
    ...
    ...    - URL "/restconf/operational/ietf-restconf-monitoring:restconf-state" is not specified neither in shiro.ini nor in MDSAL Dynamic Authorization so no specific role is required
    [Tags]
    Create Session    session    http://${ODL_SYSTEM_IP}:8181    auth=${AUTH_SDN_DOMAIN}    headers=${HEADERS}
    ${resp}=    RequestsLibrary.Post Request    session    /restconf/operations/aaa-cert-rpc:getODLCertificate    headers=${HEADERS}
    Should Contain    ${ALLOWED_STATUS_CODES}    ${resp.status_code}
    ${resp}=    RequestsLibrary.Get Request    session    /restconf/operational/ietf-restconf-monitoring:restconf-state    headers=${HEADERS}
    Should Contain    ${ALLOWED_STATUS_CODES}    ${resp.status_code}

Successful Authentication Without Domain
    [Documentation]    *Test Case: Successful Authentication with user/password credentials. No domain included*
    ...
    ...    Steps:
    ...
    ...    - Create an HTTP session with ODL as "CSC_user" user without specifying any domain then domain "Default" is considered
    ...    - Check that the access to URLs of ODL NBI is allowed because "CSC_user" user is associated to domain "Default" in Keystone and the provided password is the right one
    ...
    ...    Note:
    ...
    ...    - URL "/restconf/operations/aaa-cert-rpc:getODLCertificate" ia authorized just for "admin" roles according to shiro.ini configuration. As "CSC_user" has "admin" role in keystone the access is authorized too
    ...
    ...    - URL "/restconf/operational/ietf-restconf-monitoring:restconf-state" is not specified neither in shiro.ini nor in MDSAL Dynamic Authorization so no specific role is required
    [Tags]
    Create Session    session    http://${ODL_SYSTEM_IP}:8181    auth=${AUTH_CSC_SDN}    headers=${HEADERS}
    ${resp}=    RequestsLibrary.Post Request    session    /restconf/operations/aaa-cert-rpc:getODLCertificate    headers=${HEADERS}
    Should Contain    ${ALLOWED_STATUS_CODES}    ${resp.status_code}
    ${resp}=    RequestsLibrary.Get Request    session    /restconf/operational/ietf-restconf-monitoring:restconf-state    headers=${HEADERS}
    Should Contain    ${ALLOWED_STATUS_CODES}    ${resp.status_code}

Unsuccessful Authentication Wrong User
    [Documentation]    *Test Case: UnSuccessful Authentication with worng user/password credentials*
    ...
    ...    Steps:
    ...
    ...    - Create an HTTP session with ODL as an invalid user
    ...    - Check that the access to URLs of ODL NBI is NOT allowed \ because "invaliduser" user does not exist in Keystone
    ...
    ...    Note:
    ...
    ...    Due to authentication fails, authorization is not evaluated
    [Tags]
    Create Session    session    http://${ODL_SYSTEM_IP}:8181    auth=${AUTH_INVALID}    headers=${HEADERS}
    ${resp}=    RequestsLibrary.Post Request    session    /restconf/operations/aaa-cert-rpc:getODLCertificate    headers=${HEADERS}
    Should Contain    ${UNAUTHORIZED_STATUS_CODES}    ${resp.status_code}
    ${resp}=    RequestsLibrary.Get Request    session    /restconf/operational/ietf-restconf-monitoring:restconf-state    headers=${HEADERS}
    Should Contain    ${UNAUTHORIZED_STATUS_CODES}    ${resp.status_code}

UnSuccessful Authentication Without Domain
    [Documentation]    *Test Case: UnSuccessful Authentication without domain*
    ...
    ...    Steps:
    ...
    ...
    ...    - Create an HTTP session with ODL as "sdnadmin" user without specifying any domain then domain "Default" is considered
    ...    - Check that the access to URLs of ODL NBI is NOT allowed because "sdnadmin" user is not associated to domain "Default" in Keystone but to "sdn" which is not included in the credentials
    ...
    ...    Note:
    ...
    ...    Due to authentication fails, authorization is not evaluated
    [Tags]
    Create Session    session    http://${ODL_SYSTEM_IP}:8181    auth=${AUTH_SDN}    headers=${HEADERS}
    ${resp}=    RequestsLibrary.Post Request    session    /restconf/operations/aaa-cert-rpc:getODLCertificate    headers=${HEADERS}
    Should Contain    ${UNAUTHORIZED_STATUS_CODES}    ${resp.status_code}
    ${resp}=    RequestsLibrary.Get Request    session    /restconf/operational/ietf-restconf-monitoring:restconf-state    headers=${HEADERS}
    Should Contain    ${UNAUTHORIZED_STATUS_CODES}    ${resp.status_code}

Unsuccessful Authentication Wrong Domain
    [Documentation]    *Test Case: UnSuccessful Authentication with wrong domain*
    ...
    ...    Steps:
    ...
    ...    Steps:
    ...
    ...    - Create an HTTP session with ODL as "sdnadmin" user with "wrong" as domain
    ...    - Check that the access to URLs of ODL NBI is NOT allowed because "sdnadmin" user is not associated to domain "wrong" in Keystone but to "sdn"
    ...
    ...    Note:
    ...
    ...    Due to authentication fails, authorization is not evaluated
    [Tags]
    Create Session    session    http://${ODL_SYSTEM_IP}:8181    auth=${AUTH_SDN_WRONG_DOM}    headers=${HEADERS}
    ${resp}=    RequestsLibrary.Post Request    session    /restconf/operations/aaa-cert-rpc:getODLCertificate    headers=${HEADERS}
    Should Contain    ${UNAUTHORIZED_STATUS_CODES}    ${resp.status_code}
    ${resp}=    RequestsLibrary.Get Request    session    /restconf/operational/ietf-restconf-monitoring:restconf-state    headers=${HEADERS}
    Should Contain    ${UNAUTHORIZED_STATUS_CODES}    ${resp.status_code}

Unsuccessful Basic Authorization
    [Documentation]    *Test Case: UnSuccessful Basic Authorization*
    ...
    ...    Steps:
    ...
    ...    - Provision MDSAL so that users with role "admin" or "user" are authorized to access all URIs
    ...    - Create an HTTP session with ODL as "CSC_user_no_admin" user
    ...    - Check that the access to URL "/restconf/operations/aaa-cert-rpc:getODLCertificate" is NOT authorized because in shiro.ini configuration the access is allowed just to "admin" roles and "CSC_user_no_admin" does not have \ "admin" role in keystone but "user" role even though the MDSAL Dynamic Authorization would allow the access, that is, authorization process is an "AND" operation between shiro.ini and MDSAL Dynamic Authorization
    ...    - Check that the access to URL "/restconf/operational/ietf-restconf-monitoring:restconf-state" is authorized becaiuse thhat URL is not specified in shiro.ini and in MDSAL Dynamic Authorization access to all URLs is allowed to all user with "user" role
    [Tags]
    Set Suite Variable    ${PUT_DYNAMIC_AUTH_FILE}    ${CURDIR}/../../../variables/aaa/put-dynamic-auth.json
    Provision MDSAL    ${PUT_DYNAMIC_AUTH_FILE}
    Create Session    session    http://${ODL_SYSTEM_IP}:8181    auth=${AUTH_CSC_NO_ADMIN}    headers=${HEADERS}
    ${resp_ok}=    RequestsLibrary.Get Request    session    /restconf/operational/ietf-restconf-monitoring:restconf-state    headers=${HEADERS}
    Should Contain    ${ALLOWED_STATUS_CODES}    ${resp_ok.status_code}
    ${resp_nook}=    RequestsLibrary.Post Request    session    /restconf/operations/aaa-cert-rpc:getODLCertificate    headers=${HEADERS}
    Should Contain    ${UNAUTHORIZED_STATUS_CODES}    ${resp_nook.status_code}

Unsuccessful Dynamic Authorization
    [Documentation]    *Test Case: UnSuccessful Dynamic Authorization*
    ...
    ...    Steps:
    ...
    ...    - Provision MDSAL so that just users with role "admin" are authorized to access all URIs
    ...    - Create an HTTP session with ODL as "CSC_user_no_admin" user
    ...    - Check that the access to URL "/restconf/operations/aaa-cert-rpc:getODLCertificate" is NOT authorized because in shiro.ini configuration the access is allowed just to "admin" roles and "CSC_user_no_admin" does not have \ "admin" role in keystone but "user" role even though the MDSAL Dynamic Authorization would allow the access, that is, authorization process is an "AND" operation between shiro.ini and MDSAL Dynamic Authorization
    ...    - Check that the access to URL "/restconf/operational/ietf-restconf-monitoring:restconf-state" is NOT authorized because although the URL is not specified in shiro.ini, in MDSAL Dynamic Authorization access to all URLs is allowed just for users with "admin" role and "CSC_user_no_admin" does not have \ "admin" role in keystone but "user" role
    [Tags]
    Set Suite Variable    ${PUT_DYNAMIC_AUTH_FILE}    ${CURDIR}/../../../variables/aaa/put-dynamic-auth-2.json
    Provision MDSAL    ${PUT_DYNAMIC_AUTH_FILE}
    Create Session    session    http://${ODL_SYSTEM_IP}:8181    auth=${AUTH_CSC_NO_ADMIN}    headers=${HEADERS}
    ${resp_nook}=    RequestsLibrary.Get Request    session    /restconf/operational/ietf-restconf-monitoring:restconf-state    headers=${HEADERS}
    Should Contain    ${UNAUTHORIZED_STATUS_CODES}    ${resp_nook.status_code}
    ${resp_nook}=    RequestsLibrary.Post Request    session    /restconf/operations/aaa-cert-rpc:getODLCertificate    headers=${HEADERS}
    Should Contain    ${UNAUTHORIZED_STATUS_CODES}    ${resp_nook.status_code}

Unsuccessful Dynamic Authorization 2
    [Documentation]    *Test Case: UnSuccessful Dynamic Authorization 2*
    ...
    ...    Steps:
    ...
    ...    - Provision MDSAL so that:
    ...    \ \ - URI "/restconf/operations/aaa-cert-rpc:getODLCertificate" is authorized just for users with "user" role
    ...    \ - URI "/restconf/operational/**" is authorized just for users with "user" role
    ...
    ...    - Create an HTTP session with ODL as "sdnadmin" user
    ...    - Check that the access to URL "/restconf/operations/aaa-cert-rpc:getODLCertificate" is NOT authorized because although in shiro.ini configuration the access is allowed to "admin" roles and "cscadmin" does have \ "admin" role, \ in MDSAL Dynamic Authorization access to that URL is allowed just for users with "user" role and "cscadmin" does not have \ "user" role in keystone but "admin" role
    ...    - Check that the access to URL "/restconf/operational/ietf-restconf-monitoring:restconf-state" is NOT authorized because although in shiro.ini configuration that URL is not considered, \ in MDSAL Dynamic Authorization access to that URL is allowed just for users with "user" role and "cscadmin" does not have \ "user" role in keystone but "admin" role
    ...
    ...
    ...    - Create an HTTP session with ODL as "CSC_user_no_admin" user
    ...    - Check that the access to URL "/restconf/operations/aaa-cert-rpc:getODLCertificate" is NOT authorized because in shiro.ini configuration the access is allowed just to "admin" roles and "CSC_user_no_admin" does not have \ "admin" role in keystone but "user" role even though the MDSAL Dynamic Authorization would allow the access, that is, authorization process is an "AND" operation between shiro.ini and MDSAL Dynamic Authorization
    ...    - Check that the access to URL "/restconf/operational/ietf-restconf-monitoring:restconf-state" is authorized because the URL is not specified in shiro.ini and in MDSAL Dynamic Authorization access to that URL is allowed just for users with "user" role and "CSC_user_no_admin" does \ have \ "user" role in keystone
    [Tags]    include
    Set Suite Variable    ${PUT_DYNAMIC_AUTH_FILE}    ${CURDIR}/../../../variables/aaa/put-dynamic-auth-3.json
    Provision MDSAL    ${PUT_DYNAMIC_AUTH_FILE}
    Create Session    session    http://${ODL_SYSTEM_IP}:8181    auth=${AUTH_SDN_DOMAIN}    headers=${HEADERS}
    ${resp}=    RequestsLibrary.Post Request    session    /restconf/operations/aaa-cert-rpc:getODLCertificate    headers=${HEADERS}
    Should Contain    ${UNAUTHORIZED_STATUS_CODES}    ${resp.status_code}
    ${resp}=    RequestsLibrary.Get Request    session    /restconf/operational/ietf-restconf-monitoring:restconf-state    headers=${HEADERS}
    Should Contain    ${UNAUTHORIZED_STATUS_CODES}    ${resp.status_code}
    Create Session    session    http://${ODL_SYSTEM_IP}:8181    auth=${AUTH_CSC_NO_ADMIN}    headers=${HEADERS}
    ${resp}=    RequestsLibrary.Get Request    session    /restconf/operational/ietf-restconf-monitoring:restconf-state    headers=${HEADERS}
    Should Contain    ${ALLOWED_STATUS_CODES}    ${resp.status_code}
    ${resp}=    RequestsLibrary.Post Request    session    /restconf/operations/aaa-cert-rpc:getODLCertificate    headers=${HEADERS}
    Should Contain    ${UNAUTHORIZED_STATUS_CODES}    ${resp.status_code}

Unsuccessful No Keystone Connection
    [Documentation]    *Test Case: Unsuccessful No Keystone Connection*
    ...
    ...    Steps:
    ...
    ...    - Put down Keystone
    ...    - All accesses are forbidden
    [Tags]    include
    Cleanup Suite
    Create Session    session    http://${ODL_SYSTEM_IP}:8181    auth=${AUTH_SDN_DOMAIN}    headers=${HEADERS}
    ${resp}=    RequestsLibrary.Post Request    session    /restconf/operations/aaa-cert-rpc:getODLCertificate    headers=${HEADERS}
    Should Contain    ${UNAUTHORIZED_STATUS_CODES}    ${resp.status_code}
    ${resp}=    RequestsLibrary.Get Request    session    /restconf/operational/ietf-restconf-monitoring:restconf-state    headers=${HEADERS}
    Should Contain    ${UNAUTHORIZED_STATUS_CODES}    ${resp.status_code}
    Create Session    session    http://${ODL_SYSTEM_IP}:8181    auth=${AUTH_CSC_NO_ADMIN}    headers=${HEADERS}
    ${resp}=    RequestsLibrary.Get Request    session    /restconf/operational/ietf-restconf-monitoring:restconf-state    headers=${HEADERS}
    Should Contain    ${UNAUTHORIZED_STATUS_CODES}    ${resp.status_code}
    ${resp}=    RequestsLibrary.Post Request    session    /restconf/operations/aaa-cert-rpc:getODLCertificate    headers=${HEADERS}
    Should Contain    ${UNAUTHORIZED_STATUS_CODES}    ${resp.status_code}

*** Keywords ***
Init Suite
    [Documentation]    The steps included in the Initialization phase are:
    ...
    ...    - Run Docker Keystone: Deploy a container in the SYSTEM TOOL node containing the Keystone
    ...
    ...    - Configure AAA in Controller: shiro.ini file is modified to add new authentication realm based on Keystone
    ...
    ...    - Restart Controller: This restart is needed in order to activate new shiro.ini configuration
    ...
    ...    - Provision Keystone: Populate keystone database with the needed users and roles
    ...
    ...    - Install Keystone certificate into ODL so that the protocol used in the ODL-Keystone communication is HTTPS with server certificate authentication
    ${TOOLS_SYSTEM_NAME}    Run Command On Remote System    ${TOOLS_SYSTEM_IP}    hostname -f    user=${TOOLS_SYSTEM_USER}    password=${TOOLS_SYSTEM_PASSWORD}
    Run Docker Keystone
    Configure AAA In Controller    ${TOOLS_SYSTEM_NAME}
    Restart Controller
    Provision Keystone
    Set Suite Variable    ${PUT_KEYSTONE_CERT_FILE}    ${CURDIR}/../../../variables/aaa/put-keystone-cert.json
    Set Keystone Certificate into ODL    ${PUT_KEYSTONE_CERT_FILE}    ${TOOLS_SYSTEM_NAME}
    Set Suite Variable    ${PUT_DYNAMIC_AUTH_FILE}    ${CURDIR}/../../../variables/aaa/put-dynamic-auth.json
    Provision MDSAL    ${PUT_DYNAMIC_AUTH_FILE}

Cleanup Suite
    [Documentation]    Destoy keystone container
    ${result}    Run Keyword And Return Status    Set Domain To False    ${domain}    ${HEADERS_TOKEN}
    Run Keyword If    ${result} == True    Delete Keystone Domain    ${domain}    ${HEADERS_TOKEN}
    Run Keyword If    ${result} == True    Destroy Docker Keystone

Configure AAA In Controller
    [Arguments]    ${TOOLS_SYSTEM_NAME}
    [Documentation]    With this keyword shiro.ini and aaa-cert-config.xml are modified to configure Keystone Authentication Realm using TLS1.2. Here you have the settings:
    ...
    ...    - shiro.ini:
    ...
    ...    keystoneAuthRealm = org.opendaylight.aaa.shiro.realm.KeystoneAuthRealm
    ...    keystoneAuthRealm.url = https://sandbox-29591-30-docker-0:35357
    ...    keystoneAuthRealm.sslVerification = true
    ...
    ...    securityManager.realms = $tokenAuthRealm, $keystoneAuthRealm
    ...
    ...
    ...
    ...
    ...    - aaa-cert-config.xml:
    ...    <use-config>true</use-config>
    ...
    ...    <tls-protocols>TLSv1.2</tls-protocols>
    ${shiro_path}    Run Command On Controller    cmd=cd /;find /|grep shiro.ini|grep etc|grep -v denied
    ${cert_path}    Run Command On Controller    cmd=cd /;find /|grep aaa-cert-config.xml|grep etc|grep -v denied
    ${result}    Run Command On Controller    cmd=sed -ie 's/#keystoneAuthRealm =.*/keystoneAuthRealm = org.opendaylight.aaa.shiro.realm.KeystoneAuthRealm/g' ${shiro_path}
    ${result}    Run Command On Controller    cmd=sed -ie 's/#keystoneAuthRealm.url =.*/keystoneAuthRealm.url = https:\\/\\/${TOOLS_SYSTEM_NAME}:35357/g' ${shiro_path}
    ${result}    Run Command On Controller    cmd=sed -ie 's/securityManager.realms =.*/securityManager.realms = $tokenAuthRealm, $keystoneAuthRealm/g' ${shiro_path}
    ${result}    Run Command On Controller    cmd=sed -ie 's/#keystoneAuthRealm.sslVerification =.*/keystoneAuthRealm.sslVerification = true/g' ${shiro_path}
    ${result}    Run Command On Controller    cmd=sed -ie 's/\\/operations\\/aaa-cert-rpc.*/\\/operations\\/aaa-cert-rpc** = authcBasic, roles[admin], dynamicAuthorization/g' ${shiro_path}
    ${result}    Run Command On Controller    cmd=sed -ie 's/<use-config>.*/<use-config>true<\\/use-config>/g' ${cert_path}
    ${result}    Run Command On Controller    cmd=sed -ie 's/<tls-protocols.*/<tls-protocols>TLSv1.2<\\/tls-protocols>/g' ${cert_path}
    ${result}    Run Command On Controller    cmd=cat ${shiro_path}
    Log    ${result}
    ${result}    Run Command On Controller    cmd=cat ${cert_path}
    Log    ${result}
    ${result}    Run Command On Controller    cmd=sudo sed -i "2i${TOOLS_SYSTEM_IP} \ \ ${TOOLS_SYSTEM_NAME}" /etc/hosts
    ${result}    Run Command On Controller    cmd=cat /etc/hosts
    Log    ${result}

Restart Controller
    [Documentation]    Controller restart is needed in order the new shiro.ini config takes effect
    ${result}    Run Command On Controller    cmd=${NODE_KILL_COMMAND}
    sleep    2
    ${result}    Run Command On Controller    cmd=${NODE_START_COMMAND}
    sleep    60

Provision Keystone
    [Documentation]    As CSC_user provision:
    ...    - Domain "sdn"
    ...    - User "sdnadmin"
    ...    - Role "admin" to "sdnadmin" user in "sdn" domain
    ${result}    Create Keystone session    ${TOOLS_SYSTEM_IP}
    Log    ${result}
    Set Suite Variable    ${CREATE_TOKEN_FILE}    ${CURDIR}/../../../variables/aaa/create-token.json
    ${status}    Run Keyword And Return Status    Get Keystone Token    ${TOOLS_SYSTEM_IP}    ${CREATE_TOKEN_FILE}
    Run Keyword If    ${status}==False    Get Keystone Token    ${TOOLS_SYSTEM_IP}    ${CREATE_TOKEN_FILE}
    Log    ${HEADERS}
    &{HEADERS}    Create Dictionary    X-Auth-Token=${token}    Content-Type=application/json
    Set Suite Variable    ${HEADERS_TOKEN}    ${HEADERS}
    ${admin_role_id}    Get Admin Role Id    ${HEADERS_TOKEN}
    Set Suite Variable    ${CREATE_DOMAIN_FILE}    ${CURDIR}/../../../variables/aaa/create-domain.json
    ${domain_local}    Create Keystone Domain    ${HEADERS_TOKEN}    ${CREATE_DOMAIN_FILE}
    Set Suite Variable    ${domain}    ${domain_local}
    Set Suite Variable    ${CREATE_USERS_FILE}    ${CURDIR}/../../../variables/aaa/create-user.json
    ${normalized_file}=    OperatingSystem.Normalize Path    ${CREATE_USERS_FILE}
    ${output}    OperatingSystem.Run    sed -i 's/\"domain_id\".*/\"domain_id\"\: \"${domain}\",/g' ${CREATE_USERS_FILE}
    ${user}    Create Keystone User in a Domain    ${HEADERS_TOKEN}    ${CREATE_USERS_FILE}
    Grant Admin Role    ${domain}    ${user}    ${admin_role_id}    ${HEADERS_TOKEN}

Provision MDSAL
    [Arguments]    ${PUT_DYNAMIC_AUTH_FILE}
    Create Session    session_admin    http://${ODL_SYSTEM_IP}:8181    auth=${AUTH}    headers=${HEADERS}
    Set Suite Variable    ${PUT_DYNAMIC_AUTH_URI}    /restconf/config/aaa:http-authorization
    ${body_dyn}    OperatingSystem.Get File    ${PUT_DYNAMIC_AUTH_FILE}
    ${resp}    RequestsLibrary.Put Request    session_admin    ${PUT_DYNAMIC_AUTH_URI}    data=${body_dyn}    headers=${HEADERS}
    Should Contain    ${ALLOWED_STATUS_CODES}    ${resp.status_code}
    Delete Request    session_admin    http://${ODL_SYSTEM_IP}:8181
