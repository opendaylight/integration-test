*** Settings ***
Documentation     Suite Setup for L2GW test suites
Suite Setup       Start Suite
Suite Teardown    Stop Suite
Resource          ../../libraries/L2gwUtils.robot
Resource          ../../variables/l2gw/Variables.robot
Resource          ../../variables/Variables.robot
Resource          ../../libraries/L2GatewayOperations.robot

*** Keywords ***
Start Suite
    [Documentation]    Start suite to set log level to DEBUG and openstack environment files.
    Set Log Level For L2gw    INFO
    Get Environment Config

Stop Suite
    [Documentation]    Reset the log level to INFO
    Set Log Level For L2gw    INFO
    SSHLibrary.Close All Connections
