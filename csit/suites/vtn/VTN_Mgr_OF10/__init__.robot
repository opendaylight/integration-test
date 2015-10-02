*** Settings ***
Documentation     Test suite for VTN Manager (OF10)
Suite Setup       Start SuiteVtnMa
Suite Teardown    Stop SuiteVtnMa
Resource          ../../../libraries/VtnMaKeywords.robot

*** Variables ***
${start}          sudo mn --controller=remote,ip=${CONTROLLER} --topo tree,2
