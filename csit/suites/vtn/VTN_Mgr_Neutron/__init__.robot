*** Settings ***
Documentation     Test suite for VTN Manager (OF10)
Suite Setup       Setup Devstack     kilo      local.conf
Suite Teardown    Stop SuiteVtnMa
Resource          ../../../libraries/DevStackKeywords.robot
