*** Settings ***
Library           SSHLibrary
Library           RequestsLibrary
Resource          SSHKeywords.robot
Resource          ../variables/Variables.robot

*** Variables ***
${mount_point_url}    /restconf/operational/network-topology:network-topology/topology/topology-netconf/
${device_status}    /restconf/operational/odl-netconf-callhome-server:netconf-callhome-server
${whitelist}      /restconf/config/odl-netconf-callhome-server:netconf-callhome-server/allowed-devices
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
   SSHLibrary.Put File    ${CURDIR}/../variables/netconf/callhome/v2/configuration-files/ssh/ietf-netconf-server.xml    configuration-files/ietf-netconf-server.xml
   SSHLibrary.Put File    ${CURDIR}/../variables/netconf/callhome/v2/configuration-files/ssh/ietf-keystore.xml    configuration-files/ietf-keystore.xml

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
    [Documentation]    Opens session towards ODL controller, set configuration folder, generates a new RSA host key for the container
    RequestsLibrary.Create_Session    session    http://${ODL_SYSTEM_IP}:${RESTCONFPORT}    auth=${AUTH}
    SSHLibrary.Execute_Command    rm -rf ./configuration-files && mkdir configuration-files
    SSHLibrary.Execute_Command    ssh-keygen -q -t rsa -b 2048 -N '' -f ./configuration-files/ssh_host_rsa_key

Test Teardown
    [Documentation]    Tears down the docker running netopeer and deletes entry from the whitelist.
    ${stdout}    ${stderr}    ${rc}=    SSHLibrary.Execute Command    docker-compose down    return_stdout=True    return_stderr=True
    ...    return_rc=True
    ${stdout}    ${stderr}    ${rc}=    SSHLibrary.Execute Command    docker ps -a    return_stdout=True    return_stderr=True
    ...    return_rc=True
    SSHLibrary.Execute_Command    rm -rf ./configuration-filess
    ${resp} =    RequestsLibrary.Delete_Request    session    ${whitelist}

Suite Setup
    [Documentation]    Get the suite ready for callhome test cases.
    Install Docker Compose on tools system
    Pull Netopeer2 Docker Image
    SSHLibrary.Put File    ${CURDIR}/../variables/netconf/callhome/v2/docker-compose.yaml    .
    SSHLibrary.Put File    ${CURDIR}/../variables/netconf/callhome/v2/init_configuration.sh    .
    SSHLibrary.Execute_Command    sed -i -e 's/ODL_SYSTEM_IP/${ODL_SYSTEM_IP}/g' docker-compose.yaml
    ${netconf_mount_expected_values}    Create list    ${substring1}    ${substring2}    ${substring3}
    Set Suite Variable    ${netconf_mount_expected_values}

Suite Teardown
    [Documentation]    Tearing down the setup.
    Uninstall Docker Compose on tools system
    RequestsLibrary.Delete_All_Sessions
    SSHLibrary.Close_All_Connections
