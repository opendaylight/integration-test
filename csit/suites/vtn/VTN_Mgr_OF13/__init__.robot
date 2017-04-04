*** Settings ***
Documentation     Test suite for VTN Manager (OF13)
Suite Setup       Start SuiteVtnMa
Suite Teardown    Stop SuiteVtnMa
Test Teardown     Collect Debug Info
Resource          ../../../libraries/VtnMaKeywords.robot

*** Variables ***
${start}          sudo mn --controller=remote,ip=${ODL_SYSTEM_IP} --topo tree,2 --switch ovsk,protocols=OpenFlow13
${start_cluster}          --topo tree,2 --switch ovsk,protocols=OpenFlow13
