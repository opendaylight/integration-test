*** Settings ***
Documentation     Test suite for VTN Manager (OF10)
Suite Setup       Start SuiteVtnMa
Suite Teardown    Stop SuiteVtnMa
Resource          ../../../libraries/VtnMaKeywordsLi.robot

*** Variables ***
${start}          sudo mn --controller=remote,ip=${ODL_SYSTEM_IP} --topo tree,2
