*** Settings ***
Documentation     Test suite for MD-SAL NSF mininet OF13
Suite Setup       Start Suite
Suite Teardown    Stop Suite
Library           SSHLibrary
Resource          ../../../libraries/Utils.robot

*** Variables ***
${start}          sudo mn --controller=remote,ip=${CONTROLLER} --topo tree,2 --switch ovsk,protocols=OpenFlow13

*** Keywords ***
