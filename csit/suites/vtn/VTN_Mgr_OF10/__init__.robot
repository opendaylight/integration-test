*** Settings ***
Documentation       Test suite for VTN Manager (OF10)

Resource            ../../../libraries/VtnMaKeywords.robot

Suite Setup         Start SuiteVtnMa
Suite Teardown      Stop SuiteVtnMa
Test Teardown       Collect Debug Info


*** Variables ***
${start}    sudo mn --controller=remote,ip=${ODL_SYSTEM_IP} --topo tree,2 --switch ovsk,protocols=OpenFlow10
