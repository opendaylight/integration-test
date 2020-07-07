*** Settings ***
Documentation     Test suite to verify callhome functionality over both transport protocols (TLS and SSH) according to RFC8071.
...               Registration in OpenDaylight Controller is done via new YANG models. Netopeer2-server docker container plays
...               a role of netconf device configured with call-home. Every test case provides custom configuration for
...               netopeer2-server via docker-compose file to cover sunny-day and error scenarios.
Suite Setup       Suite Setup
Suite Teardown    Suite Teardown
Test Setup        Test Setup
Test Teardown     Test Teardown
Resource          ../../../libraries/NetconfCallHome.robot


*** Test Cases ***
CallHome with Incorrect global Credentials
    [Documentation]    Incorrect global credentials should result to mount failure. FAILED_AUTH_FAILURE should be the device status.
    Apply SSH-based Call-Home configuration
    Register global credentials for SSH call-home devices (APIv1)    incorrect    root
    Register SSH call-home device in ODL controller (APIv1)    netopeer2    ${EMPTY}    ${EMPTY}    ${NETOPEER_PUB_KEY}
    ${stdout}    ${stderr}    ${rc}=    SSHLibrary.Execute Command    docker-compose up -d    return_stdout=True    return_stderr=True
    ...    return_rc=True
    Wait Until Keyword Succeeds    30s    2s    NetconfCallHomeV2.Check Device Status    FAILED_AUTH_FAILURE
    Wait Until Keyword Succeeds    30s    2s    Run Keyword And Expect Error    *    Utils.Check For Elements At URI    ${mount_point_url}
    ...    ${netconf_mount_expected_values}

CallHome with Incorrect per-device Credentials
    [Documentation]    Incorrect per-device credentials should result to mount failure. FAILED_AUTH_FAILURE should be the device status.
    Apply SSH-based Call-Home configuration
    Register SSH call-home device in ODL controller (APIv1)    netopeer2    root    incorrect    ${NETOPEER_PUB_KEY}
    ${stdout}    ${stderr}    ${rc}=    SSHLibrary.Execute Command    docker-compose up -d    return_stdout=True    return_stderr=True
    ...    return_rc=True
    Wait Until Keyword Succeeds    30s    2s    NetconfCallHomeV2.Check Device Status    FAILED_AUTH_FAILURE
    Wait Until Keyword Succeeds    30s    2s    Run Keyword And Expect Error    *    Utils.Check For Elements At URI    ${mount_point_url}
    ...    ${netconf_mount_expected_values}

CallHome with Incorrect Node-id
    [Documentation]    CallHome from device that does not have an entry in per-device credential with result to mount point failure.
    Apply SSH-based Call-Home configuration
    Register SSH call-home device in ODL controller (APIv1)    incorrect_hostname    root    root    ${EMPTY}
    Register SSH call-home device in ODL controller (APIv1)    netopeer2    ${EMPTY}    ${EMPTY}    ${NETOPEER_PUB_KEY}
    ${stdout}    ${stderr}    ${rc}=    SSHLibrary.Execute Command    docker-compose up -d    return_stdout=True    return_stderr=True
    ...    return_rc=True
    Wait Until Keyword Succeeds    30s    2s    NetconfCallHomeV2.Check Device Status    DISCONNECTED
    Wait Until Keyword Succeeds    30s    2s    Run Keyword And Expect Error    *    Utils.Check For Elements At URI    ${mount_point_url}
    ...    ${netconf_mount_expected_values}

CallHome with Rogue Devices
    [Documentation]    A Rogue Device will fail to callhome and wont be able to mount because the keys are not added in whitelist.
    ...    FAILED_NOT_ALLOWED should be the device status.
    Apply SSH-based Call-Home configuration
    Register SSH call-home device in ODL controller (APIv1)    netopeer2    root    root    incorrect-key-value
    ${stdout}    ${stderr}    ${rc}=    SSHLibrary.Execute Command    docker-compose up -d    return_stdout=True    return_stderr=True
    ...    return_rc=True
    # Next line is commented due to https://jira.opendaylight.org/browse/NETCONF-574
    #Wait Until Keyword Succeeds    30s    2s    NetconfCallHomeV2.Check Device Status    FAILED_NOT_ALLOWED
    Wait Until Keyword Succeeds    30s    2s    Run Keyword And Expect Error    *    Utils.Check For Elements At URI    ${mount_point_url}
    ...    ${netconf_mount_expected_values}

Successful CallHome with correct global credentials
    [Documentation]    Device being in whitelist of the Call Home server along with correct global credentials will result to successful mount.
    ...    CONNECTED should be the device status.
    Apply SSH-based Call-Home configuration
    Register global credentials for SSH call-home devices (APIv1)    root    root
    Register SSH call-home device in ODL controller (APIv1)    netopeer2    ${EMPTY}    ${EMPTY}    ${NETOPEER_PUB_KEY}
    ${stdout}    ${stderr}    ${rc}=    SSHLibrary.Execute Command    docker-compose up -d    return_stdout=True    return_stderr=True
    ...    return_rc=True
    Wait Until Keyword Succeeds    30s    2s    NetconfCallHomeV2.Check Device Status    CONNECTED
    Wait Until Keyword Succeeds    30s    2s    Utils.Check For Elements At URI    ${mount_point_url}    ${netconf_mount_expected_values}

Successful CallHome with correct per-device credentials
    [Documentation]    Device being in whitelist of the Call Home server along with correct per-device credentials will result to successful mount.
    ...    CONNECTED should be the device status.
    Apply SSH-based Call-Home configuration
    Register SSH call-home device in ODL controller (APIv1)    netopeer2    root    root    ${NETOPEER_PUB_KEY}
    ${stdout}    ${stderr}    ${rc}=    SSHLibrary.Execute Command    docker-compose up -d    return_stdout=True    return_stderr=True
    ...    return_rc=True
    Wait Until Keyword Succeeds    30s    2s    NetconfCallHomeV2.Check Device Status    CONNECTED
    Wait Until Keyword Succeeds    30s    2s    Utils.Check For Elements At URI    ${mount_point_url}    ${netconf_mount_expected_values}
