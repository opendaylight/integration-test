*** Settings ***
#Documentation     Test suite for AD-SAL NSF mininet OF13
#Suite Setup       Start Suite
#Suite Teardown    Stop Suite
#Library           SSHLibrary
#Resource          ../../../libraries/VtnCoKeywords.robot

*** Variables ***
#${start}          sudo mn --controller=remote,ip=${CONTROLLER} --topo tree,2 --switch ovsk,protocols=OpenFlow13

*** Keywords ***
