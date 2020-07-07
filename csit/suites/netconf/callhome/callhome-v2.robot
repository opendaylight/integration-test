*** Settings ***
Documentation     Test suite to verify callhome functionality over both transport protocols (TLS and SSH) according to RFC8071.
...               Registration in OpenDaylight Controller is done via new YANG models. Netopeer2-server docker container plays
...               a role of netconf device configured with call-home. Every test case provides custom configuration for
...               netopeer2-server via docker-compose file to cover sunny-day and error scenarios.
Suite Setup       Suite Setup
Suite Teardown    Suite Teardown
Test Setup        Test Setup
Test Teardown     Test Teardown
Resource          ../../../libraries/NetconfCallHomeV2.robot


*** Test Cases ***
CallHome over SSH with correct credentials
    [Documentation]    Correct credentials should result to successful mount. CONNECTED should be the device status.
    NetconfCallHomeV2.Apply SSH-based Call-Home configuration
    ${stdout}    ${stderr}    ${rc}=    SSHLibrary.Execute Command    docker-compose up -d    return_stdout=True    return_stderr=True
    ...    return_rc=True
    Wait Until Keyword Succeeds    90s    2s    NetconfCallHome.Check Device Status    CONNECTED
    Wait Until Keyword Succeeds    90s    2s    Run Keyword And Expect Error    *    Utils.Check For Elements At URI    ${mount_point_url}
    ...    ${netconf_mount_expected_values}
