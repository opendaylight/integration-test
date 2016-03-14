*** Settings ***
Documentation     Test suite for VTN Manager (OF13)
Suite Setup       Start SuiteVtnMa     OF13_Li
Suite Teardown    Stop SuiteVtnMa
Resource          ../../../libraries/VtnMaKeywordsLi.robot

*** Variables ***
${start}          sudo mn --controller=remote,ip=${ODL_SYSTEM_IP} --topo tree,2 --switch ovsk,protocols=OpenFlow13
