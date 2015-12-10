*** Settings ***
Documentation     Test the devstack setup
Suite Setup       Devstacksetup
Suite Teardown    Stop Devstack
Resource          ../../../libraries/DevStackKeywords.robot
