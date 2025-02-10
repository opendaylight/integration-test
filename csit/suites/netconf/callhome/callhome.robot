*** Settings ***
Documentation       Test suite to verify callhome functionality over SSH transport protocol. Registration in OpenDaylight
...                 Controller happens via restconf interface. Netopeer2-server docker container plays a role of the
...                 netconf device with call-home feature. Docker-compose file is used to configure netopeer2 docker
...                 container(netconf configuration templates, host-key).

Resource            ../../../libraries/NetconfCallHome.robot
Resource            ../../../libraries/CompareStream.robot

Suite Setup         Suite Setup
Suite Teardown      Suite Teardown
Test Setup          Test Setup
Test Teardown       Test Teardown


*** Test Cases ***
CallHome over SSH with correct device credentials
    [Documentation]    Correct credentials should result to successful mount. CONNECTED should be the device status.
    Apply SSH-based Call-Home configuration
    Register SSH call-home device in ODL controller    netopeer2    ${NETOPEER_PUB_KEY}    root    root
    ${stdout}    ${stderr}    ${rc}=    SSHLibrary.Execute Command
    ...    docker-compose up -d
    ...    return_stdout=True
    ...    return_stderr=True
    ...    return_rc=True
    Wait Until Keyword Succeeds    90s    2s    NetconfCallHome.Check Device Status    CONNECTED
    Wait Until Keyword Succeeds
    ...    30s
    ...    2s
    ...    Utils.Check For Elements At URI
    ...    ${mount_point_url}
    ...    ${netconf_mount_expected_values}

CallHome over SSH with incorrect device credentials
    [Documentation]    Correct credentials should result to successful mount. CONNECTED should be the device status.
    Apply SSH-based Call-Home configuration
    Register SSH call-home device in ODL controller    netopeer2    ${NETOPEER_PUB_KEY}    root    incorrect
    ${stdout}    ${stderr}    ${rc}=    SSHLibrary.Execute Command
    ...    docker-compose up -d
    ...    return_stdout=True
    ...    return_stderr=True
    ...    return_rc=True
    Wait Until Keyword Succeeds    90s    2s    NetconfCallHome.Check Device Status    FAILED_AUTH_FAILURE
    Wait Until Keyword Succeeds
    ...    30s
    ...    2s
    ...    Run Keyword And Expect Error
    ...    *
    ...    Utils.Check For Elements At URI
    ...    ${mount_point_url}
    ...    ${netconf_mount_expected_values}

CallHome over SSH with correct global credentials
    [Documentation]    CallHome SSH device registered with global credentials should result to successful mount.
    Apply SSH-based Call-Home configuration
    Register global credentials for SSH call-home devices    root    root
    Register SSH call-home device in ODL controller    netopeer2    ${NETOPEER_PUB_KEY}
    ${stdout}    ${stderr}    ${rc}=    SSHLibrary.Execute Command
    ...    docker-compose up -d
    ...    return_stdout=True
    ...    return_stderr=True
    ...    return_rc=True
    Wait Until Keyword Succeeds    90s    2s    NetconfCallHome.Check Device Status    CONNECTED
    Wait Until Keyword Succeeds
    ...    30s
    ...    2s
    ...    Utils.Check For Elements At URI
    ...    ${mount_point_url}
    ...    ${netconf_mount_expected_values}

CallHome over SSH with incorrect global credentials
    [Documentation]    CallHome SSH device registered with wrong global credentials should fail to mount.
    Apply SSH-based Call-Home configuration
    Register global credentials for SSH call-home devices    root    incorrect
    Register SSH call-home device in ODL controller    netopeer2    ${NETOPEER_PUB_KEY}
    ${stdout}    ${stderr}    ${rc}=    SSHLibrary.Execute Command
    ...    docker-compose up -d
    ...    return_stdout=True
    ...    return_stderr=True
    ...    return_rc=True
    Wait Until Keyword Succeeds    90s    2s    NetconfCallHome.Check Device Status    FAILED_AUTH_FAILURE
    Wait Until Keyword Succeeds
    ...    30s
    ...    2s
    ...    Run Keyword And Expect Error
    ...    *
    ...    Utils.Check For Elements At URI
    ...    ${mount_point_url}
    ...    ${netconf_mount_expected_values}

CallHome with Incorrect Node-id
    [Documentation]    CallHome from device that does not have an entry in per-device credential with result to mount point failure.
    Apply SSH-based Call-Home configuration
    Register SSH call-home device in ODL controller    incorrect_hostname    ${INCORRECT_PUB_KEY}    root    root
    Register SSH call-home device in ODL controller    netopeer2    ${NETOPEER_PUB_KEY}
    ${stdout}    ${stderr}    ${rc}=    SSHLibrary.Execute Command
    ...    docker-compose up -d
    ...    return_stdout=True
    ...    return_stderr=True
    ...    return_rc=True
    Wait Until Keyword Succeeds    90s    2s    NetconfCallHome.Check Device Status    DISCONNECTED
    Wait Until Keyword Succeeds
    ...    30s
    ...    2s
    ...    Run Keyword And Expect Error
    ...    *
    ...    Utils.Check For Elements At URI
    ...    ${mount_point_url}
    ...    ${netconf_mount_expected_values}

CallHome with Rogue Devices
    [Documentation]    A Rogue Device will fail to callhome and wont be able to mount because the keys are not added in whitelist.
    ...    FAILED_NOT_ALLOWED should be the device status.
    Apply SSH-based Call-Home configuration
    Register SSH call-home device in ODL controller    netopeer2    ${INCORRECT_PUB_KEY}    root    root
    ${stdout}    ${stderr}    ${rc}=    SSHLibrary.Execute Command
    ...    docker-compose up -d
    ...    return_stdout=True
    ...    return_stderr=True
    ...    return_rc=True
    Wait Until Keyword Succeeds    90s    2s    NetconfCallHome.Check Device Status    FAILED_NOT_ALLOWED
    Wait Until Keyword Succeeds
    ...    30s
    ...    2s
    ...    Run Keyword And Expect Error
    ...    *
    ...    Utils.Check For Elements At URI
    ...    ${mount_point_url}
    ...    ${netconf_mount_expected_values}

CallHome over TLS with correct certificate and key
    [Documentation]    Using correct certificate and key pair should result to successful mount. CONNECTED should be the device status.
    Apply TLS-based Call-Home configuration
    Register keys and certificates in ODL controller
    Register TLS call-home device in ODL controller    netopeer2    tls-device-key    tls-device-certificate
    ${stdout}    ${stderr}    ${rc}=    SSHLibrary.Execute Command
    ...    docker-compose up -d
    ...    return_stdout=True
    ...    return_stderr=True
    ...    return_rc=True
    Wait Until Keyword Succeeds    90s    2s    NetconfCallHome.Check Device Status    CONNECTED
    Wait Until Keyword Succeeds
    ...    30s
    ...    2s
    ...    Utils.Check For Elements At URI
    ...    ${mount_point_url}
    ...    ${netconf_mount_expected_values}
