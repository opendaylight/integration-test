*** Settings ***
Documentation     Test suite to verify Restconf is OK.
Suite Setup       RequestsLibrary.Create_Session    session    http://${ODL_SYSTEM_IP}:${RESTCONFPORT}    auth=${AUTH}    headers=${HEADERS_XML}
Suite Teardown    RequestsLibrary.Delete_All_Sessions
Library           RequestsLibrary
Library           SSHLibrary
Resource	  ${CURDIR}/../../../libraries/SSHKeywords.robot
Variables         ${CURDIR}/../../../variables/Variables.py

*** Test Cases ***
Get Controller Modules
    [Documentation]    Get the restconf modules, check 200 status and ietf-restconf presence.
    ${resp} =    RequestsLibrary.Get_Request    session    ${MODULES_API}
    BuiltIn.Log    ${resp.content}
    BuiltIn.Should_Be_Equal    ${resp.status_code}    ${200}
    BuiltIn.Should_Contain    ${resp.content}    ietf-restconf

Getting Netopeer ready for CallHome
    [Documentation]    Pull the docker image for Netopeer and get it ready.
    ${netopeer_conn_id} =    SSHKeywords.Open_Connection_To_Tools_System
    Builtin.Set Suite Variable    ${netopeer_conn_id}
    ${stdout}    ${stderr}    ${rc}=    SSHLibrary.Execute Command    docker ps -a    return_stdout=True    return_stderr=True
    ...    return_rc=True
    ${stdout}    ${stderr}    ${rc}=    SSHLibrary.Execute Command    docker pull odlcallhome/netopeer    return_stdout=True    return_stderr=True
    ...    return_rc=True
