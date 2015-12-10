*** Settings ***
Documentation     Test the devstack setup
Suite Setup       Start Devstack setup
Suite Teardown    Stop Devstack
Resource          ../../../libraries/DevStackKeywords.robot
