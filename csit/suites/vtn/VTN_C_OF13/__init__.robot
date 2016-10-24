*** Settings ***
Documentation     Test suite for AD-SAL NSF mininet OF13
Suite Setup       Start Mininet
Suite Teardown    Stop Mininet
Library           SSHLibrary
Resource          ../../../libraries/VtnCoKeywords.robot

*** Variables ***
${start}          sudo mn --controller=remote,ip=${ODL_SYSTEM_IP} --topo tree,2 --switch ovsk,protocols=OpenFlow13

*** Keywords ***
