*** Settings ***
Documentation     Test suite to verify callhome functionality.
Suite Setup       Suite Setup
Suite Teardown    Suite Teardown
Test Setup        Reset Docker Compose Configuration
Test Teardown     Test Teardown
Resource          ../../../libraries/NetconfCallHome.robot

*** Test Cases ***
CallHome with Incorrect global Credentials
    [Documentation]    Incorrect global credentials should result to mount failure. FAILED_AUTH_FAILURE should be the device status.
    SSHLibrary.Execute_Command    sed -i -e 's/test/incorrect/g' docker-compose.yaml
    ${stdout}    ${stderr}    ${rc}=    SSHLibrary.Execute Command    docker-compose up -d    return_stdout=True    return_stderr=True
    ...    return_rc=True
    Wait Until Keyword Succeeds    30s    2s    Run Keyword And Expect Error    *    Do Controller Get Expect Success    ${mount_point_url}
    ...    ${substring1}    ${substring2}    ${substring3}

CallHome with Incorrect per-device Credentials
    [Documentation]    Incorrect per-device credentials should result to mount failure. FAILED_AUTH_FAILURE should be the device status.
    SSHLibrary.Execute_Command    sed -i -e 's/global/per-device netopeer/g' docker-compose.yaml    return_rc=True
    SSHLibrary.Execute_Command    sed -i -e 's/test/incorrect/g' docker-compose.yaml
    ${stdout}    ${stderr}    ${rc}=    SSHLibrary.Execute Command    docker-compose up -d    return_stdout=True    return_stderr=True
    ...    return_rc=True
    Wait Until Keyword Succeeds    30s    2s    Run Keyword And Expect Error    *    Do Controller Get Expect Success    ${mount_point_url}
    ...    ${substring1}    ${substring2}    ${substring3}

CallHome with Incorrect Node-id
    [Documentation]    CallHome from device that does not have an entry in per-device credential with result to mount point failure.
    SSHLibrary.Execute_Command    sed -i -e 's/global/per-device incorrect_hostname/g' docker-compose.yaml    return_rc=True
    ${stdout}    ${stderr}    ${rc}=    SSHLibrary.Execute Command    docker-compose up -d    return_stdout=True    return_stderr=True
    ...    return_rc=True
    Wait Until Keyword Succeeds    30s    2s    Run Keyword And Expect Error    *    Do Controller Get Expect Success    ${mount_point_url}
    ...    ${substring1}    ${substring2}    ${substring3}

CallHome with Rogue Devices
    [Documentation]    A Rogue Device will fail to callhome and wont be able to mount because the keys are not added in whitelist. FAILED_NOT_ALLOWED should be the device status.
    SSHLibrary.Execute_Command    sed -i -e 's,\/root\/whitelist_add.sh \$\$\{HOSTNAME\}\;,,g' docker-compose.yaml
    ${stdout}    ${stderr}    ${rc}=    SSHLibrary.Execute Command    docker-compose up -d    return_stdout=True    return_stderr=True
    ...    return_rc=True
    Wait Until Keyword Succeeds    30s    2s    Run Keyword And Expect Error    *    Do Controller Get Expect Success    ${mount_point_url}
    ...    ${substring1}    ${substring2}    ${substring3}

Successful CallHome with correct global credentials
    [Documentation]    Device being in whitelist of the Call Home server along with correct global credentials will result to successful mount.CONNECTED should be the device status.
    ${stdout}    ${stderr}    ${rc}=    SSHLibrary.Execute Command    docker-compose up -d    return_stdout=True    return_stderr=True
    ...    return_rc=True
    Wait Until Keyword Succeeds    30s    2s    Do Controller Get Expect Success    ${mount_point_url}    ${substring1}    ${substring2}
    ...    ${substring3}

Successful CallHome with correct per-device credentials
    [Documentation]    Device being in whitelist of the Call Home server along with correct per-device credentials will result to successful mount.CONNECTED should be the device status.
    SSHLibrary.Execute_Command    sed -i -e 's/global/per-device netopeer/g' docker-compose.yaml
    ${stdout}    ${stderr}    ${rc}=    SSHLibrary.Execute Command    docker-compose up -d    return_stdout=True    return_stderr=True
    ...    return_rc=True
    Wait Until Keyword Succeeds    30s    2s    Do Controller Get Expect Success    ${mount_point_url}    ${substring1}    ${substring2}
    ...    ${substring3}

*** Keywords ***
