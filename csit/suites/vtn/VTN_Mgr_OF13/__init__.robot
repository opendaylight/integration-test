*** Settings ***
Documentation     Test suite for VTN Manager (OF13)
Suite Setup       Start SuiteVtnMa
Suite Teardown    Stop SuiteVtnMa
Test Teardown     Collect Debug Info
Resource          ../../../libraries/VtnMaKeywords.robot

*** Variables ***
${start}          --topo tree,2
