*** Settings ***
Documentation     Test suite for VTN Manager (OF10)
Suite Setup       Start SuiteVtnMa
Suite Teardown    Stop SuiteVtnMa
Test Teardown     Collect Debug Info
Resource          ../../../libraries/VtnMaKeywords.robot

*** Variables ***
${start}          sudo mn --switch ovsk,protocols=OpenFlow13 --controller=remote,ip=${ODL_SYSTEM_IP} --topo tree,2
