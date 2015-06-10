*** Settings ***
Documentation     Test suite for VTN Manager (OF13)
Suite Setup       Start SuiteVtnMa
Suite Teardown    Stop SuiteVtnMa
Resource          ../../../libraries/VtnMaKeywords.txt

*** Variables ***
${start}=   sudo mn --controller=remote,ip=${CONTROLLER} --topo tree,2 --switch ovsk,protocols=OpenFlow13
