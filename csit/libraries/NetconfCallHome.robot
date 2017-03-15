*** Settings ***
Library           SSHLibrary
Library           RequestsLibrary
Resource          SSHKeywords.robot
Variables         ../variables/Variables.py

*** Variables ***
${mount_point_url}    /restconf/operational/network-topology:network-topology/topology/topology-netconf/
${whitelist}      /restconf/config/odl-netconf-callhome-server:netconf-callhome-server/allowed-devices
${substring1}     "netconf-node-topology:connection-status":"connected"
${substring2}     "node-id":"netopeer"
${substring3}     "netconf-node-topology:available-capabilities"

*** Keywords ***
Get Netopeer Ready
    [Documentation]    Pulls the netopeer image from the docker repository. Points ODL(CallHome Server) IP in the files used by netopeer(CallHome Client).
    ${stdout}    ${stderr}    ${rc}=    SSHLibrary.Execute Command    docker pull odlcallhome/netopeer    return_stdout=True    return_stderr=True
    ...    return_rc=True
    ${stdout}    ${stderr}    ${rc}=    SSHLibrary.Execute Command    docker images    return_stdout=True    return_stderr=True
    ...    return_rc=True
    Reset Docker Compose Configuration

Reset Docker Compose Configuration
    [Documentation]    Resets the docker compose configurations.
    SSHLibrary.Put File    ${CURDIR}/../variables/netconf/callhome/docker-compose.yaml    .
    SSHLibrary.Put File    ${CURDIR}/../variables/netconf/callhome/datastore-server.xml    .
    SSHLibrary.Execute_Command    sed -i -e 's/ODL_SYSTEM_IP/${ODL_SYSTEM_IP}/g' docker-compose.yaml
    SSHLibrary.Execute_Command    sed -i -e 's/ODL_SYSTEM_IP/${ODL_SYSTEM_IP}/g' datastore-server.xml

Get Environment Ready
    [Documentation]    Get the scripts ready to set credentials and control whitelist maintained by the CallHome server.
    SSHLibrary.Put File    ${CURDIR}/../variables/netconf/callhome/whitelist_add.sh    .
    SSHLibrary.Put File    ${CURDIR}/../variables/netconf/callhome/credentials_set.sh    .
    SSHLibrary.Execute_Command    chmod +x whitelist_add.sh
    SSHLibrary.Execute_Command    chmod +x credentials_set.sh
    SSHLibrary.Execute_Command    sed -i -e 's/ODL_SYSTEM_IP/${ODL_SYSTEM_IP}/g' credentials_set.sh

Suite Setup
    [Documentation]    Get the suite ready for callhome test cases.
    RequestsLibrary.Create_Session    session    http://${ODL_SYSTEM_IP}:${RESTCONFPORT}    auth=${AUTH}    headers=${HEADERS_XML}
    Install Docker Compose on tools system
    Get Environment Ready
    Get Netopeer Ready

Install Docker Compose on tools system
    [Documentation]    Install docker-compose on tools system.
    ${netopeer_conn_id} =    SSHKeywords.Open_Connection_To_Tools_System
    Builtin.Set Suite Variable    ${netopeer_conn_id}
    SSHLibrary.Write    sudo curl -L "https://github.com/docker/compose/releases/download/1.11.1/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    ${output}=    Wait Until Keyword Succeeds    30s    2s    SSHLibrary.Read_Until_Prompt
    ${stdout}    ${stderr}    ${rc}=    SSHLibrary.Execute Command    sudo chmod +x /usr/local/bin/docker-compose    return_stdout=True    return_stderr=True
    ...    return_rc=True

Uninstall Docker Compose on tools system
    [Documentation]    Uninstall docker-compose on tools system
    ${stdout}    ${stderr}    ${rc}=    SSHLibrary.Execute Command    pip uninstall docker-compose    return_stdout=True    return_stderr=True
    ...    return_rc=True

Suite Teardown
    [Documentation]    Tearing down the setup.
    Uninstall Docker Compose on tools system
    RequestsLibrary.Delete_All_Sessions
    SSHLibrary.Close_All_Connections

Do Controller Get Expect Success
    [Arguments]    ${url}    @{expected_value}
    [Documentation]    Perform a READ operation on the URL and also checks if the operation was successful and has a list of expected values in the content.
    ${resp} =    RequestsLibrary.Get_Request    session    ${url}
    BuiltIn.Log    ${resp.content}
    BuiltIn.Should_Be_Equal    ${resp.status_code}    ${200}
    BuiltIn.Should_Contain Any    ${resp.content}    @{expected_value}
    [Return]    ${resp.content}

Test Teardown
    [Documentation]    Tears down the docker running netopeer and deletes entry from the whitelist.
    SSHLibrary.Execute Command    docker-compose down
    ${resp} =    RequestsLibrary.Delete_Request    session    ${whitelist}
