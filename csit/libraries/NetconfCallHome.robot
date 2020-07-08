*** Settings ***
Library           SSHLibrary
Library           RequestsLibrary
Resource          SSHKeywords.robot
Resource          ../variables/Variables.robot

*** Variables ***
${mount_point_url}    /restconf/operational/network-topology:network-topology/topology/topology-netconf/
${device_status}    /restconf/operational/odl-netconf-callhome-server:netconf-callhome-server
${whitelist}      /restconf/config/odl-netconf-callhome-server:netconf-callhome-server/allowed-devices
${global_config_url}    /restconf/config/odl-netconf-callhome-server:netconf-callhome-server/global/credentials
${netconf_keystore_url}    /rests/operations/netconf-keystore
${substring1}     "netconf-node-topology:connection-status":"connected"
${substring2}     "node-id":"netopeer2"
${substring3}     "netconf-node-topology:available-capabilities"

*** Keywords ***
Check Device status
    [Arguments]    ${status}    ${id}=netopeer2
    [Documentation]    Checks the operational device status.
    @{expectedValues}    Create List    "unique-id":"${id}"    "callhome-status:device-status":"${status}"
    Run Keyword If    '${status}'=='FAILED_NOT_ALLOWED' or '${status}'=='FAILED_AUTH_FAILURE'    Remove Values From List    ${expectedValues}    "unique-id":"${id}"
    Utils.Check For Elements At URI    ${device_status}    ${expectedValues}

Apply SSH-based Call-Home configuration
    [Documentation]    Upload netopeer2 configuration files needed for SSH transport
    SSHLibrary.Put File    ${CURDIR}/../variables/netconf/callhome/configuration-files/ssh/ietf-netconf-server.xml
    ...    configuration-files/ietf-netconf-server.xml
    SSHLibrary.Put File    ${CURDIR}/../variables/netconf/callhome/configuration-files/ssh/ietf-keystore.xml
    ...    configuration-files/ietf-keystore.xml

Apply TLS-based Call-Home configuration
    [Documentation]    Upload netopeer2 configuration files needed for TLS transport
    SSHLibrary.Put File    ${CURDIR}/../variables/netconf/callhome/configuration-files/tls/ietf-keystore.xml
    ...    configuration-files/ietf-keystore.xml
    SSHLibrary.Put File    ${CURDIR}/../variables/netconf/callhome/configuration-files/tls/ietf-truststore.xml
    ...    configuration-files/ietf-truststore.xml
    SSHLibrary.Put File    ${CURDIR}/../variables/netconf/callhome/configuration-files/tls/ietf-netconf-server.xml
    ...    configuration-files/ietf-netconf-server.xml

Generate certificates for TLS configuration
    [Documentation]    Generates certificates for 2-way TLS authentication (ca, server, client)
    ${stdout}    ${stderr}    ${rc}=    SSHLibrary.Execute Command    rm -rf ./certs && mkdir ./certs
    ...    return_stderr=True    return_stdout=True    return_rc=True

    ${stdout}    ${stderr}    ${rc}=    SSHLibrary.Execute Command    openssl genrsa -out ./certs/ca.key 2048
    ...    return_stderr=True    return_stdout=True    return_rc=True
    ${stdout}    ${stderr}    ${rc}=    SSHLibrary.Execute Command    openssl req -x509 -new -nodes -key ./certs/ca.key -sha256 -days 365 -subj "/C=US/ST=CA/L=Netopeer/O=netopeerCA/CN=netopeerCA"  -out ./certs/ca.pem
    ...    return_stderr=True    return_stdout=True    return_rc=True

    ${stdout}    ${stderr}    ${rc}=    SSHLibrary.Execute Command    openssl genrsa -out ./certs/server.key 2048
    ...    return_stderr=True    return_stdout=True    return_rc=True
    ${stdout}    ${stderr}    ${rc}=    SSHLibrary.Execute Command    openssl req -new -sha256 -key ./certs/server.key -subj "/C=US/ST=CA/L=Netopeer/O=Netopeer2/CN=netopeer2-server" -out ./certs/server.csr
    ...    return_stderr=True    return_stdout=True    return_rc=True
    ${stdout}    ${stderr}    ${rc}=    SSHLibrary.Execute Command    openssl x509 -req -in ./certs/server.csr -CA ./certs/ca.pem -CAkey ./certs/ca.key -CAcreateserial -out ./certs/server.crt -days 365 -sha256
    ...    return_stderr=True    return_stdout=True    return_rc=True
    ${stdout}    ${stderr}    ${rc}=    SSHLibrary.Execute Command    openssl rsa -in ./certs/server.key -pubout > ./certs/server.pub
    ...    return_stderr=True    return_stdout=True    return_rc=True

    ${stdout}    ${stderr}    ${rc}=    SSHLibrary.Execute Command    openssl genrsa -out ./certs/client.key 2048
        ...    return_stderr=True    return_stdout=True    return_rc=True
    ${stdout}    ${stderr}    ${rc}=    SSHLibrary.Execute Command    openssl req -new -sha256 -key ./certs/client.key -subj "/C=US/ST=CA/L=Netopeer/O=Netopeer2/CN=netopeer2-client" -out ./certs/client.csr
    ...    return_stderr=True    return_stdout=True    return_rc=True
    ${stdout}    ${stderr}    ${rc}=    SSHLibrary.Execute Command    openssl x509 -req -in ./certs/client.csr -CA ./certs/ca.pem -CAkey ./certs/ca.key -CAcreateserial -out ./certs/client.crt -days 1024 -sha256
    ...    return_stderr=True    return_stdout=True    return_rc=True

    ${stdout}    ${stderr}    ${rc}=    SSHLibrary.Execute Command    mv ./certs ./configuration-files/certs
        ...    return_stderr=True    return_stdout=True    return_rc=True

Register pre-configured certificates and key in ODL controller
    [Documentation]    Register pre-configured netopeer2 certificates and key in ODL-netconf keystore
    ${template}    OperatingSystem.Get File    ${ADD_KEYSTORE_ENTRY_REQ}
    ${resp}    RequestsLibrary.Post Request    session    ${netconf_keystore_url}:add-keystore-entry    data=${template}    headers=${HEADERS}
    Should Contain    ${ALLOWED_STATUS_CODES}    ${resp.status_code}
    ${template}    OperatingSystem.Get File    ${ADD_PRIVATE_KEY_REQ}
    ${resp}    RequestsLibrary.Post Request    session    ${netconf_keystore_url}:add-private-key    data=${template}    headers=${HEADERS}
    Should Contain    ${ALLOWED_STATUS_CODES}    ${resp.status_code}
    ${template}    OperatingSystem.Get File    ${ADD_TRUSTED_CERTIFICATE}
    ${resp}    RequestsLibrary.Post Request    session    ${netconf_keystore_url}:add-trusted-certificate    data=${template}    headers=${HEADERS}
    Should Contain    ${ALLOWED_STATUS_CODES}    ${resp.status_code}

Register global credentials for SSH call-home devices (APIv1)
    [Arguments]    ${username}    ${password}
    [Documentation]    Set global credentials for SSH call-home devices
    ${template}    OperatingSystem.Get File    ${CREATE_GLOBAL_CREDENTIALS_REQ}
    ${body}    Replace String    ${template}    {username}    ${username}
    ${body}    Replace String    ${body}    {password}    ${password}
    ${resp}    RequestsLibrary.Put Request    session    ${global_config_url}    data=${body}    headers=${HEADERS}
    Should Contain    ${ALLOWED_STATUS_CODES}    ${resp.status_code}

Register SSH call-home device in ODL controller (APIv1)
    [Arguments]    ${device_name}    ${hostkey}    ${username}=${EMPTY}    ${password}=${EMPTY}
    [Documentation]    Registration call-home device with SSH transport
    Run Keyword If    '${username}' == '${EMPTY}' or '${password}' == '${EMPTY}'    Get create device request without credentials template (APIv1)
    ...    ELSE    Get create device request template (APIv1)
    ${body}    Replace String    ${template}    {device_name}    ${device_name}
    ${body}    Replace String    ${body}    {username}    ${username}
    ${body}    Replace String    ${body}    {password}    ${password}
    ${body}    Replace String    ${body}    {hostkey}    ${hostkey}
    ${resp}    RequestsLibrary.Post Request    session    ${whitelist}    data=${body}    headers=${HEADERS}
    Should Contain    ${ALLOWED_STATUS_CODES}    ${resp.status_code}

Get create device request template (APIv1)
    ${template}    OperatingSystem.Get File    ${CREATE_SSH_DEVICE_REQ_V1}
    Set Test Variable    ${template}

Get create device request without credentials template (APIv1)
    ${template}    OperatingSystem.Get File    ${CREATE_SSH_DEVICE_REQ_V1_HOST_KEY_ONLY}
    Set Test Variable    ${template}

Register SSH call-home device in ODL controller (APIv2)
    [Arguments]    ${device_name}    ${hostkey}    ${username}=${EMPTY}    ${password}=${EMPTY}
    [Documentation]    Registration call-home device with SSH transport using latest models
    Run Keyword If    '${username}' == '${EMPTY}' or '${password}' == '${EMPTY}'    Get create device request without credentials template (APIv2)
    ...    ELSE    Get create device request template (APIv2)
    ${body}    Replace String    ${template}    {device_name}    ${device_name}
    ${body}    Replace String    ${body}    {username}    ${username}
    ${body}    Replace String    ${body}    {password}    ${password}
    ${body}    Replace String    ${body}    {hostkey}    ${hostkey}
    ${resp}    RequestsLibrary.Post Request    session    ${whitelist}    data=${body}    headers=${HEADERS}
    Should Contain    ${ALLOWED_STATUS_CODES}    ${resp.status_code}

Get create device request template (APIv2)
    ${template}    OperatingSystem.Get File    ${CREATE_SSH_DEVICE_REQ_V2}
    Set Test Variable    ${template}

Get create device request without credentials template (APIv2)
    ${template}    OperatingSystem.Get File    ${CREATE_SSH_DEVICE_REQ_V2_HOST_KEY_ONLY}
    Set Test Variable    ${template}

Register TLS call-home device in ODL controller (APIv2)
    [Arguments]    ${device_name}    ${key_id}    ${certificate_id}
    [Documentation]    Registration call-home device with TLS transport
    ${template}    OperatingSystem.Get File    ${CREATE_TLS_DEVICE_REQ}
    ${body}    Replace String    ${template}    {device_name}    ${device_name}
    ${body}    Replace String    ${body}    {key_id}    ${key_id}
    ${body}    Replace String    ${body}    {certificate_id}    ${certificate_id}
    ${resp}    RequestsLibrary.Post Request    session    ${whitelist}    data=${body}    headers=${HEADERS}
    Should Contain    ${ALLOWED_STATUS_CODES}    ${resp.status_code}

Pull Netopeer2 Docker Image
    [Documentation]    Pulls the netopeer image from the docker repository.
    ${stdout}    ${stderr}    ${rc}=    SSHLibrary.Execute Command    docker pull sysrepo/sysrepo-netopeer2:latest    return_stdout=True    return_stderr=True
    ...    return_rc=True
    ${stdout}    ${stderr}    ${rc}=    SSHLibrary.Execute Command    docker images    return_stdout=True    return_stderr=True
    ...    return_rc=True

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

Test Setup
    [Documentation]    Opens session towards ODL controller, set configuration folder, generates a new host key for the container
    RequestsLibrary.Create_Session    session    http://${ODL_SYSTEM_IP}:${RESTCONFPORT}    auth=${AUTH}
    SSHLibrary.Execute_Command    rm -rf ./configuration-files && mkdir configuration-files
    SSHLibrary.Execute_Command    ssh-keygen -q -t rsa -b 2048 -N '' -f ./configuration-files/ssh_host_rsa_key
    ${public_key}    SSHLibrary.Execute_Command    cat configuration-files/ssh_host_rsa_key.pub | awk '{print $2}'
    Set Test Variable    ${NETOPEER_PUB_KEY}    ${public_key}

Test Teardown
    [Documentation]    Tears down the docker running netopeer and deletes entry from the whitelist.
    ${stdout}    ${stderr}    ${rc}=    SSHLibrary.Execute Command    docker-compose down    return_stdout=True    return_stderr=True
    ...    return_rc=True
    ${stdout}    ${stderr}    ${rc}=    SSHLibrary.Execute Command    docker ps -a    return_stdout=True    return_stderr=True
    ...    return_rc=True
    SSHLibrary.Execute_Command    rm -rf ./configuration-files
    ${resp} =    RequestsLibrary.Delete_Request    session    ${whitelist}

Suite Setup
    [Documentation]    Get the suite ready for callhome test cases.
    Install Docker Compose on tools system
    Pull Netopeer2 Docker Image
    SSHLibrary.Put File    ${CURDIR}/../variables/netconf/callhome/docker-compose.yaml    .
    SSHLibrary.Put File    ${CURDIR}/../variables/netconf/callhome/init_configuration.sh    .
    SSHLibrary.Execute_Command    sed -i -e 's/ODL_SYSTEM_IP/${ODL_SYSTEM_IP}/g' docker-compose.yaml
    ${netconf_mount_expected_values}    Create list    ${substring1}    ${substring2}    ${substring3}
    Set Suite Variable    ${netconf_mount_expected_values}
    Set Suite Variable    ${CREATE_SSH_DEVICE_REQ_V1}    ${CURDIR}/../variables/netconf/callhome/json/apiv1/create_device.json
    Set Suite Variable    ${CREATE_SSH_DEVICE_REQ_V1_HOST_KEY_ONLY}    ${CURDIR}/../variables/netconf/callhome/json/apiv1/create_device_hostkey_only.json
    Set Suite Variable    ${CREATE_GLOBAL_CREDENTIALS_REQ}    ${CURDIR}/../variables/netconf/callhome/json/apiv1/create_global_credentials.json
    Set Suite Variable    ${CREATE_SSH_DEVICE_REQ_V2}    ${CURDIR}/../variables/netconf/callhome/json/apiv2/create_ssh_device.json
    Set Suite Variable    ${CREATE_SSH_DEVICE_REQ_V2_HOST_KEY_ONLY}    ${CURDIR}/../variables/netconf/callhome/json/apiv2/create_device_hostkey_only.json
    Set Suite Variable    ${CREATE_TLS_DEVICE_REQ}    ${CURDIR}/../variables/netconf/callhome/json/apiv2/create_tls_device.json
    Set Suite Variable    ${ADD_KEYSTORE_ENTRY_REQ}    ${CURDIR}/../variables/netconf/callhome/json/apiv2/add_keystore_entry.json
    Set Suite Variable    ${ADD_PRIVATE_KEY_REQ}    ${CURDIR}/../variables/netconf/callhome/json/apiv2/add_private_key.json
    Set Suite Variable    ${ADD_TRUSTED_CERTIFICATE}    ${CURDIR}/../variables/netconf/callhome/json/apiv2/add_trusted_certificate.json

Suite Teardown
    [Documentation]    Tearing down the setup.
    Uninstall Docker Compose on tools system
    RequestsLibrary.Delete_All_Sessions
    SSHLibrary.Close_All_Connections
