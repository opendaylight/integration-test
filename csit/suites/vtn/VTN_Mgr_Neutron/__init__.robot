*** Settings ***
Documentation     Test suite for VTN Manager (OF10)
Suite Setup       Setup Devstack     kilo      local.conf
Suite Teardown    Stop Devstack
Resource          ../../../libraries/DevStackKeywords.robot
