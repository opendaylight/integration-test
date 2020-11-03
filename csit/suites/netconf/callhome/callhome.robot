*** Settings ***
Documentation     Test suite to verify callhome functionality where the Call Home Server(CONTROLLER) is provisioned with device
...               certificates when docker-compose is invoked. Every test case does a SED operation to search and replace words
...               to cover the happy path and negative scenarios.
Suite Setup       Suite Setup
Suite Teardown    Suite Teardown
Test Setup        Reset Docker Compose Configuration
Test Teardown     Test Teardown
Resource          ../../../libraries/NetconfCallHome.robot

*** Test Cases ***
CallHome with Incorrect global Credentials
    [Documentation]    Incorrect global credentials should result to mount failure. FAILED_AUTH_FAILURE should be the device status.
    SSHLibrary.Execute_Command    sed -i -e 's/global root/global incorrect/g' docker-compose.yaml
    ${stdout}    ${stderr}    ${rc}=    SSHLibrary.Execute Command    docker-compose up -d    return_stdout=True    return_stderr=True
    ...    return_rc=True
    Wait Until Keyword Succeeds    90s    2s    NetconfCallHome.Check Device Status    FAILED_AUTH_FAILURE
    Wait Until Keyword Succeeds    30s    2s    Run Keyword And Expect Error    *    Utils.Check For Elements At URI    ${mount_point_url}
    ...    ${netconf_mount_expected_values}

CallHome with Incorrect per-device Credentials
    [Documentation]    Incorrect per-device credentials should result to mount failure. FAILED_AUTH_FAILURE should be the device status.
    SSHLibrary.Execute_Command    sed -i -e 's/global root/per-device netopeer incorrect/g' docker-compose.yaml
    ${stdout}    ${stderr}    ${rc}=    SSHLibrary.Execute Command    docker-compose up -d    return_stdout=True    return_stderr=True
    ...    return_rc=True
    Wait Until Keyword Succeeds    90s    2s    NetconfCallHome.Check Device Status    FAILED_AUTH_FAILURE
    Wait Until Keyword Succeeds    30s    2s    Run Keyword And Expect Error    *    Utils.Check For Elements At URI    ${mount_point_url}
    ...    ${netconf_mount_expected_values}

CallHome with Incorrect Node-id
    [Documentation]    CallHome from device that does not have an entry in per-device credential with result to mount point failure.
    SSHLibrary.Execute_Command    sed -i -e 's/global/per-device incorrect_hostname/g' docker-compose.yaml    return_rc=True
    ${stdout}    ${stderr}    ${rc}=    SSHLibrary.Execute Command    docker-compose up -d    return_stdout=True    return_stderr=True
    ...    return_rc=True
    Wait Until Keyword Succeeds    90s    2s    NetconfCallHome.Check Device Status    DISCONNECTED
    Wait Until Keyword Succeeds    30s    2s    Run Keyword And Expect Error    *    Utils.Check For Elements At URI    ${mount_point_url}
    ...    ${netconf_mount_expected_values}

CallHome with Rogue Devices
    [Documentation]    A Rogue Device will fail to callhome and wont be able to mount because the keys are not added in whitelist.
    ...    FAILED_NOT_ALLOWED should be the device status.
    SSHLibrary.Execute_Command    sed -i -e 's,\/root\/whitelist_add.sh \$\$\{HOSTNAME\}\;,,g' docker-compose.yaml
    ${stdout}    ${stderr}    ${rc}=    SSHLibrary.Execute Command    docker-compose up -d    return_stdout=True    return_stderr=True
    ...    return_rc=True
    # Next line is commented due to https://jira.opendaylight.org/browse/NETCONF-574
    Wait Until Keyword Succeeds    90s    2s    NetconfCallHome.Check Device Status    FAILED_NOT_ALLOWED
    Wait Until Keyword Succeeds    30s    2s    Run Keyword And Expect Error    *    Utils.Check For Elements At URI    ${mount_point_url}
    ...    ${netconf_mount_expected_values}

Successful CallHome with correct global credentials
    [Documentation]    Device being in whitelist of the Call Home server along with correct global credentials will result to successful mount.
    ...    CONNECTED should be the device status.
    ${stdout}    ${stderr}    ${rc}=    SSHLibrary.Execute Command    docker-compose up -d    return_stdout=True    return_stderr=True
    ...    return_rc=True
    Wait Until Keyword Succeeds    90s    2s    NetconfCallHome.Check Device Status    CONNECTED
    Wait Until Keyword Succeeds    30s    2s    Utils.Check For Elements At URI    ${mount_point_url}    ${netconf_mount_expected_values}

Successful CallHome with correct per-device credentials
    [Documentation]    Device being in whitelist of the Call Home server along with correct per-device credentials will result to successful mount.
    ...    CONNECTED should be the device status.
    SSHLibrary.Execute_Command    sed -i -e 's/global/per-device netopeer/g' docker-compose.yaml
    ${stdout}    ${stderr}    ${rc}=    SSHLibrary.Execute Command    docker-compose up -d    return_stdout=True    return_stderr=True
    ...    return_rc=True
    Wait Until Keyword Succeeds    90s    2s    NetconfCallHome.Check Device Status    CONNECTED
    Wait Until Keyword Succeeds    30s    2s    Utils.Check For Elements At URI    ${mount_point_url}    ${netconf_mount_expected_values}
